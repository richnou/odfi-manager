package provide odfi 3.0.0
package require odfi::language::nx 1.0.0
package require odfi::attributes 2.0.0
package require odfi::files 2.0.0
package require odfi::os 1.0.0
package require odfi::log 1.0.0
package require odfi::powerbuild 1.0.0

namespace eval odfi {

    variable moduleLocation [file normalize [file dirname [info script]]]
    
    

    ## API Language Path
    ########################
    odfi::language::nx::new [namespace current] {
    
        ## Common Types
        ##################
        +type NameDescription : ::odfi::attributes::AttributesContainer  {
            +var name ""
            +var description ""
            +mixin ::odfi::log::Logger log
            
          
            
            
            
            
            ## Return the main top level ODFI instance
            +method getODFI args {
                set root [:getRoot]
                if {[$root isClass ::odfi::Odfi]} {
                    return $root 
                } else {
                    error "cann get ODFI top container, no such a top container"
                }
            }   
            
            ## Return the main top level ODFI instance
            +method getConfig args {
            
                return [:findParentInPrimaryLine { $it isClass ::odfi::Config }]
                
            }   
        }
        
        ## Main ODFI
        ###################
        :odfi : NameDescription name {
            +exportToPublic
            +expose name
            
            +builder {
            
                ## Log Config
                :log:setPrefix "odfi"
            
                ## Create a Default Config with the main odfi module in it
                :config main {
                
                    source ${::odfi::moduleLocation}/odfi_module.tcl
                    
                }
                
            }
            
            ## Utilities
            ####################
            
            ## Search in Environment for all package index scripts
            +method loadIndexScripts args {
                
                set env [:env:environment]
                $env buildFromModules

                [$env shade ::odfi::environment::PreScript children] @> filter { return [string match "*.tcl" [$it path get]] } @> foreach {
                    #puts "Sourcing prescript [$it path get]"
                    
                    source [$it path get]
                }
            }
            
            +method getAllModules args {
                
                set modules [::odfi::flist::MutableList new]
                :shade ::odfi::Module walkDepthFirstLevelOrder {
                    
                    if {![$node isClass ::odfi::repo::Module]} {
                        $modules += $node
                    }
                    return false
                }
                
                return $modules
            }

            +method getAllPhysicalModules args {
                
                set modules [::odfi::flist::MutableList new]
                :shade ::odfi::Module walkDepthFirstLevelOrder {
                    
                    if {![$node isClass ::odfi::repo::Module] && [$node isPhysical]} {
                        $modules += $node
                    }
                    return false
                }
                
                return $modules
            }
            
            ## Execution on parent level
            +method onAllPhysicalModules cl {
            
                [:getAllPhysicalModules] foreach $cl -level 2
            }
            
            
            ## On Selected Modules 
            +method onModules {modulePath cl} {
                
                [:findModules $modulePath] isEmpty {
                
                    :log:warning "Cannot find any module for provided path $modulePath"
                    
                } elseOnList {
                    
                    ## Foreach and call on level 2 to go back to caller of onModules
                    :foreach $cl -level 2
                }
            }
            
            ## On Selected One Module, falis if choice is not singular 
            +method onModule {modulePath cl} {
                
                set found [:findModules $modulePath] 
                
                $found isEmpty {
                
                    :log:warning "Cannot find any module for provided path $modulePath"
                    
                } elseOnList {
                    
                    ## Foreach and call on level 2 to go back to caller of onModules
                    if {[:size]>1} {
                        uplevel log:warning "Module path $modulePath lead to more than one result, please make your choice more specific"
                    } else {
                        [:at 0] apply $cl
                    }
                }
            }
            
            ################################
            ## COnfig
            ################################
            
            #### Remote Config
            ###############
            
            +method remoteConfig {path args} {
                
                set scriptLocation [::odfi::common::findFileLocation]
                #puts "Calling Remote Config from -> $scriptLocation"
                
                ## Create target file and another variable for save path, because the command line execution might differ from normal path
                set targetFile [file normalize [file dirname [lindex $scriptLocation 0]]/[lindex [split $path /] end].sync]
                set targetFileSavePath $targetFile
                
                ## Don't sychronise unless forced
                ###########
                if {[file exists $targetFile]} {
                    source $targetFile
                    return
                }
                
                
                ## Handle
                ## Rsync etc...
                ##############
                if {[string match "rsync://*" $path]} {
                    
                    ## Check RSYNC
                    if {[::odfi::os::isCommandInPath rsync]} {                   
                        :log:warning "Cannot request RSYNC Config file if the RSYNC command is not available" 
                        return
                    } 
                    
                    ## Running
                    ###########
                    set remoteFilePath [string range $path 8 end]
                    
                    ## Adapt Local Path if windows + msys. convert C:/x to /C/x
                    if {[::odfi::os::isWindowsMsys]} {
                        set targetFileSavePath "/[string map {: /} $targetFileSavePath]"
                    }
                    
                    :log:raw "RSYNC Sync of $remoteFilePath to $targetFile"
                    if {[catch {exec rsync -ubv $path $targetFileSavePath} res]} {
                        :log:warning "Could not sync configuration: $res"
                    } else {
                        source $targetFile
                    }
                
                }
            }
            
            
            #### DSL
            ########
            :config : NameDescription configFile {
            
                +var installPath ""
                
                ## These heuristics are used to detect module folders which don't contain module files
                +var moduleFolderHeuristics {}
                
                ## ConfigFile can be a config file or just a name
                +builder {
                
                    set scriptLocation [::odfi::common::findFileLocation]
                    puts "Config created here: $scriptLocation"
                
                    ## Config File: if there, preset name to file name and source
                    ## If not there the configFile is the name
                    if {[file exists ${:configFile}]} {
                        set :name [file tail ${:configFile}]
                        source ${:configFile}
                    } else {
                        set :name ${:configFile}
                    }
                    
                    ## Default Module Folder Heuristics
                    #########
                    
                    ## folder variable: dir
                    :addModuleFolderHeuristic {
                        
                        foreach testDir {bin lib lib64 tcl var} {
                            if {[file exists $dir/$testDir]} {
                                return true
                            }
                        }
                        
                        return false
                        
                        
                    }

                    ## GIT
                    :addModuleFolderHeuristic {
                        if {[file exists $dir/.git]} {
                            return true 
                        }
                        return false
                    }
                    
                }
                
                +method addModuleFolderHeuristic script {
                    
                    lappend :moduleFolderHeuristics [odfi::closures::newITCLLambda $script] 
                }
            
                ## Module Description
                ###########
                :group : NameDescription name {
                    +exportTo Group
                    
                    +builder {
                        :registerEventPoint postBuild
                    }
                }
                
                :module : NameDescription name {
                    +exportTo Module
                    +exportTo Group
                    +exportToPublic
                    +expose name
                    
                    +var directory ""
                    
                    +builder {
                        
                        ## Used when update/installation updates some files
                        :registerEventPoint contentUpdated directory
                        :registerEventPoint postBuild
                    }

                    +method getFullName args {

                        return [:shade { if {[$it isClass ::odfi::Module] ||  [$it isClass ::odfi::Group]  ||  [$it isClass ::odfi::Config]} { return true} else {return false} } formatHierarchyString {
                            if {[$it isClass ::odfi::Config]} {
                                return "@[$it name get]"
                            } else {
                                return "[$it name get]"
                            }
                        } /]

                    }

                    ## Resolve directory based on parents
                    +method getDirectory args {

                        set currentDirectory [:directory get]


                        set currentNode [:parent]

                        ## Determine File relative info not using file, because it might not exist
                        ## Unix: /xxxxx is absolute
                        ## Windows: LETTER:xxxxx is absolute
                        while {$currentNode!="" && ![string match "/*" $currentDirectory] && ![string match "\[a-zA-Z\]:*" $currentDirectory]  } {
                            set currentDirectory [$currentNode directory get]/$currentDirectory
                            set currentNode [$currentNode parent]
                        }

                        return $currentDirectory

                    }
                   
                    
                    ## Setup
                    ###############
                    +method useDirectory moduleDirectory {
                    
                        ## Save Directory
                        set :directory [file normalize $moduleDirectory]
                        
                        ## If Module Directory has a version name, set version and change name to one folder up folder
                        if {[::odfi::Version::isVersion [file tail ${:directory}]]} {
                            set :name [file tail [file normalize ${:directory}/../]]
                        }
                        
                        
                        ## Load Module files
                        foreach moduleFile [glob -nocomplain -type f -directory $moduleDirectory *.module.tcl] {
                            source $moduleFile
                        }
                        
                        
                        
                    
                    }
                    
                    ## Return true if the Module is a physically installed module
                    +method isPhysical args {
                        
                        if {${:directory}!="" && [file exists ${:directory}]} {
                            return true
                        } else {
                            return false
                        }
                        
                    }
                    
                    ## Requirements
                    #################
                    :requirements : ::odfi::powerbuild::Requirements {
                        
                        +var modules ""
                        
                        +method module modulePath {
                            lappend :modules $modulePath
                        }
                    }
                    
                    ## Functionality export
                    ###############
                    +method mixinToModule {builder {prefix ""}} {
                        
                        if {$prefix==""} {
                            
                            ::odfi::Module mixins add $builder
                            foreach o [::odfi::nx::getAllNXObjectsOfType ::odfi::Module] {
                                $o object mixins add $builder
                            }
                            
                        } else {
                        
                            ::odfi::Module domain-mixins add $builder -prefix $prefix
                            foreach o [::odfi::nx::getAllNXObjectsOfType ::odfi::Module] {
                                $o object domain-mixins add $builder -prefix $prefix
                            }
                        
                        }
                        
                    }
                    
                    +method exportToModule {prefix typeName script} {
                        
                        ::odfi::language::new ::odfi::export::module::${prefix} "
                            +type $typeName {
                                +exportTo ::odfi::Module $prefix
                                $script
                            }
                        "
                        
                        
                    
                    }
                    
                    ## Versioniong
                    ###########
                    +method getVersion args {
                        if {$args!=""} {
                            
                            return [:shade ::odfi::Version findChildByProperty version "$args"]
                            
                        } else {
                            return [:shade ::odfi::Version firstChild]
                        }
                    }
                    
                    +method getVersionName args {
                        set v [:getVersion]
                        if {$v==""} {
                            return "No version information available"
                        } else {
                            return [$v value get]
                        }
                        
                    }
                    
                    :version : NameDescription value {
                        
                        +var major ""
                        +var minor ""
                        +var patch ""
                        +constant versionRegexp {([0-9]+)(.[\w]*[0-9]+)+}
                        
                        +builder {
                        
                            set :name ${:value}
                            set versionRegexp {([0-9]+)(.[\w]*[0-9]+)+}
                            #set match [regexp -inline $versionRegexp $value]
                        
                        
                            ## Used when update/installation updates some files
                            :registerEventPoint contentUpdated directory
                        
                        
                        }
                        
                        +objectMethod isVersion v {
                            if {[file tail ${v}]=="master" || [regexp ${::odfi::Version::versionRegexp} $v]} {
                                return true
                            } else {
                                return false
                            }
                        }
                        
                        +method getMajor args {
                        
                        }
                    
                        +method compareTo otherVersion {
                        
                        }
                    
                    }
                    
                    ## Installation/Update
                    ##################
                    :location platform architecture url {
                        +exportTo Version
                        
                        
                        +targetMethod locations args {
                           foreach {platform architecture url} $args {
                               :location $platform $architecture $url {
                               
                               }
                           }
                       }
                    }
                    
                   
                    
                    
                    ## Tools and Commands
                    #######################
                    +type Runnable : NameDescription {
                        
                        +builder {

                            if {![:isRoot]} {
                                :log:setPrefix [[:parent] name get].${:name}
                            }
                            
                        }
                        
                        :arg value {
                        
                        }

                        ## Utilities
                        #############

                        ## Writes the Command Environment to the target file, and then the provided content using the richstream template api
                        +method externalScriptWithEnvironment {file content} {

                            :env:environment {
                                :buildUp ::odfi::Module
                                :toBash $file
                                :detach
                            }

                            ::odfi::richstream::template::stringToFile $content $file -append
                        }

                        +method runCommand {path args} {
                            return [[:getODFI ] runCommand $path [join $args]]
                        }
                        
                        
                        
                    }
                    
                    :command : Runnable name script {

                        +method run args {
                            #puts "Running command $args"

                            set location [pwd]

                            eval ${:script}
                        }

                        
                    }

                    :preCommand : Runnable name script {

                        +method run args {

                            ## Commands to run are this, and the first parent one

                            ## Run 
                            #puts "Running pre command $args"

                            set location [pwd]

                            :apply ${:script}

                            ## Look for first module with a runnable of same name 
                            #
                            set searchName {$:name}
                            #set foundParent [[:parent] findParentInPrimaryLine {puts "[$it name get] ::-> [$it shade ::odfi::Command findChildByProperty name $searchName]" ; return false}]
                            set foundParent [[:parent] findParentInPrimaryLine "return \[\$it shade ::odfi::Command findChildByProperty name ${:name}\]"]
                            if {$foundParent==""} {
                                :log:warning "Precommand ${:name} cannot find a command with same name in parents, maybe command is just enough"
                            } else {

                                set parentCommand [$foundParent shade ::odfi::Runnable findChildByProperty name ${:name}]
                                
                                ##puts "Running parent "
                                set startCommand [current object]
                                $parentCommand run [join $args]
                            }
                        }

                    }
                    
                    :tool : Runnable name {
                    
                    }
                    
                    :fileCommand : Runnable path {
                        +exportToPublic
                        
                        +builder {
                            :log:setPrefix odfi.fileCommand
                            
                            set :path [file normalize ${:path}]
                        }
                        
                        ## Content Access
                        ################
                        +var content "-"
                        
                        +method getContent args {
                            
                            set p ${:path}
                            
                            if {${:content}=="-"} {
                                ::set :content "[::odfi::files::readFileContent $p]"
                            }
                            return ${:content}
                        }
                        
                        ## Returns true if the file contains at least on of the provided pattern
                        ## String match is used here
                        +method fileContainsOneOf args {
                            
                            ::set content [:getContent]
                            foreach p $args {
                                
                               
                                if {[string match *$p* $content]} {
                                    return true
                                }
                                
                            
                            }
                            return false
                        }
                        
                        ## Tests
                        ################
                        
                        ## Test file extensions, as provided in args. !! No . is added to extension for testing!!
                        +method testExtensions args {
                        
                            foreach ext $args {
                                if {[string match "*$ext" ${:path}]} {
                                    return true
                                }
                            }
                            return false
                        }
                        
                        +method isBash args {
                            
                            if {[:testExtensions .bash .sh]} {
                                return true
                            } elseif {[:fileContainsOneOf #!/bin/bash #!/bin/sh]} {
                                return true
                            }
                            
                            
                            return false
                            
                        }
                        
                        +method isTCL args {
                        
                            if {[:testExtensions .tcl .tm]} {
                                return true
                            } elseif {[:fileContainsOneOf #!*tclsh puts "package require"]} {
                                return true
                            }
                            
                            return false
                        }
                        
                        
                        ## Run
                        #############
                        +method run args {
                            
                           
                            
                            set odfi [:parent]
                            
                            :log:debug "Running command ${:path} on $odfi"
                            
                            ## Search for FileCommandHandlers which will accept the current command
                            set command [current object]
                            set handlers [::odfi::flist::MutableList new]
                            $odfi shade ::odfi::FileCommandHandler walkDepthFirstPreorder {
                            
                                ## Look for all FCH
                                if {[$node accept $command]} {
                                    $handlers += $node
                                }
                            
                                return true
                            
                            }
                            
                            :log:debug "Found [$handlers size] handlers"
                            $handlers isEmpty {
                                
                                puts "Could not find any File Command Handlers accepting file at ${:path}"
                                
                            } else {
                                
                                ## FIXME: Handler multiple options
                                set choice [$handlers at 0]
                                
                                puts "Running Command $command with args  $args"
                                $choice run $command [join $args]
                                
                            }
                            
                            return true
                            
                            ## Handle TCL
                            if {[:isTCL]} {
                                $odfi runCommand odfi/tcl ${:path}
                                return true
                            }
                            return false
                        }
                    }
                
                    ## File Handlers
                    ############
                    
                    ## Must define:
                    ##  - method "accept fileCommand" returning true if the provided file Command is supported
                    :fileCommandHandler : NameDescription name {
                        
                        +builder {
                        
                            :registerEventPoint accept cmd
                            :registerEventPoint run    cmd args
                        
                        }
                        
                        +method accept cmd {
                            if {[catch {:callAccept $cmd} res]} {
                                :log:warning "File Command Handler ${:name} produced and error during accept $res"
                            }
                            #puts "ACCEPT res: $res [:callAccept $cmd]"
                            return $res
                        }
                        
                        +method run {cmd args} {
                            
                            :callRun $cmd [join $args]
                        }   
                        
                       
                        
                    }
                
                }
                ## EOF Module
                
               
                
              
            
            }
            ## EOF Config
            
            #### Utils
            +method getConfig name {
                return [:shade ::odfi::Config findChildByProperty name $name]
            }
        
            ## Main Tool API
            #####################
            
            ## Look in configurations' installPaths and create module objects not existings
            +method gatherModules args {
                
                
                #set allConfigInstallPaths [[:children] @> map { return [$it installPath get]}]

                set postGatherList {}
                :shade ::odfi::Config eachChild {
                    
                    set searchPath [$it installPath get]
                    set currentConfig $it
                    set currentConfigIPath [$currentConfig installPath get]

                    


                    
                    #puts "Starting Search in $searchPath, with other paths [$allConfigInstallPaths mkString ,]"
                    
                    ## Look for all folders with an odfi config
                    set nextDirectories [list [list $it [glob -nocomplain -type d -directory $searchPath *]]]
                    while {[llength $nextDirectories]>0} {
                        
                        set currentDirsAndParent [lindex $nextDirectories 0]
                        set nextDirectories [lreplace $nextDirectories 0 0]
                        
                        set currentParent [lindex $currentDirsAndParent 0]
                        set currentDirs  [lindex $currentDirsAndParent 1]
                        
                       # puts "Search loop for $currentParent and $currentDirs ($currentDirsAndParent)"
                        
                        foreach currentDir $currentDirs {
  
                            ## Ignore Current Dir if it belongs to another config
                            #if {[$allConfigInstallPaths @> findOption { if {$it != $currentConfigIPath && [string match ${it}* $currentDir]} {return true} else {return false} } @> isDefined]} {

                                ## It is only true if the target Config 
                             #   puts "$currentDir belongs to another config"
                             #   continue

                            #}

                            ## Look for module files in directory
                            ## If none, add to next search loop if not a module looking folder
                            set moduleFiles [glob -nocomplain -type f -directory $currentDir *.module.tcl]
                            if {[llength $moduleFiles]>0} {
                                
                                ## Found Config File
                                ## Create Module only if there is not already a module with same directory present in Container
                                if {[$currentParent shade ::odfi::Module findChildByProperty directory  [file normalize $currentDir]]==""} {
                                    set m [$currentParent module [file tail $currentDir]]
                                    lappend postGatherList $m
                                    $m useDirectory $currentDir
                                }
                               
                                
                            } else {
                            
                                ## Check if the folder is a module folder without module file
                                set isModule false
                                foreach heuristic [$it moduleFolderHeuristics get] {
                                
                                    if {$heuristic != "" && [$heuristic apply $currentDir [list dir $currentDir]]} {
                                        
                                        #puts "Found Module canditate by heuristic [file tail $currentDir] for [$currentParent info class] ([$currentParent name get])"
                                        
                                        ## Create Module only if there is not already a module with same directory present in Container
                                        if {[$currentParent shade ::odfi::Module findChildByProperty directory  [file normalize $currentDir]]==""} {
                                            
                                            set m [$currentParent module [file tail $currentDir]]
                                            lappend postGatherList $m
                                            $m useDirectory $currentDir
                                            
                                        }
                                        
                                        
                                        set isModule true
                                        break
                                    }
                                }
                                
                                ## If not module, create Group and explore
                                if {!$isModule} {
                                    
                                    
                                    ## Create Group if not already existing
                                    if {[$currentParent shade ::odfi::Group findChildByProperty name [file tail $currentDir]]==""} {
                                        set nextParent [$currentParent group [file tail $currentDir]]
                                        lappend postGatherList $nextParent
                                    } else {
                                        set nextParent [$currentParent shade ::odfi::Group findChildByProperty name [file tail $currentDir]]
                                    }
                                    
                                    lappend nextDirectories [list $nextParent [glob -nocomplain -type d -directory $currentDir *]]
                                    #set nextDirectories [concat $nextDirectories ]
                                    
                                    
                                }
                                
                            }
                        }
                        ## EOF Dir Grou^p
                    }
                    ## EOF while directories
                    
                    
                }
                ## EOF each Config
                
                ## Post Gather
                :loadIndexScripts
                foreach element $postGatherList {
                    if {[catch {$element callPostBuild} res]} {
                        :log:warning "Error during post build of [$element getFullName] : $res"
                        error $res 
                    }
                }
                
            }
            
            ## Module Path format: (group/)*module(/version)?
            +method findModules {modulePath {version ""}} {
                
                if {$modulePath==""} {
                    return [::odfi::flist::MutableList new]
                }

                ## Split at / if necessary
                ##########
                set originalModulePath $modulePath
                if {[string match "*/*" $modulePath]} {
                    set modulePath [split $modulePath /]
                }
                
                :log:raw "Searching for module ([llength $modulePath]): $modulePath..."
                
                ## Sort Module Path
                ##########
                #set modulePath [split $modulePath /]
                set targetConfig ""
                set targetConfigObject ""
                
                ## if first starts with "@" it is a config
                if {[string match "@*" [lindex $modulePath 0]]} {
                    set targetConfig [lindex $modulePath 0]
                    set modulePath [lreplace $modulePath 0 0]
                    
                    set targetConfigObject [:shade ::odfi::Config findChildByProperty name [string range $targetConfig 1 end]]
                    if {$targetConfigObject==""} {
                        :log:warning "Specified Target Config $targetConfig is not defined"
                    }
                    
                }
                
                ## If last is a version, then save
                set targetVersion ""
                if {[::odfi::Version::isVersion [lindex $modulePath end]]} {
                    set targetVersion  [lindex $modulePath end]
                    #set modulePath [lreplace $modulePath end end]
                }
                
                ## Checks
                #############
                if {$modulePath=="" || [llength $modulePath]==0} {
                    :log:warning "Cannot find module requestd with path $originalModulePath, because it seems only target config and or version are specified (remaining search=$modulePath)"
                }
                ## Search
                ##  - Search in all config or only the target config
                ##  - Each path in module should be leading to a sub object
                ############
                set foundModules [::odfi::flist::MutableList new]
                set searchConfigs [::odfi::flist::MutableList new]
                
                ## Select Configs
                if {$targetConfigObject!=""} {
                    $searchConfigs += $searchConfigs
                } else {
                    :shade ::odfi::Config eachChild {
                        $searchConfigs += $it
                    }
                }
                
                $searchConfigs foreach {
                    {config i } =>
                        
                        #puts "Search Config [$config name get]"
                        
                        set currentNode $config
                        set searchModulePath $modulePath
                        while {[llength $searchModulePath]>0} {
                        
                            ## get the search module
                            set currentSearchPath [lindex $searchModulePath 0]
                            set searchModulePath [lreplace $searchModulePath 0 0]
                            
                            #puts "Looking at $currentSearchPath -> version=[::odfi::Version::isVersion $currentSearchPath]"
                            
                            
                            ## Search cases:
                            ## a) last path and If Current search is a version, look for a child Module with the correct version
                            ## b) b.1) if not matched...last path search for a module in the bottom Group tree 
                            ##    b.2) Otherwise Look in current node for child with correct name
                            set foundChild ""
                            if {[llength $searchModulePath]==0 && [::odfi::Version::isVersion $currentSearchPath]} {
                                
                                set foundChildRes [[$currentNode shade ::odfi::Module children] findOption { 
                                    if {[$it shade ::odfi::Version findChildByProperty name $currentSearchPath]!=""} {
                                        return true
                                    } else {
                                        return false
                                    }
                                }]
                                
                                if {![$foundChildRes isDefined]} {
                                    set foundChild ""
                                } else {
                                    set foundChild [$foundChildRes get]
                                }
                               
                                
                            } 

                            if {$foundChild==""} {
                            
                            
                                ## Search in current children with Subtree if it is the last path, otherwise normal search
                                ## This way, after going as far as possible in group search, we'll search the subtree to find modules even if the path is not complete
                                if {[llength $searchModulePath]==0} {
                                    
                                   # puts "Using subtree search"
                                    ## Search in current Node subtree in level order
                                    set foundChild [$currentNode shade ::odfi::Module findFirstInTreeLevelOrder {
                                        if {[$it info class]!="::odfi::repo::Module" && [$it directory get]!="" && [$it name get]==$currentSearchPath} {
                                            return true
                                        } else {
                                            return false 
                                        }
                                    }]
                                } else {
                                    set foundChild [$currentNode shade { expr {[$it isClass ::odfi::Module] || [$it isClass ::odfi::Group]} } findChildByProperty name $currentSearchPath]
                                }
                                
                            }
                           
                            
                            ## Not Found -> Stop
                            ## Found: 
                            ##   - switch to current Node
                            ##   - If Last one and on Module found
                            ##   - If Last one and on Group  return all the sub modules
                            ##   - if no version check or version match, add to found modules
                            if {$foundChild==""} {
                                #puts "Nothing found"
                                break
                            } else {
                                
                                ## Current node
                                set currentNode $foundChild
                                
                               # puts "Found [$currentNode info class] for $currentSearchPath"
                                
                                ## If end and Module, found
                                if {[llength $searchModulePath]==0 && [$currentNode isClass ::odfi::Module]} {
                                    $foundModules += $currentNode
                                }
                                
                                ## If end and Group, add all sub modules
                                if {[llength $searchModulePath]==0 && [$currentNode isClass ::odfi::Group]} {
                                    
                                    $currentNode shade ::odfi::Module eachChild {
                                        $foundModules += $it
                                    }
                                    
                                }
                                #if {[llength $searchModulePath]==0 && [$currentNode isClass ::odfi::Module] && ($targetVersion==""  || ( $targetVersion!="" && [$currentNode shade ::odfi::Version findChildByProperty name $targetVersion]!="" ) ) } {
                                #    
                                #    $foundModules += $currentNode
                                #    
                                #} 
                            }
                            
                        }
                }
                
                
                
                return $foundModules
               
            
            }
            
            +method resolveCommand {mainCommand} {
                
                if {$mainCommand==""} {
                   return ""
                }
                if {[::nsf::is object $mainCommand]} {
                    return $mainCommand
                }
                
                :log:raw "Resolving $mainCommand..."
                
                
                ## Command is either to be looked in modules, or it can be a file
                if {[file exists $mainCommand] && ![file isdirectory $mainCommand]} {
                    
                    ## File Command
                    ##################
                    set foundCommand [::odfi::filecommand $mainCommand]
                    $foundCommand addParent [current object]
                    return $foundCommand

                    #set commandFile [file normalize $mainCommand]
                    
                
                    #return [:resolveCommand odfi/tcl]
                    #:runCommand odfi/tcl $commandFile
                    
                } else {
                
                    ## Standard Command
                    ## Format: module/module/module/version?/command
                    #######################
                    set originalCommand $mainCommand
                    set mainCommand [split $mainCommand /]
                    
                    ## Get Final Command
                    set command [lindex $mainCommand end]
                    
                    ## Get Module Search path
                    set moduleSearchParth [lreplace $mainCommand end end]
                    #set mainCommand [lreplace $mainCommand end end]
                    
                    ## Find Version and remove from command path if necessary
                    #set versionIndex [lsearch -regexp $mainCommand ${::odfi::versionRegexp}]
                    #if {$versionIndex!=-1} {
                    #    set version [lindex $mainCommand $versionIndex]
                    #    set mainCommand [lreplace $mainCommand $versionIndex $versionIndex]
                    #}
                    #set version [lsearch -regexp -inline $mainCommand ${::odfi::versionRegexp}]
                    
                    
                    :log:debug "Module path: $moduleSearchParth"
                    :log:debug "Command: $command"
                    
                    ## Look for all modules
                    set foundModules [:findModules $moduleSearchParth]
                    
                    
                    ## Results:
                    ##  - Nothing found, it could be:
                    ##     - A Command in a module
                    ##     - A FileCommand in the environment
                    set foundCommand ""
                    $foundModules isEmpty {
                        
                        :log:raw "Searching Command $command as command of a module or runnable file present in modules environment PATH"
                        
                        ## Try Command in a module
                        :log:debug "Looking for $command as command in a module somewhere"
                        [:shade ::odfi::Config children] @> foreach {
                            $it shade ::odfi::Module eachChild {
                                {module i} => 
                                
                                    set c [$module shade ::odfi::Command findChildByProperty name $command]
                                    if {$c!=""} {
                                        set foundCommand $c 
                                        break
                                    }
                            }
                            
                            if {$foundCommand!=""} {
                                break
                            }
                        }
                        
                        ## Try command as environment script
                        if {$foundCommand==""} {
                            
                            :log:debug "Building Environment and looking for $command in a PATH"
                            set rEnv [:env:environment]
                            set odfi [current object]
                            [$rEnv shade ::odfi::environment::Variable findChildrenByProperty name PATH] @> foreach {
                                
                                uplevel [list :log:debug "Testing in [$it value get]"]
                                
                                if {[file exists [$it value get]/$command]} {
                                    
                                    ## Create FileCommand
                                    uplevel [list :log:debug "Found $command in [$it value get]"]
                                    
                                    
                                    set foundCommand [::odfi::filecommand [$it value get]/$command]
                                    $foundCommand addParent $odfi
                                    break
                                
                                }
                            }
                        
                        }
                        #puts "Done Found FC:  $foundCommand"
                        return $foundCommand
                    
                    } else {
                        
                        ## FIXME Use version to get the correct one and run the command
                        set module [$foundModules at 0]
                        if {$module==""} {
                            ::odfi::log::error "Could not find module $moduleSearchParth for command $originalCommand"
                            return ""
                        } else {
                        
                            ## Look for Command
                            set commandObject [$module shade ::odfi::Runnable findChildByProperty name $command]
                            if {$commandObject == ""} {
                                ::odfi::log::debug "Could not find command $command in module $moduleSearchParth for $originalCommand"
                                return ""
                            } else {
                                
                                ## Return command
                                set foundCommand $commandObject
                                #$commandObject run $args
                                
                            }
                        }
                    
                    }
                    
                   
                    
                    ## Return result
                    return $foundCommand
                    
                    
                    
                }
                
            
            }
            
            +method runCommand {mainCommand args} {
                
                :log:raw "Running Command $mainCommand with arguments $args..."
                
                set foundCommand [:resolveCommand $mainCommand]
                if {$foundCommand==""} {
                
                    :log:debug "Could not resolve any command for $mainCommand"
                    
                    return ""
                } else {
                    $foundCommand run $args
                }
            
                
            
                
                
            }
            
        
        }
        ## EOF ODFI
    
    }
    ## EOF Language
    
    
    ## Tool API
    ########################
    variable versionRegexp {([0-9]+)(.[\w]*[0-9]+)+}
    proc versionMatch str {
    
    }

    ## next mdoules
    source $moduleLocation/odfi-repo.tm
    source $moduleLocation/odfi-environment.tm
    source $moduleLocation/odfi-scm.tm
}

