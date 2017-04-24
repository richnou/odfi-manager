package provide odfi::repo 3.0.0
package require odfi       3.0.0


namespace eval ::odfi::repo {

    odfi::language::nx::new [namespace current] {
    
        ## Base Repository object
        :repository : ::odfi::NameDescription name {
            +exportToPublic
            +exportTo ::odfi::Config
            
            ## Location of repository file
            +var location "undefined"
            
            +var description ""
            
            +builder {
            
                :log:setPrefix "repository"
            }
            
            ## Search 
            #################
            +method findModule path {
                
                set currentNode [current object]
                set foundModule ""
                foreach comp [split $path /] {
                    
                    :log:debug "Searching path: $comp on [$currentNode info class]"
                    
                    ## If on Module, look for version
                    ## If on Group/otehr, look by name
                    if {[$currentNode isClass ::odfi::Module]} {
                    
                        set found [$currentNode shade ::odfi::Version findChildByProperty value $comp]
                        if {$found==""} {
                            #odfi::log::error "Cannot Find module $path, current version search for $comp  not found"
                            break
                        } else {
                            set currentNode $found
                            
                        }
                        
                    } else {
                    
                        set found [$currentNode findChildByProperty name $comp]
                        if {$found==""} {
                            #odfi::log::error "Cannot Find module $path, current search for $comp in [$currentNode name get] not found"
                            break
                        } else {
                            set currentNode $found
                            if {[$currentNode isClass ::odfi::Module]} {
                                set foundModule $currentNode
                            }
                            
                        }
                    }
                    
                }
                
                return $foundModule
            }
            
            ## Install
            ####################
            +method install target {
                
                :log:info "Installing using base [$target info class]"
                
                ## Create INstall target path by using the names of groups and versions
                set installTargetPath "[$target shade {
                    if {[$it isOneClass ::odfi::Version ::odfi::Module ::odfi::repo::Group]} {
                        return true
                    } else {
                        return false
                    }
                } formatHierarchyString {$it name get} "/"]/[$target name get]"
                
                puts "Target Path: $installTargetPath"
                 
                ## Now Determine Local Platform and arch
                ###########
                set localPlatform [::odfi::os::getOs]
                set localArch     [::odfi::os::getArchitecture]
                :log:info "Local Platform: $localPlatform ($localArch)"
                :log:info "Looking for matching location"
                
                ## Search for matching location
                ################
                set foundLocation [[$target shade ::odfi::Location children] findOption {
                    
                    if {([$it platform get]=="any" || [$it platform get]==$localPlatform) && ([$it architecture get]=="any" || [$it architecture get]==$localArch) } {
                        return true
                    } else {
                        return false
                    }
                }]
                
                if {![$foundLocation isDefined]} {
                
                    :log:warning "Cannot find location for target platform and architecture in locations: "
                
                    $target shade ::odfi::Location eachChild {
                        
                        puts "Platform=[$it platform get] , Architecture=[$it architecture get], Url=[$it url get]"
                    }
                    return
                }
                
                ## Found, handle URL and install
                #######################
                set foundLocation [$foundLocation get]
                
                ## Prepare Folder
                set installPath [[:parent] installPath get]
                set finalFolder $installPath/$installTargetPath
                file mkdir $finalFolder
                
                :log:info "Installing from [$foundLocation url get] into $finalFolder..."
                
                ## Handling
                ################
                set success false
                if {[file exists [$foundLocation url get]]} {
                
                    :log:info "Doing simple file copy of [$foundLocation url get] to $finalFolder/[file tail  [$foundLocation url get]]"
                    file copy -force [$foundLocation url get] $finalFolder/[file tail  [$foundLocation url get]]
                    set success true
                
                    ## FIXME Handle Zip Like Package
                
                } elseif {[string match *.git [$foundLocation url get]] || [string match git:* [$foundLocation url get]]} {
                    
                    ## Git
                    ##############
                    
                    :log:info "Using GIT Clone"
                    package require odfi::git 2.0.0
                    ::odfi::git::clone [$foundLocation url get] $finalFolder
                    
                } elseif {[string match http* [$foundLocation url get]]} {
                    
                    ## Http
                    ###################
                    
                    :log:info "Using HTTP Handler..."
                    package require odfi::ewww 2.0.0
                    
                    ## Copy File
                    odfi::ewww::httpcopy [$foundLocation url get] $finalFolder/[file tail  [$foundLocation url get]]
                    
                    ## FIXME Handle Zip Like Package
                    
                    set success true
                    
                    
                    
                } else {
                    
                    puts "URL [$foundLocation url get] cannot be handled (see code [::odfi::common::findUserCodeLocation])"
                }
                
                if {$success} {
                
                    ## Run Updated Content on the source 
                    $target callContentUpdated $finalFolder
                    
                    ## Run updated Content on the module class
                    set sourceModule [$target findParentInPrimaryLine {$it isClass ::odfi::Module}]
                    if {$sourceModule!=""} {
                        $sourceModule directory set $finalFolder
                        $sourceModule callContentUpdated $finalFolder
                    }
                }
                
            
            }
            
            
            
            
            ## Grouping of Modules
            ##############
            :group name {
                +exportTo Group
            }
            
            ## Module Definition
            #############
            :module : ::odfi::Module name {
                +exportTo Group
                
                +method getFullName args {

                    return [:shade { if {[$it isClass ::odfi::Module] ||  [$it isClass ::odfi::repo::Group]  ||  [$it isClass ::odfi::Config] ||  [$it isClass ::odfi::repo::Repository]} { return true} else {return false} } formatHierarchyString {
                        if {[$it isClass ::odfi::Config]} {
                            return "config:[$it name get]"
                        } else {
                            return "[$it name get]"
                        }
                    } /]/[:name get]

                }


                :access name url {
                
                }
                
                +method getRepository args {
                
                    return [:findParentInPrimaryLine {$it isClass ::odfi::repo::Repository}]
                }
            }
        
        
        }
    
    }

}
