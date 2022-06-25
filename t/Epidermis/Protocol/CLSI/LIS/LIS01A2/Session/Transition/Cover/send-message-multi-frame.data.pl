{
local =>
	[
		[ STATE_N_IDLE , SendMsgWithMultipleFrames(3) ],
		[ STATE_N_IDLE , StepUntilIdle() ],
		[ STATE_N_IDLE , TestTransition(EV_TRANSFER_DONE) ],
	],
remote =>
	[
		[ STATE_N_IDLE , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]

}
