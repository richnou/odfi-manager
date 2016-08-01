set location [file dirname [info script]]

source $location/../../private/odfi.tm

package require odfi::utests 1.0.0

## Create a default test odfi
################
set odfi [::odfi::odfi test]

## Create two test config
###########
$odfi config test.first {
    
    :installPath set $location/rep
    
    ## Create Modules with various versions
    ##########
    
    :module a {
        :version 1.0
    }
    
    :module a {
        :version 1.1
    }
    :module a {
        :version 1.2
    }
    
    :module b {
        :module a {
            :module a {
                :version  1.0
            }
        }
    }
} 

$odfi config test.second {
    
    :installPath set $location/rep
    
    ## Create Modules with various versions
    ##########
    
    :module a {
        :version 1.3
    }
    
    :module a {
        :version 1.4
    }
    :module a {
        :version 1.5
    }
    
    :module b {
        :module a {
            :module a {
                :version 1.1
            }
        }
    }
} 

## Check FInd Module
################
odfi::utests::suite command_find {

    :test "find module a all version" {
    
        set modules [$odfi findModules a]
        puts "Searching for A Module: [$modules size]"
        
        :assert "6 Module a are defined" 6 [$module size]"
        
    }

}


## Run some commands
###########################



## 