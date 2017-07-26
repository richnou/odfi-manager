# Modules Manager for ODFI

## Installation in MSYS2

### Add the extra repository


First, Install the nano text editor:

	MINGW64 ~ $ pacman -S nano
   
Open the File /etc/pacman.conf : 

	MINGW64 ~ $ nano /etc/pacman.conf
   
Add the following lines at the end of the file:

	[odfi]
	Server = http://www.opendesignflow.org/packaging/msys2/$arch
	SigLevel = Optional TrustAll

Save the file by pressing `CTRL+X`, then press Y to accept the changes.

###  Update the Package list

Now run the command to update the list of available packages:

	MINGW64 ~ $ pacman -Syy

###  Install ODFI

	MINGW64 ~ $ pacman -S odfi