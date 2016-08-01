package provide odfi::scm 3.0.0
package require odfi 3.0.0
package require odfi::git 2.0.0

namespace eval ::odfi::scm {


    odfi::language::nx::new [namespace current] {
    
        +type SCM : ::odfi::NameDescription {
            +var type ""
            +var sanityCheck true
            +exportTo ::odfi::Config
            
          
            
            +method isReady args {
            
                return ${:sanityCheck}
            }
            
        }
        
        ## GIT
        ############
        +type Git : SCM {
            
            +method init args {
                next
            
                set :type git
                :log:setPrefix scm.git
            }
            
            +method accept module {
                
                if {[$module isPhysical] && [file exists [$module directory get]/.git]} {
                    return true
                } else {
                    return false
                }
            }
            
            +method update module {
                
                :log:raw "Pulling..."
                if {[catch {::odfi::git::pull [${module} directory get]} res resOptions]} {
                    #:log:warning "$res"
                }
            
            }
            
            +method isClean module {
                return [::odfi::git::isClean [${module} directory get]]
            }
        
        }
    }
    
   
    

}