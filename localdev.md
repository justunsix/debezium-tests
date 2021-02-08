# Steps to set up a sandbox environment to test debezium

My team runs a Windows only environment, so instructions are focusing on Windows. 
Ideally, a sandbox environment should run Linux with the developer having sudo (administrative) privleges.

# Docker, Windows Subsystem for Linux (WSL)
- Install WSL using Microsoft's [Windows Subsystem for Linux for Windows 10](https://github.com/MicrosoftDocs/wsl/blob/master/WSL/install-win10.md) by following [Get started using Docker contianers with WSL](https://github.com/MicrosoftDocs/wsl/blob/master/WSL/tutorials/wsl-containers.md) that covers on WSL, Windows Terminal, VS Code IDE, and Docker setup on Windows. 
  - Enable virtualization on local machine BIOS
  - Ubuntu 20.04 LTS was used for set up
  - Windows Terminal
  - VS Code with extensions:
    - [WSL Remote Extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-wsl) - enables you to open your Linux project running on WSL in VS Code (no need to worry about pathing issues, binary compatibility, or other cross-OS challenges)
    - [Remote-Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers) - enables you to open your project folder or repo inside of a container, taking advantage of Visual Studio Code's full feature set to do your development work within the container.
    - [Docker extension](https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker) - adds the functionality to build, manage, and deploy containerized applications from inside VS Code. (You need the Remote-Container extension to actually use the container as your dev environment.)
    - [Github Pull request extension](https://marketplace.visualstudio.com/items?itemName=GitHub.vscode-pull-request-github)
      - Set git path, e.g. edit settings.json 
     ```json
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

# A. Kubernetes (K8S)
- [Debezium Openshift install](https://debezium.io/documentation/reference/operations/openshift.html)
- Install a Kubernetes cluster for development or use a remote cluster such as the [Openshift 3.11 Playground for 1 hour usage](https://learn.openshift.com/playgrounds/openshift311/).

## A.1 Kubernetes local
- Install [Docker desktop Kubernetes](https://docs.docker.com/docker-for-windows/#kubernetes) which includes [kubectl](https://kubernetes.io/docs/reference/kubectl/overview/)

## A.2 Openshift local
- Install [Minishift 3.11](https://docs.okd.io/3.11/minishift/index.html)
- [Openshift 3.11 CLI](https://docs.openshift.com/container-platform/3.11/cli_reference/get_started_cli.html)

# Debezium, Azure Event Hubs Set up

## High level steps
1. [Install Strimzi Cluster Operator](https://strimzi.io/docs/operators/latest/quickstart.html)
2. Build Debezium image with connectors needed
3. Set configuration files with Azure Event Hubs and database connections
4. Set up Kafka Connect Cluster with image and configuration files
5. Test changes

## Tutorials on Above Steps
- [Debezium Openshift install with Strimzi operator and MS SQL connector](https://github.com/lenisha/aks-tests/tree/master/oshift/strimzi-kafka-connect-eventhubs)
- [Kafka Connect on Kubernetes the easy way](https://itnext.io/kafka-connect-on-kubernetes-the-easy-way-b5b617b7d5e9)

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
```sh
sudo apt update && sudo apt upgrade -y
sudo apt-get autoremove
```
- If there are proxy problems, follow the "Proxy set up" section below and try the command again.
- Get SSH running for secure remote access
```sh
sudo apt-get install openssh-server
sudo service ssh status
```

## Proxy set up
This step is required if the VM's host or network uses a proxy to the internet.
You may have to set package manager proxy and HTTP/HTTPS proxy environment variables (e.g. http_proxy=...)

Example proxy setting for 204.40.130.129 port 3128

Add these lines to etc/environment or shell initialization like ~/.bashrc
```sh
http_proxy=http://204.40.130.129 3128:3128/
https_proxy=https://204.40.130.129 3128:3128/
```

Set the proxy used by Aptitude package manager. Create a new file 'proxy.conf' under the '/etc/apt/apt.conf.d/' directory, and then add the following lines. e.g.
```sh
sudo nano /etc/apt/apt.conf.d/proxy.conf
# In editor, add these lines
Acquire {
  HTTP::proxy "http://204.40.130.129:3128";
  HTTPS::proxy "http://204.40.130.129:3128";
}
```

### Temporary proxy settings
#### Set

```sh
export http_proxy=http://204.40.130.129:3128
export https_proxy=http://204.40.130.129:3128
# git proxy
git config --global http.proxy http://204.40.130.129:3128
```

#### Unset (remove proxy settings)

```sh
# remove system proxy
unset http_proxy
unset https_proxy
# remove git proxy
git config --global --unset http.proxy  
```

## Install Docker 
Use [install instructions provided by Docker](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)

# Conectivity

## Check connectivity to databases and Kakfa endpoints

### Windows
```sh
tnc -ComputerName "eventhub-dev.servicebus.windows.net" -InformationLevel "Detailed" -Port 9093
tnc -ComputerName "192.168.2.1" -InformationLevel "Detailed" -Port 1433
```

### Linux
#### Telnet
```sh
telnet eventhub-dev.servicebus.windows.net 9093
telnet 192.168.2.1 1433
```
#### Ncat aka nc

```sh
nc -vz eventhub-dev.servicebus.windows.net 9093
nc -vz 192.168.2.1 1433
```

#### curl

```sh
curl -v telnet://142.1.1.1:1433

* About to connect() to 142.1.1.1 port 1433 (#0)
*   Trying 142.1.1.1...
^C
```

## Check connectivity in Docker, Kuberenetes, Openshift

Before setup, connectivity to endpoints can be tested quickly using an simple container that has the curl command such as [tutum/curl](https://hub.docker.com/r/tutum/curl) container that has curl on an ubuntu base image.

### Docker

Pull an image with curl, run it, then run the connectivity test.
```sh
docker pull tutum/curl
docker run -it tutum/curl bash
$ curl -v telnet://eventhub-dev.servicebus.windows.net:9093
```

### Kubernetes / Openshift

Create a new pod using this configuration below that uses the image with curl.

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: tutum
  labels:
    app: tutum
spec:
  containers:
  - name: tutum
    image: tutum/curl
    command: ["/bin/sleep", "3650d"]
    imagePullPolicy: IfNotPresent
  restartPolicy: Always
```

When the pod is running, get into the container's shell, then run connectivity tests

```sh
$ oc get pods
NAME         READY     STATUS             RESTARTS   AGE
tutum        1/1       Running            0          114m
$ oc rsh  --shell=/bin/bash tutum
1000710000@tutum:/$ curl -v telnet://eventhub-dev.servicebus.windows.net:9093
```

# Kafka server.properties
Defaults in the Strimzi base image
```sh
[kafka@44db389f6bbe config]$ cd /opt/kafka/config/
[kafka@44db389f6bbe config]$ more server.properties 
```
```properties
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# see kafka.server.KafkaConfig for additional details and defaults

############################# Server Basics #############################

# The id of the broker. This must be set to a unique integer for each broker.
broker.id=0

############################# Socket Server Settings #############################

# The address the socket server listens on. It will get the value returned from 
# java.net.InetAddress.getCanonicalHostName() if not configured.
#   FORMAT:
#     listeners = listener_name://host_name:port
#   EXAMPLE:
#     listeners = PLAINTEXT://your.host.name:9092
#listeners=PLAINTEXT://:9092

# Hostname and port the broker will advertise to producers and consumers. If not set, 
# it uses the value for "listeners" if configured.  Otherwise, it will use the value
# returned from java.net.InetAddress.getCanonicalHostName().
#advertised.listeners=PLAINTEXT://your.host.name:9092

# Maps listener names to security protocols, the default is for them to be the same. See the config documentation for more details
#listener.security.protocol.map=PLAINTEXT:PLAINTEXT,SSL:SSL,SASL_PLAINTEXT:SASL_PLAINTEXT,SASL_SSL:SASL_SSL

# The number of threads that the server uses for receiving requests from the network and sending responses to the network
num.network.threads=3

# The number of threads that the server uses for processing requests, which may include disk I/O
num.io.threads=8

# The send buffer (SO_SNDBUF) used by the socket server
socket.send.buffer.bytes=102400

# The receive buffer (SO_RCVBUF) used by the socket server
socket.receive.buffer.bytes=102400

# The maximum size of a request that the socket server will accept (protection against OOM)
socket.request.max.bytes=104857600


############################# Log Basics #############################

# A comma separated list of directories under which to store log files
log.dirs=/tmp/kafka-logs

# The default number of log partitions per topic. More partitions allow greater
# parallelism for consumption, but this will also result in more files across
# the brokers.
num.partitions=1

# The number of threads per data directory to be used for log recovery at startup and flushing at shutdown.
# This value is recommended to be increased for installations with data dirs located in RAID array.
num.recovery.threads.per.data.dir=1

############################# Internal Topic Settings  #############################
# The replication factor for the group metadata internal topics "__consumer_offsets" and "__transaction_state"
# For anything other than development testing, a value greater than 1 is recommended to ensure availability such as 3.
offsets.topic.replication.factor=1
transaction.state.log.replication.factor=1
transaction.state.log.min.isr=1

############################# Log Flush Policy #############################

# Messages are immediately written to the filesystem but by default we only fsync() to sync
# the OS cache lazily. The following configurations control the flush of data to disk.
# There are a few important trade-offs here:
#    1. Durability: Unflushed data may be lost if you are not using replication.
#    2. Latency: Very large flush intervals may lead to latency spikes when the flush does occur as there will be a lot of data to flush.
#    3. Throughput: The flush is generally the most expensive operation, and a small flush interval may lead to excessive seeks.
# The settings below allow one to configure the flush policy to flush data after a period of time or
# every N messages (or both). This can be done globally and overridden on a per-topic basis.

# The number of messages to accept before forcing a flush of data to disk
#log.flush.interval.messages=10000

# The maximum amount of time a message can sit in a log before we force a flush
#log.flush.interval.ms=1000

############################# Log Retention Policy #############################

# The following configurations control the disposal of log segments. The policy can
# be set to delete segments after a period of time, or after a given size has accumulated.
# A segment will be deleted whenever *either* of these criteria are met. Deletion always happens
# from the end of the log.

# The minimum age of a log file to be eligible for deletion due to age
log.retention.hours=168

# A size-based retention policy for logs. Segments are pruned from the log unless the remaining
# segments drop below log.retention.bytes. Functions independently of log.retention.hours.
#log.retention.bytes=1073741824

# The maximum size of a log segment file. When this size is reached a new log segment will be created.
log.segment.bytes=1073741824

# The interval at which log segments are checked to see if they can be deleted according
# to the retention policies
log.retention.check.interval.ms=300000

############################# Zookeeper #############################

# Zookeeper connection string (see zookeeper docs for details).
# This is a comma separated host:port pairs, each corresponding to a zk
# server. e.g. "127.0.0.1:3000,127.0.0.1:3001,127.0.0.1:3002".
# You can also append an optional chroot string to the urls to specify the
# root directory for all kafka znodes.
zookeeper.connect=localhost:2181

# Timeout in ms for connecting to zookeeper
zookeeper.connection.timeout.ms=18000



############################# Group Coordinator Settings #############################

# The following configuration specifies the time, in milliseconds, that the GroupCoordinator will delay the initial consumer rebalance.
# The rebalance will be further delayed by the value of group.initial.rebalance.delay.ms as new members join the group, up to a maximum of max.poll.interval.ms.
# The default value for this is 3 seconds.
# We override this to 0 here as it makes for a better out-of-the-box experience for development and testing.
# However, in production environments the default value of 3 seconds is more suitable as this will help to avoid unnecessary, and potentially expensive, rebalances during application startup.
group.initial.rebalance.delay.ms=0
```
