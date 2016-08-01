set location [file dirname [info script]]
source $location/../../private/odfi.tm
package require odfi::utests 1.0.0

## Clean
################
file delete -force $location/installRepo

## Create a default test odfi
################
set odfi [::odfi::odfi test]
set testConfig [$odfi config testconfig {
    
    :installPath set $location/installRepo
    
    source $location/../../repositories/odfi-base.repo.tcl
    
    ## Test repo
    :repository testScript {
    
        :group test {
        
            :group js {
            
                :module node {
                    
                    :version 6.3.1 {
                    
                        :location windows x86_64 [file normalize $location/../data/sources/node-6.3.1/node.exe]
                    }
                    
                    :onContentUpdated {
                        file mkdir ${:directory}/bin
                        if {[catch {file copy -force ${:directory}/node.exe ${:directory}/bin}]} {
                            error "Could not move node to bin folder"
                        } else {
                            file delete -force ${:directory}/node.exe
                        }
                    }
                }
            }
            
            :group doc {
                        
                :module duckdoc {
                    
                    :version master {
                        :location any any https://github.com/richnou/odfi-doc.git
                    }
                    
                }
            }
        
        }
        
        
    }
}]
$odfi gatherModules




## Install
puts "----------- First install run "
$odfi runCommand odfi/install test/js/node
puts "----------- First install run "
$odfi runCommand odfi/install test/js/node

#$odfi runCommand odfi/install test/doc/duckdoc

## Regather
#$odfi gatherModules

$testConfig shade ::odfi::Module eachChild {

    puts "Found Module: [$it name get]"

}

## Run node for fun
#$odfi runCommand node.exe --help