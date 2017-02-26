:repository base {
    
    :location set [file normalize [info script]]

    :group indesign {

        :module ide {

            :groupId    org.odfi.indesign.ide
            :artifactId indesign-ide-core


        }

    }

    :group tcl {
    
        :module devlib {
        
            :version master {
                :location any any https://github.com/unihd-cag/odfi-dev-tcl.git
            }
        
        }
    
    }
    
    :group doc {
    
        :module duckdoc {
            
            :version master {
                :location any any https://github.com/richnou/odfi-doc.git
            }
            
        }
    }
    
    :group eda {
        
        :module utils {
                       
           :version master {
               :location any any https://github.com/unihd-cag/odfi-dev-hw.git
           }
       
       }
        
        :group hdl {
            
            :module h2dl {
            
                :version master {
                    :location any any https://github.com/richnou/h2dl.git
                }
            
            }
            
            :module rfg3 {
            
                :version master {
                    :location any any https://github.com/kit-adl/rfg3.git
                }
            
            }
            
           
        
        }
    
    }
    
    :group js {
    
        :module node {
            
            
            foreach version {4.4.7 6.3.1} {
                
                :version $version {
                    
                    foreach {platform arch path} {
                                    windows x86_64 win-x64/node.exe 
                                    windows x86    win-x86/node.exe} {
                                    
                        :location $platform $arch http://nodejs.org/dist/v$version/$path {
                        
                        }
                        
                    }
                }
            }
            
            :onContentUpdated {
                file mkdir ${:directory}/bin
                file copy -force ${:directory}/node.exe ${:directory}/bin
            }
            
            #:platform windows 64 {
            #    :location https://nodejs.org/dist/v6.3.1/win-x64/node.exe
            #}
            #:platform windows 64 {
            #    :location https://nodejs.org/dist/v6.3.1/win-x64/node.exe
            #}
        }
    }

    

    ## Scala Libraries
    ##############

    :group scala {


        :group utils {
            :module tea {
                :version master {
                    :location any any git@github.com:richnou/tea.git 
                }
            }
        }

        

        :group wsb {
            :module core {

                :version master {
                    :location any any git@github.com:richnou/wsb-core.git 
                }

            }

            :module webapp {

                :version master {
                    :location any any git@github.com:richnou/wsb-webapp.git 
                }

            }
        }
            
        

        :group gui {

            :group vui2 {
                :module core {

                    :version master {
                        :location any any git@github.com:richnou/vui2.git 
                    }
                }
            }

            :group vui {
                
                #:attribute odfi deprecated true

                :module core {

                    :version master {
                        :location any any git@github.com:richnou/virtualui-core.git 
                    }

                }

                :module javafx {
                   
                    :version master {

                        :location any any git@github.com:richnou/virtualui-javafx.git  

                    }
                }
                
            }

            

        }

        :group xml {


            :group ooxoo {

                :module core {

                    :version master {

                        :location any any git@github.com:richnou/ooxoo-core.git  

                    }
                }
            }
        }
    }

    ## Indesign
    ######################
    :group indesign {

        :module core {
            :version master {
                :location any any git@github.com:richnou/indesign.git 
            }
        }

    }


}
