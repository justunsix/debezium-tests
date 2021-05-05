# Installing Xubuntu in a Virtualbox Virtual Machine on Windows

1. Download LTS version of Xubuntu on [https://xubuntu.org/](https://xubuntu.org/). Xubuntu chosen to provide a graphical desktop environment and minimizing packages for performance reasons.
2. Install/upgrade VirtualBox, Install guest additions
3. In Virtualbox, create new Linux VM, approx half cpu and RAM of host. Dynamically allocated 
4. Install with updates from network, default (CSB) secure password with account
5. Restart VM, remove Ubuntu installation ISO
6. Boot into Linux, open run terminal, run 

```sh 
# upgrade software
sudo apt update && sudo apt upgrade
# Install the dependencies for building kernel modules
sudo apt install build-essential dkms linux-headers-$(uname -r)`

```

7. Attach VirtualBox guest additions CD to VM
8. In Linux, access the CD and allow it to auto-run or use `autorun.sh`
9. Restart Linux `shutdown -r now`
10. When booted into Linux against, against VM Window. If it adjusts, the guest additions installed successfully
11. Optionally, in Virtualbox menu for the VM, enable Devices > Shared Clipboard and Drag and Drop

# Install other Software
- [Docker](https://docs.docker.com/engine/install/ubuntu/)
- [SSHD to ssh to VirtualBox VM from host](https://dev.to/yassineselllami/how-to-ssh-into-ubuntu-vm-virtualbox-from-host-machine-1kii)
- [git](https://www.digitalocean.com/community/tutorials/how-to-install-git-on-ubuntu-20-04)
