## Update
################
:command update {

    :log:raw "Updating Modules..."
    set cmd [current object]
    
    ## Get all SCM
    set scms [[:getODFI] shade ::odfi::Config @> mapChildren { $it shade ::odfi::scm::SCM children} @> flatten]
    
    :log:raw "SCM Support found: [$scms @> map {$it type get} mkString ,]"

    ## Get Args
    if {[llength $args]==0} {
        set args "*"
    }
    
    ## Loop on args
    foreach modulePath $args {
            
            :log:raw "======================================================"
            :log:raw "Updating $modulePath..."
            
            ## Look for module
            [:getODFI] onModules $modulePath {
                
                {module index} => 
                
                    :log:raw "Found [$module name get] at [$module directory get]..."
                    
                    $scms @> findOption { $it accept $module} @> match {
                                
                        :some scm {
                            #$cmd log:raw "Found SCM [$scm type get]"
                            #$scm update $module
                            
                            if {[$scm isBehind $module]} {
                                
                                :log:raw "Updating..."
                                $scm update $module
                            } else {
                                :log:raw "No need to update..."
                            }
                            
                        }
                        
                        :none {
                        
                            :log:fine "Module  [$module name get] is not under a revision mechanism which supports updates"
                        }
                    }
                
                
            }
            
            #[:getODFI] @> findModules $modulePath @> isEmpty {
            #    
            #    :log:fine "Module  [$module name get] is not under a revision mechanism which supports updates"
            #
            #} else {
            #    
            #}
            
    }
   
    
    return
    [:getODFI] onAllPhysicalModules {
                    
        {module parent} => 
            
            :log:raw "======================================================"
            :log:raw "Updating [$module name get] in [$module directory get]"
            
            
           
        
    
    }

    
}