#!/bin/bash

### Bootstrap script for ODFI Manager
### Use this script to prepare the local system for manager
loc="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"

echo "ODFI Module Manager is at: $loc"

## System Dependencies
###############

#### TCL
#####################
if [[ -z $(which tclsh) ]]
then
	echo "TCL is missing on the system, trying to install"
	exit
fi



## Export Ourselves to PATH
#################
export PATH="$loc/bin:$PATH"

## Load Modules
###################
$loc/bin/odfi --load

loadRes=`$loc/bin/odfi --load`

while read -r line; do

    #echo "Showing line2: $line"

    eval $line

done <<< "$loadRes"

#eval `$loc/bin/odfi --load`

#echo $TCLLIBPATH

echo $SCALT

echo $PATH
