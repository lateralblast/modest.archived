Overview
========

Multi Os Deployment Engine Server Tool

A Ruby script to configure server and client configuration for PXE/DHCP and BOOTP based install services, eg:

- Solaris 11 Automated Installer (AI) service
- Solaris 10 (and earlier) Jumpstart services
- Centos and RedHat Linux Kickstart services
- Ubuntu Linux Preseed support
- SuSE Linux AutoYast support
- ESXi Kickstart services

This script is a wrapper which sits on top of the exisitng tools.
It changes defaults to be more suitable to customer environments,
and sanity checks server and client configuration to ensure the
chance of human error is reduced.
By doing this the script reduces the time lost debugging installations,
which in complex environments can be time consuming.
It also reduces the time to deploy servers and increases the consistency of installations.

This script will provide the ability to install Solaris 2.6-10, Solaris 11, ESXi,
and Linux (SuSE, Ubuntu, RedHat and Centos) all from one server and OS, consolidating and
simplifying installation services. This can be hosted on a physical server or a VM.
In particular it can be used with a laptop to provide installation services via a cross-over cable.
This is expecially useful for resolving issues with servers and installing firmware.
It can be used in combination with the firmware and patch repository script (goofball)
to install patches, firmware and SRUs.

Features
========

VirtualBox and VMware Fusion VM creation

- Can create VMs to speed up the automation of testing new images

Solaris 11 AI

- If a local repository exists it is used to configure installation services
- If a local repository is not present it mounts the repository ISO and configures it
- Changes the default install service manifest to reboot servers after installation
- Changes the default install service to use the local repository rather than the Oracle one
- Changes the default grub configuration default to an autamated install rather than an interactive one
- Disables the default range based DHCP configuration and adds clients on an individual basis
  - Reduces the chances of conflicts with existing DHCP services, and
  - Resolves the issue of DHCP licenses running out
- Creates an individual configuration profile for each client
  - Configures network and other services
- Includes code to optionally create alternate package repository
  - Automatically builds packages for facter, hiera, and puppet
  - Adds packages to base installation manifest
- Post installation script capability (work in progress)

Centos and RedHat Linux Kickstart

- Creates an Apache directory and alias for a HTTP based installation
- Creates PXE configuration that jumps straight into an installation and pulls kickstart file from server
- Includes code for optionally installing additional packages
  - Automatically downloads Puppet packages
  - Add packages to post installation

Ubuntu Linux Preseed

- Adds required append statement to PXE configuration so install is fully automated
- Currently only basic client support (auto partitions disk)

SuSE Linux AutoYast

- Creates AutoYast XML file based on answers to questions

Solaris 10 (and earlier) Jumpstart:

- Automatically tries to determine boot and mirror disk ids based on model
- Automatically tires to determine kernel architecture (e.g. sun4u / sun4v) based on model

ESXi Kickstart:

- Automatically created PXE boot and jumpstart configuration files
- Automatically adds post install commands to turn on ESXi services such as SSH

All:

- Asks a set of default questions to produce a consistent error checked profile for each client
- Makes sure clients are added and deleted correctly removing the chance of installing the wrong thing to the wrong machine
- Installs and configures (and uninstalls and unconfigures if needed) server services (DHCP etc)
- Post installation scripting to perform tasks such as patching and security

Background
==========

What does modest do?

This script is intended to work as a wrapper script on top of Solaris AI and other install services.
It manages the configuration of the install server and the addition of clients.

Why write a wrapper script?

Although vendors package server and client configuration scrips for their Operating Systems,
additional modification is required to modify it for customer environments.
For example adding local software packages and configurations.
In the case of Solaris AI and Jumpstart although the software has installers and scripts,
there are a number of manual operations that must be performed.
This leads to the possibility of human error and wasted time debugging the error.
There are also a number of defaults that are unsatisfactory for a lot of customer installs,
for example using vendor software repositories that are unavailable behind firewalls.
Similarly although vendors provide example configurations, copying them and editing them
leads to the possibility of human error.
This script asks a basic set of questions and output a valid error checked configuration file.
This saves time and reduces the likely hood of error. It also makes sure sensible settings
(such as security) are in place when the OS is installed.


More Information
================

For more information, including examples of usage refer to the wiki:

https://github.com/richardatlateralblast/modest/wiki

Solaris 11 AI Related Information
=================================

https://github.com/richardatlateralblast/modest/wiki/AIServerExamples

https://github.com/richardatlateralblast/modest/wiki/AIClientExamples

Kickstart, Preseed, and AutoYast Related Information
===================================================

https://github.com/richardatlateralblast/modest/wiki/KSServerExamples

https://github.com/richardatlateralblast/modest/wiki/KSClientExamples

Solaris 10 (and earlier) Jumpstart Related Information
======================================================

https://github.com/richardatlateralblast/modest/wiki/JSServerExamples

https://github.com/richardatlateralblast/modest/wiki/JSClientExamples

ESXi Related Information
========================

https://github.com/richardatlateralblast/modest/wiki/VSServerExamples

https://github.com/richardatlateralblast/modest/wiki/VSClientExamples

Virtual Box Related Information
===============================

https://github.com/richardatlateralblast/modest/wiki/VirtualBoxExamples

VMware Fusion Related Information
=================================

https://github.com/richardatlateralblast/modest/wiki/VMwareFusionExamples
