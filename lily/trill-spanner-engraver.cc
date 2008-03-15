/*
  trill-spanner-engraver.cc -- implement Trill_spanner_engraver

  source file of the GNU LilyPond music typesetter

  (c) 2000--2007 Jan Nieuwenhuizen <janneke@gnu.org>
*/

/*
  C&P from text-spanner.cc

  - todo: ending should be detected automatically? a new note
  automatically is the end of the trill?
*/

#include "engraver.hh"

#include "international.hh"
#include "note-column.hh"
#include "pointer-group-interface.hh"
#include "side-position-interface.hh"
#include "stream-event.hh"
#include "spanner.hh"

#include "translator.icc"

class Trill_spanner_engraver : public Engraver
{
public:
  TRANSLATOR_DECLARATIONS (Trill_spanner_engraver);
protected:
  virtual void finalize ();
  DECLARE_TRANSLATOR_LISTENER (trill_span);
  DECLARE_ACKNOWLEDGER (note_column);

  void stop_translation_timestep ();
  void process_music ();

private:
  Spanner *span_;
  Spanner *finished_;
  Stream_event *current_event_;
  Drul_array<Stream_event *> event_drul_;
  void typeset_all ();
};

Trill_spanner_engraver::Trill_spanner_engraver ()
{
  finished_ = 0;
  current_event_ = 0;
  span_ = 0;
  event_drul_[START] = 0;
  event_drul_[STOP] = 0;
}

IMPLEMENT_TRANSLATOR_LISTENER (Trill_spanner_engraver, trill_span);
void
Trill_spanner_engraver::listen_trill_span (Stream_event *ev)
{
  Direction d = to_dir (ev->get_property ("span-direction"));
  ASSIGN_EVENT_ONCE (event_drul_[d], ev);
}

void
Trill_spanner_engraver::acknowledge_note_column (Grob_info info)
{
  if (span_) {
    Pointer_group_interface::add_grob (span_,
				       ly_symbol2scm ("note-columns"),
				       info.grob());
    add_bound_item (span_, info.grob ());
  } else if (finished_) {
    Pointer_group_interface::add_grob (finished_, ly_symbol2scm ("note-columns"),
				       info.grob());
    add_bound_item (finished_, info.grob ());
  }
}

void
Trill_spanner_engraver::process_music ()
{
  if (event_drul_[STOP])
    {
      if (!span_)
	event_drul_[STOP]->origin ()->warning (_ ("cannot find start of trill spanner"));
      else
	{
	  finished_ = span_;
	  announce_end_grob (finished_, SCM_EOL);
	  span_ = 0;
	  current_event_ = 0;
	}
    }

  if (event_drul_[START])
    {
      if (current_event_)
	event_drul_[START]->origin ()->warning (_ ("already have a trill spanner"));
      else
	{
	  current_event_ = event_drul_[START];
	  span_ = make_spanner ("TrillSpanner", event_drul_[START]->self_scm ());
	  Side_position_interface::set_axis (span_, Y_AXIS);
	  event_drul_[START] = 0;
	}
    }
}

void
Trill_spanner_engraver::typeset_all ()
{
  if (finished_)
    {
      if (!finished_->get_bound (RIGHT))
	{
	  Grob *e = unsmob_grob (get_property ("currentMusicalColumn"));
	  finished_->set_bound (RIGHT, e);
	}
      finished_ = 0;
    }
}

void
Trill_spanner_engraver::stop_translation_timestep ()
{
  if (span_ && !span_->get_bound (LEFT))
    {
      Grob *e = unsmob_grob (get_property ("currentMusicalColumn"));
      span_->set_bound (LEFT, e);
    }

  typeset_all ();
  event_drul_[START] = 0;
  event_drul_[STOP] = 0;
}

void
Trill_spanner_engraver::finalize ()
{
  typeset_all ();
  if (span_)
    {
      finished_ = span_;
      typeset_all ();
    }
}

ADD_ACKNOWLEDGER (Trill_spanner_engraver, note_column);

ADD_TRANSLATOR (Trill_spanner_engraver,
		/* doc */
		"Create trill spanner from an event.",

		/* create */
		"TrillSpanner ",

		/* read */
		"",

		/* write */
		""
		);
