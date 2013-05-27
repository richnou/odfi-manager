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

## Private dependencies
##############################

## DEV TCL
if [[ ! -d $loc/private/odfi-dev-tcl ]]
then

    url="http://lebleu/gitlab/odfi/odfi-dev-tcl.git"

    echo "Modules Managers needs dev TCL module privately."
    echo "Trying to clone from $url"

    git clone $url $loc/private/odfi-dev-tcl
fi



## Export Ourselves to PATH
#################
export PATH="$loc/bin:$PATH"

## Load Modules
###################
#$loc/bin/odfi --load
