/*
  This file is part of LilyPond, the GNU music typesetter.

  Copyright (C) 1999--2011 Han-Wen Nienhuys <hanwen@xs4all.nl>

  LilyPond is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  LilyPond is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with LilyPond.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "context.hh"
#include "beaming-pattern.hh"

/*
  Represents a stem belonging to a beam. Sometimes (for example, if the stem
  belongs to a rest and stemlets aren't used) the stem will be invisible.

  The rhythmic_importance_ of an element tells us the significance of the
  moment at which this element occurs. For example, an element that occurs at
  a beat is more significant than one that doesn't. Smaller number are
  more important. The rhythmic_importance_ is decided and filled in by
  Beaming_pattern. A rhythmic_importance_ smaller than zero has extra
  significance: it represents the start of a beat and therefore beams may
  need to be subdivided.
*/
Beam_rhythmic_element::Beam_rhythmic_element ()
{
  start_moment_ = 0;
  rhythmic_importance_ = 0;
  beam_count_drul_[LEFT] = 0;
  beam_count_drul_[RIGHT] = 0;
  invisible_ = false;
  factor_ = Rational (1);

}

Beam_rhythmic_element::Beam_rhythmic_element (Moment m, int i, bool inv, Rational factor)
{
  start_moment_ = m;
  rhythmic_importance_ = 0;
  beam_count_drul_[LEFT] = i;
  beam_count_drul_[RIGHT] = i;
  invisible_ = inv;
  factor_ = factor;
}

void
Beam_rhythmic_element::de_grace ()
{
  if (start_moment_.grace_part_)
    {
      start_moment_.main_part_ = start_moment_.grace_part_;
      start_moment_.grace_part_ = 0;
    }
}

int
Beam_rhythmic_element::count (Direction d) const
{
  return beam_count_drul_[d];
}

/*
  Finds the appropriate direction for the flags at the given index that
  hang below the neighbouring flags. If
  the stem has no more flags than either of its neighbours, this returns
  CENTER.
*/
Direction
Beaming_pattern::flag_direction (Beaming_options const &options, vsize i) const
{
  // The extremal stems shouldn't be messed with, so it's appropriate to
  // return CENTER here also.
  if (i == 0 || i == infos_.size () - 1)
    return CENTER;

  int count = infos_[i].count (LEFT); // Both directions should still be the same
  int left_count = infos_[i - 1].count (RIGHT);
  int right_count = infos_[i + 1].count (LEFT);

  // If we are told to subdivide beams and we are next to a beat, point the
  // beamlet away from the beat.
  if (options.subdivide_beams_)
    {
      if (infos_[i].rhythmic_importance_ < 0)
        return RIGHT;
      else if (infos_[i + 1].rhythmic_importance_ < 0)
        return LEFT;
    }

  if (count <= left_count && count <= right_count)
    return CENTER;

  // If all else fails, point the beamlet away from the important moment.
  return (infos_[i].rhythmic_importance_ <= infos_[i + 1].rhythmic_importance_)
         ? RIGHT : LEFT;
}

void
Beaming_pattern::de_grace ()
{
  for (vsize i = 0; i < infos_.size (); i++)
    {
      infos_[i].de_grace ();
    }
}

void
Beaming_pattern::beamify (Beaming_options const &options)
{
  if (infos_.size () <= 1)
    return;

  unbeam_invisible_stems ();

  if (infos_[0].start_moment_.grace_part_)
    de_grace ();

  if (infos_[0].start_moment_ < Moment (0))
    for (vsize i = 0; i < infos_.size (); i++)
      infos_[i].start_moment_ += options.measure_length_;

  find_rhythmic_importance (options);

  vector <Direction> flag_directions;
  // Get the initial flag directions
  for (vsize i = 0; i < infos_.size (); i++)
    flag_directions.push_back (flag_direction (options, i));

  // Correct flag directions for subdivision
  for (vsize i = 1; i < infos_.size () - 1; i++)
    {
      if ((flag_directions[i] == CENTER) && (flag_directions[i - 1] == LEFT))
        flag_directions[i] = RIGHT;
      if ((flag_directions[i] == CENTER) && (flag_directions[i + 1] == RIGHT))
        flag_directions[i] = LEFT;
    }

  // Set the count on each side of the stem
  // We need to run this code twice to make both the
  // left and the right counts work properly
  for (int i = 0; i < 2; i++)
    for (vsize i = 1; i < infos_.size () - 1; i++)
      {
        Direction non_flag_dir = other_dir (flag_directions[i]);
        if (non_flag_dir)
          {
            int importance = infos_[i + 1].rhythmic_importance_;
            int count = (importance < 0 && options.subdivide_beams_)
                        ? 1 : min (min (infos_[i].count (non_flag_dir),
                                        infos_[i + non_flag_dir].count (-non_flag_dir)),
                                   infos_[i - non_flag_dir].count (non_flag_dir));

            infos_[i].beam_count_drul_[non_flag_dir] = count;
          }
      }
}

/*
   Get the group start position, the next group starting position, and the
   next beat starting position, given start_moment, base_moment,
   grouping, and factor
*/
void
find_location (SCM grouping, Moment base_moment, Moment start_moment,
               Rational factor, Moment *group_pos, Moment *next_group_pos,
               Moment *next_beat_pos)
{
  *group_pos = Moment (0);
  *next_group_pos = Moment (0);
  *next_beat_pos = base_moment;

  while (*next_beat_pos <= start_moment)
    *next_beat_pos += base_moment;

  while (*next_group_pos < *next_beat_pos)
    {
      int count = 1;  //default -- 1 base moments in a beam
      if (scm_is_pair (grouping))
        {
          count = scm_to_int (scm_car (grouping));
          grouping = scm_cdr (grouping);
        }

      // If we have a tuplet, the count should be determined from
      // the maximum tuplet size for beamed tuplets.
      int tuplet_count = factor.num ();
      if (tuplet_count > 1)
        {
          // We use 1/8 as the base moment for the tuplet because it's
          // the largest beamed value.  If the tuplet is shorter, it's
          // OK, the code still works
          int test_count = (tuplet_count * Moment (Rational (1, 8)) / base_moment).num ();
          if (test_count > count) count = test_count;
        }
      *group_pos = *next_group_pos;
      *next_group_pos = *group_pos + count * base_moment;
    }
}

void
Beaming_pattern::find_rhythmic_importance (Beaming_options const &options)
{
  Moment group_pos (0);  // 0 is the start of the first group
  Moment next_group_pos (0);
  Moment next_beat_pos (options.base_moment_);
  int tuplet_count = 1;

  SCM grouping = options.grouping_;
  vsize i = 0;

  // Find where we are in the beat structure of the measure
  if (infos_.size ())
    find_location (grouping, options.base_moment_, infos_[i].start_moment_,
                   infos_[i].factor_, &group_pos, &next_group_pos, &next_beat_pos);

  // Mark the importance of stems that start at a beat or a beat group.
  while (i < infos_.size ())
    {
      tuplet_count = infos_[i].factor_.den ();
      if ((next_beat_pos > next_group_pos)
          || (infos_[i].start_moment_ > next_beat_pos))
        // Find the new group ending point
        find_location (grouping, options.base_moment_, infos_[i].start_moment_,
                       infos_[i].factor_, &group_pos, &next_group_pos, &next_beat_pos);
      // Mark the start of this beat group
      if (infos_[i].start_moment_ == group_pos)
        infos_[i].rhythmic_importance_ = -2;
      // Work through the end of the beat group or the end of the beam
      while (i < infos_.size () && infos_[i].start_moment_ < next_group_pos)
        {
          Moment dt = infos_[i].start_moment_ - group_pos;
          Rational tuplet = infos_[i].factor_;
          Moment tuplet_moment (tuplet);
          // set the beat end (if not in a tuplet) and increment the next beat
          if (tuplet_count == 1 && infos_[i].start_moment_ == next_beat_pos)
            {
              infos_[i].rhythmic_importance_ = -1;
              next_beat_pos += options.base_moment_;
            }
          // The rhythmic importance of a stem between beats depends on its fraction
          // of a beat: those stems with a lower denominator are deemed more
          // important.  For tuplets, we need to make sure that we use
          // the fraction of the tuplet, instead of the fraction of
          // a beat.
          Moment ratio = (dt / options.base_moment_ / tuplet_moment);
          if (infos_[i].rhythmic_importance_ >= 0)
            infos_[i].rhythmic_importance_ = (int) ratio.den ();
          i++;
        }

      if (i < infos_.size () && infos_[i].start_moment_ == next_beat_pos)
        {
          if (tuplet_count == 1)
            infos_[i].rhythmic_importance_ = -1;
          next_beat_pos += options.base_moment_;
          if (infos_[i].start_moment_ == next_group_pos)
            infos_[i].rhythmic_importance_ = -2;
          i++;
        }
    }
}

/*
  Invisible stems should be treated as though they have the same number of
  beams as their least-beamed neighbour. Here we go through the stems and
  modify the invisible stems to satisfy this requirement.
*/
void
Beaming_pattern::unbeam_invisible_stems ()
{
  for (vsize i = 1; i < infos_.size (); i++)
    if (infos_[i].invisible_)
      {
        int b = min (infos_[i].count (LEFT), infos_[i - 1].count (LEFT));
        infos_[i].beam_count_drul_[LEFT] = b;
        infos_[i].beam_count_drul_[RIGHT] = b;
      }

  if (infos_.size () > 1)
    for (vsize i = infos_.size () - 1; i--;)
      if (infos_[i].invisible_)
        {
          int b = min (infos_[i].count (LEFT), infos_[i + 1].count (LEFT));
          infos_[i].beam_count_drul_[LEFT] = b;
          infos_[i].beam_count_drul_[RIGHT] = b;
        }
}

void
Beaming_pattern::add_stem (Moment m, int b, bool invisible, Rational factor)
{
  infos_.push_back (Beam_rhythmic_element (m, b, invisible, factor));
}

Beaming_pattern::Beaming_pattern ()
{
}

int
Beaming_pattern::beamlet_count (int i, Direction d) const
{
  return infos_.at (i).beam_count_drul_[d];
}

Moment
Beaming_pattern::start_moment (int i) const
{
  return infos_.at (i).start_moment_;
}

Moment
Beaming_pattern::end_moment (int i) const
{
  Duration *dur = new Duration (2 + max (beamlet_count (i, LEFT),
                                         beamlet_count (i, RIGHT)),
                                0);

  return infos_.at (i).start_moment_ + dur->get_length ();
}

bool
Beaming_pattern::invisibility (int i) const
{
  return infos_.at (i).invisible_;
}

Rational
Beaming_pattern::factor (int i) const
{
  return infos_.at (i).factor_;
}

/*
    Split a beaming pattern at index i and return a new
    Beaming_pattern containing the removed elements
*/
Beaming_pattern *
Beaming_pattern::split_pattern (int i)
{
  Beaming_pattern *new_pattern = 0;
  int count;

  new_pattern = new Beaming_pattern ();
  for (vsize j = i + 1; j < infos_.size (); j++)
    {
      count = max (beamlet_count (j, LEFT), beamlet_count (j, RIGHT));
      new_pattern->add_stem (start_moment (j),
                             count,
                             invisibility (j),
                             factor (j));
    }
  for (vsize j = i + 1; j < infos_.size ();)
    infos_.pop_back ();
  return (new_pattern);
}

void
Beaming_options::from_context (Context *context)
{
  grouping_ = context->get_property ("beatStructure");
  subdivide_beams_ = to_boolean (context->get_property ("subdivideBeams"));
  base_moment_ = robust_scm2moment (context->get_property ("baseMoment"),
                                    Moment (1, 4));
  measure_length_ = robust_scm2moment (context->get_property ("measureLength"),
                                       Moment (4, 4));
}

Beaming_options::Beaming_options ()
{
  grouping_ = SCM_EOL;
  subdivide_beams_ = false;
}
