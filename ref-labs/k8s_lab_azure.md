# Kubernetes lab


This material is copyright of Canonical Limited. This material may be used for personal and noncommercial
use only.

This documentation is copyright of Canonical Limited. You are welcome to display on your
computer, download and print this documentation or to use the hard copy provided to you for
personal, education and non-commercial use only. You must retain copyright, trademark and
other notices unaltered on any copies or printouts you make. Any trademarks, logos an service
marks displayed in this document are property of their owners, whether Canonical or third
parties.

This documentation is provided on an "as is" basis, without warranty of any kind, either express
or implied. Your use of this documentation is at your own risk. Canonical disclaims all warranties
and liability that may result directly or indirectly from the use of this documentation.

## Lab assumptions

The following exercises will be done in a practice lab environment comprised of Virtual Machines on Azure cloud. The instructor will provide you with a public IP and credentials for a student machine. SSH will be used to connect to the student machine. The IP is static and reboot persistent.

The purpose of this lab is to familiarize the student with Kubernetes. Kubernetes version ```1.13``` will be deployed.

At the end of each day the VMs will be powered off, this will be done by the instructor. On the next day, the IPs of the Kubernetes workers nodes will change. This is easely fixed by running ```juju scp kubernetes-master/0:/home/ubuntu/config ~/.kube/config``` on the student machine.



# 1. LXD and Docker containers

## Containerization

Containers are isolated userspace instances running on the same kernel effectively providing multiple machines. They share certain portions of the host kernel and operating system instance so they require much less overhead than hypervisor based virtualization. (With full machine virtualization, a virtual machine runs its own full kernel and operating system instance.) A single host can run many more containers than VMs. Containers can be started, stopped and deleted extremely quickly.

There are two broad types:

 * Application containers (Ex. Docker)
 * Full machine containers (LXD)

Containers run on top of LXC. LXC is an operating-system-level virtualization method for running multiple isolated Linux systems (containers) on a control host using a single Linux kernel. LXC is a userspace interface for the Linux kernel containment features. The interface has an application programming interface (API) o Linux users can create and manage system or application containers.

## 1.1 LXD containers
LXD is a pure-container hypervisor that runs unmodified Linux operating systems and applications with VM-style operations at incredible speed and density. LXD is an enhancement of the existing LXC Linux container hypervisor with it’s own toolset. The goal is to provide an interface that is similar to a virtual machine. However, it uses Linux containers instead of hardware virtualization. LXC-based containers are easier to use through the addition of a back-end daemon supporting  REST API and a CLI client that works with both the local daemon and remote daemons via the REST API. RESTful API allows communication between LXD and its clients over http which is encapsulated over SSL for remote operations or a Unix socket for local operations. Once LXD is installed, an image is required. The container is based on the image.

LXD is comprised of the following components:

 * A system-wide daemon (lxd) which exports a REST API locally (and if enabled, over the network).
 * A command line client (lxc) which is a simple tool to manage containers: connect multiple container hosts, provide a network overview of all containers, and create and move containers.

LXD is image based. Images must be downloaded to LXD before a container can be launched. A number of remote image stores are already available. Images will be downloaded to the local LXD when a container is first launched. At its simplest, LXD is a daemon which provides a REST API to drive LXC containers. Its main goal is to provide a user experience that’s similar to that of virtual machines but using Linux containers rather than hardware virtualization.


## LXD Setup

Traditionally, LXD used to get installed from the default repository, or from a PPA. With the arrival of ```snappy``` we can now install LXD as a snap. We must clean any LXD version that may have been pre-installed on the system:

```bash
sudo apt update && sudo apt dist-upgrade -y
```

```bash
sudo apt remove --purge lxd lxd-client
```

Install ZFS support:

```bash
sudo apt install zfsutils -y
```

Create lxd group and add ourselves to it:

```bash
sudo usermod --append --groups lxd $USER
newgrp lxd
```

And install LXD as a snap:

```bash
sudo snap install lxd
```

Initialize LXD:

```bash
# use DEFAULT for all
# just hit ENTER
sudo lxd init
```

Follow the setup wizard. In most cases defaults should do.

Launch a new container:

```bash
lxc launch ubuntu:18.04 bionic
```

Afterwards, rename the new image with ```ubuntu``` as alias (use ```lxc image list``` to get the image fingerprint)

```bash
lxc image alias create ubuntu <fingetprint>
```

This will download the 18.04 image from the remote ```ubuntu:``` repository and launch a container using it.

## Using a remote LXD as an image server

A list with all the images from a remote can be obtained:

```bash
lxc image list images:
```
Create a container directly from a remote:

```bash
lxc launch images:centos/7/amd64 centos
```

## Creating and using a container

Create the first container with:

```bash
lxc launch ubuntu first
```

That will create and start a new ubuntu container. Confirm it with:

```bash
lxc list
```

The container here is called “first”. Let LXD give it a random name by calling “lxc launch ubuntu” without a name. Once the container is running, get a shell inside it with:

```bash
lxc exec first /bin/bash

root@first:~# exit
```

Or run a command directly:

```bash
lxc exec first apt update
```

To stop the containers:

```bash
lxc stop first
lxc stop bionic
lxc stop centos
```

And to remove them entirely:

```bash
lxc delete first
lxc delete bionic
lxc delete centos
```

Delete any other running containers that are listed in ```lxc list```.

Delete ```LXD```:

```bash
sudo snap remove lxd
```


## 1.2 Docker containers
Docker is another containerization engine. It is called a process container because it is designed to support a single application per container. In versions prior to 1.8 Docker was also using ```LXC runtime```, but since then ```containerd``` with ```runc``` runtime is used.

Docker Engine is a client-server application with these major components:
  * A server which is a type of long-running program called a daemon process called ```dockerd ```
  * A REST API which specifies interfaces that programs can use to talk to the daemon and instruct it what to do
  * A command line interface (CLI) client (the ```docker``` command)

The CLI uses the Docker REST API to control or interact with the Docker daemon through scripting or direct CLI commands. Many other Docker applications use the underlying API and CLI.

The daemon creates and manages Docker objects, such as images, containers, networks, and volumes.

A Docker registry stores Docker images. Docker Hub and Docker Cloud are public registries that anyone can use, and Docker is configured to look for images on Docker Hub by default. You can even run your own private registry.

When you use the ```docker pull``` or ```docker run``` commands, the required images are pulled from your configured registry. When you use the docker push command, your image is pushed to your configured registry.


## Docker Setup

Remove any remanent from LXD and install Docker packages:

```bash
sudo apt remove --purge lxc lxd

sudo apt install docker.io -y
```

Create the ```ubuntu``` user and add it to the ```docker``` group so you won't have to use sudo every time.

```bash
sudo usermod --append --groups docker $USER
newgrp docker
```

Check the status of the Docker daemon, everything should be fine:

```bash
sudo systemctl status docker
# output
* docker.service - Docker Application Container Engine
   Loaded: loaded (/lib/systemd/system/docker.service; enabled; vendor preset: enabled)
   Active: active (running) since Mon 2018-07-09 08:02:50 UTC; 13min ago
```

System wide information regarding the Docker installation can be displayed. Information includes the docker software version, kernel version, number of containers and images:

```bash
docker info
```

## Use Docker

Everything is set now. Containers can be created and runned. Every container requires an image to run from. The first step is to ```pull``` an image from the default ```Docker Hub``` repository. After we check that the image is present, the container can be executed.

```bash
docker pull hello-world
```

List the local images, the hello-world image should be present:

```bash
docker images
```

Now let's run the container. This will create the container and execute the processes defined for that image. In our case, a hello string should be displayed on output.


**NOTE**: if the desired images is not present when ```docker run``` is executed (e.g. ```docker pull``` was not executed before), it will automatically pull the image.

```bash
docker run hello-world
# output
Hello from Docker!
This message shows that your installation appears to be working correctly.
```

Let's list all the running containers to see how the container just created is running with ```docker ps```:

```bash
docker ps
# output
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS
```

There is no container! Use ```-a``` argument for the previous command, it will list all containers, not just the running ones:

```bash
docker ps -a
# output
CONTAINER ID        IMAGE               COMMAND          CREATED             STATUS
d75942ed3283        hello-world         "/hello"         5 minutes ago       Exited (0) 5 minutes ago
```

Can you explaind what is happening here? Tell the trainer what you think is happening.

In the hello world container, ```/hello``` script or command was executed. Eventually, the last process was executed and exited ```0```. At that moment the container also finished execution because there were no more processes to execute, all of them completed. Usually, in production and real world non-testing environments, long running processed are used, like daemons. Apache is a good example for this, or any other server listening for connections. The main idea is that a container will run as long as a running process is inside.


This is nice but surely we can do more than just display a hello world message. Containers can be interacted with. Let's create an ubuntu container, update it with the latest packages and install ```lsb_release``` utility to check the Ubuntu release on which we are running:

```bash
docker pull ubuntu
# output
Using default tag: latest
latest: Pulling from library/ubuntu
6b98dfc16071: Pull complete
4001a1209541: Pull complete
6319fc68c576: Pull complete
b24603670dc3: Pull complete
97f170c87c6f: Pull complete
Digest: sha256:5f4bdc3467537cbbe563e80db2c3ec95d548a9145d64453b06939c4592d67b6d
Status: Downloaded newer image for ubuntu:latest
```

```bash
docker images
# output
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
ubuntu              latest              113a43faa138        4 weeks ago         81.2 MB
hello-world         latest              e38bc07ac18e        2 months ago        1.85 kB
```

```bash
docker run -it ubuntu /bin/bash

# in container right now
root@486f9b6b3319:/# apt update && apt install -y lsb-release
...
```

```bash
root@486f9b6b3319:/# lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 18.04 LTS
Release:	18.04
Codename:	bionic
```

```bash
root@486f9b6b3319:/# uname -a
Linux f596f40415d0 4.15.0-1021-gcp...

root@486f9b6b3319:/# exit
```

The key here is the ```docker run``` command. In combination with ```-it``` options (-i interactive, -t allocates a preudo-TTY), it allows a user to execute a process inside a container in an interactive manner. In the above example, bash process was launched and attached to. If ```docker ps``` is runned again, there are no running containers beucase we exited from the bash process.

Redo the container creation part but without the exit command. Instead, try to detach from the container with ```CTRL-p``` + ```CTRL-q```. Now there should be a running container. Attach to it with ```docker attach``` and install the apache package:

```bash
docker ps
# output
CONTAINER ID      IMAGE        COMMAND          CREATED           STATUS           NAMES
904ccecea8b5      ubuntu       "/bin/bash"      5 minutes ago     Up 5 minutes     tender_heyrovsky
```

Use an evironment variable to store the container ID.

```bash
CONTAINER_ID=$(docker ps | awk 'FNR == 2 {print $1}')
```

```bash
docker attach $CONTAINER_ID

# inside container
root@904ccecea8b5:/# apt update -y && apt install apache2 -y
...

root@904ccecea8b5:/# service apache2 start
 * Starting Apache httpd web server

root@904ccecea8b5:/# ps aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.3  18508  3400 ?        Ss   12:36   0:00 /bin/bash
root       957  0.0  0.4  73960  4428 ?        Ss   12:39   0:00 /usr/sbin/apache2 -k start
www-data   960  0.0  0.6 821876  6284 ?        Sl   12:39   0:00 /usr/sbin/apache2 -k start
www-data   961  0.0  0.6 821876  6284 ?        Sl   12:39   0:00 /usr/sbin/apache2 -k start
root      1018  0.0  0.2  34400  3028 ?        R+   12:39   0:00 ps aux
```

If we detach the container (```CTRL-p``` + ```CTRL-q```) we should be able to see the apache processes from the host:

```bash
ps aux | grep apache
# output
root     13108  0.0  0.4  73960  4428 ?        Ss   12:39   0:00 /usr/sbin/apache2 -k start
www-data 13111  0.0  0.6 821876  6284 ?        Sl   12:39   0:00 /usr/sbin/apache2 -k start
www-data 13112  0.0  0.6 821876  6284 ?        Sl   12:39   0:00 /usr/sbin/apache2 -k start
```


Commands can also be executed from outside running containers with ```docker exec``` command:

```bash
docker ps
# output
CONTAINER ID   IMAGE      COMMAND        CREATED           STATUS           NAMES
904ccecea8b5   ubuntu     "/bin/bash"    3 minutes ago     Up 3 minutes     tender_heyrovsky
```

```bash
docker exec $CONTAINER_ID ls

bin   dev  home  lib64	mnt  proc  run	 srv  tmp  var
boot  etc  lib	 media	opt  root  sbin  sys  usr
```

```bash
docker exec $CONTAINER_ID ps aux
# output
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.3  18508  3472 ?        Ss+  12:21   0:00 /bin/bash
root      1066  0.0  0.4  73960  4472 ?        Ss   12:22   0:00 /usr/sbin/apach
www-data  1069  0.0  0.6 821876  6272 ?        Sl   12:22   0:00 /usr/sbin/apach
www-data  1070  0.0  0.6 821876  6272 ?        Sl   12:22   0:00 /usr/sbin/apach
root      1131  0.0  0.2  34400  2868 ?        Rs+  12:26   0:00 ps aux
```

The output of the ```ls``` and ```ps aux``` commands are from inside of container.

Finally, the container can be stopped and removed:

```bash
docker stop $CONTAINER_ID
docker rm $CONTAINER_ID
```

## Networking and exposing ports

Docker’s networking subsystem is pluggable, using drivers. Several drivers exist by default, and provide core networking functionality:
  * ```bridge```: the default network driver. If you don’t specify a driver, this is the type of network you are creating
  * ```host```: for standalone containers, remove network isolation between the container and the Docker host, and use the host’s networking directly.
  * ```overlay```: creates a distributed network among multiple Docker daemon hosts. This network sits on top of (overlays) the host-specific networks, allowing containers connected to it to communicate securely. Docker transparently handles routing of each packet to and from the correct Docker daemon host and the correct destination container.
  * ```macvlan```: macvlan networks allow you to assign a MAC address to a container, making it appear as a physical device on your external network
  * ```network plugins```: third-party plugins from third-party vendors


![docker networking](assets/docker_networking1.png)


By default, when you create a container, it does not publish any of its ports to the outside world. To make a port available to services outside of Docker use the ```--publish``` or ```-p``` flag. This creates a firewall rule which maps a container port to a port on the Docker host.

Let's create a container based on nginx:

```bash
docker run -d -p 7070:80 nginx:latest
```

Inside the container, nginx server listens on the default ```80``` port. As mentioned, by default that port is not exposed to outside. With ```-p 7070:80``` we exposed container port ```80``` to host machine port ```7070```. If we ```curl``` the localhost on that port we should get the nginx landing page:

```bash
curl localhost:7070
# output
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
```
If ```docker ps``` is executed, the container is running because there is a long running process in it, the nginx server. Also, the exposed port can be seen:

```bash
docker ps
# output
CONTAINER ID     IMAGE            COMMAND                  CREATED           PORTS
cdee173195a2     nginx:latest     "nginx -g 'daemon ..."   9 minutes ago     0.0.0.0:7070->80/tcp
```

## Inspect and debug

We can see the application logs from outside the container. Let's check the logs from the previously installed nginx server, we should see a ```200``` status code from ```curl```:

```bash
CONTAINER_ID=$(docker ps | awk 'FNR == 2 {print $1}')
```

```bash
docker logs $CONTAINER_ID
# output
172.17.0.1 - - [09/Jul/2018:13:40:27 +0000] "GET / HTTP/1.1" 200 612 "-" "curl/7.47.0" "-"
```

Time to see exactly how the container is configured and how it looks like:

```bash
docker inspect $CONTAINER_ID
```

A lot of information about the container configuration can be seen here: networking, mounts, image, volume paths, state, etc

## Docker volumes and mounts

By default all files created inside a container are stored on a writable container layer. This means that the data doesn’t persist when that container is no longer running, and it can be difficult to get the data out of the container if another process needs it. The data can’t easily be moved.

Docker has two options for containers to store files in the host machine, so that the files are persisted even after the container stops: ```volumes```, and ```bind mounts```.
No matter which type of mount you choose to use, the data looks the same from within the container. It is exposed as either a directory or an individual file in the container’s filesystem.

```Volumes``` are stored in a part of the host filesystem which is managed by Docker (```/var/lib/docker/volumes/``` on Linux). Non-Docker processes should not modify this part of the filesystem. Volumes are the best way to persist data in Docker. Volumes are Docker objects and can be created with ```docker volume create``` or Docker can create a volume during container provisioning.

```Bind mounts``` may be stored anywhere on the host system. They may even be important system files or directories. Non-Docker processes on the Docker host or a Docker container can modify them at any time.

```Volumes``` are the preferred mechanism for persisting data for Docker containers. While ```bind mounts``` are dependent on the directory structure of the host machine, ````volumes``` are completely managed by Docker. Volumes have several advantages over bind mounts, one being that volume drivers let the volumes to be stored on remote dedicated storage servers.

We'll create a container with a nginx server. The ```index.html``` file will be served from the host machine. This can be done with ```-v <host path>:<container path>``` option:

```bash
# the directory may already exist, ignore the warning
mkdir ~/nginx
echo "hello world" > ~/nginx/index.html
```

Now that the file is in place, we can create the container:

```bash
docker run -d -p 7071:80 -v /home/ubuntu/nginx/:/usr/share/nginx/html nginx:latest
```

Curl should show the hello world message:

```bash
curl localhost:7071
# output
hello world
```

## A word on storage drivers

A Docker image is built up from a series of layers. Each layer represents an instruction in the image’s ```Dockerfile```. Each layer is read-only.

Each layer is only a set of differences from the layer before it. The layers are stacked on top of each other. When you create a new container, you add a new writable layer on top of the underlying layers. This layer is often called the “container layer”. All changes made to the running container, such as writing new files, modifying existing files, and deleting files, are written to this thin writable container layer.

The major difference between a container and an image is the top writable layer. All writes to the container that add new or modify existing data are stored in this writable layer. When the container is deleted, the writable layer is also deleted. The underlying image remains unchanged.

Because each container has its own writable container layer, and all changes are stored in this container layer, multiple containers can share access to the same underlying image and yet have their own data state.

Docker uses ```storage drivers``` to manage the contents of the image layers and the writable container layer. Each storage driver handles the implementation differently, but all drivers use stackable image layers and the copy-on-write (CoW) strategy. Some of the popular storage drivers are: ```aufs```, ```overlay2```, ```devicemapper```.

You can check the storage driver that Docker is using right now:

```bash
docker info | grep "Storage Driver"
# output
Storage Driver: overlay2
```

## Image building, tagging and pushing to registry

Docker images are built from ```Dockerfiles```, a text file containing instructions/commands in a specific order and format. Each instruction represents is a read-only layer in the final image. After the image is built, when the container is generated and running, a new writable layer is added on top of the underlying image layers. Any modification or addition made is written on this new layer.

Let's build a nginx server container, the ```Dockerfile``` is already present in ```~/docker```:

```bash
cd ~/docker
cp ../nginx/index.html .
ls -l
# output
total 8
-rw-rw-r-- 1 ubuntu ubuntu 426 Jul  9 16:09 Dockerfile
-rw-rw-r-- 1 ubuntu ubuntu  13 Jul  9 16:10 index.html
```

Inspect the ```Dockerfile```:

```bash
cat ~/docker/Dockerfile
# output
FROM ubuntu

# Set the file maintainer (your name - the file's author)
MAINTAINER DARDELEAN

# install nginx
RUN \
  apt-get update && \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx

# Copy the index.html
COPY index.html /usr/share/nginx/html/index.html

CMD ["nginx"]

# Expose ports.
EXPOSE 80
EXPOSE 443
```

For more info on Dockerfile directives and instruction visit https://docs.docker.com/engine/reference/builder/#environment-replacement.

Build the new image, watch the process and try to explain what is happening:

```bash
docker build . -t mynginx
```

Docker knows to build the Dockerfile from the current working directory ```.```

After the building process is done, images can be listed:

```bash
docker images
# output
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
mynginx             latest              b45c62948a2e        2 minutes ago       139 MB
```

Run the container:

```bash
docker run -d -p 8080:80 mynginx
```

Now there should be output when we do curl:

```bash
curl localhost:8080
```

Now we have a container images that contains our application. It can now be tagged, meaning that we can specify, for example, that it's version 1 or latest. Tags are a way to specify useful information about an image, like an alias. It creates a reference from a source image to a target image, like assigning an existing image another name to refer to it. An image can have multiple tags and they’re usually used to specify major and minor versions.

Tag ```mynginx``` image:

```bash
docker image tag mynginx localhost:5000/mynginx:v1
```
The tagging format is:

```bash
docker image tag <source image name/ID> <repository>/<target image name>:<version>
```

Check the images:

```bash
docker images
# output
REPOSITORY               TAG                 IMAGE ID            CREATED             SIZE
localhost:5000/mynginx   v1                  b45c62948a2e        4 hours ago         139 MB
mynginx                  latest              b45c62948a2e        4 hours ago         139 MB
```

A central image repository can be created called a ```registry```. We'll create it on the current host. This is very useful when there is a large environment with many hosts. This way a user can store private images on premise. Also the image pull is faster, from hosts on the same network.

Create the registry. It's just another container, usually exposed on port 5000:

```bash
docker run -d -p 5000:5000 registry
```

Push the newly tagged ```mynginx v1``` image to the registry:

```bash
docker push localhost:5000/mynginx:v1
```

Now the image is present in a second location, the registry, which is remote if we think about it. This can be tested, we can remove the locally cached ```mynginx``` and ```localhost:5000/mynginx``` images and try to pull it back with ```docker pull localhost:5000/mynginx:v1```.

It's also easy to cleanup all the containers and images we don't need anymore:

```bash
docker stop $(docker ps -a -q)
docker rm $(docker ps -a -q)
docker rmi $(docker images -q) --force
```

# 2. Kubernetes Basics

Kubernetes is an open-source infrastructure for automating deployment, scaling, and management of containerized applications. Originally built by Google, it is currently maintained by the Cloud Native Computing Foundation.

The upstream Kubernetes version is comprised of:
  * control plane components:
    * etcd distributed key-value store
    * the API server
    * the Scheduler
    * the Controller Manager
  * worker nodes components:
    * the kubelet
    * the service proxy called kube-proxy
    * the container runtime - docker

## Canonical Distribution on Kubernetes

The official distribution of Kubernetes on Ubuntu delivers a pure 'upstream' version of Kubernetes for organisations to use privately, plus a few more features like key distribution and overlay networking.

Like Ubuntu itself, Canonical Kubernetes is free to use, and Canonical backs it up with enterprise support, consulting, and management services. Canonical makes it secure and easy to deploy, operate, and upgrade.

Canonical Kubernetes works on AWS, Google Cloud, Azure and Oracle Cloud as well as private infrastructure from bare-metal racks to VMware and OpenStack. Ubuntu is the most widely used platform for container operations, and Canonical offers the largest ecosystem of Kubernetes partners, solutions and integration options.


## 2.1 Deploy CDK

We will be using ```Juju``` to model, deploy and manage a Kubernetes cluster on Azure cloud provider.

First, install juju:

```bash
sudo apt-get -y install snapd
sudo snap install juju --channel=2.7/stable --classic
export PATH="$PATH:/snap/bin"
```

Juju uses clouds providers as backends to run workloads. Add Azure as a clouds provider by adding the necesarry credentials. A ```mycreds.yaml``` file should be present on your machine in ```/home/ubuntu``` which should be your current working directory.

```bash
juju add-credential google -f /home/ubuntu/mycreds.yaml
```

The available clouds can be listed

```bash
juju clouds
```

The current in use credentials can also be listed

```bash
juju list-credentials
```

Juju stores states in ```controllers```. Before any workload is deployed, a controller needs to be bootstrapped. It can be deployed in multiple regions, but we will deploy it to the closest one, ask the trainer for the ```location```.

```bash
juju bootstrap <location> azure-controller-$HOSTNAME --bootstrap-constraints "instance-type=Standard_B2s" \
--bootstrap-series=bionic --debug --show-log
```

After the bootstrap process is done, check its status:

```bash
juju status
# output
Model        Controller        Cloud/Region     Version  SLA          Timestamp
student-dan  azure-controller  azure/westeurope  2.6.10   unsupported  12:07:59Z
```

Workloads live inside ```models```, which is an environment associated with a controller. Create a new model for kubernetes:

```bash
juju add-model student-$HOSTNAME
```

Juju automatically switched to the new model. Models can be listed with:

```bash
juju list-models
```

The are two files in ```/home/ubuntu/bundles/``` called ```k8s-1.13_azure_bundle.yaml``` and ```k8s-azure-overlay.yaml```. The first one is the bundle that contains the Kubernetes model and all the logic. Take a look and discuss it with the trainer:

```bash
cat ~/bundles/k8s-1.13_bundle.yaml
# output
series: bionic
description: A five-machine Kubernetes cluster.
services:
  easyrsa:
    annotations:
      gui-x: '450'
      gui-y: '550'
    charm: cs:~containers/easyrsa-222
    constraints: root-disk=8G
    num_units: 1
  etcd:
    annotations:
      gui-x: '800'
      gui-y: '550'
    charm: cs:~containers/etcd-397
    constraints: root-disk=8G
    num_units: 1
    options:
      channel: 3.2/stable
  flannel:
    annotations:
      gui-x: '450'
      gui-y: '750'
    charm: cs:~containers/flannel-386
  kubeapi-load-balancer:
    annotations:
      gui-x: '450'
      gui-y: '250'
    charm: cs:~containers/kubeapi-load-balancer-583
    constraints: root-disk=8G
    expose: true
    num_units: 1
  kubernetes-master:
    annotations:
      gui-x: '800'
      gui-y: '850'
    charm: cs:~containers/kubernetes-master-604
    constraints: cores=2 mem=4G root-disk=16G
    num_units: 1
    options:
      channel: 1.13/stable
  kubernetes-worker:
    annotations:
      gui-x: '100'
      gui-y: '850'
    charm: cs:~containers/kubernetes-worker-472
    constraints: cores=4 mem=4G root-disk=16G
    expose: true
    num_units: 2
    options:
      channel: 1.13/stable
relations:
- - kubernetes-master:kube-api-endpoint
  - kubeapi-load-balancer:apiserver
- - kubernetes-master:loadbalancer
  - kubeapi-load-balancer:loadbalancer
- - kubernetes-master:kube-control
  - kubernetes-worker:kube-control
- - kubernetes-master:certificates
  - easyrsa:client
- - etcd:certificates
  - easyrsa:client
- - kubernetes-master:etcd
  - etcd:db
- - kubernetes-worker:certificates
  - easyrsa:client
- - kubernetes-worker:kube-api-endpoint
  - kubeapi-load-balancer:website
- - kubeapi-load-balancer:certificates
  - easyrsa:client
- - flannel:etcd
  - etcd:db
- - flannel:cni
  - kubernetes-master:cni
- - flannel:cni
  - kubernetes-worker:cni
```

More CDK bundles can be found on https://ubuntu.com/kubernetes/docs/install-manual


This CDK cluster composed of the following components and features:
  * Kubernetes (automated deployment, operations, and scaling)
    * Kubernetes cluster with one master and three two nodes.
    * TLS used for communication between nodes for security.
    * A CNI plugin (Flannel)
    * A load balancer for HA kubernetes-master
    * Optional Ingress Controller (on worker)
    * Optional Dashboard addon (on master) including Heapster for cluster monitoring
  * EasyRSA
    * Performs the role of a certificate authority serving self signed certificates
      to the requesting units of the cluster.
  * Etcd (distributed key value store)
    * Can be in three node cluster for reliability.



The second file, ```k8s-azure-overlay.yaml```, allows juju to use Azure specific features, such as firewalls, load balancing, block storage, object storage, etc.


Disable the Fan network, we don't need it:

```bash
juju model-config fan-config= container-networking-method=local
```

Finally, deploy the cluster from bundle:

```bash
juju deploy ~/bundles/k8s-1.13_azure_bundle.yaml --overlay ~/bundles/k8s-azure-overlay.yaml
juju trust azure-integrator
```

For more information on the charms, please visit https://jujucharms.com/canonical-kubernetes/


Track the deployment process:

```bash
watch -c juju status --color
```

After the deployment process is done, run ```juju status```, it should look like this:

```bash
juju status
# output
Model        Controller         Cloud/Region         Version  SLA          Timestamp
student-dan  azure-controller   azure/westeurope  2.5.1    unsupported  14:31:24Z

App                    Version  Status  Scale  Charm                  Store       Rev  OS      Notes
easyrsa                3.0.1    active      1  easyrsa                jujucharms   45  ubuntu
etcd                   3.2.10   active      1  etcd                   jujucharms   90  ubuntu
flannel                0.10.0   active      2  flannel                jujucharms   60  ubuntu
gcp-integrator         237.0.0  active      1  gcp-integrator         jujucharms    3  ubuntu
kubeapi-load-balancer  1.14.0   active      1  kubeapi-load-balancer  jujucharms   64  ubuntu  exposed
kubernetes-master      1.13.4   active      1  kubernetes-master      jujucharms  116  ubuntu
kubernetes-worker      1.13.4   active      1  kubernetes-worker      jujucharms  131  ubuntu  exposed

Unit                      Workload  Agent  Machine  Public address  Ports           Message
easyrsa/0*                active    idle   0        35.241.216.72                   Certificate...
etcd/0*                   active    idle   1        35.241.177.53   2379/tcp        Healthy...
gcp-integrator/0*         active    idle   2        35.240.7.189                    ready
kubeapi-load-balancer/0*  active    idle   3        35.205.73.47    443/tcp         Loadbalancer...
kubernetes-master/0*      active    idle   4        35.241.175.190  6443/tcp        Kubernetes...
  flannel/0*              active    idle            35.241.175.190                  Flannel...
kubernetes-worker/0*      active    idle   5        35.195.123.153  80/tcp,443/tcp  Kubernetes...
  flannel/1               active    idle            35.195.123.153                  Flannel...

Entity  Meter status  Message
model   amber         user verification pending

Machine  State    DNS             Inst id        Series  AZ              Message
0        started  35.241.216.72   juju-c49e7d-0  xenial  europe-west1-b  RUNNING
1        started  35.241.177.53   juju-c49e7d-1  xenial  europe-west1-c  RUNNING
2        started  35.240.7.189    juju-c49e7d-2  xenial  europe-west1-d  RUNNING
3        started  35.205.73.47    juju-c49e7d-3  xenial  europe-west1-c  RUNNING
4        started  35.241.175.190  juju-c49e7d-4  xenial  europe-west1-b  RUNNING
5        started  35.195.123.153  juju-c49e7d-5  xenial  europe-west1-d  RUNNING
```

All of this was modeled via the bundle file.
**NOTE**: on your environment the IPs will be different.


Kubernetes is now deployed.


## 2.2 Interacting with the cluster and observability

After the cluster is deployed you may assume control over the Kubernetes
cluster from any kubernetes-master or kubernetes-worker node.

```kubectl``` is the command line tool for Kubernetes. It controls the Kubernetes cluster manager.

```config``` are files used to organize information about clusters, users, namespaces, and authentication mechanisms. The ```kubectl``` command-line tool uses ```config``` files to find the information it needs to choose a cluster and communicate with the API server of a cluster. By default, the config files are created on the ```kubernetes-master``` nodes. Create the ```kubectl``` config directory and copy the ```config``` file to the default location:

```bash
mkdir -p ~/.kube

juju scp kubernetes-master/0:config ~/.kube/config
```

Multiple clusters can be managed with the help of ```config``` file. Users can switch between different clusters. For more information on this:
https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/


**Note**: A file that is used to configure access to a cluster is also sometimes called a ```kubeconfig``` file. This is just a generic way of referring to configuration files. It does not mean that there is a file named ```kubeconfig```.

Install ```kubectl``` locally:

```bash
sudo snap install kubectl --channel=1.13/stable --classic
```

For information on how to install `kubectl` on other systems, please use this link <https://kubernetes.io/docs/tasks/tools/install-kubectl/>.


Query the cluster:

```bash
kubectl cluster-info
# output
Kubernetes master is running at https://18.184.164.175:443
Heapster is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/services/...
KubeDNS is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/services/...
kubernetes-dashboard is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/...
Metrics-server is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/services/...
Grafana is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/services/...
InfluxDB is running at https://18.184.164.175:443/api/v1/namespaces/kube-system/services/...
```


The Kubernetes dashboard addon is installed by default, along with Heapster, Grafana and InfluxDB for cluster monitoring. This is one of the benefits of going with CDK. Each component is exposed via a NodePort  Service.

Kubernetes components like the sheduler or the distributed database can be checked to ensure cluster functionality:

```bash
kubectl get componentstatuses
# output
NAME                 STATUS    MESSAGE              ERROR
controller-manager   Healthy   ok
scheduler            Healthy   ok
etcd-0               Healthy   {"health": "true"}
```

In Kubernetes terminology, the workers which run the ```kubelet``` service are called ```nodes```. The cluster is modeled with two nodes, take a look:

```bash
kubectl get nodes -o wide
# output
NAME            STATUS   ROLES    AGE   VERSION   EXTERNAL-IP   OS-IMAGE            KERNEL-VERSION
juju-c49e7d-5   Ready    <none>   7m    v1.13.4    <none>        Ubuntu 18.04 LTS   4.15.0-1021-gcp
juju-c49e7d-6   Ready    <none>   29s   v1.13.4    <none>        Ubuntu 18.04 LTS   4.15.0-1021-gcp
```

Aditionally, check a specific node status, CPU and memory data, system information:

```bash
kubectl describe node juju-c49e7d-5
```

Because we have `Heapster` enabled, we can check how much resources are consumed (current resource usage) on each
node:

```bash
kubectl top nodes
# output
NAME            CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
juju-6a301d-5   138m         3%     1440Mi          9%
juju-6a301d-6   78m          1%     1194Mi          8%
```

Resource utilization per pod can also be inspected. You may get an error in the beginning, don't worry, the metrics take some
time to be collected, try again in a minute:

```bash
kubectl top pods --all-namespaces
# output
NAMESPACE                         NAME                                                      CPU(cores)
ingress-nginx-kubernetes-worker   default-http-backend-kubernetes-worker-7f7f76df64-cdhls   1m 
ingress-nginx-kubernetes-worker   nginx-ingress-controller-kubernetes-worker-86lss          10m 
ingress-nginx-kubernetes-worker   nginx-ingress-controller-kubernetes-worker-d2wxn          9m
kube-system                       heapster-v1.6.0-beta.1-58774bcb4d-gktl8                   3m 
kube-system                       kube-dns-8f7866879-k5n6f                                  4m 
kube-system                       kubernetes-dashboard-86849c89b5-gvw99                     1m
kube-system                       metrics-server-v0.3.1-54b884db75-9f6f9                    2m
kube-system                       monitoring-influxdb-grafana-v4-5866497777-gfswl           3m
```



## 2.3 Pods and namespaces

A ```pods``` is smallest deployment unit that a user can create. It is an encapsulation of one or more containers with a shared network and storage scope. The shared context of a pod is implemented with Linux namespaces, cgroups, among others, the same used for Docker containers isolation. Docker is the most commonly known runtime for containers in pods.

Containers within a pod share an IP address and a port space, of the pod. They communicate with each other inside pods using standard IPC. Containers in different pods have distinct IPs and communicate on that IP.

Using pods, applications can be designed in a highly distributed manner. Microservice architectures are common for applications that run on Kubernetes.

Pods are considerate to have ephemeral life and should be treated like cattle. Another important mention is that pods alone do not offer application high availability. For that, kubernetes has mechanism that make use of pods, but more of that later.

List the pods:

```bash
kubectl get pods -o wide --all-namespaces
```

Multiple pods can be seen, buy why? Kubernetes itself runs it's services (api server, dashboard, etc.) inside pods. Those pods run in a special namespace called ```kube-system```, a system reserved namespace. ```Namespaces``` are a way to create scopes for different projects. For example, the development team can work in their ```dev``` namespace, and the support team can work in their ```support``` namespace. The two can be considered different projects, resources are not shared and the two namespaces are isolated from each other.

By default, a ```default``` namespace is created along with the kube-system one. List all the namespaces:

```bash
kubectl get namespaces
```

## 2.4 Work with pods and volumes

Kubernetes treats everything as objects, including pods, and each object has a definition. A definition is a declaration of a desired state. Kubernetes ensures that the current state matches the desired state. For example, when you create a Pod and declare that the containers in it to be running. If the containers are not running due to an app failure, kubernetes will recreate the pod in order to drive the pod to desired state.

Take a look at this simple nginx pod definition. The definition is present in a fine in ```~/pods/simple-nginx-pods.yaml```:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.0
    ports:
    - containerPort: 80
```

Create the pod:

```bash
kubectl create -f ~/pods/simple-nginx-pods.yaml
```

List the pods and describe the newly created pod, try to understand what is in there and talk with the trainer on the bits that you do not understand:

```bash
kubectl get pods -o wide

kubectl describe pod nginx
```

Delete the pod:

```bash
kubectl delete pod nginx
```

That's good for a simple web server, but what persistent storage is needed? The container file system only lives as long as the container does. Volumes should be used for any persistent storage needs.


There are many volume types available, with some being cloud platform specific (e.g. ```azureDisk```, ```gcePersistentDisk```, ```azureDisk```, ```awsElasticBlockStore```). The standard types include:

```EmptyDir```: is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node.  It is initially empty and is stored on whatever medium is backing the node - that might be disk or HDD/SSD or network storage, depending on your environment.

```HostPath```: Mounts an existing directory on the node’s file system. For example ```/var/logs```.


Here is an example of how volumes will look like in a pod definition:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: redis-storage
      mountPath: /data/redis
  volumes:
  - name: redis-storage
    emptyDir: {}
```

Create the pod with and run the ```describe pod``` command on it afterwards to see the volumes attached. Delete the pod once done.

```bash
kubectl create -f ~/pods/redis-volume.yaml

kubectl describe pod redis
```

Multiple containers can also exist in open pod. Take a look at this example:

```bash
cat ~/pods/multiple-containers.yaml
```

There are two containers, `nginx` and `git-monitor`. The first one is a web server and the second one polls a git repository for new updates.

Finally, delete the pod:

```bash
kubectl delete pod redis
```


# 3. Networking

## 3.1 Exposing apps using Services and Labels

The pods/apps we've created so far were not accessible. Kubernetes does not follow the legacy networking architecture because of a number of reasons:

  * pods are ephemeral
  * Kubernetes itselt asigns IPs to pods after they are scheduled -> the user cannot asign or know the IP beforehand
  * scaling and load-balancing: users should not care how many pods are backing a service, what their IPs are, on which nodes the pods are scheduled

To solve these issues, Kubernetes provides the ```Service``` object resource type.

A ```Service``` is a single point of access to a group of pods that provide the same type of service. Each service has an IP and a port that will never change during the lifetime of the service. Users will initiate connections to the IP and port, and those connections are routed to one of the pods backing the service. This way, users don't have to care about pod location and if a pods crashes.

![service](assets/service.png)


There are three types of Services:
  * ```ClusterIPs```: the purpose of this type of service is exposing groups of pods to other pods in the cluster
  * ```NodePort```: allocates a static port on the Node on which the pod is running. Used to access Pod port from outside the cluster
  * ```LoadBalancer```: exposes the service externally using a cloud provider’s load balancer. Used to access Pod's from outside the cluster

```Labels``` and ```Selectors``` help in asociating Services to Pods. ```Labels``` are key-value pairs that can be asociated with pods in the pod denifiniton. Then, a Service will use label ```Selectors``` to know to which pods to redirect traffic to.


For example, given some pods running an app, we would specify in the pod definition of the app we specify a label ```app: nginx``` and we scale the pods to 3. Then a service can be create with Selector ```app: nginx```. This is how Services know where to route traffic and load-balance between the 3 pods.

![labels and selectors](assets/labels_selectors.png)

Let's take a look at the existing services:

```bash
kubectl get svc -o wide --all-namespaces
# output
NAMESPACE     NAME                   TYPE       CLUSTER-IP       EXT-IP  PORT(S) 
default       default-http-backend   ClusterIP  10.152.183.73    <none>  80/TCP 
default       kubernetes             ClusterIP  10.152.183.1     <none>  443/TCP 
kube-system   heapster               ClusterIP  10.152.183.187   <none>  80/TCP
kube-system   kube-dns               ClusterIP  10.152.183.228   <none>  53/UDP,53/TCP
kube-system   kubernetes-dashboard   ClusterIP  10.152.183.186   <none>  443/TCP
kube-system   metrics-server         ClusterIP  10.152.183.112   <none>  443/TCP
kube-system   monitoring-grafana     ClusterIP  10.152.183.134   <none>  80/TCP 
kube-system   monitoring-influxdb    ClusterIP  10.152.183.229   <none>  8083/TCP,8086/TCP
```

Here we can see all the Services within the cluster. Control plane Kubernetes Pods talk to each other via the ```ClusterIPs```. None of the Pods are externally exposed with a Service. In the ```Selector``` field can be seen the association between a Service and Pods. The ```ClusterIPs``` are internal, virtual IPs that only Kubernetes has knowledge of.

**NOTE**: The same Selector mechanism is used for other objects (resources) offered by Kubernetes. Other Kubernetes objects (Deployment, ReplicaSets, etc,) which interact with Pods use the same mechanism.

Ok, let's redeploy `nginx` and use a label. Check the ```~/pods/simple-nginx-pods.yaml``` pod definition to see the label:

```bash
vim ~/pods/simple-nginx-pods.yaml
...
labels:
  app: nginx
...
```

```bash
cat ~/pods/simple-nginx-pods.yaml
# output
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.14.0
    ports:
    - containerPort: 80
```

```bash
kubectl create -f ~/pods/simple-nginx-pods.yaml
```

Now it's time to create the Service. The Service definition file should be found under ```~/pods/simple-nginx-service.yaml```. Let's examine the contents and create the Service:

```bash
cat ~/pods/simple-nginx-service.yaml
# output
apiVersion: v1
kind: Service
metadata:
  name: nginx
spec:
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: nginx
```

```bash
kubectl create -f ~/pods/simple-nginx-service.yaml
```

The service should now be visible:

```bash
kubectl get svc -o wide
# output
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE       SELECTOR
nginx                  ClusterIP   10.152.183.197   <none>        8080/TCP    20s       app=nginx
```

Currently, the app can now be accessed from within the cluster, but not from outside of the cluster.

Actually, there are two ways to probe the web app, but both of them are just for demonstration purposes. In production environments direct access to the apps is desired, we do not have that yet. This is just for demonstration purposes and to understand the architecture.

One of the rules of Kubernetes networking is: all nodes can communicate with all containers without NAT. This means that if we ```ssh``` in one of the Nodes, we should be able to ```curl``` the web app. For this two things are needed, the ```ClusterIP``` of the app and the port on which the app is listening, both of which we can extract from the previous ```kubectl get svc -o wide```command. We need to log in one of the Nodes , doesn't matter which one, both of our Nodes can reach the Pod. List the nodes:

```bash
juju status
# output
...
kubernetes-worker/0       active    idle   5        18.197.13.138   80/tcp,443/tcp  Kubernetes...
  flannel/2               active    idle            18.197.13.138                   Flannel...
kubernetes-worker/1*      active    idle   6        18.197.32.94    80/tcp,443/tcp  Kubernetes...
  flannel/1               active    idle            18.197.32.94                    Flannel...
kubernetes-worker/2       active    idle   7        18.184.64.91    80/tcp,443/tcp  Kubernetes...
  flannel/3               active    idle            18.184.64.91                    Flannel...
```

Node ```5``` should do it:

```bash
juju ssh 5

curl 10.152.183.197:8080
Welcome to nginx!
```

Go back to the student machine:

```bash
exit
```


## 3.2 Service discovery

Another rule of Kubernetes networking is: all containers can communicate with all the other containers without NAT. This means that the web app can be probed from another pod with a ```ClusterIP``` associated with it. But for this we won't be using the ```ClusterIP```, but the DNS record of the Service.

Pods need to talk to each other. Kubernetes has multiple mechanisms to do this. One of them is to set the ```ClusterIPs``` as environment variables inside the pods. In this way, when some frontend component needs to talk to the backend, for example, the IP and port can be referenced from the environment variable. In the nginx example, it would look like this ```NGINX_SERVICE_HOST=10.152.183.197``` and ```NGINX_SERVICE_PORT=8080```. This is not the best approach, however. If you add a new Service, it will not be automatically be set on already running pods.

Another method is to have a DNS server in a Pod. CDK comes with this feature by default. All the pods in the cluster are automatically configured to uset the DNS server (```/etc/resolv.conf``` file). In this way, any query performed by a process within a Pod will be handled by Kubernetes' own DNS server, which is accessible from the whole cluster.

Alongside the previous nginx pod and service, we'll create another pod and do a ```curl``` on the nginx record from there. Commands can be ran directly inside a pod by using ```kubectl exec```. You can also lunch an interactive bash shell inside a pod (granted if the base container has the bash installed).

The pod can be created without a pods definition file:

```bash
kubectl run shell --generator=run-pod/v1 -i --tty --image ubuntu -- /bin/bash

# exit pod
root@shell:/# exit
```

After which we can reconnect to the pod:

```bash
kubectl exec -it shell -- /bin/bash

root@shell:/# apt update

root@shell:/# apt install curl -y

root@shell:/# curl nginx:8080
Welcome to nginx!

# go back to the student machine
root@shell:/# exit
```

Here ```nginx``` is the name of the Service:

```bash
kubectl get svc -o wide
# output
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE       SELECTOR
nginx                  ClusterIP   10.152.183.197   <none>        8080/TCP    20s       app=nginx
```



## 3.3 NodePort and LoadBalancer Services

Until now we made the web app available only inside the cluster. There are a couple of ways to allow outside access.

```NodePorts``` are one way to do it. Kubernetes will open a port on all Nodes. That port is accessible via the Nodes IP address.

![nodeport](assets/nodeport.png)

This is a ```NodePort``` Service definition for nginx app:

```bash
cat ~/pods/nodeport-service.yaml
# output
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
spec:
  type: NodePort
  ports:
  - port: 8080
    targetPort: 80
    nodePort: 30111
  selector:
    app: nginx
```

```bash
kubectl create -f ~/pods/nodeport-service.yaml
```

```nodePort: 30111``` is of utmost importance here. The connection would look like this ```<NodeIP>:<30111>```:

```bash
curl 18.197.13.138:30111
# output
Welcome to nginx!
```

```18.197.13.138``` is the public IP of the first Node ```kubernetes-worker/0```, get your IP by running ```juju status``` command.

**NOTE**: This required that port ```30111``` is opened on the Node. In this situation the Node is an Azure instance, so this is implemented at the security group level of the instance.


```LoadBalancer``` is another type of Service allowing connections from outside. Kubernetes clusters usually run on top of Cloud providers like AWS, Azure and GCP. Clusters and Cloud providers know how to interact with each other. The Cloud provider will associate a public IP with the app.

![loadbalancer](assets/loadbalancer2.png)

**NOTE** the IPs and ports from the diagram differ from the exercise ones.


Create a ```LoadBalancer``` IP and associate it with the nginx app:

```bash
cat ~/pods/loadbalancer-service.yaml
# output
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
spec:
  type: LoadBalancer
  ports:
  - port: 8080
    targetPort: 80
  selector:
    app: nginx
```

```bash
kubectl create -f ~/pods/loadbalancer-service.yaml
```

It will take a couple of seconds for the cloud provider to allocate a Load Balancer. The easiest
way to see the status is to run a `watch` command:

```bash
watch kubectl get svc
```


Take a look at services:

```bash
kubectl get svc
# output
NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
default-http-backend   ClusterIP      10.152.183.130   <none>        80/TCP           1h
kubernetes             ClusterIP      10.152.183.1     <none>        443/TCP          1h
nginx                  ClusterIP      10.152.183.233   <none>        8080/TCP         11m
nginx-loadbalancer     LoadBalancer   10.152.183.132   35.187.18.3   8080:31362/TCP   1m
nginx-nodeport         NodePort       10.152.183.222   <none>        8080:30111/TCP   8m
```

```35.187.18.3:8080``` is public and can be accessed from anywhere. Try to access it from your browser.


Cleanup the resources created so far:

```bash
# run 'kubectl get svc' to get the services
kubectl delete svc nginx nginx-loadbalancer nginx-nodeport

# run 'kubectl get pods' to get the pods
kubectl delete pod nginx shell
```

## 3.4 Ingress controllers

Ingress resources are DNS mappings to your containers, routed through endpoints. They can manage external access to the services in a cluster, providing load balancing, name-based virtual hosting and SSL termination.


![ingress](assets/ingress2.png)

CDK comes by default with an NGINX Ingress Controller. This is the case because of the `juju config kubernetes-worker ingress=true
` option set in the worker charm. Ingress allows access from the Internet to containers running web services inside the cluster.


Check the Ingress pods:

```bash
kubectl get pods -n ingress-nginx-kubernetes-worker
# output
NAME                                                      READY   STATUS    RESTARTS   AGE
default-http-backend-kubernetes-worker-7f7f76df64-fkwn7   1/1     Running   0          85m
nginx-ingress-controller-kubernetes-worker-zfrgm          1/1     Running   0          85m
```

Let's imagine we have a web application with two microservices, red and blue. The microservices are just displaying some text, but from a design perspective, a real world application would work just the same.

Check the blue microservice definition:

```bash
cat ~/pods/blue-app.yml
```

The red microservice looks the same but instead of blue, it displays red.

Also, check the Ingress Controller definition:

```bash
cat ~/pods/ingress.yml
```

Create the objects:

```bash
kubectl create -f ~/pods/blue-app.yml
kubectl create -f ~/pods/red-app.yml
kubectl create -f ~/pods/ingress.yml
```

The Ingress Controller is created:

```bash
kubectl get ingress
# output 
NAME              HOSTS   ADDRESS         PORTS   AGE
example-ingress   *       104.199.31.11   80      62s
```

```104.199.31.11``` is the Azure provided public IP for this Ingress. Open your browser and navigate to ```104.199.31.11/blue``` and ```104.199.31.11/red``` 
**NOTE**: your public IP will be different

After everything is tested, remove the Ingress and pods.

```bash
kubectl delete -f ~/pods/blue-app.yml
kubectl delete -f ~/pods/red-app.yml
kubectl delete -f ~/pods/ingress.yml
```

For more Ingress related information regarding CDK, visit here https://ubuntu.com/kubernetes/docs/operations


# 4. Keeping apps healthy

## 4.1 ReplicaSets

A ```ReplicaSet``` enables us to achieve high availability by ensuring that a specified number of pod replicas are running at any one time. In other words, a
```ReplicaSet``` makes sure that a pod or a homogeneous set of pods is always up and available.

If there are too many pods, the ```ReplicaSet``` terminates the additional pods. If there are too few, the ```ReplicaSet``` starts more pods. Unlike manually created pods, the pods maintained by a ```ReplicaSet``` are automatically replaced if they fail, are deleted, or are terminated.

```ReplicaSet``` is often abbreviated to ```rs``` as a shortcut in ```kubectl``` commands.

**NOTE**: ```ReplicaSet``` is the next-generation ```ReplicationController```. The only difference between a ```ReplicaSet``` and a ```ReplicationController``` right now is the selector support.

Now we'll create a ```ReplicaSet``` with this definition:

```bash
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.0
        ports:
        - containerPort: 80
```

The 3 most important things here are:
  * replica count: which specifies the desired number of pods that should be running
  * label selector: which determines what pods are in the ReplicaSets’s scope
  * pod template: which is used when creating new pod replicas

Create the ```rs```:

```bash
kubectl create -f ~/pods/nginx-rs.yaml
```

Inspect the ```rs```:

```bash
kubectl get rs -o wide
# output
NAME       DESIRED   CURRENT   READY     AGE       CONTAINERS   IMAGES         SELECTOR
nginx-rs   3         3         3         4m        nginx        nginx:1.14.0   app=nginx
```

```bash
kubectl describe rs nginx-rs
# output
Name:         nginx-rs
Namespace:    default
Selector:     app=nginx
Labels:       app=nginx
Annotations:  <none>
Replicas:     3 current / 3 desired
Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:1.14.0
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Events:
  Type    Reason            Age   From                   Message
  ----    ------            ----  ----                   -------
  Normal  SuccessfulCreate  40s   replicaset-controller  Created pod: nginx-rs-j4btv
  Normal  SuccessfulCreate  40s   replicaset-controller  Created pod: nginx-rs-lcdsf
  Normal  SuccessfulCreate  40s   replicaset-controller  Created pod: nginx-rs-cxvb2

kubectl get pods
# output
NAME                                               READY     STATUS    RESTARTS   AGE
...
nginx-rs-cxvb2                                     1/1       Running   0          23s
nginx-rs-j4btv                                     1/1       Running   0          23s
nginx-rs-lcdsf                                     1/1       Running   0          23s
```

Now the application is highly available. They now need a Service to be accessed. We can recreate any type of Service that we have used before. This is possible because of the Labels and Selectors. The newly create pods have the ```app=nginx``` label and the Services we create before point to that label.

Recreate the ```LoadBalancer``` service:

```bash
kubectl create -f ~/pods/loadbalancer-service.yaml
```

The website should be available after a few minutes. Run the ```kubectl get svc``` command to get the DNS record and access it:

```bash
curl 35.241.192.204:8080
#output
Welcome to nginx!
```

The traffing will now be load balanced between the 3 pods.

You can try to delete a Pod to see what happens. A new Pod should take its place in a few seconds.

```bash
kubectl delete pod nginx-rs-lcdsf
```

```
kubectl get pods
# output
NAME                                               READY     STATUS    RESTARTS   AGE
...
nginx-rs-cxvb2                                     1/1       Running   0          23s
nginx-rs-j4btv                                     1/1       Running   0          23s
nginx-rs-duicv                                     1/1       Running   0          1s
```

Delete the ```rs``` and the Service:

```bash
kubectl delete rs nginx-rs

kubectl delete svc nginx-loadbalancer
```

## 4.2 Deployments

All the functionality we have worked with so far can already cover a wide variety of app deployment usecases, but there is more Kubernetes can do. It can also provide a clan way for applications that run in pods to be upgraded from version to version, with NO downtime. This is provided through declarative updates for Pods and ReplicaSets.

Kubernetes provides the ```Deployment``` resource that sits on top of ```ReplicaSets```, a declarative way to update Pods. You describe a desired state in a Deployment object, and the Deployment controller changes the actual state to the desired state at a controlled rate.

![deployment](assets/deployment.png)


Let's take a look on how a Deployment definition looks like:

```bash
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deploy
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.0
        ports:
        - containerPort: 80
```

Again, like in the case of ```ReplicaSets```, the most important things are:
  * replica count: which specifies the desired number of pods that should be running
  * label selector: which determines what pods are in the ReplicaSets’s scope
  * pod template: which is used when creating new pod replicas


Create the Deployment:

```bash
kubectl create -f ~/pods/nginx-deploy.yaml
```

Inspect what was creates:

```bash
kubectl get deploy -o wide
# output
NAME           DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE       CONTAINERS   IMAGES
nginx-deploy   3         3         3            3           49s       nginx        nginx:1.14.0
```

```bash
kubectl describe deploy nginx-deploy
# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Mon, 16 Jul 2018 13:55:00 +0000
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision=1
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:1.14.0
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deploy-6cb5f7bf4f (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  1m    deployment-controller  Scaled up replica set...
```

```bash
kubectl get pods
# output
NAME                                               READY     STATUS    RESTARTS   AGE
nginx-deploy-6cb5f7bf4f-l46gn                      1/1       Running   0          1m
nginx-deploy-6cb5f7bf4f-lxmpg                      1/1       Running   0          1m
nginx-deploy-6cb5f7bf4f-v766c                      1/1       Running   0          1m
...
```

So far everything looks similar to the  ```ReplicaSets``` case. The addition lies in how easely upgrades can be made. First, check the rollout status. Initially, it should only tell that the deployment was created:

```bash
kubectl rollout status deploy nginx-deploy
# output
deployment "nginx-deploy" successfully rolled out
```
A Deployment ```rollout``` is a mechanism which allows performing application rolling upgrades. The rollout is triggered if and only if the Deployment pod template is changed, for example if the image version is changed.

![deployment](assets/rolling_upgrade.png)

Suppose that we now want to update the nginx Pods to use the ```nginx:1.15.0``` image instead of the ```nginx:1.14.0``` image:

```bash
kubectl set image deploy nginx-deploy nginx=nginx:1.15.0
# output
deployment.extensions/nginx-deploy image updated
```
**NOTE**: Alternatively, the Deployment definition can be changed with ```kubectl edit deploy nginx-deploy``` in an interactive manner. This stands true for all Kubernetes resource types.

Check Deployment status:

```bash
kubectl rollout status deploy nginx-deploy
# output
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deploy" successfully rolled out

```

```bash
kubectl get deploy
```

```bash
kubectl get pods
# output
NAME                                               READY     STATUS    RESTARTS   AGE
nginx-deploy-5db8bc9444-7s2mk                      1/1       Running   0          6m
nginx-deploy-5db8bc9444-q596k                      1/1       Running   0          7m
nginx-deploy-5db8bc9444-xktk7                      1/1       Running   0          6m
...
```

```bash
kubectl describe deploy nginx-deploy
# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Mon, 16 Jul 2018 13:55:00 +0000
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision=2
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:1.15.0
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deploy-5db8bc9444 (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  14m   deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet  5m    deployment-controller  Scaled down replica set...
```

As can be seen everything is up-to-date and running. The image in use is ```nginx:1.15.0```. The scaling process can also be viewed on the deployment description ```Events``` section.

The same Services can be asociated with the pods, same as before.

It's important to mention that there are two strategies for upgrading apps with Deployments:
  * ```recreate``` strategy: old pods are deleted before new ones are created
  * ```RollingUpdate``` strategy: replace pods step by step

The default one is ```RollingUpdate```, the one we used in our case. This works if the application supports two versions of it running at the same time, for a brief period. The major advantage of this strategy is that there is no downtime. With the ```recreate``` strategy there is a downtime brief period between when then the last old version pod was deleted and the first new version pod comes up.

But let's say there is an issue with the current application version that was rolledout. Another powerful feature of ```Deployments``` is that they can be rolled back to a previous revision if there are any issues.

Check and inspect the revision history:

```bash
kubectl rollout history deploy nginx-deploy
# output
deployments "nginx-deploy"
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

```

```bash
# this command does not do anything, it just inspects the revision
kubectl rollout history deploy nginx-deploy --revision=1
# output
deployments "nginx-deploy" with revision #1
Pod Template:
  Labels:	app=nginx
	pod-template-hash=2761936909
  Containers:
   nginx:
    Image:	nginx:1.14.0
    Port:	80/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
```

```bash
# this command does not do anything, it just inspects the revision
kubectl rollout history deploy nginx-deploy --revision=2
# output
deployments "nginx-deploy" with revision #2
Pod Template:
  Labels:	app=nginx
	pod-template-hash=1864675000
  Containers:
   nginx:
    Image:	nginx:1.15.0
    Port:	80/TCP
    Host Port:	0/TCP
    Environment:	<none>
    Mounts:	<none>
  Volumes:	<none>
```

Revision ```1``` is the initial deployment version. Revision ```2``` is the upgraded version.

Rollback to the initial state:

```bash
kubectl rollout undo deploy nginx-deploy --to-revision=1
# output
deployment.extensions/nginx-deploy
```

Check how the Deployment looks like, it should have ```nginx:1.14.0```, the old version:

```bash
kubectl describe deploy nginx-deploy
# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Mon, 16 Jul 2018 13:55:00 +0000
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision=3
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:1.14.0
    Port:         80/TCP
    Host Port:    0/TCP
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  <none>
NewReplicaSet:   nginx-deploy-6cb5f7bf4f (3/3 replicas created)
Events:
  Type    Reason              Age   From                   Message
  ----    ------              ----  ----                   -------
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet   44m   deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled up replica set...
  Normal  DeploymentRollback  1m    deployment-controller  Rolled back deployment...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled up replica set...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled down replica set...
  Normal  ScalingReplicaSet   1m    deployment-controller  Scaled down replica set...
```

If we check for ```ReplicaSets```, we can see the ```rs``` that backs the ```Deployment```:

```bash
kubectl get rs
# output
NAME                      DESIRED   CURRENT   READY     AGE
nginx-deploy-6cb5f7bf4f   3         3         3         1h
```

Concluding this chapter, we'll need to cleanup the whole deployment:

```bash
kubectl delete deploy nginx-deploy
```


# 6. Storage and User Data

Applications can write and read data directly on and from the container filesystem. This approach can have many drawbacks, one is when two container of the same pod need to access the same piece of data. Also, Kubernetes works on pod level, so something new had to be done to address this.

## 6.1 Volumes

```Volumes``` are a Kubernetes resource type that solves this. A Volume can be shared between containers of the same pod. There are different types of volumes, some are ephemeral, meaning that they live as long as the pods do, and some are persistent on pod deletion.

There are many volume types, but some of the most used are:
  * ```emptyDir```: exists as long as that pod does, it is initially empty. By default, emptyDir volumes are stored on whatever medium is backing the node - that might be disk or SSD or network storage, depending on your environment. Priviledged containers are required for this type of volume.
  * ```hostPath```: mounts a directory from the host Node's filesystem. Useful in some situations: e.g. containers need to accesss Docker internals or host’s ```/sys``` special filesystem
  * ```awsElasticBlockStore```: AWS cloud specific type of volume, creates and mounts a AWS EBS volume in the pod
  * ```azureDisk```: Azure cloud specific type of volume, used to mount Azure Data Disks into pods
  * ```gcePersistentDisk```: Azure cloud specific type of volume, mounts a GCE Persistent Disk into pods
  * ```nfs```: mounts NFS shared into pods
  * ```iscsi```: mounts iSCSI volumes into pods

Let's create a Pod with two running containers and a shared ```emptyDir``` volume. This is how the pod definition looks like:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
  labels:
    app: two-containers
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: nginx-container
    image: nginx:1.14.0
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: debian-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html; sleep 900000"]
```

The volume is called ```shared-data```. Containers reference the volume by name in the ```volumeMounts``` of the container template. ```mountPath``` is from where the volume is accessible from inside the container. As you can see, the first container sees the html file in ```/usr/share/nginx/html/index.html``` and the second container in  ```/pod-data/index.html```, but it's the same file. Try to understand the definition file, discuss any interesting details with the trainer.


Create the pod and a service for it, the definition files are already provisioned in ```~/pods/multiple-containers.yaml``` and ```~/pods/pod-with-volume-service.yaml```:

```bash
kubectl create -f ~/pods/multiple-containers.yaml
```

```bash
kubectl create -f ~/pods/pod-with-volume-service.yaml
```
Get the ClusterIP, connect to a Node and ```curl``` from there:

```bash
kubectl get svc
# output
NAME                   TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
...
two-containers-svc     ClusterIP   10.152.183.125   <none>        8080/TCP   20s
```

```bash
juju ssh 5
```
```bash
ubuntu@node:~$ curl 10.152.183.125:8080
# output
Hello from the debian container
```
As you can see the two containers work together in this scenario with the help of the volume. This is a simple example, but complex scenarios can be built on the presented concepts.

Go back to the student node and delete the pods:

```bash
# exit back to student node
exit

#on student machine
kubectl delete svc two-containers-svc
kubectl delete pod two-containers
```

## 6.2 ConfigMaps

```ConfigMaps``` allow developers to decouple configuration options from the app source coude or container image. ```ConfigMaps``` consist of key/value pairs and can be created in 3 ways:
  * from directories
  * from files
  * from literal values

Create a ```ConfigMap``` with literal values:

```bash
kubectl create configmap test-configmap --from-literal=val1=dan \
--from-literal=val2=bill --from-literal=val3=ben
```

Inspect the ```ConfigMap```:

```bash
kubectl describe configmap test-configmap
# output
Name:         test-configmap
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
val1:
----
dan
val2:
----
bill
val3:
----
ben
Events:  <none>
```


Create a Pod that references the ```ConfigMap```

```bash
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
  - name: pod-with-configmap
    image: alpine
    command: ["sleep", "999999"]
    envFrom:
    - prefix: CONFIG_DATA_
      configMapRef:
        name: test-configmap
```

```bash
kubectl create -f ~/pods/pod-with-configmap.yaml
```

Check if the Pod sees the values:

```bash
kubectl exec configmap-pod -- env
# output
...
HOSTNAME=configmap-pod
CONFIG_DATA_val1=dan
CONFIG_DATA_val2=bill
CONFIG_DATA_val3=ben
...
```

Delete the pod:

```bash
kubectl delete pod configmap-pod
```

## 6.3 Secrets

```Secrets``` are a way to securely inject sensitive data into Pods. By sensitive data is meant: credentials, encryption keys, tokens, etc. The data is represented as key-values pairs and are encoded in base64.

There are two ways to create secrets, from CLI using ```kubectl``` or from a file definition, we'll use the CLI method:

```bash
kubectl create secret generic bob-secret --from-literal=username='bob' \
--from-literal=password='Passw0rd'
```
**NOTE**: If the CLI method is used, the values will automatically be encoded for the user. If the file definition is used, the user will have to input the already encoded values in the definition.

Observe the secret and node the encoded value:

```bash
kubectl get secret bob-secret
```

```bash
kubectl describe secret bob-secret
```

```bash
kubectl get secret bob-secret -o yaml
```


Now create a pod that has access to the ```Secret``` via environment variables. Here is the pod definition:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-secrets
spec:
  containers:
  - name: container-with-secrets
    image: nginx
    env:
    - name: SECRET_USERNAME
      valueFrom:
        secretKeyRef:
          name: bob-secret
          key: username
    - name: SECRET_PASSWORD
      valueFrom:
        secretKeyRef:
          name: bob-secret
          key: password
```

Create the pod:

```bash
kubectl create -f ~/pods/pod-with-secrets.yaml
```

Wait for the pod to come up. Connect to it afterwards and see if the secrets were passed:

```bash
kubectl exec -it pod-with-secrets -- /bin/bash
```

```bash
root@pod-with-secrets:/# printenv | grep SECRET
# output
SECRET_PASSWORD=Passw0rd
SECRET_USERNAME=bob
```

Now, a database, for example, can directly reference the environment variables for credentials.

Exit the pod and delete the resources you've created:

```bash
root@pod-with-secrets:/# exit
...
kubectl delete pod pod-with-secrets
kubectl delete secret bob-secret
```

## 6.4 PersistentVolumes, PersistentVolumeClaims and StorageClasses

This works great but volume types such as ```emptyDir``` and ```hostPath``` have the drawback that developers need to have knowledge of the storage and network infrastructure. Storage should be provisioned in a transparent manner and fully abstracted of the backend solution.

```PersistentVolumes```, ```PersistentVolumeClaims``` and ```StorageClasses``` can be used. A storage backend is represented by the ```StorageClass```. It dynamically provisions ```PVs``` with the help of ```PVCs```.

**NOTE**: PersistentVolumes will be referenced with ```PVs```, ```PersistentVolumeClaims``` with ```PVCs``` and ```StorageClasses``` with ```SCs```.

```PVs``` are like volumes, but it's lifecycle does not depend on the pods lifecycle. A user or pod can request a ```PV``` with a ```PVC```.

![roles](assets/pvc.png)

We are running on GCE so we'll create a ```SC``` for it. Administrators can also create ```PVs``` statically, meaning that the PVs will pe pre-provisoned. This is bad because it's not automated, and may require manual intervention later on. ```SCs``` are allow for ```PVs``` to be provisioned dynamically:

```bash
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: gce
provisioner: kubernetes.io/gce-pd
parameters:
  type: pd-standard
  replication-type: none
```

For more info on storage classes please visit https://kubernetes.io/docs/concepts/storage/storage-classes/.

Create the StorageClass:

```bash
kubectl create -f ~/pods/gce-sc.yaml
```

```bash
kubectl get sc
# output
NAME   PROVISIONER            AGE
gce    kubernetes.io/gce-pd   8s
```

```bash
kubectl describe sc gce
# output
Name:                  gce
IsDefaultClass:        No
Annotations:           <none>
Provisioner:           kubernetes.io/gce-pd
Parameters:            replication-type=none,type=pd-standard
AllowVolumeExpansion:  <unset>
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     Immediate
Events:                <none>
```

Make the ```gce``` SC the default one:

```bash
kubectl patch storageclass gce -p \
'{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
```

Great now we can dynamically allocate volumes for containers, the way workflows are intended to be.

Create a ```PVC``` using the ```SC```:

```bash
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gce-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 100Mi
  storageClassName: gce
```

Notice the reference to gce ```SC``` via ```storageClassName: gce```. ```PVCs``` are the way to bind to ```PVs```. Create the ```PVC```:

```bash
kubectl create -f ~/pods/gce-pvc.yaml
```
```bash
kubectl get pvc
# output
NAME      STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
gce-pvc   Bound    pvc-6074abf5-d079-11e8-a2bc-42010a840008   1Gi        RWO            gce
```

```bash
kubectl describe pvc gce-pvc
# output
Name:          gce-pvc
Namespace:     default
StorageClass:  gce
Status:        Bound
Volume:        pvc-6074abf5-d079-11e8-a2bc-42010a840008
Labels:        <none>
Annotations:   pv.kubernetes.io/bind-completed: yes
               pv.kubernetes.io/bound-by-controller: yes
               volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/gce-pd
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:      1Gi
Access Modes:  RWO
Events:
  Type       Reason                 Age   From                         Message
  ----       ------                 ----  ----                         -------
  Normal     ProvisioningSucceeded  72s   persistentvolume-controller  Successfully provisioned...
Mounted By:  <none>
```

This volume can actually be seen from GCE console.

Create a pod that will make use of the new ```PV```:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
    - image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
      name: busybox
      volumeMounts:
        - mountPath: "/pv"
          name: testvolume
  restartPolicy: Always
  volumes:
    - name: testvolume
      persistentVolumeClaim:
        claimName: gce-pvc
```

```bash
kubectl create -f ~/pods/busybox-with-pv.yaml
```

Check inside the pod to see if the volume was mounted:

```bash
kubectl exec busybox -- mount | grep pv
# output
/dev/sdb on /pv type ext4 (rw,relatime,data=ordered)
```

If the new device shows up, we have successfully configured and provisioned an GCE-backed PV.

Dynamically allocated PVs is the most flexible and reliable way to allocate storage for applications running in Kubernetes. Cleanup the pods we've created in this chapter:

```bash
kubectl delete pod busybox
kubectl delete pvc gce-pvc
```


# 7. Autoscaling

Kubernetes can autoscale your application based on load. Numeric based resources like ```CPU``` and ```Memory``` can be used for this. For example, when the CPU reaches a certain threshold, the application can be scaled without human interaction, in an automated manner.

```cAdvisor``` and ```Heapster``` are the Kubernetes resources that collect the metrics needed for this operation. ```cAdvisor``` runnes as a DaemonSet on every Node collectiog the metrics and then ```Heapster``` collects them.

The ```Horizontal Pod Autoscaler``` is the Kubernetes object that scales a Deployment or ReplicaSet. It is a control loop that periodically checks pod metrics from ```Heapster```, calculates the number of replicas required to meet the target metric value configured by the user in the ```HPA``` resource, and updates the ```REPLICAS``` field in the target Deployment resource.

So the autoscaling process works in 3 steps:
  * collect metrics from all the pods managed by the resource object (deployment, replicaSet) : via ```cAdvisor``` and ```Heapster```
  * calculate the number of pods needed to match the specified target value
  * update the replicas field in the resource object


## 7.1 Autoscale a Deployment resource

Create an nginx deployment, this will be the scaled application:

```bash
kubectl run nginx-hpa --image=nginx --requests=cpu=100m --expose --port=80
```

Create a ```HPA``` that will autoscale when the pod ```CPU``` load reaches 30%, but keep the pods between 1 pod minimum and 5 pods at max. In this case the pod replicas will not exeed 5 even if the ```CPU``` is above 30%:

```bash
kubectl autoscale deployment nginx-hpa --cpu-percent=30 --min=1 --max=5
```

Run a load generator that will do ```wget``` continuously on the nginx app:

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
```

```bash
# inside loadgenerator container
while true; do wget -q -O- http://nginx-hpa; done
```

Open a new tab and log in the public machine again. Do a watch getting the ```HPA``` status. Wait a minute or two for the load to increase:

```bash
watch kubectl get hpa
NAME        REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   36%/30%   1         5         2          4m
```

Because the CPU utilization went over 30%, it's 36% now, a new replica was added and there are 2 now. Please note that in your case the load can be higher, and the replica count can be higher.

A new nginx pod was added and the app was autoscaled:

```bash
kubectl get pods
# output
NAME                                               READY   STATUS    RESTARTS   AGE
nginx-hpa-6c9c95f84c-2tlpf                         1/1     Running   0          4m
nginx-hpa-6c9c95f84c-c5xcg                         1/1     Running   0          2m
...
```

If you go back on the first tab and stop the ```wget``` command, the CPU utilization will drop below 30% and the ```REPLICAS``` field will be set to 1. The scale down operation is performed every five mines, so you may not see this right away.

```bash
kubectl get hpa
NAME        REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   0%/30%    1         5         1          43m
```

Inspect the ```HPA``` for a minute, if you find something interesting don't hesitate to talk with the trainer about it:

```bash
kubectl describe hpa nginx-hpa
```

Do a cleanup on the created resources:

```bash
kubectl delete deploy nginx-hpa
kubectl delete svc nginx-hpa
kubectl delete deploy load-generator
kubectl delete hpa nginx-hpa
```




# 8. Authentication and Authorization

## 8.1 Users and ServiceAccounts

Kubernetes does NOT have a resource called ```user```. It has the concept of ```ServiceAccounts``` which live inside ```Namespaces```, objects used for multi-tenancy. However, Kubernetes understands the concept of users as an external object.

```ServiceAccounts``` are Kubernetes resource types that are associated with Pods to offer them the posibility to talk to the API Server. They represent the identify of the app running inside Pods. Pods can make API calls against the Server to request pod metadata such as: pod name, IP, namespace, labels, CPU and memory utilization. Usually, apps can make use of this kind of information. Each ```SA``` contains a token, this token is mounted as a ```secret``` volume inside pods on creation. The token is then used to authenticate and authorize the pod requests for the API Server.

Kubernetes distinguishes between the concept of a user account and a service account for a number of reasons:
  * user accounts are for humans, the intent is for user accounts to be managed externally to the Kubernetes cluster
  * service accounts are for Pods and processes that run in them
  * user accounts are global and unique across all namespaces of the cluster
  * service accounts are namespaced
  * auditing for humans and service accounts may differ

Each namespace has a ```default``` ```SA```. Additional ```SAs``` can be created for security reasons, read-only ```SAs``` for pods that only need to read API info, and separate ```SAs``` with write permissions for pods that need to modify API objects.


Each Pod is associated with a ```SA``` on creation. If no ```SA``` is specified in the Pod definition, the namespace's default ```SA``` is used. The ```secret``` volume contains the ```default``` token of the namespace in which the pod is running.

In this chapter we'll create a pod with ```curl``` binary installed and see how the secret volume is mounted in it. The last step would be to send an API request to the API server.

First, let's check the default namespace and the ```SAs```:

```bash
kubectl get namespace
# output
NAME          STATUS    AGE
default       Active    5d
kube-public   Active    5d
kube-system   Active    5d
```

```bash
kubectl get sa
# output
# as mentioned, each Namespace has a default ServiceAccount within it.
NAME                                             SECRETS   AGE
default                                          1         5d
```

```bash
kubectl describe sa default
# output
Name:                default
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   default-token-dl5fg
Tokens:              default-token-dl5fg
Events:              <none>
```

The ```token``` is shown in ```Mountable secrets: default-token-dl5fg```. This will be the token that the app will use to make request to the API Server. We can actually inspect it:

```bash
kubectl describe secret default-token-dl5fg
# output
Name:         default-token-dl5fg
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=default
              kubernetes.io/service-account.uid=86affdbe-84e9-11e8-b05a-0a7548647964

Type:  kubernetes.io/service-account-token

Data
====
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6IiJ9.eyJ6Ie7AC8rzFw
ca.crt:     1183 bytes
```

Now create the ```nginx``` pod and see if the token is mounted:

```bash
kubectl create -f ~/pods/curl-pod.yaml
```

```bash
kubectl describe pod curl
# output
...
Volumes:
  default-token-dl5fg:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  default-token-dl5fg
    Optional:    false
...
```

Kubernetes mounts the secret volume at ```/var/run/secrets/kubernetes.io/serviceaccount/``` inside the container. Based on the certificate and token, the application can talk to the API Server when needed:


```bash
kubectl exec -it curl -- bash
```

```bash
root@curl:/# ls -l /var/run/secrets/kubernetes.io/serviceaccount/
# output
lrwxrwxrwx 1 root root 13 Jul 17 11:59 ca.crt
lrwxrwxrwx 1 root root 16 Jul 17 11:59 namespace
lrwxrwxrwx 1 root root 12 Jul 17 11:59 token
```

Note that you can get the API cluster IP with ```kubectl get svc``` or the DNS record which is ```kubernetes```.

```bash
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes
```

```bash
exit
```

A long list of API should be listed. If we would have not used the certificate and token, this request would have NOT been unauthorized.

**NOTE**: ```ServiceAccounts``` must be set when creating the pod. It can't be changed later. One pod is associated with only one ```SA```, but multiple pods can use the same ```SA``` in a namespace.

Cleanup the pod:

```bash
kubectl delete pod curl
```

## 8.2 RBAC, Roles and ClusterRoles

All Kubernetes resources are objects which allow CRUD (create, read, update, delete) operations. Role-based access control (RBAC) is a method of regulating access to resources based on the roles of individual users. RBAC works and understands 4 types of Kubernetes resources:
  * ```Role``` and ```ClusterRole```: contain rules that represent a set of permissions. Permissions are additive, no ```deny``` rules. ```Roles``` grant access to resources within a single namespace, while ```ClusterRoles``` are cluster-wide.
  * ```RoleBinding``` and ```ClusterRoleBinding```: grant permissions defined in a ```Role``` to a user or set of users

![roles](assets/roles_bindings.png)


By default, RBAC is not enabled. To enable it, the API server has to be started with ```--authorization-mode=RBAC```:

```bash
juju config kubernetes-master authorization-mode="RBAC,Node"
```

Do a ```juju status```, the kubernetes-master/0 unit should be in in maintenance mode since it's updating the service.

From the student machine, SSH into the ```kubernetes-master/0``` unit and check that the authorization mode is RBAC:

```bash
juju ssh kubernetes-master/0
```

```bash
ubuntu@kubernetes-master~$ ps aux | grep "authorization-mode"
# output
...
--authorization-mode=RBAC,Node
...
```

```bash
# go back to the student machine
ubuntu@kubernetes-master~$ exit
```

Users can create their own ```Roles``` and ```ClusterRoles``` - see the definitions, but Kubernetes clusters also come with a default set of ```ClusterRoles```. The “edit” role lets users perform basic actions like deploying pods; “view” lets a user observe non-sensitive resources; “admin” allows a user to administer a namespace; and “cluster-admin” grants access to administer a cluster. Take a look:

```bash
kubectl get clusterroles
# output
NAME                                                                   AGE
admin                                                                  39m
cluster-admin                                                          39m
edit                                                                   39m
view                                                                   39m
...
```

### Create a ServiceAccount and grant permissions

In this exercise we'll create a ```ServiceAccount```, a ```Role``` and a ```RoleBinding```. The ```Role``` will grant read access to pod resources in the default namespace.

The ```SA``` definition looks like this:

```bash
apiVersion: v1
kind: ServiceAccount
metadata:
 name: student-sa
 namespace: default
```

Create the ```SA```:

```bash
kubectl create -f ~/pods/stundent-sa.yaml
```

The ```Role``` definition looks like this:

```bash
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Create the ```Role```:

```bash
kubectl create -f ~/pods/pod-reader-role.yaml
```

The ```Role``` has to be associated with the user, this is done with the ```RoleBinding``` resource:

```bash
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: student-sa
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl create -f ~/pods/pod-reader-rb.yaml
```

Inspect the ```RoleBinding```, it should be associated with ```student-sa```:

```bash
kubectl describe rolebinding read-pods
# output
Name:         read-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pod-reader
Subjects:
  Kind             Name        Namespace
  ----             ----        ---------
  ServiceAccount   student-sa
```

Create a Pod with the newly created ```SA```. The pod definition looks like this:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: curl
spec:
  serviceAccountName: student-sa
  containers:
  - name: curl
    image: tutum/curl
    command: ["sleep", "999999"]
```

The key field here is ```serviceAccountName: student-sa```. Create the Pod:

```bash
kubectl create -f ~/pods/curl-pod-with-sa.yaml
```

Finally, start a bash process inside the container and attach to it.

```bash
kubectl exec -it curl -- bash
```

Query the API server for pods, this action should be allowed:

```bash
root@curl:/# TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods
# output
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "selfLink": "/api/v1/namespaces/default/pods",
    "resourceVersion": "16921"
  },
  "items": [
    {
      "metadata": {
        "name": "curl",
        "namespace": "default",
        "selfLink": "/api/v1/namespaces/default/pods/curl",
        "uid": "58c2b78b-93f8-11e8-b176-0aa3add23206",
        "resourceVersion": "16570",
        "creationTimestamp": "2018-07-30T12:59:08Z"
```

Now let's try to read something we should not be allowed to see, like ```Secrets```:

```bash
root@curl:/# curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/secrets
# output
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {

  },
  "status": "Failure",
  "message": "secrets is forbidden: \"system:serviceaccount:default:student-sa\"
   cannot list secrets in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "secrets"
  },
  "code": 403
```

```bash
exit
```

As expected, forbidden action.

Cleanup:

```bash
kubectl delete pod curl
kubectl delete rolebinding read-pods
kubectl delete role pod-reader
kubectl delete sa student-sa
```


### Grant full access to all ServiceAccounts

For testing and learning purposes, create a ```ClusterRoleBinding``` between the ```cluster-admin``` role and all the ```ServiceAccounts```. This is not usually recommended in production as all the ```ServiceAccounts``` will have full permisions on all the resources.

```bash
kubectl create clusterrolebinding permissive-binding \
--clusterrole=cluster-admin \
--group=system:serviceaccounts
```


## 8.3 Access the dashboard

There are two ways to access the dashboard, use the address ```kube-dashboard``` address from the ```kubectl cluster-info``` command's output, or proxy it via your given VM or laptop. For this option you will need the ```config``` file on the machine and the ```kubectl``` tool installed. The ```config``` file is very important because it contains credentials and the IP of the cluster based on which the connection is made.

```bash
~ dan-laptop >>> kubectl proxy

Starting to serve on 127.0.0.1:8001
```

Now it can be accessed from a browser on the address

```http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/```


# 9. Helm

Helm is like a package manager for Kubernetes. It allows users to install simple or complex apps with ```Charts```. Charts are packages of pre-configured Kubernetes resources.

Helm has two components:
  * the CLI client: can run anywhere
  * the server: it is called ```Tiller```, runs as a Pod inside the Kubernetes cluster.


In this chapter we'll install a ```wordpress``` stack with a ```mariaDB``` database. This requires some Kubernetes resources such as: pods, loadBalancer services, PVCs and PVs. All of this will be deployed from a chart.


## 9.1 Deploy an app

Install helm client on the student machine:

```bash
sudo snap install helm --channel=2.16/stable --classic
```

In order to talk to the Kubernetes cluster, Helm uses the cluster's ```kubeconfig```. Copy it to the Helm location and ```init``` Helm:

```bash
mkdir -p /home/ubuntu/snap/helm/common/kube/
cp ~/.kube/config /home/ubuntu/snap/helm/common/kube/config
helm init
```

Check the ```Tiller``` pod:

```bash
kubectl get pods --namespace kube-system | grep tiller
```

Helm has it's own repository, update it to make sure you get the latest list of charts:

```bash
helm repo update
```

Search for the Wordpress chart:

```bash
helm search wordpress
```

Time to install the chart. We are going to use the ```gce```  ```StorageClass``` we provisioned earlier.

```bash
helm install stable/wordpress --name my-wordpress-blog \
--set wordpressUsername=admin,wordpressPassword=password,\
persistence.storageClass=gce,mariadb.persistence.storageClass=gce
```

Take a look at all the Kubernetes resources that were created:

```bash
NAME:   my-wordpress-blog
LAST DEPLOYED: Fri Jul 20 13:08:40 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1beta1/Deployment
NAME                         DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
my-wordpress-blog-wordpress  1        1        1           0          0s

==> v1beta1/StatefulSet
NAME                       DESIRED  CURRENT  AGE
my-wordpress-blog-mariadb  1        1        0s

==> v1/Pod(related)
NAME                                          READY  STATUS   RESTARTS  AGE
my-wordpress-blog-wordpress-54ffb6dd5b-6czd9  0/1    Pending  0         0s
my-wordpress-blog-mariadb-0                   0/1    Pending  0         0s

==> v1/Secret
NAME                         TYPE    DATA  AGE
my-wordpress-blog-mariadb    Opaque  2     0s
my-wordpress-blog-wordpress  Opaque  2     0s

==> v1/ConfigMap
NAME                             DATA  AGE
my-wordpress-blog-mariadb        1     0s
my-wordpress-blog-mariadb-tests  1     0s

==> v1/PersistentVolumeClaim
NAME                         STATUS   VOLUME  CAPACITY  ACCESS MODES  STORAGECLASS  AGE
my-wordpress-blog-wordpress  Pending  gce     0s

==> v1/Service
NAME                         TYPE          CLUSTER-IP      EXTERNAL-IP  PORT(S) 
my-wordpress-blog-mariadb    ClusterIP     10.152.183.126  <none>       3306/TCP
my-wordpress-blog-wordpress  LoadBalancer  10.152.183.91   <pending>    80:30042/TCP,443:31726/TCP
```

The chart create a loadBalancer service:

```bash
kubectl get svc
# output
NAME                          TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)
my-wordpress-blog-wordpress   LoadBalancer   10.152.183.172   35.205.105.0   80:32299/TCP,443:30042
```

Now the wordpress app should be available via ```35.205.105.0```

In this chapter we saw how easy it is to deploy simple or complex apps with Helm.

Delete the app. Helm usually deletes all the resources associated with a chart, but for the moment the mariadb PersistentVolumeClaim needs to be deleted manually:

```bash
helm delete my-wordpress-blog
kubectl delete pvc data-my-wordpress-blog-mariadb-0
```


## 9.2 Deployment Chart

First, the application code has to be built into a Docker image. Here you can find code for a simple ```nodejs``` web app plus the ```Dockerfile``` for it:
https://github.com/cloudbase/kubernetes-tools

```bash
cd ~ && git clone https://github.com/cloudbase/kubernetes-tools.git
```

There are two ways to get the image, either build it or pull it from ```DockerHub```. I am going to demonstrate how to built it, you don't have to do it because the image is going to be pulled from ```DockerHub```.

**NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub!
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app/
docker build -t dardelean/web-app .
docker tag dardelean/web-app dardelean/web-app:v1
```

The image is already public on ```DockerHub```. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Because the image is used with a complex environment like Kubernetes, it's useful to test it beforehand on it's own:

```bash
docker run -p 80:80 dardelean/web-app:v1
```

Open another tab on your public machine and test the container:
```bash
curl localhost:80
```

Go back on the first tab and kill the container with ```CTRL+C```.

Create a helm chart template and modify ```values.yaml``` to point to the correct image and ```replicaCount```:

```bash
helm create ~/web-app
```

```bash
cd ~/web-app
vim values.yaml
# do desired edits on values.yaml, for example specify
# dardelean/web-app:v1 Docker image

...
replicaCount: 3

image:
  repository: dardelean/web-app
  tag: v1
  pullPolicy: IfNotPresent
...
```

Package the app:

```bash
helm package .
```

```bash
# do a dry run to check that everything is ok
helm install --debug --dry-run web-app-0.1.0.tgz

helm install web-app-0.1.0.tgz
```

More info on Helm templating:
https://docs.helm.sh/chart_template_guide/

Because the app now has a ClusterIP service, you can go on any of the Nodes and do a curl on it on port ```80```.

List all the apps. We should only have one, delete it:

```bash
helm list
# output
NAME          	REVISION
wandering-seal	1
```

```bash
helm delete wandering-seal
```


## 9.3 StatefulSet Chart

The Docker image can be built as before. I will only demonstrate how to do this, the image is already public so no need for you to to this:

**NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub!
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app-stateful/image
docker build -t dardelean/web-app-stateful .
docker tag dardelean/web-app-stateful dardelean/web-app-stateful:v1
```

The image is already public on ```DockerHub```. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Build the Chart:

```bash
mkdir ~/web-app-stateful && cd ~/web-app-stateful
cp -r ~/kubernetes-tools/web-app-stateful/chart/* ~/web-app-stateful/
```

Package the app:

```bash
helm package .
```

Based on the archive that we now have, we cah install the Helm chart anywhere:

```bash
helm install web-app-stateful-0.1.0.tgz
# output
NAME:   exacerbated-octopus
LAST DEPLOYED: Mon Aug 13 08:41:01 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Service
NAME                                  TYPE       CLUSTER-IP  EXTERNAL-IP  PORT(S)  AGE
exacerbated-octopus-web-app-stateful  ClusterIP  None        <none>       80/TCP   0s

==> v1beta1/StatefulSet
NAME                                  DESIRED  CURRENT  AGE
exacerbated-octopus-web-app-stateful  2        1        0s

==> v1/Pod(related)
NAME                                    READY  STATUS   RESTARTS  AGE
exacerbated-octopus-web-app-stateful-0  0/1    Pending  0         0s


NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app=web-app-stateful,...
  echo "Visit http://127.0.0.1:8080 to use your application"
  kubectl port-forward $POD_NAME 8080:80
```

The ```StatefulSet``` requires a ```clusterIP``` headless service, this means that the service will not have an IP. So how do we connect to the app? There are two ways, create another ```clusterIP``` service or use the proxy:

```bash
kubectl proxy
# output
Starting to serve on 127.0.0.1:8001
```

Open another terminal tab on your ssh machine. List your apps to get the name of the `StatefulSet` and query the pods:

```bash
helm list
# output
vetoed-orangutan
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/vetoed-orangutan-web-app-stateful-0/proxy/
# output
You hit vetoed-orangutan-web-app-stateful-0
Data stored on this pod: No data posted yet
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/vetoed-orangutan-web-app-stateful-1/proxy/
# output
You hit vetoed-orangutan-web-app-stateful-1
Data stored on this pod: No data posted yet
```

Write data to a pod and check to see if it was written:

```bash
curl -X POST -d "Hey there!" \
localhost:8001/api/v1/namespaces/default/pods/vetoed-orangutan-web-app-stateful-1/proxy/
# output
Data stored on pod vetoed-orangutan-web-app-stateful-1
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/vetoed-orangutan-web-app-stateful-1/proxy/
# output
You hit vetoed-orangutan-web-app-stateful-1
Data stored on this pod: Hey there!
```

Delete the pod that stores the data:

```bash
kubectl delete pod vetoed-orangutan-web-app-stateful-1
```

The pod should be recreated by the ```StatefulSet``` but should retain the stored information:

```bash
curl localhost:8001/api/v1/namespaces/default/pods/vetoed-orangutan-web-app-stateful-1/proxy/
# output
You hit vetoed-orangutan-web-app-stateful-1
Data stored on this pod: Hey there!
```

Do a cleanup:

```bash
helm list
# output
NAME                  	REVISION	UPDATED                 	STATUS  	CHART
existing-olm          	1       	Mon Oct 15 13:53:25 2018	DEPLOYED	web-app-0.1.0
oldfashioned-crocodile	1       	Mon Oct 15 13:56:10 2018	DEPLOYED	web-app-stateful-0.1.0
```

```bash
helm delete --purge existing-olm oldfashioned-crocodile
```


# 10. Upgrading CDK

The installed version of Kubernetes is ```1.13```, which is not the latest one. In this chapter we will learn how easy it is to upgrade the Kubernetes cluster to the latest ```1.14``` version with in place upgrades. This is another powerful Juju feature. Charms are written in such a way that upgrading and scaling are easy to do.

Check the current cluster status, note the app versions. The Kubernetes components should be in ```1.13.x``` versions :

```bash
juju status
# output
App                    Version  Status  Scale  Charm                  Store       Rev  OS      Notes
easyrsa                3.0.1    active      1  easyrsa                jujucharms   45  ubuntu
etcd                   3.2.10   active      1  etcd                   jujucharms   90  ubuntu
flannel                0.10.0   active      3  flannel                jujucharms   60  ubuntu
gcp-integrator         220.0.0  active      1  gcp-integrator         jujucharms    3  ubuntu
kubeapi-load-balancer  1.14.0   active      1  kubeapi-load-balancer  jujucharms   64  ubuntu  exposed
kubernetes-master      1.13.4   active      1  kubernetes-master      jujucharms  116  ubuntu
kubernetes-worker      1.13.4   active      2  kubernetes-worker      jujucharms  131  ubuntu  exposed
```

First, upgrade the etcd and kubeapi-load-balancer charms:

```bash
juju upgrade-charm etcd
juju upgrade-charm kubeapi-load-balancer
```

Wait a minute or two for the charms to update. Run the ```juju status``` command to check the progress, you should see the agent in ```executing``` state.

Upgrade the master:

```bash
juju upgrade-charm kubernetes-master
juju config kubernetes-master channel=1.14/stable
juju run-action kubernetes-master/0 upgrade
```

Wait a minute or two for the charms to upgrade. Run the ```juju status``` command to check the progress, you should see the agent in ```executing``` state.

Now the workder nodes:

```bash
juju upgrade-charm kubernetes-worker
juju config kubernetes-worker channel=1.14/stable
juju run-action kubernetes-worker/0 upgrade
juju run-action kubernetes-worker/1 upgrade
```

The kubernetes-worker units will enter a blocked state, with status message `Connect a container runtime`. We need to
deploy and relate the new Docker charm. This step is needed even if you do not intend to use Docker following the upgrade.
Docker is already installed on your kubernetes-worker units.

```bash
juju deploy cs:~containers/docker
juju add-relation docker kubernetes-master
juju add-relation docker kubernetes-worker
```

Run the following command to upgrade the worker charm:

```bash
juju run-action kubernetes-worker/0 upgrade
```

Again, wait a minute or two for the charm to upgrade.


Finally, upgrade ```flannel``` and ```easyrsa``` charms. Note that networking is interrupted during the upgrade. You can initiate the easyrsa and flannel upgrades with:

```bash
juju upgrade-charm flannel
juju upgrade-charm easyrsa
```

After everything is upgraded, the new charm versions can be observed:

```bash
juju status
# output
App                    Version  Status  Scale  Charm                  Store       Rev  OS      Notes
easyrsa                3.0.1    active      1  easyrsa                jujucharms  114  ubuntu
etcd                   3.2.10   active      1  etcd                   jujucharms  201  ubuntu
flannel                0.10.0   active      3  flannel                jujucharms  141  ubuntu
gcp-integrator         220.0.0  active      1  gcp-integrator         jujucharms    3  ubuntu
kubeapi-load-balancer  1.14.0   active      1  kubeapi-load-balancer  jujucharms  154  ubuntu  exposed
kubernetes-master      1.13.4   active      1  kubernetes-master      jujucharms  210  ubuntu
kubernetes-worker      1.13.4   active      2  kubernetes-worker      jujucharms  231  ubuntu  exposed
```

Note that the Kubernetes services are at ```1.14.x``` version.


## 10.1 Remove Kubernetes

As a final step, destroy the Kubernetes deployment with Juju. One way to do it is to
destroy the juju model that was created before deployment. This will remove all the
applications part of the model:

```bash
juju list-models
# output
Controller: azure-controller

Model         Cloud/Region         Status     Machines  Cores  Access  Last connection
controller    azure/westeurope     available         1      2  admin   just now
default       azure/westeurope     available         0      -  admin   2019-01-14
student-dan*  azure/westeurope     available         0      -  admin   never connected
```

```bash
juju destroy-model student-dan
# output
WARNING! This command will destroy the "student-dan" model.
This includes all machines, applications, data and other resources.

Continue [y/N]? y
Destroying model
Waiting on model to be removed, 6 machine(s), 7 application(s)...
Waiting on model to be removed, 6 machine(s), 7 application(s)...
...
```

The Juju controller can also be removed now:

```bash
juju list-controllers
# output
Use --refresh flag with this command to see the latest information.

Controller          Model        User   Access     Cloud/Region         Models  Machines
azure-controller*   student-dan  admin  superuser  azure/westeurope     2         1
```

```bash
juju destroy-controller azure-controller --destroy-all-models
# output
WARNING! This command will destroy the "azure-controller" controller.
This includes all machines, applications, data and other resources.

Continue? (y/N):y
Destroying controller
Waiting for hosted model resources to be reclaimed
All hosted models reclaimed, cleaning up controller machines
```
