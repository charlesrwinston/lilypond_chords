\version "1.5.68"

\score{
	\context PianoStaff <
		\context StaffCombineStaff=one \skip 1*7
		\context StaffCombineStaff=two \skip 1*7
		\context StaffCombineStaff=one \partcombine StaffCombineStaff
			\context StaffCombineVoice=one \notes\relative c''
				{
					c4 d e f\break
					c d e f\break
					c d e f
					c4 d e f\break
					a8 a a a b b b b
					a,4 a a a\break
					c2 e4 f\break
				}
			\context StaffCombineVoice=two \notes\relative c''
				{
					c2 e2
					c4 d e f
					c2 e2
					c,4 d e f
					a8 a a a b b b b
					a4 a a a
					c2 e2
				}
		>
	\paper {

		textheight = 295.0\mm
		linewidth = 180.0\mm

		\translator{ \HaraKiriStaffContext }
		%
		% The Voice combine hierarchy
		%
		\translator{
			\ThreadContext
			\name "VoiceCombineThread"
			\consists "Rest_engraver"
		}
		\translator{
			\VoiceContext
			\name "VoiceCombineVoice"
			soloText = #"I."
			soloIIText = #"II."
			\remove "Rest_engraver"
			\accepts "VoiceCombineThread"
		}
		\translator{
			\HaraKiriStaffContext
			\consists "Mark_engraver"
			\name "VoiceCombineStaff"
			\accepts "VoiceCombineVoice"
		}

		%
		% The Staff combine hierarchy
		%
		\translator{
			\ThreadContext
			\name "StaffCombineThread"
		}
		\translator{
			\VoiceContext
			\name "StaffCombineVoice"
			\accepts "StaffCombineThread"
			\consists "Thread_devnull_engraver"
		}
		\translator {
			\HaraKiriStaffContext
			\name "StaffCombineStaff"
			\accepts "StaffCombineVoice"

			soloADue = ##t
			soloText = #""
			soloIIText = #""
			aDueText = #""
			splitInterval = #'(1 . 0)
			changeMoment = #`(,(make-moment 1 1) . ,(make-moment 1 1))

		}
		\translator {
			\StaffGroupContext
			\accepts "VoiceCombineStaff"
			\accepts "StaffCombineStaff"
		}
		\translator{ \HaraKiriStaffContext }

		\translator {
			\ScoreContext
			\accepts "VoiceCombineStaff"
			\accepts "StaffCombineStaff"
			skipBars = ##t 

			barScriptPadding = #2.0 % dimension \pt
			markScriptPadding = #4.0

			%% urg: in pt?
			barNumberScriptPadding = #15
			%% URG: this changes dynamics too
			%%textStyle = #"italic"
			TimeSignature \override #'style = #'C
			maximumRestCount = #1
		}
	}
}
