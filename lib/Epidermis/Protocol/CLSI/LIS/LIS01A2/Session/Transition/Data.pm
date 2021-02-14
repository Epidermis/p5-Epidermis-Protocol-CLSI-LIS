package Epidermis::Protocol::CLSI::LIS::LIS01A2::Session::Transition::Data;
# ABSTRACT: Data transitions

use Moo::Role;
use Future::AsyncAwait;

async sub event_on_good_frame {
	...
}

async sub event_on_get_frame {
	...
}
async sub event_on_has_data_to_send {
}
async sub event_on_not_has_data_to_send {
}
async sub event_on_bad_frame {
}

1;
