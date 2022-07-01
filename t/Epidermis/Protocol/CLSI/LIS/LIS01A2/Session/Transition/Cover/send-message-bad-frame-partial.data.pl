{
local =>
	[
		[ STATE_N_IDLE , EnableCorruption() ],
		[ STATE_N_IDLE , SendMsgWithSingleFrame() ],

		[ STATE_N_IDLE , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 1 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestRetryCount(1) ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 2 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestRetryCount(2) ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 3 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestRetryCount(3) ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , DisableCorruption() ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_NEXT_FRAME) ],

		[ STATE_S_TRANSFER_SETUP_NEXT_FRAME, TestTransition(EV_RECEIVE_ACK) ],
		[ STATE_S_TRANSFER_SETUP_NEXT_FRAME, StepUntilIdle() ],

		[ STATE_N_IDLE    ,   TestTransition(EV_TRANSFER_DONE) ],
		[ STATE_N_IDLE    ,   TestRetryCount(0) ],
	],
remote =>
	[
		[ STATE_N_IDLE           , StepUntil(STATE_R_FRAME_RECEIVED) ],
		[ STATE_R_FRAME_RECEIVED , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 1
		[ STATE_R_WAITING        , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 2
		[ STATE_R_WAITING        , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 3

		[ STATE_R_WAITING        , StepUntil(STATE_R_GOOD_FRAME) ],

		[ STATE_R_GOOD_FRAME , TestLastFrameGood("\x021Hello world\x0370\r\n") ],
		[ STATE_R_GOOD_FRAME , StepUntil(STATE_N_IDLE) ],
	]
}
