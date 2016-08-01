## This Module holds the features to gather an environment from the installed modules
package provide odfi::environment



namespace eval ::odfi::environment {


    odfi::language::nx::new [namespace current] {
    
        :environment {
            +exportTo ::odfi::Odfi env
            
            ## Default
            +builder {
                
                set odfi [:parent]
                set renv [current object]
                $odfi shade ::odfi::Module walkDepthFirstPreorder {
                    
                    ## Add Default Variables
                    #puts "Env building ofr:  [$node directory get]"
                    if {[file exists [$node directory get]/bin]} {
                       # puts "-> adding bin"
                        $renv variable PATH [$node directory get]/bin
                    }
                    
                    ## Add Default Prescript for Package index
                    if {[file exists [$node directory get]/tcl/pkgIndex.tcl]} {
                        $renv preScript  [$node directory get]/tcl/pkgIndex.tcl
                    }
                    if {[file exists [$node directory get]/lib/pkgIndex.tcl]} {
                        $renv preScript  [$node directory get]/lib/pkgIndex.tcl
                    }
                    
                    ## Special variables
                    #$node callFeedEnvironment $env
                }
                
              
            
            }
            
          
            
            ## Elements
            #############
            
            
            ## Environment Variable
            :variable name value {
                +builder {
                    #puts "Created Variable for ENV: ${:name}"
                }
            }
            
            ## PreScript
            :preScript path {
            
            }
            
            
            ## Outputs
            #######################
            
            ## Creates a BASH script output to be sourced
            +method toBash args {
            
            
            }
            
            
        
        }
    
    }

}