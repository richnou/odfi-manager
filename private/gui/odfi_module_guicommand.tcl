

set guiCommand [:command "gui" {

    package require odfi::ewww 3.0.0
   
    :log:raw "Starting GUI Command using EWWW Framework"

    set command [current object]
    set server [::odfi::ewww::server 8685 {

        :application odfi /odfi {

            :htmlViewTemplate base [$command templatesFolder get]/odfi-gui-base.tcl

            :htmlView index / {
                set template [:getTemplate base]
                $template apply {

                }

                return $template
            }

        } 

    }]


    [:getODFI] addChild $server

    $server start

    


}]
$guiCommand object variable -accessor public templatesFolder [file dirname [info script]]/templates/
$guiCommand object variable -accessor public filesFolder     [file dirname [info script]]/files/


:command "vwait" {

    :log:raw "Waiting on ::forever for event listener loop"
    vwait ::forever

}

:command "vwait-stop" {

    :log:raw "Stopping event listener loop"
    set ::forever true

}
