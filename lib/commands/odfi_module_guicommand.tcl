

set guiCommand [:command "gui" {

    package require odfi::ewww 3.0.0
   
    :log:raw "Starting GUI Command using EWWW Framework"

    set c [current object]
    set server [::odfi::ewww::server 8685 {

        :application odfi /odfi {

            :htmlViewTemplate base [${c} templatesFolder get]/odfi-gui-base.tcl

            :htmlView index / {
                set template [:getTemplate base]
                $template apply {

                }

                return $template
            }

        } 

    }]

    :log:raw "Webapp ready...."
    [:getODFI] addChild $server

    $server start

    


}]
$guiCommand object variable -accessor public templatesFolder [file dirname [info script]]/templates/
$guiCommand object variable -accessor public filesFolder     [file dirname [info script]]/files/


:command "vwait" {

    :log:raw "Waiting on ::forever for event listener loop"
    ${:commandResult} setState waiting
    vwait ::forever
    :log:raw "Finished vwait"

}

:command "vwait-stop" {

    :log:raw "Stopping event listener loop"
    set ::forever true

}
