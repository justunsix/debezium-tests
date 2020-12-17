@echo off

rem ==================================
rem Replace with your values
rem ==================================
set "QEMUDIR=C:\Virtual\qemu"
set "ISOFILE=ubuntu-18.04.4-live-server-amd64.iso"

rem ==================================
rem You can add a w suffix to this if 
rem you don't want a console
rem ==================================
set "QEMUBIN=qemu-system-x86_64.exe"

rem ==================================
rem Run the virtual machine
rem ==================================
start "QEMU" %QEMUDIR%\%QEMUBIN% -drive file=hda.img,index=0,media=disk,format=raw -cdrom %ISOFILE% -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -parallel none -serial none -name ubuntu18 -no-acpi -no-hpet -no-reboot 
