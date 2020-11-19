# Steps to set up a sandbox environment to test debezium

My team runs a Windows only environment, so instructions are focusing on Windows. 
Ideally, the sandbox environment should run Linux natively with the developer having sudo (administrative) privleges.

## Option 1 Windows Subsystem for Linux (WSL)
- Install WSL using Microsoft's [Windows Subsystem for Linux for Windows 10](https://github.com/MicrosoftDocs/wsl/blob/master/WSL/install-win10.md) by following [Get started using Docker contianers with WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers) that covers on WSL, Windows Terminal, VS Code IDE, and Docker setup on Windows. 
  - Ubuntu 20.04 LTS was used for set up
  - Windows Terminal
  - VS Code 
    - WSL Remote Extension
  - Create new or use existing Docker Hub ID
- Restart your machine manually
-  Install flavour of Linux from Microsoft Store
-  Launch the flavour and configure it

### Openshift Specific

- [Openshift 3.11 CLI](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html)
- [Debezium Openshift install](https://debezium.io/documentation/reference/operations/openshift.html)

Remote User Acceptance Testing
1. Install Version 0.20 of the Strimzi operator > [installation options](https://github.com/lenisha/aks-tests/tree/master/oshift/strimzi-kafka-connect-eventhubs#install-strimzi-operator)
2.	You will not be able to see the operator as it is installed in a different namespace called strimzi-operator.  You have permissions to use it, not see it. You have to specify the namespace, for example:
`oc process strimzi-operator//strimzi-ephemeral ....`


## Option 2 Local Command line 
- Install Cygwin on local machine, get packages for curl, git, etc. or use cloud IDE, workspace e.g. [gitpod](https://gitpod.io/workspaces/)
- Local dev reuses existing Linux VMs or container hosting for sandbox development

### Linux VM setup

#### Installing a Linux Virtual Machine on Windows 10 with Linux Virtual Machine
1. Get Installation Binaries
- Ubuntu latest LTS 64 bit
- Hyper V or Virtualbox
  - Virtualbox, for Windows, got 6.1.12-139181-Win, latest as of 2020-07-27
- Either download the files on the host from the internet or copy the files using remote desktop clipboard copy and paste. Mounting local drives or secure file transfer may also be an option
2. Install/Activate Virtualization:
- Install VirtualBox (VB) or activate Hyper V on the host machine.
- Note the VB installation will temporarily disconnect the network. Simply reconnect to your remote server if needed.
3. Create Linux Virtual Machine
- Resources:
  - https://medium.com/nycdev/how-to-ssh-from-a-host-to-a-guest-vm-on-your-local-machine-6cb4c91acc2e written for VirtualBox v6 and Ubuntu 18.04 LTS
  - Activate SSH using Virtualbox port forwarding and configure guest machine network. Alternate instructions at 
https://medium.com/@pierangelo1982/setting-ssh-connection-to-ubuntu-on-virtualbox-af243f737b8b 

- When your VM is started, open your terminal and try to connect: `ssh yourusername@127.0.0.1 -p 2222`

#### Guide to create the Linux VM on Hyper-V
Follow steps at https://www.nakivo.com/blog/run-linux-hyper-v/  
Settings used during the set up were:
- Specific Name and Location: Ubuntu 18 and use default VM location on Windows C:\ProgramData\Microsoft\Windows\Hyper-V\
- Specify Generation: 1 for compatibility reasons
- Assign Memory: 2 GB 
- 2048 mb or half of host OS
- Connection: Default Switch
  - Later other virtual switches can be created/used
- Connect Virtual Hard Disk: Use default name and location. Set size 10 GB. 16 GB is recommended but host machine is not large enough at this time.
- Installation Option: Select the Linux image you downloaded in the earlier step
- Select a static MAC address. Right click VM > Settings > Network > +plus icon > Advanced Features. Set static MAC address, change 00-00-00-00-00-00 to 00-15-3D-33-02-00. Click apply and ok.
- Run the VM by right click on the VM then Connect.
- To get IP of machine using ifconfig. IP is assigned by default switch in Hyper-V. Use external switch if external IPs are required.

### Troubleshooting VM Install

#### Setup - Windows 10 machine
Example specifications for the host of the Linux VM
- Uses Processor - Intel(R) Xeon(R) CPU E5-2690 v4 @ 2.60GHz, 2600 Mhz, 2 Core(s), 2 Logical Processor(s). https://ark.intel.com/content/www/us/en/ark/products/64596/intel-xeon-processor-e5-2690-20m-cache-2-90-ghz-8-00-gt-s-intel-qpi.html 
- 4 GB RAM
- Intel® Virtualization Technology (VT-x) is supported, so 64 bit guests are supported on it.
- Only has limited GB free, may need to free space in future for use

#### Virtualbox cannot detect 64 bit. 
Follow these steps https://forums.virtualbox.org/viewtopic.php?f=1&t=62339 

#### Nested virtualization
From error messages like 
- VT-X is not enabled
- Not Hyper-V CPUID signature: 0x61774d56 0x4d566572 0x65726177 (expected 0x7263694d 0x666f736f 0x76482074) (VERR_NEM_NOT_AVAILABLE).
- VT-x is not available (VERR_VMX_NO_VMX)
##### About the issue and suggested fixes
- https://timothygruber.com/hyper-v-2/run-a-nested-vm-on-kvm-qemu-vm-in-hyper-v/ 
- https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization 
- Remove App & Browser settings for VMcompute and related executables: https://stackoverflow.com/questions/41182714/unable-to-start-docker-in-windows-10-hyper-v-error-is-thrown , Restart VMM

#### VM Clean up
Remove Hyper-V configured VM or delete VirtualBox VM

# Linux setup

## Update
- Try installing package updates executing this command in terminal. The commands will check updates and then upgrade packages, then remove any unused packages due to upgrades.
```
$ sudo apt update && sudo apt upgrade -y
$ sudo apt-get autoremove
```
- If there are proxy problems, follow the "Proxy set up" section below and try the command again.
- Get SSH running for secure remote access
```
$ sudo apt-get install openssh-server
$ sudo service ssh status
```

## Proxy set up
This step is required if the VM's host or network uses a proxy to the internet.
You may have to set package manager proxy and HTTP/HTTPS proxy environment variables (e.g. http_proxy=...)

Example proxy setting for 204.1.1.1 3128

Add these lines to etc/environment
```
http_proxy=http://204.1.1.1 3128:3128/
https_proxy=https://204.1.1.1 3128:3128/
```

Set the proxy used by Aptitude package manager. Create a new file under the /etc/apt/apt.conf.d directory, and then add the following lines.
```
Acquire {
  HTTP::proxy "http://204.40.130.129:3128";
  HTTPS::proxy "http://204.40.130.129:3128";
}
```
For temporary proxy settings, use the following on the commmand line
```shell 
proxy_http=204.40.130.129:3128
```

## Install Docker 
Use instructions provided by Docker
https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository 
