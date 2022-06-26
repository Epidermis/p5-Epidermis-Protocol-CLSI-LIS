{
local =>
	[
		[ STATE_N_IDLE , SendMsgWithSingleFrame() ],
		[ STATE_N_IDLE , StepUntilIdle() ],
		[ STATE_N_IDLE , TestTransition(EV_TIMED_OUT) ],
	],
remote =>
	[
		[ STATE_N_IDLE , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME, SleepPlus('sender') ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]

}
