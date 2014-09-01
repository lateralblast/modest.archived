# Usage information

# Detailed usage

def print_examples(examples)
  puts
  if examples.match(/iso|all/)
    puts "Information related examples:"
    puts
    puts "List Linux ISOs:\t\t\t"+$script+" -K -S -I"
    puts "List Solaris 10 ISOs:\t\t\t"+$script+" -J -S -I"
    puts "List Solaris 11 ISOs:\t\t\t"+$script+" -A -S -I"
    puts
  end
  if examples.match(/vbox|all/)
    puts "Creating VirtualBox VM examples:"
    puts
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -O -c centos510vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create Preseed (Linux) VM:\t\t"+$script+" -U -O -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create Autoyast (Linux) VM:\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create Jumpstart (Solaris 10) VM:\t"+$script+" -J -O -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -O -c sol11u01vm03 -a i386 -e 00:50:56:26:92:D8"
    puts "Create vSphere (ESXi) VM:\t\t"+$script+" -E -O -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts "Create OpenBSD VM:\t\t\t"+$script+" -B -O -c openbsd55vm01 -a x86_64 -e 08:00:27:61:B7:AA"
    puts "Create NetBSD VM:\t\t\t"+$script+" -N -O -c netbsd10vm01 -a x86_64 -e 08:00:27:61:B7:AB"
    puts
    puts "Deleting VirtualBox VM examples:"
    puts
    puts "Delete Kickstart (Linux) VM:\t\t"+$script+" -O -d centos510vm01"
    puts "Delete Jumpstart (Solaris 10) VM:\t"+$script+" -O -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -O -d sol11u01vm03"
    puts "Delete vSphere (ESXi) VM:\t\t"+$script+" -O -d vmware55vm01"
    puts
    puts "Managing VirtualBox VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -O -b centos510vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -O -b centos510vm01 -2"
    puts "Boot non headless Linux VM:\t\t"+$script+" -O -b centos510vm01 -X"
    puts "Connect to serial port of running VM:\t"+$script+" -O -p centos510vm01"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -O -s centos510vm01"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -O -c centos510vm01 -e 00:50:56:34:4E:7A"
    puts "Check VirtualBox Configuration:\t\t"+$script+" -G -O"
    puts "List running VirtualBox VMs:\t\t"+$script+" -O -R"
    puts
  end
  if examples.match(/fusion|all/)
    puts "Creating Kickstart VMware Fusion VM examples:"
    puts
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c centos510vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c centos65vm01 -e 00:50:56:34:4E:7B -a x86_64"
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c sl64vm01 -e 00:50:56:34:4E:FB -a x86_64"
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c oel65vm01 -e 00:50:56:34:4E:BB -a x86_64"
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c rhel63vm01 -e 00:50:56:34:4E:AA -a x86_64"
    puts "Create Kickstart (Linux) VM:\t\t"+$script+" -K -F -c fedora20vm01 -e 00:50:56:34:4E:AB -a x86_64"
    puts
    puts "Creating other VMware Fusion VM examples:"
    puts
    puts "Create Preseed (Linux) VM:\t\t"+$script+" -U -F -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create Autoyast (Linux) VM:\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create Jumpstart (Solaris 10) VM:\t"+$script+" -J -F -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -F -c sol11u01vm03 -e 00:50:56:26:92:D8"
    puts "Create vSphere (ESXi) VM:\t\t"+$script+" -E -F -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts "Create NT (Windows) VM:\t\t\t"+$script+" -W -F -c win2008r2vm01 -e 08:00:27:61:B7:AF"
    puts "Create OpenBSD VM:\t\t\t"+$script+" -B -F -c openbsd55vm01 -e 08:00:27:61:B7:AA"
    puts "Create NetBSD VM:\t\t\t"+$script+" -N -F -c netbsd10vm01 -e 08:00:27:61:B7:AB"
    puts
    puts "Deleting VMware Fusion VM examples:"
    puts
    puts "Delete Kickstart (Linux) VM:\t\t"+$script+" -F -d centos510vm01"
    puts "Delete Kickstart (Linux) VM:\t\t"+$script+" -F -d centos65vm01"
    puts "Delete Kickstart (Linux) VM:\t\t"+$script+" -F -d sl64vm01"
    puts "Delete Kickstart (Linux) VM:\t\t"+$script+" -F -d rhel63vm01"
    puts "Delete Jumpstart (Solaris 10) VM:\t"+$script+" -F -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -F -d sol11u01vm03"
    puts "Delete vSphere (ESXi) VM:\t\t"+$script+" -F -d vmware55vm01"
    puts
    puts "Managing VMware Fusion VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -F -b centos510vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -F -b centos510vm01 -2"
    puts "Boot non headless Linux VM:\t\t"+$script+" -F -b centos510vm01 -X"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -F -s centos510vm01"
    puts "Boot Windows VM:\t\t\t"+$script+" -F -b win2008r2vm01 -X"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -F -c centos510vm01 -e 00:50:56:34:4E:7A"
    puts
  end
  if examples.match(/server|ai|all/)
    puts "AI server related examples:"
    puts
    puts "List AI services:\t\t\t"+$script+" -A -S -L"
    puts "Configure all AI services:\t\t"+$script+" -A -S"
    puts "Unconfigure AI service:\t\t\t"+$script+" -A -S -z sol_11_1"
    puts
  end
  if examples.match(/server|ks|all/)
    puts "Kickstart server related examples:"
    puts
    puts "List Kickstart services:\t\t"+$script+" -K -S -L"
    puts "List Kickstart ISOs:\t\t\t"+$script+" -K -S -I"
    puts "Configure Kickstart services:\t\t"+$script+" -K -S"
    puts "Configure Kickstart service (from ISO):\t"+$script+" -K -S -f /export/isos/Fedora-20-x86_64-DVD.iso"
    puts "Unconfigure Kickstart service:\t\t"+$script+" -K -S -z centos_5_10_i386"
    puts "Delete Kickstart service:\t\t"+$script+" -K -S -z centos_5_10_i386 -y"
    puts
  end
  if examples.match(/server|ay|all/)
    puts "AutoYast server related examples:"
    puts
    puts "List Autoyast services:\t\t\t"+$script+" -Y -S -L"
    puts "Configure Autoyast services:\t\t"+$script+" -Y -S"
    puts "Configure Autoyast service (from ISO):\t"+$script+" -Y -S -f /export/isos/SLES-11-SP2-DVD-x86_64-GM-DVD1.iso"
    puts
  end
  if examples.match(/server|ps|all/)
    puts "Preseed server related examples:"
    puts
    puts "List all Preseed services:\t\t"+$script+" -U -S -L"
    puts "Configure all Preseed services:\t\t"+$script+" -U -S"
    puts "Configure a Preseed service (from ISO):\t"+$script+" -U -S -f /export/isos/ubuntu-13.10-server-amd64.iso"
    puts
  end
  if examples.match(/server|xb|ob|nb|all/)
    puts "*BSD server related examples:"
    puts
    puts "List all *BSD services:\t\t\t"+$script+" -B -S -L"
    puts "Configure all *BSD services:\t\t"+$script+" -B -S"
    puts "Configure a NetBSD service (from ISO):\t"+$script+" -B -S -f /export/isos/install55-i386.iso"
    puts "Configure a FreeBSD service (from ISO):\t"+$script+" -B -S -f /export/isos/FreeBSD-10.0-RELEASE-amd64-dvd1.iso"
    puts
  end
  if examples.match(/server|js|all/)
    puts "Jumpstart server related examples:"
    puts
    puts "List Jumpstart services:\t\t"+$script+" -J -S -L"
    puts "Configure Jumpstart services:\t\t"+$script+" -J -S"
    puts "Unconfigure Jumpstart service:\t\t"+$script+" -J -S -z sol_10_11"
    puts
  end
  if examples.match(/server|vs|all/)
    puts "ESX/vSphere server related examples"
    puts
    puts "List vSphere ISOs:\t\t\t"+$script+" -E -S -I"
    puts "List vSphere services:\t\t\t"+$script+" -E -S -L"
    puts "Configure all vSphere services:\t\t"+$script+" -E -S"
    puts "Configure vSphere service (from ISO):\t"+$script+" -E -S -f /export/isos/VMware-VMvisor-Installer-5.5.0.update01-1623387.x86_64.iso"
    puts
  end
  if examples.match(/maint|all/)
    puts "Maintenance related examples:"
    puts
    puts "Configure AI client services:\t\t"+$script+" -A -G -C -a i386"
    puts "Enable AI proxy:\t\t\t"+$script+" -A -G -W -n sol_11_1"
    puts "Disable AI proxy:\t\t\t"+$script+" -A -G -W -z sol_11_1"
    puts "Configure AI alternate repo:\t\t"+$script+" -A -G -R"
    puts "Unconfigure AI alternate repo:\t\t"+$script+" -A -G -R -z sol_11_1_alt"
    puts "Configure Kickstart alternate repo:\t"+$script+" -K -G -R -n centos_5_10_x86_64"
    puts "Unconfigure Kickstart alternate repo:\t"+$script+" -K -G -R -z centos_5_10_x86_64"
    puts "Enable Kickstart alias:\t\t\t"+$script+" -K -G -W -n centos_5_10_x86_64"
    puts "Disable Kickstart alias:\t\t"+$script+" -K -G -W -z centos_5_10_x86_64"
    puts "Import Kickstart PXE files:\t\t"+$script+" -K -G -P -n centos_5_10_x86_64"
    puts "Delete Kickstart PXE files:\t\t"+$script+" -K -G -P -z centos_5_10_x86_64"
    puts "Unconfigure Kickstart client PXE:\t"+$script+" -K -G -P -d centos510vm01"
    puts
  end
  if examples.match(/zone|all/)
    puts "Solaris Zone related examples:"
    puts
    puts "List Zones:\t\t\t\t"+$script+" -Z -L"
    puts "Configure Zone:\t\t\t\t"+$script+" -Z -c sol11u01z01 -i 192.168.1.181"
    puts "Configure Branded Zone:\t\t\t"+$script+" -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin"
    puts "Configure Branded Zone:\t\t\t"+$script+" -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386"
    puts "Delete Zone:\t\t\t\t"+$script+" -Z -d sol11u01z01"
    puts "Boot Zone:\t\t\t\t"+$script+" -Z -b sol11u01z01"
    puts "Boot Zone (connect to console):\t\t"+$script+" -Z -b sol11u01z01 -B"
    puts "Halt Zone:\t\t\t\t"+$script+" -Z -s sol11u01z01"
    puts
  end
  if examples.match(/ldom|all/)
    puts "Oracle VM Server for SPARC related examples:"
    puts
    puts "Configure Control Domain:\t\t"+$script+" -O -S"
    puts "List Guest Domains:\t\t\t"+$script+" -O -L"
    puts "Configure Guest Domain:\t\t\t"+$script+" -O -c sol11u01gd01"
    puts
  end
  if examples.match(/lxc|all/)
    puts "Linux Container related examples:"
    puts
    puts "Configure Container Services:\t\t"+$script+" -Z -S"
    puts "List Containers:\t\t\t"+$script+" -Z -L"
    puts "Configure Standard Container:\t\t"+$script+" -Z -c ubuntu1310lx01 -i 192.168.1.206"
    puts "Execute post install script:\t\t"+$script+" -Z -p ubuntu1310lx01"
    puts
  end
  if examples.match(/client|ks|all/)
    puts "Kickstart client creation related examples:"
    puts
    puts "List Kickstart clients:\t\t\t"+$script+" -K -C -L"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c centos510vm01 -e 00:50:56:34:4E:7A -a x86_64 -i 192.168.1.194 -n centos_5_10_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c centos65vm01 -e 00:50:56:34:4E:7B -a x86_64 -i 192.168.1.184 -n centos_6_5_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c sl64vm01 -e 00:50:56:34:4E:FB -a x86_64 -i 192.168.1.185 -n sl_6_4_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c oel65vm01 -e 00:50:56:34:4E:BB -a x86_64 -i 192.168.1.186 -n oel_6_5_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c rhel63vm01 -e 00:50:56:34:4E:AA -a x86_64 -i 192.168.1.187 -n rhel_6_3_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c rhel70vm01 -e 00:50:56:34:4E:AB -a x86_64 -i 192.168.1.188 -n rhel_7_0_x86_64"
    puts "Create Kickstart client:\t\t"+$script+" -K -C -c fedora20vm01 -e 00:50:56:34:4E:AC -a x86_64 -i 192.168.1.189 -n fedora_20_x86_64"
    puts
    puts "Kickstart client modification examples:"
    puts
    puts "Configure Kickstart client PXE:\t\t"+$script+" -K -P -c centos510vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_10_x86_64"
    puts
    puts "Kickstart client deletion related examples:"
    puts
    puts "Delete Kickstart client:\t\t"+$script+" -K -C -d centos510vm01"
    puts "Delete Kickstart client:\t\t"+$script+" -K -C -d centos65vm01"
    puts "Delete Kickstart client:\t\t"+$script+" -K -C -d sl64vm01"
    puts "Delete Kickstart client:\t\t"+$script+" -K -C -d oel65vm01"
    puts
  end
  if examples.match(/client|ai|all/)
    puts "AI client related examples:"
    puts
    puts "List AI clients:\t\t\t"+$script+" -A -C -L"
    puts "Create AI client:\t\t\t"+$script+" -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
    puts "Delete AI client:\t\t\t"+$script+" -A -C -d sol11u01vm03"
    puts
  end
  if examples.match(/client|xb|ob|nb|all/)
    puts "*BSD client related examples:"
    puts
    puts "List *BSD clients:\t\t\t"+$script+" -B -C -L"
    puts "Create OpenBSD client:\t\t\t"+$script+" -B -C -c openbsd55vm01 -e 00:50:56:26:92:d8 -a x86_64 -i 192.168.1.193 -n openbsd_5_5_x86_64"
    puts "Create FreeBSD client:\t\t\t"+$script+" -B -C -c freebsd10vm01 -e 00:50:56:26:92:d7 -a x86_64 -i 192.168.1.194 -n netbsd_10_0_x86_64"
    puts "Delete FreeBSD client:\t\t\t"+$script+" -B -C -d freebsd10vm01"
    puts
  end
  if examples.match(/client|ps|all/)
    puts "Preseed client related examples:"
    puts
    puts "List Preseed clients:\t\t\t"+$script+" -U -C -L"
    puts "Create Preseed client:\t\t\t"+$script+" -U -C -c ubuntu1310vm01 -e 08:00:27:BA:34:7C -a x86_64 -i 192.168.1.196 -n ubuntu_13_10_x86_64"
    puts "Delete Preseed client:\t\t\t"+$script+" -U -C -d ubuntu1310vm01"
    puts
  end
  if examples.match(/client|js|all/)
    puts "Jumpstart client related examples:"
    puts
    puts "List Jumpstart clients:\t\t\t"+$script+" -J -C -L"
    puts "Create Jumpstart client:\t\t"+$script+" -J -C -c sol10u11vm01 -e 00:0C:29:FA:0C:7F -a i386 -i 192.168.1.195 -n sol_10_11"
    puts "Delete Jumpstart client:\t\t"+$script+" -J -C -d sol10u11vm01"
    puts
  end
  if examples.match(/client|ay|all/)
    puts "AutoYast client related examples:"
    puts
    puts "List Autoyast clients:\t\t\t"+$script+" -Y -C -L"
    puts "Create Autoyast client:\t\t\t"+$script+" -Y -C -c sles11sp2vm01 -e 08:00:27:BA:34:7D -a x86_64 -i 192.168.1.197 -n sles_11_2_x86_64"
    puts "Delete Autoyast client:\t\t\t"+$script+" -Y -C -d sles11sp2vm01"
    puts
  end
  if examples.match(/client|vs|all/)
    puts "ESX/vSphere client related examples:"
    puts
    puts "List vSphere clients:\t\t\t"+$script+" -E -C -L"
    puts "Create vSphere client:\t\t\t"+$script+" -E -C -c vmware55vm01 -e 08:00:27:61:B7:AD -i 192.168.1.195 -n vmware_5_5_0_x86_64"
    puts "Delete vSphere client:\t\t\t"+$script+" -E -C -d vmware55vm01"
    puts
  end
  exit
end
