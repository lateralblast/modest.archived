![alt tag](https://raw.githubusercontent.com/lateralblast/modest/master/modest.jpg)

MODEST
======

Multi OS Deployment Engine Server Tool

Introduction
------------

A Ruby script to configure server and client configuration for PXE/DHCP and
BOOTP based install services, eg:

- Solaris 11 Automated Installer (AI) service
- Solaris 10 (and earlier) Jumpstart services
- Centos, Scientific, OEL, and RHEL Kickstart services
- Ubuntu Linux Preseed services
- SuSE Enterprise Linux AutoYast services
- ESXi Kickstart services
- Simplify creation of VirtualBox VMs
- Simplify creation of VMware Fusion VMs
- Simpllfy creation of Solaris Zones
- Simplify creation of Solaris VM Server for SPARC Control Domains
- Simplify creation of Solaris VM Server for SPARC Guest Domains
- Linux Containers (Currently Ubuntu support only)

This script is a wrapper which sits on top of the exisitng tools. It changes
defaults to be more suitable to customer environments, and sanity checks server
and client configuration to ensure the chance of human error is reduced.

By doing this the script reduces the time lost debugging installations,
which in complex environments can be time consuming. It also reduces the time
to deploy servers and increases the consistency of installations.

This script will provide the ability to install Solaris 2.6-10, Solaris 11,
ESXi, and Linux (SuSE, Ubuntu, RedHat and Centos) all from one server and OS,
consolidating and simplifying installation services. This can be hosted on a
physical server or a VM.

In particular it can be used with a laptop to provide installation services via
a cross-over cable. This is expecially useful for resolving issues with servers
and installing firmware. It can be used in combination with the firmware and
patch repository script (goofball) to install patches, firmware and SRUs.

License
-------

This software is licensed as CC-BA (Creative Commons By Attrbution)

http://creativecommons.org/licenses/by/4.0/legalcode

Usage
-----

Modest is designed to be used in a number of scenarios:

- Testing vendor OS deployment technologies (e.g. Kickstart, Jumpstart etc)
  - PXE boot
  - Pre and post install scripts
- A environment for quickly deploying VMs for testing purposes
  - In a similar fashion to veewee or vagrant
- An environment for quickly deploying servers in a Datacenter or testlab via cross-over cable

A good place to get started is the [Usage](https://github.com/lateralblast/modest/wiki/3.-Usage)
Wiki page which includes a section on getting started.

Wiki Index
----------

[Background](https://github.com/lateralblast/modest/wiki/AIServerExamples/1.-Background)

[Features](https://github.com/lateralblast/modest/wiki/AIServerExamples/2.-Features)

[Usage](https://github.com/lateralblast/modest/wiki/AIServerExamples/3.-Usage)

- [VirtualBox](https://github.com/lateralblast/modest/wiki/AIServerExamples/3.1.-VirtualBox-Examples)
- [VMware Fusion](https://github.com/lateralblast/modest/wiki/AIServerExamples/3.2.-VMware-Fusion-Examples)

[Server](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.-Server)

- [AI](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.1.-AI-Server-Examples)
- [Jumpstart](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.2.-Jumpstart-Server-Examples)
- [Kickstart](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.3.-Kickstart-Server-Examples)
- [LDom](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.4.-LDom-Server-Examples)
- [LXC](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.5.-Linux-Container-Server-Examples)
- [Preseed](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.6.-Preseed-Server-Examples)
- [vShpere](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.7.-Sphere-Server-Examples)
- [Zones](https://github.com/lateralblast/modest/wiki/AIServerExamples/4.8.-Zone-Server-Examples)

[Client](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.-Client)

- [AI](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.1.-AI-Client-Example)
- [Jumpstart](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.2.-Jumpstart-Client-Examples)
- [Kickstart](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.3.-Kickstart-Client-Examples)
- [LDom](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.4.-LDom-Client-Examples)
- [LXC](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.5.-Linux-Container-Client-Examples)
- [Preseed](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.6.-Preseed-Client-Examples)
- [vSphere](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.7.-vSphere-Client_Examples)
- [Zones](https://github.com/lateralblast/modest/wiki/AIServerExamples/5.8.-Zone-Client-Examples)

Features
--------

Linux Container Creation

- Installs required packages and sets up network for public facing containers
  that can be connected to via ssh (Currently Ubuntu support only)
- Creates containers and sets up network (Currently Ubuntu support only)

Oracle VM Server for SPARC

- Setup Control Domain based on a set of questions
- Cleate Guest Domains based on a set of questions

VirtualBox and VMware Fusion VM creation

- Can create VMs to speed up the automation of testing new images

Solaris Zone Creation

- Asks a set of questions to generate a template and then install a zone

Solaris 11 AI

- If a local repository exists it is used to configure installation services
- If a local repository is not present it mounts the repository ISO and
  configures it
- Changes the default install service manifest to reboot servers after
  installation
- Changes the default install service to use the local repository rather than
  the default Oracle one
- Changes the default grub configuration default to an autamated install rather
  than an interactive one
- Disables the default range based DHCP configuration and adds clients on an
  individual basis
  - Reduces the chances of conflicts with existing DHCP services, and
  - Resolves the issue of DHCP licenses running out
- Creates an individual configuration profile for each client
  - Configures network and other services
- Includes code to optionally create alternate package repository
  - Automatically builds packages for facter, hiera, and puppet
  - Adds packages to base installation manifest
- Post installation script capability (work in progress)

CentOS and RedHat Linux Kickstart

- Creates an Apache directory and alias for a HTTP based installation
- Creates PXE configuration that jumps straight into an installation and pulls
  kickstart file from server
- Includes code for optionally installing additional packages
  - Automatically downloads Puppet packages
  - Add packages to post installation

Ubuntu Linux Preseed

- Adds required append statement to PXE configuration so install is fully
  automated
- Currently only basic client support (auto partitions disk)

SuSE Linux AutoYast

- Creates AutoYast XML file based on answers to questions

Solaris 10 (and earlier) Jumpstart:

- Automatically tries to determine boot and mirror disk ids based on model
- Automatically tires to determine kernel architecture (e.g. sun4u / sun4v)
  based on model
- Ability to quickly deploy flar based installs by answering a few questions

ESXi Kickstart:

- Automatically created PXE boot and jumpstart configuration files
- Automatically adds post install commands to turn on ESXi services such as SSH

All:

- Asks a set of default questions to produce a consistent error checked profile
  for each client
- Makes sure clients are added and deleted correctly removing the chance of
  installing the wrong thing to the wrong machine
- Installs and configures (and uninstalls and unconfigures if needed) server
  services (DHCP etc)
- Post installation scripting to perform tasks such as patching and security

Architecture
------------

The architecture of modest is made up of the following layers:

- Host machine
  - Can be a laptop or a server
  - Manages VMs (including Deployment Server)
  - Provides hostonly or bridged networking for VMs
  - Can provide boot services for external machines via cross-over cable or switch
  - Can be used to provide installation media (ISOs) to deployment server via shared filesystem
- Deployment Server
  - Manages OS installation media (ISOs) and repositories
  - Manages PXE boot configurations
    - The VMs on the host you wish an OS to be installed to
    - External machines you may wish to install and OS to (e.g. Testlab or DC)
  - Manages client VM configurations
    - The VMs on the host you wish an OS to be installed to
    - External machines you may wish to install and OS to (e.g. Testlab or DC)
  - Manages post installation scripts

I'll go into more detail and an actual example of the process in the getting
started section, but basically the process of deploying a VM is as follows:

- Create a blank VM on the host machine
- Configure the VM installation template/configuration on the Deployment Server
- Boot the VM on the host machine and let it PXE boot and install

Requirements
------------

All:

- Ruby
  - Version 1.8 or greater
    - Although it's been coded with 2.x I've avoided using 2.x features
- Gems
  - rubygems
  - getopt/std
  - builder
  - socket
  - parseconfig
  - unix_crypt
  - pathname
  - netaddr

Kickstart, AutoYast, and Preseed Services:

- Solaris 11, Linux, or OS X

AI Services:

- Solaris 11

Jumpstart Services:

- Solaris 11 or OS X (Linux to be added)

Linux Containers:

- Linux (Currently only Ubuntu supported)

Solaris Containers:

- Solaris 10 or 11 (Some branded container support on Solaris 11)

VM Client Services:

- VMware Fusion or VirtualBox

VirtualBox bridged networking on OS X has been severly broken for quite
some time, therefore it is recommended to use VMware Fusion if available.

If using OS X and a installation platform for Jumpstart it is recommended to
use flar based installs as the performance of the OS X NFS server being so
utterly useless.

More Information
----------------

For more information, including examples of usage refer to the wiki:

https://github.com/lateralblast/modest/wiki






