:command "bash" {

    puts "Bash to : [lindex $args 0]"
    
    
    [:getODFI] onModule [lindex $args 0] {
        
        puts "Going to: [:directory get]: $::env(SHELL)"
        ::odfi::files::inDirectory [:directory get] {
        
            
       
           
            #exec env PS1=TEST $::env(SHELL) >@stdout <@stdin 2>@1
            #exec env PS1=TEST\ [:name \w>>  $::env(SHELL) --norc >@stdout <@stdin 2>@1
            
            set ps1 "\\e\[32m\\u@\\h\\e\[0m on module [:name get] \\e\[33m\\w\\e\[0m >> "
            
            exec env PS1=$ps1 CYG_SYS_BASHRC=1 $::env(SHELL) >@stdout <@stdin 2>@1
        }
        
        puts "Done"
        
    
    }
}