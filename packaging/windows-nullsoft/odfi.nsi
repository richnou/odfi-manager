;!define MULTIUSER_EXECUTIONLEVEL Standard
;!define MULTIUSER_NOUNINSTALL ;Uncomment if no uninstaller is created
;!include MultiUser.nsh

;Function .onInit
;  !insertmacro MULTIUSER_INIT
;FunctionEnd

;Function un.onInit
 ; !insertmacro MULTIUSER_UNINIT
;FunctionEnd

!include EnvVarUpdate.nsh
!include MUI2.nsh


;!include LogicLib.nsh


;;;;;; NAMING and parameters
;;;;;;;;;;;;;;;;;;;;;;;;
!define VERSION "<% return $version %>"

Name "ODFI Manager"
;;OutFile "odfi-installer-${VERSION}.exe"
OutFile "odfi-installer.exe"


;LicenseData ..\..\..\LICENSE.txt

;; Splash
;;;;;;;;;;;;;;;;;;
Function .onInit
  SetOutPath $TEMP
  File /oname=spltmp.bmp "splash.bmp"


  splash::show 1000 $TEMP\spltmp

  Pop $0 ; $0 has '1' if the user closed the splash screen early,
	 ; '0' if everything closed normally, and '-1' if some error occurred.

  Delete $TEMP\spltmp.bmp

FunctionEnd

;; Modern UI
;;;;;;;;;;;;;;;;;;;;;;;;

;--------------------------------
;Interface Settings

!define MUI_ABORTWARNING

;Default installation folder
InstallDir "$LOCALAPPDATA\odfi-manager"

;Get installation folder from registry if available
InstallDirRegKey HKCU "Software\odfi-manager" ""

;Request application privileges for Windows Vista and +
RequestExecutionLevel user

!define MUI_COMPONENTSPAGE_SMALLDESC ;No value
;!define MUI_UI "odfi.exe" ;Value
!define MUI_INSTFILESPAGE_COLORS "FFFFFF 000000" ;Two colors

;; Define Parameters
;;;;;;;;;;;;;

;!define MUI_PAGE_HEADER_TEXT "ODFI Manager"
;!define MUI_PAGE_HEADER_SUBTEXT "ODFI Manager"
!define  MUI_ICON ..\..\..\logo\logo_main_512.ico
!define  MUI_UNICON ..\..\..\logo\logo_remove.ico

;; Create Pages
;;;;;;;;;;;;;;;;;;;;;;;;

!define MUI_WELCOMEPAGE_TITLE Welcome
!insertmacro MUI_PAGE_WELCOME

!insertmacro MUI_PAGE_LICENSE "..\..\..\LICENSE.txt"

!define MUI_COMPONENTSPAGE_TEXT_TOP "Component Selection"
!insertmacro MUI_PAGE_COMPONENTS

!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"


;; Version
;;;;;;;;;;;;;;;;;
VIProductVersion "${VERSION}.0"
VIAddVersionKey /LANG=${LANG_ENGLISH} "ProductName" "ODFI Manager"
VIAddVersionKey /LANG=${LANG_ENGLISH} "CompanyName" "ODFI"
VIAddVersionKey /LANG=${LANG_ENGLISH} "LegalCopyright" "Copyright 2016 @ ODFI"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileDescription" "ODFI Manager Installer"
VIAddVersionKey /LANG=${LANG_ENGLISH} "FileVersion" "${VERSION}.0"

;; Pages
;;;;;;;;;;;;;;;;;;;;;;
;Page license
;Page components
;Page directory
;Page instfiles 

;;;;;; Components

Section "ODFI Manager"

  SetOutPath $INSTDIR
  File  ..\..\..\logo\logo_main_512.ico
  
  SetOutPath $INSTDIR\bin
  File  ..\..\..\bin\*
  File  ..\..\..\server\target\odfi-manager-server.exe
  
  SetOutPath $INSTDIR\private
  File  ..\..\..\private\*.tm
  File  ..\..\..\private\*.tcl
  File /r ..\..\..\private\odfi-dev-tcl
  File /r ..\..\..\private\commands

  SetOutPath $INSTDIR\private\nsf
  File /r ..\..\..\private\nsf\nsf2.0.0-msys64
  File /r ..\..\..\private\nsf\nsf2.0.0-win64

  SetOutPath $INSTDIR\configs
  File  ..\..\..\configs\*

  ;;SetOutPath $INSTDIR\site
  ;;File /r ..\..\..\site\*

   SetOutPath $INSTDIR

  ;Store installation folder and uninstall path
  WriteRegStr HKCU "Software\odfi-manager" "" $INSTDIR
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "DisplayName"         "ODFI Manager"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "Publisher"           "ODFI.org"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "DisplayName"         "ODFI Manager"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "UninstallString"     "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "DisplayIcon"         "$INSTDIR\uninstall.exe"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "NoModify"            "1"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "NoRepair"            "1"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "DisplayVersion"      "${VERSION}"
  WriteRegStr HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager" "Version"             "${VERSION}"

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\uninstall.exe"

  ;; Modify Path
  ${EnvVarUpdate} "mp" "PATH" "A" "HKCU" "$INSTDIR\bin"

  ;; Add Progam Startup Menu
  CreateDirectory "$SMPROGRAMS\odfi-manager"
  CreateShortcut "$SMPROGRAMS\odfi-manager\ODFI Manager.lnk" "$INSTDIR\bin\odfi-manager.exe"     "" $INSTDIR\logo_main_512.ico"
  CreateShortcut "$SMPROGRAMS\odfi-manager\Uninstall ODFI Manager.lnk" "$INSTDIR\uninstall.exe"

SectionEnd

;--------------------------------
;Descriptions

  ;Language strings
  LangString DESC_SecDummy ${LANG_ENGLISH} "A test section."

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDummy} $(DESC_SecDummy)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END

;---------------------------------
; Uninstall

Section "Uninstall"


  Delete "$INSTDIR\Uninstall.exe"

  RMDir /r "$INSTDIR\*"
  
  ;RMDir /r "$INSTDIR"

  DeleteRegKey /ifempty HKCU "Software\odfi-manager"
  DeleteRegKey HKCU "Software\Microsoft\Windows\CurrentVersion\Uninstall\odfi-manager"

  ;; Modify Path
  ${un.EnvVarUpdate} "mpu" "PATH" "R" "HKCU" "$INSTDIR\bin"

  ;; Remove Program Startup

SectionEnd




