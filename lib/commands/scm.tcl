:module "scm" {
    
    ## Return true or false
    :command changes-in {


    }

    ## Utilities for all commands
    :command "get-scms" {
        
        ## Get all SCM
        #set scms [[:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten]
        
        set v  [:getValueAs scms {
        
           # puts "Building value SCMS from get-scms"
            [:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten
        
        }]
        
        #puts "Running get-scms -> $v"
        return $v
    }
    
    :command "scm-for" {
    
        set module [lindex $args 0]
        if {![file exists $module]} {

          #puts "SCM form: $module"
          return [:getValueAs scm-for-$module {
              
              #puts "Building value SCM for: $module"
              
              ## Look for SCMs
              set scms [:getValueAs scms {:runCommandGet get-scms}]
              
              ## Look for an accepting one
              $scms @> findOption { $it accept $module }
              
          }]

        } else {

          ## Look for SCMs
          set scms [:getValueAs scms {:runCommandGet get-scms}]
          
          #puts "SCM Found: [$scms size]"
          ## Look for an accepting one
          return [$scms findOption { $it accept $module }]

        }
 
    }

    :command hasChanges {

      set pathOrModule [lindex $args 0]
      set scm [:runCommandGet "scm-for" $pathOrModule]
      puts "Run command res: [$scm info class]"
      if {[$scm isEmpty]} {

        :log:warning "Cannot compute hasChanges for $pathOrModule , no applicable SCM found"
        return false

      } else {

        set scm [$scm get]
        if {[$scm isClean $pathOrModule]} {
          return false
        } else {
          return true
        }
      }

    }

    :command "changes" {
    
       
        set scms [:runCommand get-scms]
        :log:raw "Checking Changes...$args [llength $args]"
        :log:raw "SCM Found...[$scms @> map {$it type get} @> mkString ,]"
        
        ## Parse Arguments
        #####
        
        
        ## Check on all modules or only on one
        ############
        if {[llength $args]==0} {
            
            :log:raw "Checking state of all modules..."
            [:getODFI] onAllPhysicalModules {
                                
                {module parent} => 
                    
                    #puts "current: [[current object] info class]"
                    set scm [:runCommand scm-for $module] 
                    #:log:raw "Module [$module getFullName]....[$scm isNone]"
                    if {[$scm isDefined]} {
                        set scm [$scm get]
                        if {![$scm isClean $module]} {
                            :log:raw "==========================================="
                            :log:raw "Module [$module getFullName] has changes..."
                            
                            #$scm printStatus $module
                        }
                        
                    }
                    
                    #:log:raw "Module [$module getFullName]....$scm"
                    #:log:raw "Updating [$module name get] in [$module directory get]"
                    
                    
                   
                
            
            }
        }
    }
    
    :command isClean {
            
        :log:raw "Checking clean status..."
        set cmd [current object]
        
        ## Get all SCM
        set scms [[:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten]
        
        [:getODFI] shade { if {[string match ::odfi::Module [$it info class]] && [$it isPhysical]} { return true} else {return false}  } walkDepthFirstPreorder {
                   
           {module parent} => 
               
               $scms @> findOption { $it accept $module} @> match {
                               
                   :some scm {
                       #$cmd log:raw "Found SCM [$scm type get]"
                       if {[$scm isClean $module]} {
                            $cmd log:raw "\[-\] Module [$module name get]...clean"
                       } else {
                            $cmd log:raw "\[X\] Module [$module name get]...not clean ([$module directory get])"
                       }
                   }
                   
                   :none {
                   
                       $cmd log:raw "Module [$module name get] is not under a revision mechanism which supports updates"
                   }
               }
                
               
        }
    }
    
    :command notClean {
                
            :log:raw "Checking clean status..."
            set cmd [current object]
            
            ## Get all SCM
            set scms [[:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten]
            
            [:getODFI] shade { if {[string match ::odfi::Module [$it info class]] && [$it isPhysical]} { return true} else {return false}  } walkDepthFirstPreorder {
                       
               {module parent} => 
                   
                   $scms @> findOption { $it accept $module} @> match {
                                   
                       :some scm {
                           #$cmd log:raw "Found SCM [$scm type get]"
                           if {[$scm isClean $module]} {
                                #$cmd log:raw "\[-\] Module [$module name get]...clean"
                           } else {
                                $cmd log:raw "\[X\] Module [$module getFullName]...not clean ([$module directory get])"
                           }
                       }
                       
                       :none {
                       
                           $cmd log:raw "Module [$module getFullName] is not under a revision mechanism which supports updates"
                       }
                   }
                    
                   
            }
        }
    
    
    :command "sync" {
    
        lassign $args modulePath
        
        :log:raw "Syncing $modulePath"
        
         [[:getODFI] findModules $modulePath] isEmpty {
         
            :log:raw "Cannot find $modulePath" 
            
         } else {
            
            $list foreach {
                :log:raw "Syncing [$it getFullName]"
                
                set scm [:runCommand scm-for $it]
                if {![$scm isDefined]} {
                    :log:raw "Not SCM available"
                } else {
                    
                    set scm [$scm get]
                    
                    ## Show Update
                    
                    ## Accept
                    :log:raw "Do you accept the actual status for syncing?"
                }
                
            }
            
            
         
         }
        
       # puts "Module: $module"
    
    }
    
    

}