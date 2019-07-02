#!/bin/bash

### Bootstrap script for ODFI Manager
### Use this script to prepare the local system for manager
loc="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"

#echo "ODFI Module Manager is at: $loc"

debug=false
if [[ -n $1 && "$1" == "--debug" ]]
then
	debug=true
fi


## System Dependencies
###############

#### TCL
#####################
if [[ -z $(which tclsh) ]]
then
	echo "TCL is missing on the system, please install at least TCL 8.5"
	return -1
fi


## Hooks
###############
#if [[ ! -e $loc/.git/hooks/post-commit ]]
#then
#	ln -s $loc/hooks/post-commit $loc/.git/hooks/post-commit
#fi

#if [[ ! -e $loc/.git/hooks/post-merge ]]
#then
#	ln -s $loc/hooks/post-merge $loc/.git/hooks/post-merge
#fi

## Export Ourselves to PATH
#################
export PATH="$loc/bin:$PATH"

## Load Modules
###################
#$loc/bin/odfi --load

loadRes=`"$loc/bin/odfi" --load`

## If Return code is not 0, an error occured
if [[ $? != 0 ]]; 
then
  echo "ODFI Loading failed: "
  
  ## Show output
  while read -r line; do

    echo $line

    done <<< "$loadRes"

   # exit $ERROR_CODE
	return $ERROR_CODE
fi

while read -r line; do

    #echo "Showing line2: $line"
#	echo $line
	if [[ $debug == true ]]
	then
		echo $line
	fi

    eval $line

done <<< "$loadRes"

export ODFI_LOADED=1
#eval `$loc/bin/odfi --load`

#echo $TCLLIBPATH

#echo $SCALT

#echo $PATH
