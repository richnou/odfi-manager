:module odfi {
    :version  3.0.0
    
    ## ODFI INFO Commands
    #############
    :command info {
        puts "TCL Version: [info tclversion]"
    }
    
    :command modules {
    
        :log:raw "Fast Informations on modules"
        [:getODFI] shade { if {[string match ::odfi::Module [$it info class]] && [$it isPhysical]} { return true} else {return false} } walkDepthFirstPreorder {

            :log:raw "Module [$node getFullName]"


        }

        return
        [:getODFI] shade ::odfi::Config eachChild {
            odfi::common::println "Config: [$it name get]"
            
            odfi::common::printlnIndent
            $it shade ::odfi::Module eachChild {
                {module i} => 
                    
                    odfi::common::println "Module: [$module name get]"
            }
            odfi::common::printlnOutdent
        }
    }
    
    :command show {
        puts "Show informations for module $args"
        
        ## Get 
        [[:getODFI] findModules $args] foreach {
            
            puts "-- Module [$it name get]"
            puts "-- Version: [$it getVersionName]"
        }
    }
    
    :command repositories {
        
        :log:raw "Repositories information"
        [:getODFI] shade ::odfi::repo::Module walkDepthFirstPreorder {
            
            :log:raw "Module [$node getFullName]"
        
        }
    }
    
    
    ## Repositories and Installation
    ####################
    
    ## USe First Config for now
    :command install {
        
        set targetModule $args
        puts "Installation of module: $targetModule..."
        
        ## Look for module in installed
        set odfi [:getODFI]
        set installedTargetModule [[:getODFI] findModules $targetModule]
        
        puts "Existing installations found: [$installedTargetModule size]..."
        
        ## If not empty, cancel
        $installedTargetModule isEmpty {
        
            ## Looking for the Module in the configuration repositories
            set allModules [[$odfi shade ::odfi::Config children] @> map  {
            
                [$it shade ::odfi::repo::Repository children] @> map {
                    repository => 
                        ::set res [$repository findModule $targetModule]
                        puts "Found module $targetModule : $res"
                        return $res
                } @> filter { if {$it==""} { return false } else { return true} } 
            } @> flatten]
            
            #puts "Found Module in repositories: [$allModules size]"
            
            $allModules isEmpty {
                puts "Nothing found to install for $targetModule"
            } else {
                
                puts "All Found Matches for $targetModule : "
                set selection ""
                $allModules foreach {
                    
                    if {[$it isClass ::odfi::Module]} {
                        
                        puts "--> Module: [$it name get] from [[$it getRepository] name get]"
                        $it shade ::odfi::Version eachChild {
                            {version i} =>
                                
                                puts "----> ($i) Version [$version value get] "
                                set selection $version
                        }
                        
                    } elseif {[$it isClass ::odfi::Version]} {
                    
                        puts "--> Module: [$it name get], version: [$it value get]"
                        
                    } 
                
                }
                
                ## Handle Selection for Installation
                puts ""
                puts "Selection: [$selection info class]"
                [$selection parent] @> getRepository @> install $selection
           
           
                ## Regather modules
                $odfi gatherModules
                
            }
           
            
        
        } else {
            puts "Cannot install $targetModule, because it is already installed, use update or upgrade to update the version or upgrade to the newest version"
        }
        
        
    
    }
    
    
    ## Update
    ################
    :command update {
    
        :log:raw "Updating Modules..."
        set cmd [current object]
        
        ## Get all SCM
        set scms [[:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten]
        
        :log:raw "SCM Support found: [$scms @> map {$it type get} mkString ,]"
    
        [:getODFI] shade { if {[string match ::odfi::Module [$it info class]] && [$it isPhysical]} { return true} else {return false} } walkDepthFirstPreorder {
            
            {module parent} => 
                
                $cmd log:raw "======================================================"
                $cmd log:raw "Updating [$module name get] in [$module directory get]"
                
                $scms @> findOption { $it accept $module} @> match {
                
                    :some scm {
                        #$cmd log:raw "Found SCM [$scm type get]"
                        $scm update $module
                    }
                    
                    :none {
                    
                        $cmd log:raw "Module is not under a revision mechanism which supports updates"
                    }
                }
               
            
        
        }
    }
    
    ## SCM
    ###############
    :module scm {
    
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
                                $cmd log:raw "Module [$module name get]...clean"
                           } else {
                                $cmd log:raw "Module [$module name get]...not clean ([$module directory get])"
                           }
                       }
                       
                       :none {
                       
                           $cmd log:raw "Module [$module name get] is not under a revision mechanism which supports updates"
                       }
                   }
                    
                   
            }
        }
    }
    
    ## FileCommands Support
    ####################
    
    :fileCommandHandler exe {
    
        :log:setPrefix odfi.FCH.EXE
        
        :onAccept {
            if {[::odfi::os::isWindows] &&  [$cmd testExtensions .exe .bat]} {
                return true
            } else {
                return false
            }
            
        }
        
        :onRun {
            puts "Running EXCE [$cmd path get] with [lindex $args 1]"
            ::odfi::common::exec [$cmd path get] [join [lindex $args 1]]
        }
        
    }
    
    :fileCommandHandler tcl {
        
        :log:setPrefix odfi.FCH.TCL
        
        :onAccept {
        
            if {[$cmd isTCL]} {
                return true
            } else {
                return false
            }
            
        }
        
        :onRun {
        
            ## Create Environment
            set runEnv [[:getODFI] env:environment]
            
            ## Create Interpreter
            set runInterpreter [interp create]
            
            ## Source prescripts
            #puts "Prescripts: [[$runEnv shade ::odfi::environment::PreScript firstChild]  path get]"
            [$runEnv shade ::odfi::environment::PreScript children] @> filter { return [string match "*.tcl" [$it path get]] } @> foreach {
                #puts "Sourcing prescript [$it path get]" 
                $runInterpreter eval [list source [$it path get]]
            }
            
            ## Source script in interpreter then delete
            try {
                
                $runInterpreter eval [list set argv [join [lrange $args 1 end]]]
                $runInterpreter eval [list source [$cmd path get]]
            
            } finally {
                interp delete $runInterpreter
            }
        }
        
    }
    
    :command tcl {
    
        puts "Running TCL File: $args"
        
        ## Create Environment
        set runEnv [[:getODFI] env:environment]
        
        ## Create Interpreter
        set runInterpreter [interp create]
        
        ## Source prescripts
        #puts "Prescripts: [[$runEnv shade ::odfi::environment::PreScript firstChild]  path get]"
        [$runEnv shade ::odfi::environment::PreScript children] @> filter { return [string match "*.tcl" [$it path get]] } @> foreach {
            #puts "Sourcing prescript"
            $runInterpreter eval [list source [$it path get]]
        }
        
        ## Source script in interpreter then delete
        try {
        
            $runInterpreter eval [list source $args]
        
        } finally {
            interp delete $runInterpreter
        }
        
    }
    
    
    
    
    ## SCM Support
    ###################
    [:getConfig] addChild [::odfi::scm::Git new]


    ## Load Gui Command
    ###############
    source [file dirname [info script]]/gui/odfi_module_guicommand.tcl
}
