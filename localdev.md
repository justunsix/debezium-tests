# Steps to set up a sandbox environment to test debezium

My team runs a Windows only environment, so instructions are focusing on Windows. 
Ideally, a sandbox environment should run Linux with the developer having sudo (administrative) privleges.

# Docker, Windows Subsystem for Linux (WSL)
- Install WSL using Microsoft's [Windows Subsystem for Linux for Windows 10](https://github.com/MicrosoftDocs/wsl/blob/master/WSL/install-win10.md) by following [Get started using Docker contianers with WSL](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers) that covers on WSL, Windows Terminal, VS Code IDE, and Docker setup on Windows. 
  - Enable virtualization on local machine BIOS
  - Ubuntu 20.04 LTS was used for set up
  - Windows Terminal
  - VS Code with extensions:
    - [WSL Remote Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) - enables you to open your Linux project running on WSL in VS Code (no need to worry about pathing issues, binary compatibility, or other cross-OS challenges)
    - [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - enables you to open your project folder or repo inside of a container, taking advantage of Visual Studio Code's full feature set to do your development work within the container.
    - [Docker extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) - adds the functionality to build, manage, and deploy containerized applications from inside VS Code. (You need the Remote-Container extension to actually use the container as your dev environment.)
    - [Github Pull request extension](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
      - Set git path, e.g. edit settings.json 
     ```
     // Is git enabled
     "git.enabled": true,

     // Path to the git executable
     "git.path": "C:\\usr\\bin\\ptbl\\PortableApps\\PortableGit\\bin\\git.exe",
     ```
  - If using a proxy, set proxy settings for [git, Advanced Package Tool (apt), and other tools](https://github.com/justintungonline/debezium-tests/blob/main/localdev.md#proxy-set-up)
  - Create new or use existing Docker Hub ID
- Restart your machine manually
-  Install a Linux distribution (e.g. Ubuntu LTS, Fedora Remix) from Microsoft Store
-  Launch Linux and configure it

# A. Kubernetes
- [Debezium Openshift install](https://debezium.io/documentation/reference/operations/openshift.html)
- Install a Kubernetes cluster for development or use a remote cluster such as the [Openshift 3.11 Playground for 1 hour usage](https://learn.openshift.com/playgrounds/openshift311/).

## A.1 Kubernetes local
- Install [Docker desktop Kubernetes](https://docs.docker.com/docker-for-windows/#kubernetes)

## A.2 Openshift local
- Install [Minishift 3.11](https://docs.okd.io/3.11/minishift/index.html)
- [Openshift 3.11 CLI](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html)

Remote User Acceptance Testing
1. Install Version 0.20 of the Strimzi operator > [installation options](https://github.com/lenisha/aks-tests/tree/master/oshift/strimzi-kafka-connect-eventhubs#install-strimzi-operator)
2.	If the operator is installed in a different namespace (e.g. strimzi-operator), grant persmissions for your user to use it. It is a cluster wide operator. Specify the namespace to use it - e.g.: `oc process strimzi-operator//strimzi-ephemeral ....`


# Local Command line 
- Install Cygwin on local machine, get packages for curl, git, etc. and use cloud IDE, workspace e.g. [Gitpod](https://gitpod.io/workspaces/), [Cloud9](https://aws.amazon.com/cloud9/), [Google Cloud Shell (includes Docker)](https://cloud.google.com/shell)
- Local development can reuse existing Linux VMs or container hosting for sandbox development

# Linux VM setup

## Installing a Linux Virtual Machine on Windows 10 with Linux Virtual Machine
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
  - [How to ssh from host to guest VM on local](https://medium.com/nycdev/how-to-ssh-from-a-host-to-a-guest-vm-on-your-local-machine-6cb4c91acc2e) written for VirtualBox v6 and Ubuntu 18.04 LTS
  - Activate SSH using Virtualbox port forwarding and configure guest machine network. Alternate instructions at [setting sshe connection to Ubuntu on VirtualBox](https://medium.com/@pierangelo1982/setting-ssh-connection-to-ubuntu-on-virtualbox-af243f737b8b)

- When your VM is started, open your terminal and try to connect: `ssh yourusername@127.0.0.1 -p 2222`

## Guide to create the Linux VM on Hyper-V
Follow steps at [Run Linux Hyper-V](https://www.nakivo.com/blog/run-linux-hyper-v/)
Settings used during the set up were:
- Specific Name and Location: Ubuntu 18 and use default VM location on Windows 'C:\ProgramData\Microsoft\Windows\Hyper-V\'
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

## Troubleshooting VM Install
Issues that might be encountered

### Setup - Windows 10 machine
Example specifications for the host of the Linux VM
- Uses Processor - [Intel(R) Xeon(R) CPU E5-2690](https://ark.intel.com/content/www/us/en/ark/products/64596/intel-xeon-processor-e5-2690-20m-cache-2-90-ghz-8-00-gt-s-intel-qpi.html) v4 @ 2.60GHz, 2600 Mhz, 2 Core(s), 2 Logical Processor(s).  
- 4 GB RAM
- Intel® Virtualization Technology (VT-x) is supported, so 64 bit guests are supported on it.
- Only has limited GB free, may need to free space in future for use

### Virtualbox cannot detect 64 bit. 
Follow these steps [on VirtualBox forums](https://forums.virtualbox.org/viewtopic.php?f=1&t=62339)

### Nested virtualization
You are receiving error messages like:
- VT-X is not enabled
- Not Hyper-V CPUID signature: 0x61774d56 0x4d566572 0x65726177 (expected 0x7263694d 0x666f736f 0x76482074) (VERR_NEM_NOT_AVAILABLE).
- VT-x is not available (VERR_VMX_NO_VMX)
#### About the issue and suggested fixes
- [Run a nested VM on KVM QEMU VM in Hyper-V](https://timothygruber.com/hyper-v-2/run-a-nested-vm-on-kvm-qemu-vm-in-hyper-v/)
- [Microsoft Hyper-V on Windows User Guide, nested virtualization](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/nested-virtualization)
- [Remove App & Browser settings for VMcompute and related executables](https://stackoverflow.com/questions/41182714/unable-to-start-docker-in-windows-10-hyper-v-error-is-thrown), Restart VMM

## VM Clean up
Remove Hyper-V configured VM or delete VirtualBox VM

# Linux setup

## Update
- Assume Linux is Debian/Ubuntu distribution
- Try installing package updates executing this command in terminal. The commands will check updates and then upgrade packages, then remove any unused packages due to upgrades.
```shell
sudo apt update && sudo apt upgrade -y
sudo apt-get autoremove
```
- If there are proxy problems, follow the "Proxy set up" section below and try the command again.
- Get SSH running for secure remote access
```shell
sudo apt-get install openssh-server
sudo service ssh status
```

## Proxy set up
This step is required if the VM's host or network uses a proxy to the internet.
You may have to set package manager proxy and HTTP/HTTPS proxy environment variables (e.g. http_proxy=...)

Example proxy setting for 204.40.130.129 port 3128

Add these lines to etc/environment
```shell
http_proxy=http://204.40.130.129 3128:3128/
https_proxy=https://204.40.130.129 3128:3128/
```

Set the proxy used by Aptitude package manager. Create a new file 'proxy.conf' under the '/etc/apt/apt.conf.d/' directory, and then add the following lines. e.g.
```shell
sudo nano /etc/apt/apt.conf.d/proxy.conf
# In editor, add these lines
Acquire {
  HTTP::proxy "http://204.40.130.129:3128";
  HTTPS::proxy "http://204.40.130.129:3128";
}
```
For temporary proxy settings, use the following on the commmand line
```shell 
export http_proxy=http://204.40.130.129:3128
export https_proxy=http://204.40.130.129:3128
# git proxy
git config --global http.proxy http://204.40.130.129:3128
```

## Install Docker 
Use [install instructions provided by Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
