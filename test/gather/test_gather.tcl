set location [file dirname [info script]]
source $location/../../private/odfi.tm
package require odfi::utests 1.0.0


## Create a default test odfi
################
set odfi [::odfi::odfi test]
set testConfig [$odfi config testconfig {
    
    :installPath set $location/../data/repo
}]

::odfi::utests::suite gathering {

    :test "Gather Once Gives One module Instance" {
        
        $odfi gatherModules
        
        set found [$odfi findModules a]
        :assert "A found once" 1 [$found @> size]
        puts "A: [$found at 0]"
    }
    
    :test "Second Gather Keeps one module instance, and the same one" {
    
        $odfi gatherModules
        
        set found [$odfi findModules a]
        :assert "A found once" 1 [$found  @> size]
        puts "A: [$found at 0]"
    
    }
    
    :test "Searching without version, returns multiple modules" {
        
        $odfi gatherModules
        set found [$odfi findModules d]
        :assert "D found twice" 2 [$found @> size]
    }
    
    :test "Searching with Version" {
    
        set found [$odfi findModules d/1.0]
        :assert "D found once" 1 [$found @> size]
    }
}

::odfi::utests::run 

return
