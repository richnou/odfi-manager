## This file contains TCL configuration of available ODFI modules

## Installation paths
:installPath set [file normalize [file dirname [info script]]/../install/main]


## Main ODFI Module




return
set baseGitURL "http://lebleu/gitlab/odfi"
set baseDevGitURL "gitlab@lebleu:/odfi"

group dev {


	module tcl {

		url default   "https://github.com/unihd-cag/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"
	}

    module tcl-scenegraph {

        url default   "https://github.com/unihd-cag/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }

	module scala {

		url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

	}

    group sublime {

        module scalbuild {

            url default "http://bitbucket.org/richnou/odfi-dev-sublime-scalbuild.git"
            url developer "git@bitbucket.org:richnou/odfi-dev-sublime-scalbuild.git"

        }

    }

    module cpp {

        url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }

    module maven {

        url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"
    }

    module hw {

        url default   "https://github.com/unihd-cag/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"
        
    }

}

group implementation {


    module physicaldesign {

       url default    https://github.com/kit-adl/odfi-implementation-physicaldesign.git
       url developer  git@github.com:kit-adl/odfi-implementation-physicaldesign.git
    }

    module xilinx {

        url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }

}

group integration {


    module mbuild {

        url default   "https://github.com/richnou/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }



}

group testing {

    module quality-validation {

        url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }

}

group collaboration {

    module doc {

        url default   "$baseGitURL/odfi-${name}.git"
        url developer "$baseDevGitURL/odfi-${name}.git"

    }

}


## TCL
group tcl {
    
    module integration {
        url default   "https://github.com/richnou/odfi-${name}.git"
        url developer   "https://github.com/richnou/odfi-${name}.git"
    }
}


## RFG
module rfg {
    url default   "https://github.com/unihd-cag/odfi-${name}.git"
}

module rfg3 {
  url default   "git@github.com:richnou/rfg3.git"
}

## Vendors
group vendor {
    module cadence {
        url default https://github.com/richnou/odfi-vendor-cadence.git	
    }
}
