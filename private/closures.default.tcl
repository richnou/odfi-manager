#####################################
## This file contains closures that are registered in some manager objects
##  - They are the defaults,but the user can add some closures.xxxx.tcl files here, to overwrite or complete some
#######################################

closurePoint load {

	## bin -> PATH
	#####################
	if {[file exists $path/bin]} {
		$loadResult env PATH $path/bin
	}

	## TCL Library
	####################
	foreach tclLibPath {
		tcl
		scripts/tcl
	} {

		if {[file exists $path/$tclLibPath]} {
			$loadResult env TCLLIBPATH $path/$tclLibPath -separator " "
		}


	}

}
