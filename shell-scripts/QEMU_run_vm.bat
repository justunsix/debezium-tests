@echo off

rem ================================== C:\Virtual\qemu\qemu-system-x86_64.exe -drive file=hda.img,index=0,media=disk,format=raw -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -parallel none -serial none -name ubuntu18 -no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::2222-:22
rem Replace with your values
rem ==================================
set "QEMUDIR=C:\Virtual\qemu"

rem ==================================
rem You can add a w suffix to this if 
rem you don't want a console
rem ==================================
set "QEMUBIN=qemu-system-x86_64.exe"

rem ==================================
rem Run the virtual machine
rem ==================================
start "QEMU" %QEMUDIR%\%QEMUBIN% -drive file=hda.img,index=0,media=disk,format=raw -m 2G -L Bios -usbdevice mouse -usbdevice keyboard -boot menu=on -rtc base=localtime,clock=host -parallel none -serial none -name ubuntu18 -no-acpi -no-hpet -no-reboot -device e1000,netdev=user.0 -netdev user,id=user.0,hostfwd=tcp::2222-:22