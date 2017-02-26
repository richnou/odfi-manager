## This Module holds the features to gather an environment from the installed modules
package provide odfi::environment



namespace eval ::odfi::environment {


    odfi::language::nx::new [namespace current] {
        

        ## Elements
        #############
        :group name {
            +exportTo Group

            :environment : Group {

                +exportTo ::odfi::Odfi env
                +exportTo ::odfi::Module env
                +exportTo ::odfi::Runnable env 

                +mergeWith name

                +var name "default"

                ## Default builder 
                +builder {
                 
                
                }


                ## Utils
                ##################

                +method isDefault args {
                    if {[$it name get]=="default"} {
                        return true
                    } else {
                        return false
                    }
                }

                ## Get the directory of first module in parents 
                +method getDirectory args {

                    set moduleParent [:findParentInPrimaryLine {$it isClass ::odfi::Module}]
                    if {$moduleParent==""} {
                        error "Cannot get Environment directory based on first Module in parent hierarchy, no Module in parent hierarchy"
                    }
                    return [$moduleParent getDirectory]

                }

                ## Create
                ###################

                ## Build from modules
                +method buildFromModules args {

                    set odfi [:parent]
                    set renv [current object]
                    [:parent] shade ::odfi::Module walkDepthFirstPreorder {
                        
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
                
                
                ## Go up the hierarchy and gather defined environements into a new one
                ## Only Default envionrments are accepted
                +method buildUp matchClosure {

                    ## Get Hierarchy and feed current environment from all the environment defined on the hierarchy objects
                    set hierarchy [:shade $matchClosure getPrimaryParents]
                    set environments [$hierarchy @> map {$it shade ::odfi::environment::Environment children} @> flatten @> filter {$it isDefault}]

                    ## Maintain a visited environment list, because when referencing multiple from same subtree, we don'T want to revisit all the parents everytime
                    set visited [::odfi::flist::MutableList new]
                    

                    puts "Builup hierarchy with environments: [$hierarchy size]"
                    set name  [:formatHierarchyString {$it name get} /]

                    while {![$environments isEmpty]} {

                        ## Get Env and Check agains visited
                        set env [$environments pop]
                        if {[$visited contains $env]} {
                            continue
                        } else {
                            $visited += $env 
                        }
                        


                        ## Go Through Environment stuff
                        ## References get resolved and added as group
                        ## Create Group for the env
                        set envHierName [$env formatHierarchyString {$it name get} /]
                        :group $envHierName {
                            [$env children] foreach {

                                if {[$it isClass ::odfi::environment::Ref]} {

                                    ## Format:
                                    ##  a) module/path/@environmentName
                                    ##  b) module/path/ (in that case the default environments are used)
                                    ##  INFO: Path string is first splited then tests to avoid conflicts with @config/module/path syntax
                                    set splited [split [$it name get] /]
                                    set module [lindex $splited 0]
                                    set envName [lindex $splited 1]
                                    if {![string match "@*" $envName]} {
                                        set module [$it name get]
                                        set envName "default"
                                    } else {
                                        set envName [string range $envName 1 end ]
                                    }

                                    puts "looking for referenced environment=$envName in module=$module "
                                    set foundEnvironments [[:parent] @> parent @> getODFI @> findModules $module @> map {$it shade ::odfi::environment::Environment findChildrenByProperty name $envName} @> flatten]

                                    puts "Found env: [$foundEnvironments size]"
                                    if {[$foundEnvironments size]==0} {

                                        puts "No Env found, for module=$module , env=$envName"
                                        puts "Module results: [[:parent] @> getODFI @> findModules $module @> size]"

                                    } else {

                                        ## Add Referenced Environment and its parents to the processing list
                                        $foundEnvironments foreach {
                                             $environments += $it 

                                             set h [$it  shade $matchClosure getPrimaryParents]
                                             $h @> map {$it shade ::odfi::environment::Environment children} @> flatten @> filterNot {$visited contains $it} @> filter {$it isDefault} @> foreach {
                                                $environments += $it
                                             }
                                        }

                                    }
                                    

                                } else {
                                    :addChild $it
                                }
                                
                            }

                        }
                        ## EOF Group
                        
                                
                      

                    }


                }
                

                ## Outputs
                #######################
                
                ## Creates a BASH script output to be sourced
                +method toBash file {


                    puts "Outputing to bash file: $file"
                    package require odfi::richstream 3.0.0

                    set out [::new ::odfi::richstream::RichStream #auto]
                    $out streamToFile $file 

                    $out puts "#!/bin/bash"
                    $out puts ""
                    $out puts ""
                    
                    ## Groups 
                    set allGroups [[:shade ::odfi::environment::Group children] @> mapSort {$it name get}]
                    $allGroups addFirst [current object] 

                    $allGroups @> filterNot { $it isEmpty } @> foreach {
                        {group gi} => 

                        $out puts "## From Environment [$group name get]"
                        $out puts "##############"
                        $out puts ""

                        ## Get all variables and sort by name 
                        set allVars [[$group shade ::odfi::environment::Variable children] mapSort {$it name get}]

                        $out puts ""
                        $out puts "## Defined Variables "
                        $out puts ""

                        $allVars @> filterNot { $it append get} @> foreach {
                            $out puts "export [$it name get]=\"[$it value get]\""
                        }
                        
                        $out puts ""
                        $out puts "## Appended values"
                        $out puts ""
                        $allVars @> filter { $it append get} @> foreach {
                            $out puts "export [$it name get]=\"[$it value get]:\$[$it name get]\""
                        }
                        $out puts ""

                        $out puts ""
                        $out puts ""

                    }

                    

                    $out close
                    
                
                }

                


                
                
                
                
            
            }


            ## Environment Variable
            :variable name value {
                +expose name
                +var append false 

                +constant appendingNames {
                    PATH
                    LD_LIBRARY_PATH
                }

                +objectMethod addAppendingName name {
                    lappend ::odfi::environment::Variable::appendingNames $name
                }

                +builder {
                    #puts "Created Variable for ENV: ${:name}"
                }
            }

            ## :export VAR VALUe or :export VAR=VALUE
            ## Export will set the append parameter automatically based on Variable::appendNames list
            ## If Variable name begins with "+a+" then always append
            +method export args {

                set createdVariables {}

                ## Create Variable
                if {[llength $args]>=2} {
                    foreach val [lindex $args 1] {

                        set var [uplevel [list :variable [lindex $args 0] $val]] 
                        lappend createdVariables $var

                      
                    }
                    
                } else {
                    set splitted [split [lindex $args 0] = ]
                    set var [uplevel [list :variable [lindex $splitted 0] [lindex $splitted 1]]]
                    lappend createdVariables $var
                    
                }

                foreach created $createdVariables {

                    ## Decide if it should be appending
                    if {[string match "+a+*" [$created name get]]} {

                        $var append set true 
                        $var name   set [string range [$var name get] 3 end]
                    
                    } elseif {[lsearch -exact ${::odfi::environment::Variable::appendingNames} [$var name get]]>=0} {
                    
                        $var append set true
                    
                    }

                }

                

            }

            ## Export one value to multiple names
            +method exportValue {value names} {

                set nameValuePairs $names
                foreach name $names {   
                    
                    set name [subst $name]
                    :export $name $value
                }
            }

            ## Export name and value with a variable $value set to provided value
            +method exportWithValue {value keyWord valueName nameValuePairs} {

                #puts "Name value pair: [::odfi::closures::declosure $nameValuePairs]"

                ## Declosure the values list, because the closure API have replaced $var by odfi::closures::value var, which causes issue for list format
                set nameValuePairs [::odfi::closures::declosure $nameValuePairs]
                set $valueName $value

                foreach {name values} $nameValuePairs {

                    #puts "Exporting: $name -> $values ([llength $values])"
                    if {[llength $values]>0} {

                    }

                    foreach vvalue $values {

                        set vvalue [subst $vvalue]
                        #puts "Exporting: $name -> $vvalue"

                        :export $name $vvalue

                    }
                }
            }
            
            ## PreScript
            :preScript path {
                +exportTo Environment
            }
            

            ## Environment Ref
            :ref name {
                +exportTo Environment
            }   
            

        }

        
    
    }

}
