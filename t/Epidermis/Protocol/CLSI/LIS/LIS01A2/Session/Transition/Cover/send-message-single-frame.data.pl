{
local =>
	[
		[ STATE_N_IDLE , SendMsgWithSingleFrame() ],
		[ STATE_N_IDLE , StepUntilIdle() ],
		[ STATE_N_IDLE , TestTransition(EV_TRANSFER_DONE) ],
	],
remote =>
	[
		[ STATE_N_IDLE , StepUntil(STATE_R_GOOD_FRAME) ],
		[ STATE_R_GOOD_FRAME , TestLastFrameGood("\x021Hello world\x0370\r\n") ],
		[ STATE_R_GOOD_FRAME , StepUntilIdle() ],
	]

}
