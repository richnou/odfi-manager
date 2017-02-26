#!/bin/csh

set findFullPath=`lsof +p $$ | grep -oE /.\*setup.linux.csh`
#echo "Path: $findFullPath"


### Bootstrap script for ODFI Manager
### Use this script to prepare the local system for manager

set loc=`dirname $findFullPath`

#echo "Hello $loc"
#if ($#argv == 0) echo There are no arguments

##&& $1 == "--debug"

set debug=false

if ($#argv > 0 && $1 == "--debug") then
    set debug=true
endif
 


## System Dependencies
###############

#### TCL
#####################
if (-z `which tclsh`) then
	echo "TCL is missing on the system, please install at least TCL 8.5"
    exit -1
endif




## Export Ourselves to PATH
#################
setenv PATH "$loc/bin:$PATH"

## Load Modules
###################
#$loc/bin/odfi --load

set loadRes=`$loc/bin/odfi --load | sed 's/ /@@@@/g'`




## If Return code is not 0, an error occured
if ( $status != 0 ) then
    echo "ODFI Loading failed: "
  
    ## Show output
    foreach line ( $loadRes)
        set line=`echo $line | sed 's/@@@@/ /g'`
        echo $line

    end

    # exit $ERROR_CODE
	exit $ERROR_CODE
endif



foreach line ( $loadRes)
    
    set line=`echo $line | sed 's/@@@@/ /g'`
    #echo "Showing line2: $line"
#	echo $line
	

    ## Before evaluation, replace BASH syntax
    set line=`echo $line | sed 's/export/setenv/g'`

    ## Debug?
    if ($debug == true) then
        echo $line
    endif
    eval $line

end 


setenv ODFI_LOADED=1
#eval `$loc/bin/odfi --load`

#echo $TCLLIBPATH

#echo $SCALT

#echo $PATH
