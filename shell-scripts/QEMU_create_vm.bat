@echo off
rem ==================================
rem Replace with your values
rem ==================================
set "QEMUDIR=C:\Virtual\qemu"

rem ==================================
rem Safety net
rem ==================================
if not exist hda.img (
    rem CREATE a virtual hard disk 
    %QEMUDIR%\qemu-img.exe create hda.img 10G
) else (
    echo file hda.img already exist. Delete or move and try again.
    goto:eof
)