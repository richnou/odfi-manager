## This script contains bootstrap code to load the correct NSF library depending on system:
## Windows ActiveTCL/Mingw or Linux
if {[catch {package require nsf 2.0.0} res]} {
    
    set nsfBootstrapFolder [file dirname [info script]]

    ## Try to load local
    ########
    #puts "Looking for NSF [string tolower $::tcl_platform(os)]"
    if {[string match "*windows*" [string tolower $::tcl_platform(platform)]] && [string match "*msys64*" $::tcl_library]} {
        
           
        
       puts "Can't load NSF, using local version for msys nt"
        
        set dir  $nsfBootstrapFolder/nsf2.0.0-msys64
        source   $nsfBootstrapFolder/nsf2.0.0-msys64/pkgIndex.tcl
        
        set     nxLocalPath $nsfBootstrapFolder/nsf2.0.0-msys64/pkgIndex.tcl
        
    } elseif {[string match "*windows*" [string tolower $::tcl_platform(platform)]]} {
    
        #puts "Can't load NSF, using local version for windows"
        
        set dir  $nsfBootstrapFolder/nsf2.0.0-win64
        source   $nsfBootstrapFolder/nsf2.0.0-win64/pkgIndex.tcl
        
        set     nxLocalPath $nsfBootstrapFolder/nsf2.0.0-win64/pkgIndex.tcl
        
   
        
       
    }
    
}