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
		[ STATE_R_GOOD_FRAME , TestLastFrameGood("\x021frame 1\x17A4\r\n") ],
		[ STATE_R_GOOD_FRAME , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , TestLastFrameGood("\x022frame 2\x17A6\r\n") ],
		[ STATE_R_GOOD_FRAME , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , TestLastFrameGood("\x023frame 3\x0394\r\n") ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]

}
