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
            
            ## Abstract functions
            #########
            +method accept module {
                
               # puts "GIT accept: $module? [$module isPhysical] && [file exists [$module directory get]/.git]"
                if {[$module isPhysical] && [file exists [$module directory get]/.git]} {
                    #puts "Accept"
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
            
            +method getStatus module {
                
                return [::odfi::files::inDirectory [${module} directory get] {
                                
                        catch {exec git status} res
                        
                        return $res
                }]
            }
            
            +method printStatus module {
            
                puts [:getStatus $module]
                
            }
            
            +method isClean module {
                return [::odfi::git::isClean [${module} directory get]]
            }
            
            +method isBehind module {
            
                :fetch $module
                
                set currentBranch [odfi::git::current-branch [${module} directory get]]
                
                ## Look for current branch status in list
                set gitStatus [::odfi::files::inDirectory [${module} directory get] {
                
                        catch {exec git status} res
                        
                        return $res
                }]
                
               #puts "Fetch Status: $gitStatus"
                
                ## Get Actual Status result
                if {[string match "*Your branch is behind*" $gitStatus]} {
                    return true
                } else {
                    return false
                }
                #regexp  "(.+)\s+$currentBranch\s+->" $fetchStatus -> status
                
                
                
                return false
            }
            
            ## Low level
            +method fetch module {
                ::odfi::files::inDirectory [${module} directory get] {
                    catch {exec git fetch}
                }
                
            }
        
        }
    }
    
   
    

}