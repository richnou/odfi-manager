## Script to preLoad Indexes from NPM Style modules
#puts "Running Prescript to find node_modules injects"
set currentFolder [file dirname  $script]
#puts "File Folder: $currentFolder"

## Search for node_modules
foreach nodeFolder [glob -type d -nocomplain $currentFolder/node_modules/*] {

   #puts "Node folder: $nodeFolder"
    foreach tclindex [glob -type f -nocomplain $nodeFolder/lib/pkgIndex.tcl] {
      #  puts "Found Library in $tclindex"
        source $tclindex
    }
    foreach tclindex [glob -type f -nocomplain $nodeFolder/tcl/pkgIndex.tcl] {
      #  puts "Found Library in $tclindex"
        source $tclindex
    }

}