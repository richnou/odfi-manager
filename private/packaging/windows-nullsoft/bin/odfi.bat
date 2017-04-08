
@echo off

REM Get current script path
REM ----------------------

SET mypath=%~dp0

REM Run with TCLSH
REM ------------------
tclsh86 %mypath:~0,-1%\odfi %*

