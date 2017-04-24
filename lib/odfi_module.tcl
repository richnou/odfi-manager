:module odfi {
    :version  3.0.0
    
    ## ODFI INFO Commands
    #############
    :command help {
        puts "Available Commands:"
        [[:parent] shade odfi::Command children] foreach {
            puts "- [$it name get]"
        }
    }
    :command info {
        puts "TCL Version: [info tclversion]"
        
        ${:commandResult} puts "Result of info command"
        ${:commandResult} add tclversion [info tclversion]
        
    }
    
    :command modules {
    
        :log:raw "Fast Informations on modules"
        [:getODFI] shade { if {[string match ::odfi::Module [$it info class]] && [$it isPhysical]} { return true} else {return false} } walkDepthFirstPreorder {

            :log:raw "Module [$node getFullName] : [$node getDirectory]"


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
    :command findModules {

        set targetModule $args
        
        puts "Searching Module: $targetModule..."

        
        ## Look for module in installed
        set odfi [:getODFI]
        set installedTargetModule [[:getODFI] findModules $targetModule]
        
        puts "Existing installations found: [$installedTargetModule size]..."

        ${:commandResult} set $installedTargetModule
        #return $installedTargetModule
    }

    :command update {

        set foundModules [[:runCommand findModules $args] get]
        puts "Result: [$foundModules info class]"
        
        
        $foundModules foreach {

            {module i} -> 

                puts "- Updating: [$module getFullName]"
                puts "-- Directory: [$module getDirectory]"

                ## Updates Sources 
                set scm [:runCommandGet scm/scm-for $module]
                if {[$scm isDefined]} {
                    puts "-- Updating with SCM...[$scm  @> get @> info class]"
                    $scm @> get @> update $module
                }

                ## Reload 
                $module reloadDirectory

                ## Requirements
                [$module shade ::odfi::powerbuild::Requirements children] foreach {
                    {reqs i} -> 

                        foreach requiredModule [$reqs modules get] {
                            puts "-- Installing required module: $requiredModule"
                            :runCommand install $requiredModule
                        }
                }
            
        }
    }

    ## USe First Config for now
    :command install {
        
        set targetModule $args
        
        #puts "Installation of module: $targetModule..."

        
        ## Look for module in installed
        set odfi [:getODFI]
        set installedTargetModule [[:getODFI] findModules $targetModule]
        
        #puts "Existing installations found: [$installedTargetModule size]..."
        
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
                
                ##puts "All Found Matches for $targetModule : "
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

                ## Update 
                :runCommand update $targetModule
           
           
              
                
            }
           
            
        
        } else {
        
            #puts "Cannot install $targetModule, because it is already installed, use update or upgrade to update the version or upgrade to the newest version"
            :runCommand update $targetModule
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
    
    
    
    
    
    
    ## SCM Support
    ###################
    [:getConfig] addChild [::odfi::scm::Git new]


    ## Load Gui Command
    ###############
    foreach f [glob -nocomplain -type f -directory [file dirname [info script]]/commands/ *.tcl] {
        source $f
    }
    
}
