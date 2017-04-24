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
        puts "Creating slave interpreter"
        set runInterpreter [interp create]
        puts "Interp name: $runInterpreter"
        #interp hide $runInterpreter open open
       #interp hide $runInterpreter puts puts
        #$runInterpreter alias open ::open
        #$runInterpreter alias puts ::puts
        
        ## Source prescripts
        #set foundDevTCL false
        #puts "Prescripts: [[$runEnv shade ::odfi::environment::PreScript firstChild]  path get]"
        [$runEnv shade ::odfi::environment::PreScript children] @> filter { return [string match "*.tcl" [$it path get]] } @> foreach {
             #puts "Sourcing prescript [$it path get]" 
            $runInterpreter eval [list source [$it path get]]
            #if {[string match "*tcl/devlib*"  [$it path get]]} {
            #    set foundDevTCL true
            #}
        }
        
        ## If devlib was not found; set the internal one
        #if {!$foundDevTCL} {
            #puts "Loading internal dev-tcl"
            #$runInterpreter eval [list source ${::odfi::moduleLocation}/odfi-dev-tcl/tcl/pkgIndex.tcl]
        #}
        
        ## Make Sure NX can be found
        if {![catch {set ::nxLocalPath}]} {
            if {${::nxLocalPath}!="" && [file isfile ${::nxLocalPath}]} {
                puts "Loading local NX -> ${::nxLocalPath}"
                $runInterpreter eval [list set dir [file dirname ${::nxLocalPath}]]
                $runInterpreter eval [list source ${::nxLocalPath}]
            }
            
        }
        #if {${::nxLocalPath}!=""} {
        #    #puts "Loading local NX -> ${::nxLocalPath}"
        #    $runInterpreter eval [list set dir [file dirname ${::nxLocalPath}]]
        #    $runInterpreter eval [list source ${::nxLocalPath}]
        #}
        
        
        ## Source script in interpreter then delete
        try {
            
            $runInterpreter eval [list set argv [join [lrange $args 1 end]]]
            $runInterpreter eval [list source [$cmd path get]]
        
        } finally {
            interp delete $runInterpreter
        }
    }
    
}

:module tcl {

    :command packageIndex {
    
        set outputLocation [lindex $args 0]
        
    
        puts "Generating TCL package index to $outputLocation"
        if {$outputLocation!=""} {
            
            set outFile [::new ::odfi::richstream::RichStream #auto]
            $outFile streamToFile $outputLocation
            
            ## Create Environment
            set env [[:getODFI] env:environment]
            $env buildFromModules
            $env detach
            
            [$env shade ::odfi::environment::PreScript children] @> filter { return [string match "*.tcl" [$it path get]] } @> foreach {
                #puts "Sourcing prescript [$it path get]"
                $outFile puts "source [$it path get]"
                #source [$it path get]
            }
            
            $outFile close
            
        }
    }
    
    :command runFile {
    
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


}




