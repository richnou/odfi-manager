#!/bin/zsh

## Get Script location
location=$(dirname $(readlink -f $0))

## System Dependencies
###############

#### TCL
#####################
if [[ -z $(which tclsh) ]]
then
    echo "TCL is missing on the system, please install at least TCL 8.5"
    exit
fi


## Hooks
###############
if [[ ! -f $loc/.git/hooks/post-commit ]]
then
    cp -p $loc/hooks/post-commit $loc/.git/hooks/post-commit
fi

if [[ ! -f $loc/.git/hooks/post-merge ]]
then
    cp -p $loc/hooks/post-merge $loc/.git/hooks/post-merge
fi

## Export Ourselves to PATH
#################
export PATH="$loc/bin:$PATH"

## Load Modules
###################
#$loc/bin/odfi --load

loadRes=`$loc/bin/odfi --load`

while read -r line; do

    eval $line

done <<< "$loadRes"

