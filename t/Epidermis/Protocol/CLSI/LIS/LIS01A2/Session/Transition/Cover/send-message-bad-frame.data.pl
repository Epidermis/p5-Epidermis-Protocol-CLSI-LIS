{
local =>
	[
		[ STATE_N_IDLE , EnableCorruption() ],
		[ STATE_N_IDLE , SendMsgWithSingleFrame() ],

		[ STATE_N_IDLE , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 1 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 2 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 3 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 4 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 5 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_S_TRANSFER_SETUP_OLD_FRAME) ],
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , TestTransition(EV_RECEIVE_NAK_OR_FAIL) ], # sent 6 (bad)
		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , PrintRetryCount() ],

		[ STATE_S_TRANSFER_SETUP_OLD_FRAME , StepUntil(STATE_N_IDLE) ], # no more retries
		[ STATE_N_IDLE    ,   TestTransition(EV_NO_CAN_RETRY) ],
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
		[ STATE_R_WAITING        , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 4
		[ STATE_R_WAITING        , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 5
		[ STATE_R_WAITING        , StepUntil(STATE_R_WAITING) ],

		[ STATE_R_WAITING , TestLastFrameBad("\x021Hello world\x0371\r\n")	], # 6
		[ STATE_R_WAITING        , StepUntil(STATE_N_IDLE) ],
	]
}
