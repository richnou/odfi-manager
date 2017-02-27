#!/usr/bin/env tclsh

package require odfi::git 
package require odfi::files 2.0.0
package require odfi::richstream 3.0.0

set location [file dirname [info script]]

## Parameters
##############

if {[catch {set nsisPath [exec which makensis]}]} {

    set nsisPath "C:/Program Files (x86)/NSIS/Bin/makensis.exe"

}


### Determine version
##########################

#### Version from pom
regexp {<version>([\w\d\.\-]+)<\/version>} [odfi::files::readFileContent $location/../../../server/pom.xml] -> pomVersion
set version [regsub -- {-SNAPSHOT} $pomVersion "" ]




#### Nightly?
if {[catch {set branch [::odfi::git::current-branch $location]}]} {
    set branch "dev"
}

set nightly false
if {$branch=="dev"} {
    set nightly true
    set version "${version}.[clock milliseconds]"
}


puts "Version: $version $branch"

## Build Manager
#####################
odfi::files::inDirectory $location/../../../server/ {

    if {![file exists target/odfi-manager-server.exe]} {
        puts "Test: [exec which mvn]"
        set mvn [exec which mvn]
        #exec bash  E:/git/main/java/maven/3.3.9/bin/mvn package >&@stdout
    }
    
    
    file copy -force target/odfi-server-${pomVersion}.exe target/odfi-manager-server.exe
}


## Generate Script replacing version
##############
::odfi::richstream::template::fileToFile $location/odfi.nsi $location/odfi.generated.nsi 


## Call NSIS
##############

odfi::files::inDirectory $location {

    ## Delete ODFI exe and regenerate
    puts "Generating installer..."
    file delete -force  $location/odfi-installer-$version.exe >&@stdout
    exec $nsisPath $location/odfi.generated.nsi
    
    ## If odfi exe exists, upload it 
    ## Disable for now, try to deploy to maven
    if {[file exists odfi-installer-$version.exe]} {
        puts "Uploading..."
        #::odfi::richstream::template::stringToFile "$version" $location/odfi-version.ini 
        #exec scp odfi-installer-$version.exe        rleys@buddy.idyria.com:/data/access/osi/files/builds/odfi/win32/odfi-installer-$version.exe >&@stdout
        #exec scp odfi-version.ini                   rleys@buddy.idyria.com:/data/access/osi/files/builds/odfi/win32/odfi-version.ini >&@stdout
    }
    
}

