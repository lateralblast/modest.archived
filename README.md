modest
======

Multi Os Deployment Engine Server Tool

A Ruby script to configure server and client configuration for PXE/DHCP and BOOTP based install services, eg:

- Solaris 11 base Automated Installer (AI) service
- Solaris 10 and early Jumpstart services
- Linux Kickstart services

This script is a wrapper which sits on top of the exisitng tools.
It changes defaults to be more suitable to customer environments,
and sanity checks server and client configuration to ensure the
chance of human error is reduced.
By doing this the script reduces the time lost debugging installations,
which in complex environments can be time consuming.
It also reduces the time to deploy servers and increases the consistency of installations.

This script will provide the ability to install Solaris 2.6-10, Solaris 11, 
and Linux all from one server and OS, consolidating and simplifying installation services. 
This can be hosted on a physical server or a VM. 
In particular it can be used with a laptop to provide installation services via a cross-over cable.
This is expecially useful for resolving issues with servers and installing firmware.
It can be used in combination with the firmware and patch repository script (goofball)
to install patches, firmware and SRUs.

Features
========

Solaris AI

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

Linux Kickstart

- Creates an Apache directory and alias for a HTTP based installation
- Creates PXE configuration that jumps straight into an installation and pulls kickstart file from server
- Includes code for optionally installing additional packages
  - Automatically downloads Puppet packages
  - Add packages to post installation

Solaris Jumpstart:

- Automatically tries to determine boot and mirror disk ids based on model
- Automatically tires to determine kernel architecture (e.g. sun4u / sun4v) based on model

All:

- Asks a set of default questions to produce a consistent error checked profile for each client
- Makes sure clients are added and deleted correctly removing the chance of installing the wrong thing to the wrong machine
- Installs and configures (and uninstalls and unconfigures if needed) server services (DHCP etc)
- Post installation scripting to perform tasks such as patching and security

Solaris Jumpstart (to be added)


Linux Kickstart (to be added)

Requirements
============

The following is required:

- Solaris 11
- Ruby
- Gems (getopt and builder)
- Repo ISOs in /export/cdrom if no local repository already exits

The Ruby code has been modified to be able to use the Ruby 1.8 that comes with Solaris 11, 
however it does require the getopt and build gems.

Installing Ruby on Solaris 11:

	# pkg install ruby-18
	           Packages to install:  1
	       Create boot environment: No
	Create backup boot environment: No

	DOWNLOAD                                PKGS         FILES    XFER (MB)   SPEED
	Completed                                1/1   12001/12001      6.4/6.4    0B/s

	PHASE                                          ITEMS
	Installing new actions                   14016/14016
	Updating package state database                 Done
	Updating image state                            Done
	Creating fast lookup database                   Done

Installing required modules:

	# gem install getopt
	Successfully installed getopt-1.4.1
	1 gem installed
	Installing ri documentation for getopt-1.4.1...
	Installing RDoc documentation for getopt-1.4.1...

	# gem install builder
	Successfully installed builder-3.2.2
	1 gem installed
	Installing ri documentation for builder-3.2.2...

The builder gem installer may complain during the documentation installation phase,
but completes successfully.

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

Usage
=====

	Usage: ./modest.rb -[F:a:c:d:e:f:h:i:n:p:z:ACDJKLMPRSVWZtv]

	-h: Display usage
	-c: Create client
	-V: Display version
	-A: Configure AI
	-J: Configure Jumpstart
	-K: Configure Kicstart
	-M: Maintenance mode
	-a: Architecture
	-e: Client MAC Address
	-i: Client IP Address
	-m: Client model (used for Jumpstart)
	-S: Configure server
	-C: Configure client services
	-p: Puplisher server port number
	-h: Puplisher server Hostname/IP
	-t: Run it test mode (in client mode create files but don't import them)
	-v: Run in verbose mode
	-f: ISO file to use
	-F: Set location of ISOs (directory)
	-d: Delete client
	-n: Set service name
	-z: Delete service name
	-M: Maintenance operations
	-P: Configure PXE
	-W: Update apache proxy entry for AI
	-R: Use alternate package repository (additional packages like puppet)
	-Z: Destroy ZFS filesystem as part of uninstallation
	-D: Use default values for questions

Solaris 11 AI Examples
======================

Unconfigure AI service sol_11_!:              

	modest.rb -A -S -z sol_11_1

Configure AI services (if not repos exist, it will search /export/isos for valid repo isos to build repo):
         
	modest.rb -A -S

Manually configure AI client services only (for i386 - normally done as part of previous step):   

	modest.rb -A -M -C -a i386

Create AI client:

	modest.rb -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193

Create AI client (use default values):               

	modest.rb -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193 -D

Manually update AI proxy (normally done as part of configuring the server)

	modest.rb -A -M -W -n sol_11_1

Delete AI client:

	modest.rb -A -C -d sol11u01vm03

Configure alternate repo as part of server setup:

	modest.rb -A -S -R

Manually configure alternate repo only (normally done as part of configuring the server):

	modest.rb -A -M -R

Manually unconfigure alternate repo only (normally done as part of unconfiguring the server):: 

	modest.rb -A -M -R -z sol_11_1_alt

Linux Kickstart Examples
========================

Configure KS services (will search for CentOS and RedHat ISOs in /export/isos and set up services if the don't exist):		

	modest.rb -K -S 

Unconfigure KS service:		

	modest.rb -K -S -z centos_5_9

Create KS client:		

	modest.rb -K -C -c centos59vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_9

Manually configure KS client PXE (normally done as part of client setup):	

	modest.rb -K -M -P -c centos59vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_9

Manually configure KS apache alias (normally done as part of server configuration):		

	modest.rb -K -M -W -n centos_5_9

Manually unconfigure KS apache alias:		

	modest.rb -K -M -W -z centos_5_9

Unconfigure KS client:		

	modest.rb -K -C -d centos59vm01

Manually Import PXE files (normally dones as part of server configuration):		

	modest.rb -K -M -P -n centos_5_9

Manually unconfigure KS client PXE (normally dones as part of client unconfiguration):	

	modest.rb -K -M -P -d centos59vm01

Configure alternate repo as part of server setup:	

	modest.rb -K -S -R -n centos_5_9

Manually configure alternate repo:

	modest.rb -K -M -R -n centos_5_9

Manually unconfigure alternate repo (normally done as part of server unconfiguration):	

	modest.rb -K -M -R -z centos_5_9

Solaris Jumpstart Examples
==========================

Unconfigure Jumpstart service sol_11_!:              

	modest.rb -J -S -z sol_11_1

Configure Jumpstart services (if not repos exist, it will search /export/isos for valid repo isos to build repo):
         
	modest.rb -J -S

Manually configure Jumpstart client services only (for i386 - normally done as part of previous step):   

	modest.rb -J -M -C -a i386

Create Jumpstart client:

	modest.rb -J -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193

Create Jumpstart client (use default values):               

	modest.rb -J -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193 -D

Manually update Jumpstart proxy (normally done as part of configuring the server)

	modest.rb -J -M -W -n sol_11_1

Delete AI client:

	modest.rb -A -C -d sol11u01vm03

Session Examples
================

Configuring AI Server:

	# ./modest.rb -A -S -v
	Information:    Running in verbose mode
	Setting:        Work directory to /opt/modest
	Determining:    Default host IP
	Executing:      ipadm show-addr net0/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'
	Output:         192.168.1.191
	Getting:        default route
	Executing:      netstat -rn |grep default |awk '{print $2}'
	Output:         192.168.1.254
	Checking:       /etc/inet/dhcpd4.conf exists
	Archiving:      File /etc/inet/dhcpd4.conf to /etc/inet/dhcpd4.conf.preai
	Executing:      cp /etc/inet/dhcpd4.conf /etc/inet/dhcpd4.conf.preai
	Getting:        List of AI services
	Executing:      installadm list
	Output:         There are no services configured on this server.
	Checking:       If file based repository exists
	Executing:      pkg publisher |grep online |grep file |awk '{print $5}'
	Output:         file:///export/repo/sol_11_1/
	Locating:       Release file
	Executing:      cat /export/repo/sol_11_1//publisher/solaris/pkg/release%2Fname/* |grep 'release' |grep '^file' |head -1 |awk '{print $2}'
	Output:         9557cc47273a76106663d8c76bf8b7bdfaeb29f0
	Getting Release information
	Executing:      gzcat /export/repo/sol_11_1/publisher/solaris/file/95/9557cc47273a76106663d8c76bf8b7bdfaeb29f0 |head -1 |awk '{print $3}'
	Output:         11.1
	Checking:       /export/auto_install
	Executing:      svccfg -s pkg/server add sol_11_1
	Executing:      svccfg -s pkg/server:sol_11_1 addpg pkg application
	Executing:      svccfg -s pkg/server:sol_11_1 setprop pkg/port=10081
	Executing:      svccfg -s pkg/server:sol_11_1 setprop pkg/inst_root=/export/repo/sol_11_1/
	Executing:      svccfg -s pkg/server:sol_11_1 addpg general framework
	Executing:      svccfg -s pkg/server:sol_11_1 addpropvalue general/complete astring: sol_11_1
	Executing:      svccfg -s pkg/server:sol_11_1 addpropvalue general/enabled boolean: true
	Executing:      svccfg -s pkg/server:sol_11_1 setprop pkg/readonly=true
	Executing:      svccfg -s pkg/server:sol_11_1 setprop pkg/proxy_base = astring: http://192.168.1.191/sol_11_1
	Archiving:      /etc/apache2/2.2/httpd.conf to /etc/apache2/2.2/httpd.conf.no_sol_11_1
	Executing:      cp /etc/apache2/2.2/httpd.conf /etc/apache2/2.2/httpd.conf.no_sol_11_1
	Adding:         Proxy entry to /etc/apache2/2.2/httpd.conf
	Executing:      echo 'ProxyPass /sol_11_1 http://192.168.1.191:10081 nocanon max=200' >>/etc/apache2/2.2/httpd.conf
	Enable: Service apache22
	Executing:      svcadm enable apache22 ; sleep 5
	Refresh:        Service apache22
	Executing:      svcadm refresh apache22 ; sleep 5
	Creating:       AI services
	Creating:       AI service for i386
	Executing:      installadm create-service -a i386 -n sol_11_1_i386 -p solaris=http://192.168.1.191:10081 -d /export/auto_install/sol_11_1_i386
	Output:
	Creating service from: pkg:/install-image/solaris-auto-install
	 Startup: Caching catalogs ... Done
	 Startup: Refreshing catalog 'solaris' ... Done
	 Startup: Caching catalogs ... Done
	 Startup: Refreshing catalog 'solaris' ... Done
	Planning: Solver setup ... Done
	Planning: Running solver ... Done
	Planning: Finding local manifests ... Done
	Planning: Fetching manifests: 0/1  0% complete
	Planning: Fetching manifests: 1/1  100% complete
	Planning: Package planning ... Done
	Planning: Merging actions ... Done
	Planning: Checking for conflicting actions ... Done
	Planning: Consolidating action changes ... Done
	Planning: Evaluating mediators ... Done
	Planning: Planning completed in 0.18 seconds
	Download:   0/514 items    0.0/292.3MB  0% complete
	Download: Completed 292.27 MB in 3.67 seconds (79.6M/s)
	 Actions:   1/661 actions (Installing new actions)
	 Actions: Completed 661 actions in 3.59 seconds.
	Finalize: Updating package state database ...  Done
	Finalize: Updating image state ...  Done
	Finalize: Creating fast lookup database ...  Done
	Finalize: Reading search index ...  Done
	Finalize: Updating search index ...  Done
	Refreshing install services
	Refreshing install services

	Creating i386 service: sol_11_1_i386

	Image path: /export/auto_install/sol_11_1_i386


	Creating default-i386 alias

	Setting the default PXE bootfile(s) in the local DHCP configuration
	to:
	bios clients (arch 00:00):  default-i386/boot/grub/pxegrub2
	uefi clients (arch 00:07):  default-i386/boot/grub/grub2netx64.efi


	Creating:       AI service for sparc
	Executing:      installadm create-service -a sparc -n sol_11_1_sparc -p solaris=http://192.168.1.191:10081 -d /export/auto_install/sol_11_1_sparc
	Output:
	Creating service from: pkg:/install-image/solaris-auto-install
	 Startup: Caching catalogs ... Done
	 Startup: Refreshing catalog 'solaris' ... Done
	 Startup: Caching catalogs ... Done
	 Startup: Refreshing catalog 'solaris' ... Done
	Planning: Solver setup ... Done
	Planning: Running solver ... Done
	Planning: Finding local manifests ... Done
	Planning: Fetching manifests: 0/1  0% complete
	Planning: Fetching manifests: 1/1  100% complete
	Planning: Package planning ... Done
	Planning: Merging actions ... Done
	Planning: Checking for conflicting actions ... Done
	Planning: Consolidating action changes ... Done
	Planning: Evaluating mediators ... Done
	Planning: Planning completed in 0.17 seconds
	Download:  0/45 items    0.0/237.8MB  0% complete
	Download: Completed 237.76 MB in 2.36 seconds (100M/s)
	 Actions:   1/187 actions (Installing new actions)
	 Actions: Completed 187 actions in 2.34 seconds.
	Finalize: Updating package state database ...  Done
	Finalize: Updating image state ...  Done
	Finalize: Creating fast lookup database ...  Done
	Finalize: Reading search index ...  Done
	Finalize: Updating search index ...  Done
	Service discovery fallback mechanism set up
	Creating SPARC configuration file
	Refreshing install services
	Service discovery fallback mechanism set up
	Creating SPARC configuration file
	Refreshing install services
	
	Creating sparc service: sol_11_1_sparc
	
	Image path: /export/auto_install/sol_11_1_sparc
	

	Creating default-sparc alias

	Information:    Setting date string to Tue_Dec_24_01_46_39_UTC_2013
	Archiving:      File /etc/inet/dhcpd4.conf to /opt/modest/dhcpd4.conf.Tue_Dec_24_01_46_39_UTC_2013
	Executing:      cp /etc/inet/dhcpd4.conf /opt/modest/dhcpd4.conf.Tue_Dec_24_01_46_39_UTC_2013

	You will be presented with a set of questions followed by the default output
	If you are happy with the default output simply hit enter

	Determining:    If available repository version from http://192.168.1.191:10081
	Executing:      pkg info -g http://192.168.1.191:10081 entire |grep Branch |awk '{print $2}'
	Output:         0.175.1.0.0.24.2

	Reboot after installation? [ true ]
	Setting auto_reboot to true
	Publisher location? [ http://192.168.1.191:10081 ]
	Setting publisher_url to http://192.168.1.191:10081
	Solaris repository verstion? [ pkg:/entire@0.5.11-0.175.1 ]
	Setting repo_url to pkg:/entire@0.5.11-0.175.1
	Server install? [ pkg:/group/system/solaris-large-server ]
	Setting server_install to pkg:/group/system/solaris-large-server
	Determining:    Service name for i386
	Executing:      installadm list |grep -v default |grep 'i386' |awk '{print $1}'
	Output:         sol_11_1_i386
	Determining:    Service name for sparc
	Executing:      installadm list |grep -v default |grep 'sparc' |awk '{print $1}'
	Output:         sol_11_1_sparc
	Information:    Setting date string to Tue_Dec_24_01_50_31_UTC_2013
	Archiving:      Service configuration for sol_11_1_i386 to /opt/modest/sol_11_1_i386_orig_default.xml.Tue_Dec_24_01_50_31_UTC_2013
	Executing:      installadm export -n sol_11_1_i386 -m orig_default > /opt/modest/sol_11_1_i386_orig_default.xml.Tue_Dec_24_01_50_31_UTC_2013
	Validating:     Service configuration /opt/modest/sol_11_1_i386_ai_manifest.xml
	Executing:      AIM_MANIFEST=/opt/modest/sol_11_1_i386_ai_manifest.xml ; export AIM_MANIFEST ; aimanifest validate
	Importing:      /opt/modest/sol_11_1_i386_ai_manifest.xml to service sol_11_1_i386
	Executing:      installadm update-manifest -n sol_11_1_i386 -m orig_default -f /opt/modest/sol_11_1_i386_ai_manifest.xml
	Information:    Setting date string to Tue_Dec_24_01_50_32_UTC_2013
	Archiving:      Service configuration for sol_11_1_sparc to /opt/modest/sol_11_1_sparc_orig_default.xml.Tue_Dec_24_01_50_32_UTC_2013
	Executing:      installadm export -n sol_11_1_sparc -m orig_default > /opt/modest/sol_11_1_sparc_orig_default.xml.Tue_Dec_24_01_50_32_UTC_2013
	Validating:     Service configuration /opt/modest/sol_11_1_sparc_ai_manifest.xml
	Executing:      AIM_MANIFEST=/opt/modest/sol_11_1_sparc_ai_manifest.xml ; export AIM_MANIFEST ; aimanifest validate
	Importing:      /opt/modest/sol_11_1_sparc_ai_manifest.xml to service sol_11_1_sparc
	Executing:      installadm update-manifest -n sol_11_1_sparc -m orig_default -f /opt/modest/sol_11_1_sparc_ai_manifest.xml	

Creating an AI client:

	# ./modest.rb -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193 -v
	Information:    Running in verbose mode
	Setting:        Work directory to /opt/modest
	Determining:    Default host IP
	Executing:      ipadm show-addr net0/v4 |grep net |awk '{print $4}' |cut -f1 -d'/'
	Output:         192.168.1.191
	Information:    Setting client name to sol11u01vm03

	Root password? [ XXXX ]
	Setting root_password to $1$XPn/rJET$mu4tH731y2XFNhd.47bNy1
	Root account type? [ role ]
	Setting root_type to role
	Password expiry date (0 = next login)? [ 0 ]
	Setting root_expire to 0
	Account login name? [ sysadmin ]
	Setting account_login to sysadmin
	Account password? [ XXXX ]
	Setting account_password to $1$VTOWHh.l$1CEo00oRZ2kb3DT8GWCzL1
	Account description? [ System Administrator ]
	Setting account_description to System Administrator
	Account shell? [ /usr/bin/bash ]
	Setting account_shell to /usr/bin/bash
	Account UID? [ 101 ]
	Setting account_uid to 101
	Account GID? [ 10 ]
	Setting account_gid to 10
	Account type? [ normal ]
	Setting account_type to normal
	Account roles? [ root ]
	Setting account_roles to root
	Account profiles? [ System Administrator ]
	Setting account_profiles to System Administrator
	Account sudoers entry? [ ALL=(ALL) ALL ]
	Setting account_sudoers to ALL=(ALL) ALL
	Password expiry date (0 = next login)? [ 0 ]
	Setting account_expire to 0
	Hostname? [ sol11u01vm03 ]
	Setting system_identity to sol11u01vm03
	Terminal type? [ sun ]
	Setting system_console to sun
	System keymap? [ US-English ]
	Setting system_keymap to US-English
	System timezone? [ Australia/Victoria ]
	Setting system_timezone to Australia/Victoria
	System environment? [ en_US.UTF-8 ]
	Setting system_environment to en_US.UTF-8
	IPv4 interface name? [ net0/v4 ]
	Setting ipv4_interface_name to net0/v4
	IPv4 static address? [ 192.168.1.193 ]
	Setting ipv4_static_address to 192.168.1.193
	IPv4 default route? [ 192.168.1.254 ]
	Setting ipv4_default_route to 192.168.1.254
	IPv6 interface name? [ net0/v6 ]
	Setting ipv6_interface_name to net0/v6
	Nameserver? [ 8.8.8.8 ]
	Setting dns_nameserver to 8.8.8.8
	DNS search domain? [ local ]
	Setting dns_search to local
	DNS default lookup? [ files ]
	Setting dns_files to files
	DNS hosts lookup? [ files dns ]
	Setting dns_hosts to files dns
	Configuring client sol11u01vm03 with MAC address 00:50:56:26:92:d8
	Determining:    Service name for i386
	Executing:      installadm list |grep -v default |grep 'i386' |awk '{print $1}'
	Output:         sol_11_1_i386
	Creating:       Profile for client sol11u01vm03 with MAC address 00:50:56:26:92:d8
	Executing:      installadm create-profile -n sol_11_1_i386 -f /opt/modest/sol11u01vm03_ai_profile.xml -p sol11u01vm03 -c mac='00:50:56:26:92:d8'
	Profile sol11u01vm03 added to database.
	Creating:       Client entry for sol11u01vm03 with architecture i386 and MAC address 00:50:56:26:92:d8
	Executing:      installadm create-client -n sol_11_1_i386 -e 00:50:56:26:92:d8
	Output:         Adding host entry for 00:50:56:26:92:D8 to local DHCP configuration.
	
	Information:    Setting date string to Tue_Dec_24_01_53_17_UTC_2013
	Archiving:      File /etc/inet/dhcpd4.conf to /opt/modest/dhcpd4.conf.Tue_Dec_24_01_53_17_UTC_2013
	Executing:      cp /etc/inet/dhcpd4.conf /opt/modest/dhcpd4.conf.Tue_Dec_24_01_53_17_UTC_2013
	Refresh:        Service svc:/network/dhcp/server:ipv4
	Executing:      svcadm refresh svc:/network/dhcp/server:ipv4 ; sleep 5

XML Manifest Examples
=====================

The following are XML manifest examples for a Solaris 11 AI server.

Install service manifest (without alternate package repository):

	<!DOCTYPE auto_install SYSTEM "file:///usr/share/install/ai.dtd.1">
	<auto_install>
	  <ai_instance auto_reboot="true" name="orig_default">
	    <target>
	      <logical>
	        <zpool is_root="true" name="rpool">
	          <filesystem mountpoint="/export" name="export"/>
	          <filesystem name="export/home"/>
	          <be name="solaris"/>
	        </zpool>
	      </logical>
	    </target>
	    <software type="IPS">
	      <destination>
	        <image>
	          <facet set="false">facet.local.*</facet>
	          <facet set="true">facet.local.en</facet>
	          <facet set="true">facet.local.en_US</facet>
	        </image>
	      </destination>
	      <source>
	        <publisher name="solaris">
	          <origin name="http://192.168.1.191:10081"/>
	        </publisher>
	      </source>
	      <software_data action="install">
	        <name>pkg:/entire@0.5.11-0.175.1</name>
	        <name>pkg:/group/system/solaris-large-server</name>
	        <name>pkg:/runtime/ruby-18</name>
	      </software_data>
	    </software>
	  </ai_instance>
	</auto_install>

Install service manifest (without alternate package repository):

	<!DOCTYPE auto_install SYSTEM "file:///usr/share/install/ai.dtd.1">
	<auto_install>
	  <ai_instance auto_reboot="true" name="orig_default">
	    <target>
	      <logical>
	        <zpool name="rpool" is_root="true">
	          <filesystem mountpoint="/export" name="export"/>
	          <filesystem name="export/home"/>
	          <be name="solaris"/>
	        </zpool>
	      </logical>
	    </target>
	    <software type="IPS">
	      <destination>
	        <image>
	          <facet set="false">facet.local.*</facet>
	          <facet set="true">facet.local.en</facet>
	          <facet set="true">facet.local.en_US</facet>
	        </image>
	      </destination>
	      <source>
	        <publisher name="solaris">
	          <origin name="http://192.168.1.191:10081"/>
	        </publisher>
	      </source>
	      <software_data action="install">
	        <name>pkg:/entire@0.5.11-0.175.1</name>
	        <name>pkg:/group/system/solaris-large-server</name>
	        <name>pkg:/runtime/ruby-18</name>
	      </software_data>
	    </software>
	    <software type="IPS">
	      <destination>
	        <image>
	          <facet set="false">facet.local.*</facet>
	          <facet set="true">facet.local.en</facet>
	          <facet set="true">facet.local.en_US</facet>
	        </image>
	      </destination>
	      <source>
	        <publisher name="solaris">
	          <origin name="http://192.168.1.191:10082"/>
	        </publisher>
	      </source>
	      <software_data action="install">
	        <name>pkg:/application/puppet</name>
	      </software_data>
	    </software>
	  </ai_instance>
	</auto_install>

Client profile manifest:

	<!DOCTYPE service_bundle SYSTEM "/usr/share/lib/xml/dtd/service_bundle.dtd.1">
	<service_bundle type="profile" name="system configuration">
	  <service version="1" name="system/config-user">
	    <instance name="default" enabled="true">
	      <property_group name="root_account">
	        <propval type="astring" value="$1$HRkJyTBl$S4AJKT7PadiyD3.7Bmazr/" name="password"/>
	        <propval type="astring" value="role" name="type"/>
	        <propval type="astring" value="0" name="expire"/>
	      </property_group>
	      <property_group name="user_account">
	        <propval type="astring" value="sysadmin" name="login"/>
	        <propval type="astring" value="$1$v6T9cSV/$VDth0yo9S73ToBTSZ6yJs." name="password"/>
	        <propval type="astring" value="System Administrator" name="description"/>
	        <propval type="astring" value="/usr/bin/bash" name="shell"/>
	        <propval value="101" name="uid"/>
	        <propval value="10" name="gid"/>
	        <propval type="astring" value="normal" name="type"/>
	        <propval type="astring" value="root" name="roles"/>
	        <propval type="astring" value="System Administrator" name="profiles"/>
	        <propval type="astring" value="ALL=(ALL) ALL" name="sudoers"/>
	        <propval type="astring" value="0" name="expire"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="system/identity">
	    <instance name="node" enabled="true">
	      <property_group name="config">
	        <propval value="sol11u01vm03" name="nodename"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="system/console-login">
	    <instance name="default" enabled="true">
	      <property_group name="ttymon">
	        <propval value="sun" name="terminal_type"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="system/keymap">
	    <instance name="default" enabled="true">
	      <property_group name="keymap">
	        <propval value="US-English" name="layout"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="system/timezone">
	    <instance name="default" enabled="true">
	      <property_group name="timezone">
	        <propval value="Australia/Victoria" name="localtime"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="system/environment">
	    <instance name="default" enabled="true">
	      <property_group name="environment">
	        <propval value="en_US.UTF-8" name="LC_ALL"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="network/physical">
	    <instance name="default" enabled="true">
	      <property_group type="application" name="netcfg">
	        <propval type="astring" value="DefaultFixed" name="active_ncp"/>
	      </property_group>
	    </instance>
	  </service>
	  <service type="service" version="1" name="network/install">
	    <instance name="default" enabled="true">
	      <property_group type="application" name="install_ipv4_interface">
	        <propval type="astring" value="net0/v4" name="name"/>
	        <propval type="astring" value="static" name="address_type"/>
	        <propval type="net_address_v4" value="192.168.1.193" name="static_address"/>
	        <propval type="net_address_v4" value="192.168.1.254" name="default_route"/>
	      </property_group>
	      <property_group type="application" name="install_ipv6_interface">
	        <propval type="astring" value="net0/v6" name="name"/>
	        <propval type="astring" value="addrconf" name="address_type"/>
	        <propval type="astring" value="yes" name="stateless"/>
	        <propval type="astring" value="yes" name="stateful"/>
	      </property_group>
	    </instance>
	  </service>
	  <service version="1" name="network/dns/client">
	    <property_group name="config">
	      <property name="nameserver">
	        <net_address_list>
	          <value_node value="8.8.8.8"/>
	        </net_address_list>
	      </property>
	      <property name="search">
	        <astring_list>
	          <value_node value="local"/>
	        </astring_list>
	      </property>
	    </property_group>
	    <instance name="default" enabled="true"/>
	  </service>
	  <service version="1" name="system/name-service/switch">
	    <property_group name="config">
	      <propval value="files" name="default"/>
	      <propval value="files dns" name="host"/>
	    </property_group>
	    <instance name="default" enabled="true"/>
	  </service>
	</service_bundle>

Example Kickstart config:

	# kickstart file for centos59vm01 - modest 0.6.2
	text
	install
	cdrom
	url --url=http://192.168.1.191/centos_5_9
	lang en_US.UTF-8
	langsupport --default=en_US.UTF-8 en_US.UTF-8
	keyboard us
	network --device eth0 --bootproto static --ip 192.168.1.194 --netmask 255.255.255.0 --gateway 192.168.1.254 --nameserver 8.8.8.8 --hostname centos59vm01
	rootpw --iscrypted $1$W0QbHjDm$mgVU.lVRzN6KyWGzMLxxy1
	selinux --enforcing
	authconfig --enableshadow --enablemd5
	timezone Australia/Melbourne
	bootloader --location=mbr
	clearpart --all --drives=sda --initlabel
	part /boot --fstype ext3 --size=100 --ondisk=sda
	part pv.2 --size=0 --grow --ondisk=sda
	volgroup VolGroup00 --pesize=32768 pv.2
	logvol swap --fstype swap --name=LogVol01 --vgname=VolGroup00 --size=512 --grow --maxsize=1024
	logvol / --fstype ext3 --name=LogVol00 --vgname=VolGroup00 --size=1024 --grow
	reboot
	
	%packages
	@ core
	grub
	e2fsprogs
	lvm2
	kernel-devel
	kernel-headers
	libselinux-ruby
	tk

	%post
	groupadd wheel
	groupadd sysadmin
	useradd -p $1$36WEOLla$.kaa3v72sGfxpg34pYg051 -g sysadmin -G wheel -d /home/sysadmin -m sysadmin
	echo "sysadmin	ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
	mkdir /tmp/rpms
	cd /tmp/rpms
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-1.8.7.374-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-augeas-0.4.1-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-rgen-0.6.5-1.el5.noarch.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-shadow-1.4.1-7.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-libs-1.8.7.374-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/rubygem-json-1.5.5-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/augeas-libs-0.10.0-4.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/rubygems-1.3.7-1.el5.noarch.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-rdoc-1.8.7.374-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/ruby-irb-1.8.7.374-2.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/facter-1.7.4-1.el5.x86_64.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/hiera-1.3.0-1.el5.noarch.rpm
	wget http://192.168.1.191/export/repo/centos_5_9/alt/puppet-3.4.1-1.el5.noarch.rpm
	rpm -i *.rpm
	cd /tmp
	rm -rf /tmp/rpms

Example Jumpstart sysidcfg file:

	network_interface=e1000g0 { hostname=sol11u01vm03 default_route=192.168.1.254 ip_address=192.168.1.193 netmask=255.255.255.0 ipv6_protocol=no }
	timezone=Australia/Victoria
	system_locale C
	terminal=sun-cmd
	timeserver=localhost
	root_password=1l9UlhW5sssddd
	name_service=none
	nfsv4_domain=dynamic
	security_policy=none
	auto_reg=disable

Example Jumpstart machine file:

	install_type initial_install
	cluster SUNWcall
	partitioning explicit
	pool rpool auto auto auto any
	bootenv installbe bename sol_10_11_i386

Example Jumpstart rules file:

	karch i386 - machine.sol11u01vm03 -

