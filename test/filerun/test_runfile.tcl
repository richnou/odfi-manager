set location [file dirname [info script]]
source $location/../../private/odfi.tm
package require odfi::utests 1.0.0

## Create a default test odfi
################
set odfi [::odfi::odfi test]
set testConfig [$odfi config testconfig {
    
    :installPath set $location/../data/repo
}]
$odfi gatherModules

## Run File
$odfi runCommand $location/boot.tcl