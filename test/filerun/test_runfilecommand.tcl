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

## Look for a FileCommand, meaning a command which is a file to be run, without first explicit details on what kind of file it is
odfi::utests::suite main {

    :test "Simple Bash Script" {
        
        
        :assertNXObject [$odfi resolveCommand aBashCommand] -> cmd
        :assert "Command is BashStyle" true [$cmd isBash]
        
    }
    
    :test "TCL Command" {
        
        :assertNXObject [$odfi resolveCommand aTCLCommand] -> cmd
        :assert "Command is TCL" true [$cmd isTCL]
        $odfi runCommand $cmd
    }

}
odfi::utests::run