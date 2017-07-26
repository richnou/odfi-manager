set location [file dirname [info script]]
source $location/../../private/odfi.tm
package require odfi::utests 1.0.0


## Create a default test odfi
################
set odfi [::odfi::odfi test]
set testConfig [$odfi config testconfig {
    
    :installPath set $location/../data/repo
}]

## Look for modules
#############
$odfi gatherModules


## Create Environment
################
odfi::utests::suite main {
    
    :test "Environment Variables Check" {
        
        set rEnv [$odfi env:environment]
        set pathValue [$rEnv shade ::odfi::environment::Variable findChildrenByProperty name PATH]
        
        :assert "Number of updates to PATH variable" 1 [$pathValue size]
        #puts "Number of Path updated: [$pathValue size]"
        
    }
    
    :test "Prescript Check for TCL" {
    
        set rEnv [$odfi env:environment]
        set preScripts [$rEnv shade ::odfi::environment::PreScript children]
        
        :assert "Number of TCL prescripts" 1 [$preScripts size]
    
    }
    

}
odfi::utests::run

