# Usage information

# Detailed usage

def print_examples(examples)
  puts
  if examples.match(/iso/)
    puts "Information related examples:"
    puts
    puts "List Linux ISOs:\t\t"+$script+" -K -S -I"
    puts "List Solaris 10 ISOs:\t\t"+$script+" -J -S -I"
    puts "List Solaris 11 ISOs:\t\t"+$script+" -A -S -I"
    puts
  end
  if examples.match(/vbox/)
    puts "Creating VirtualBox VM examples:"
    puts
    puts "Create KS (Linux) VM:\t\t\t"+$script+" -K -O -c centos510vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create PS (Linux) VM:\t\t\t"+$script+" -U -O -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create AY (Linux) VM:\t\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create JS (Solaris 10) VM:\t\t"+$script+" -J -O -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -O -c sol11u01vm03 -a i386 -e 00:50:56:26:92:D8"
    puts "Create VS (ESXi) VM:\t\t\t"+$script+" -E -O -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts
    puts "Deleting VirtualBox VM examples:"
    puts
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -O -d centos510vm01"
    puts "Delete JS (Solaris 10) VM:\t\t"+$script+" -O -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -O -d sol11u01vm03"
    puts "Delete VS (ESXi) VM:\t\t\t"+$script+" -O -d vmware55vm01"
    puts
    puts "Managing VirtualBox VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -O -b centos510vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -O -b centos510vm01 -B"
    puts "Boot non headless Linux VM:\t\t"+$script+" -O -b centos510vm01 -X"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -O -s centos510vm01"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -O -c centos510vm01 -e 00:50:56:34:4E:7A"
    puts
  end
  if examples.match(/fusion/)
    puts "Creating Kickstart VMware Fusion VM examples:"
    puts
    puts "Create KS (Linux) VM:\t\t\t"+$script+" -K -F -c centos510vm01 -a x86_64 -e 00:50:56:34:4E:7A"
    puts "Create KS (Linxu) VM:\t\t\t"+$script+" -K -F -c centos65vm01 -e 00:50:56:34:4E:7B -a x86_64"
    puts "Create KS (Linxu) VM:\t\t\t"+$script+" -K -F -c sl64vm01 -e 00:50:56:34:4E:FB -a x86_64"
    puts "Create KS (Linxu) VM:\t\t\t"+$script+" -K -F -c oel65vm01 -e 00:50:56:34:4E:BB -a x86_64"
    puts "Create KS (Linxu) VM:\t\t\t"+$script+" -K -F -c rhel63vm01 -e 00:50:56:34:4E:AA -a x86_64"
    puts
    puts "Creating other VMware Fusion VM examples:"
    puts
    puts "Create PS (Linux) VM:\t\t\t"+$script+" -U -F -c ubuntu1310vm01 -a x86_64 -e 08:00:27:BA:34:7C"
    puts "Create AY (Linux) VM:\t\t\t"+$script+" -Y -F -c sles11sp2vm01 -a x86_64 -e 08:00:27:BA:34:7D"
    puts "Create JS (Solaris 10) VM:\t\t"+$script+" -J -F -c sol10u11vm01 -a i386 -e 00:0C:29:FA:0C:7F"
    puts "Create AI (Solaris 11) VM:\t\t"+$script+" -A -F -c sol11u01vm03 -a i386 -e 00:50:56:26:92:D8"
    puts "Create VS (ESXi) VM:\t\t\t"+$script+" -E -F -c vmware55vm01 -e 08:00:27:61:B7:AD"
    puts "Create NT (Windows) VM:\t\t\t"+$script+" -N -F -c win2008r2vm01 -e 08:00:27:61:B7:AF"
    puts
    puts "Deleting VMware Fusion VM examples:"
    puts
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -F -d centos510vm01"
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -F -d centos65vm01"
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -F -d sl64vm01"
    puts "Delete KS (Linux) VM:\t\t\t"+$script+" -F -d rhel63vm01"
    puts "Delete JS (Solaris 10) VM:\t\t"+$script+" -F -d sol10u11vm01"
    puts "Delete AI (Solaris 11) VM:\t\t"+$script+" -F -d sol11u01vm03"
    puts "Delete VS (ESXi) VM:\t\t\t"+$script+" -F -d vmware55vm01"
    puts
    puts "Managing VMware Fusion VM examples:"
    puts
    puts "Boot headless Linux VM:\t\t\t"+$script+" -F -b centos510vm01"
    puts "Boot headless serial enabled Linux VM:\t"+$script+" -F -b centos510vm01 -B"
    puts "Boot non headless Linux VM:\t\t"+$script+" -F -b centos510vm01 -X"
    puts "Halt Linux VM:\t\t\t\t"+$script+" -F -s centos510vm01"
    puts "Boot Windows VM:\t\t\t"+$script+" -F -b win2008r2vm01 -X"
    puts "Modify VM MAC Address:\t\t\t"+$script+" -F -c centos510vm01 -e 00:50:56:34:4E:7A"
    puts
  end
  if examples.match(/server|ai/)
    puts "AI server related examples:"
    puts
    puts "List AI services:\t\t"+$script+" -A -S -L"
    puts "Configure all AI services:\t"+$script+" -A -S"
    puts "Unconfigure AI service:\t\t"+$script+" -A -S -z sol_11_1"
    puts
  end
  if examples.match(/server|ks/)
    puts "Kickstart server related examples:"
    puts
    puts "List KS services:\t\t"+$script+" -K -S -L"
    puts "List KS ISOs:\t\t\t"+$script+" -K -S -I"
    puts "Configure KS services:\t\t"+$script+" -K -S"
    puts "Unconfigure KS service:\t\t"+$script+" -K -S -z centos_5_10_i386"
    puts "Delete KS service:\t\t"+$script+" -K -S -z centos_5_10_i386 -y"
    puts
  end
  if examples.match(/server|ay/)
    puts "AutoYast server related examples:"
    puts
    puts "List AY services:\t\t\t"+$script+" -Y -S -L"
    puts "Configure AY services:\t\t\t"+$script+" -Y -S"
    puts "Configure a AY service (from ISO):\t"+$script+" -Y -S -f /export/isos/SLES-11-SP2-DVD-x86_64-GM-DVD1.iso"
    puts
  end
  if examples.match(/server|ps/)
    puts "Preseed server related examples:"
    puts
    puts "List all PS services:\t\t\t"+$script+" -U -S -L"
    puts "Configure all PS services:\t\t"+$script+" -U -S"
    puts "Configure a PS service (from ISO):\t"+$script+" -U -S -f /export/isos/ubuntu-13.10-server-amd64.iso"
    puts
  end
  if examples.match(/server|js/)
    puts "Preseed server related examples:"
    puts
    puts "List JS services:\t\t"+$script+" -J -S -L"
    puts "Configure JS services:\t\t"+$script+" -J -S"
    puts "Unconfigure JS service:\t\t"+$script+" -J -S -z sol_10_11"
    puts
  end
  if examples.match(/maint/)
    puts "Maintenance related examples:"
    puts
    puts "Configure AI client services:\t"+$script+" -A -G -C -a i386"
    puts "Enable AI proxy:\t\t"+$script+" -A -G -W -n sol_11_1"
    puts "Disable AI proxy:\t\t"+$script+" -A -G -W -z sol_11_1"
    puts "Configure AI alternate repo:\t"+$script+" -A -G -R"
    puts "Unconfigure AI alternate repo:\t"+$script+" -A -G -R -z sol_11_1_alt"
    puts "Configure KS alternate repo:\t"+$script+" -K -G -R -n centos_5_10_x86_64"
    puts "Unconfigure KS alternate repo:\t"+$script+" -K -G -R -z centos_5_10_x86_64"
    puts "Enable KS alias:\t\t"+$script+" -K -G -W -n centos_5_10_x86_64"
    puts "Disable KS alias:\t\t"+$script+" -K -G -W -z centos_5_10_x86_64"
    puts "Import KS PXE files:\t\t"+$script+" -K -G -P -n centos_5_10_x86_64"
    puts "Delete KS PXE files:\t\t"+$script+" -K -G -P -z centos_5_10_x86_64"
    puts "Unconfigure KS client PXE:\t"+$script+" -K -G -P -d centos510vm01"
    puts
  end
  if examples.match(/zone/)
    puts "Solaris Zone related examples:"
    puts
    puts "List Zones:\t\t\t"+$script+" -Z -L"
    puts "Configure Zone:\t\t\t"+$script+" -Z -c sol11u01z01 -i 192.168.1.181"
    puts "Configure Branded Zone:\t\t"+$script+" -Z -c sol10u11z01 -i 192.168.1.171 -f /export/isos/solaris-10u11-x86.bin"
    puts "Configure Branded Zone:\t\t"+$script+" -Z -c sol10u11z02 -i 192.168.1.172 -n sol_10_11_i386"
    puts "Delete Zone:\t\t\t"+$script+" -Z -d sol11u01z01"
    puts "Boot Zone:\t\t\t"+$script+" -Z -b sol11u01z01"
    puts "Boot Zone (connect to console):\t"+$script+" -Z -b sol11u01z01 -B"
    puts "Halt Zone:\t\t\t"+$script+" -Z -s sol11u01z01"
    puts
  end
  if examples.match(/ldom/)
    puts "Oracle VM Server for SPARC related examples:"
    puts
    puts "Configure Control Domain:\t\t"+$script+" -O -S"
    puts "List Guest Domains:\t\t\t"+$script+" -O -L"
    puts "Configure Guest Domain:\t\t\t"+$script+" -O -c sol11u01gd01"
    puts
  end
  if examples.match(/lxc/)
    puts "Linux Container related examples:"
    puts
    puts "Configure Container Services:\t\t"+$script+" -Z -S"
    puts "List Containers:\t\t\t"+$script+" -Z -L"
    puts "Configure Standard Container:\t\t"+$script+" -Z -c ubuntu1310lx01 -i 192.168.1.206"
    puts "Execute post install script:\t\t"+$script+" -Z -p ubuntu1310lx01"
    puts
  end
  if examples.match(/client|ks/)
    puts "Kickstart client creation related examples:"
    puts
    puts "List KS clients:\t\t"+$script+" -K -C -L"
    puts "Create KS client:\t\t"+$script+" -K -C -c centos510vm01 -e 00:50:56:34:4E:7A -a x86_64 -i 192.168.1.194 -n centos_5_10_x86_64"
    puts "Create KS client:\t\t"+$script+" -K -C -c centos65vm01 -e 00:50:56:34:4E:7B -a x86_64 -i 192.168.1.184 -n centos_6_5_x86_64"
    puts "Create KS client:\t\t"+$script+" -K -C -c sl64vm01 -e 00:50:56:34:4E:FB -a x86_64 -i 192.168.1.185 -n sl_6_4_x86_64"
    puts "Create KS client:\t\t"+$script+" -K -C -c oel65vm01 -e 00:50:56:34:4E:BB -a x86_64 -i 192.168.1.186 -n oel_6_5_x86_64"
    puts "Create KS client:\t\t"+$script+" -K -C -c rhel63vm01 -e 00:50:56:34:4E:AA -a x86_64 -i 192.168.1.187 -n rhel_6_3_x86_64"
    puts "Configure KS client PXE:\t"+$script+" -K -P -c centos510vm01 -e 00:50:56:34:4E:7A -i 192.168.1.194 -n centos_5_10_x86_64"
    puts
    puts "Kickstart client deletion related examples:"
    puts
    puts "Delete KS client:\t\t"+$script+" -K -C -d centos510vm01"
    puts "Delete KS client:\t\t"+$script+" -K -C -d centos65vm01"
    puts "Delete KS client:\t\t"+$script+" -K -C -d sl64vm01"
    puts "Delete KS client:\t\t"+$script+" -K -C -d oel65vm01"
    puts
  end
  if examples.match(/client|ai/)
    puts "AI client related examples:"
    puts
    puts "List AI clients:\t\t"+$script+" -A -C -L"
    puts "Create AI client:\t\t"+$script+" -A -C -c sol11u01vm03 -e 00:50:56:26:92:d8 -a i386 -i 192.168.1.193"
    puts "Delete AI client:\t\t"+$script+" -A -C -d sol11u01vm03"
    puts
  end
  if examples.match(/client|ps/)
    puts "Preseed client related examples:"
    puts
    puts "List PS clients:\t\t\t"+$script+" -U -C -L"
    puts "Create PS client:\t\t\t"+$script+" -U -C -c ubuntu1310vm01 -e 08:00:27:BA:34:7C -a x86_64 -i 192.168.1.196 -n ubuntu_13_10_x86_64"
    puts "Delete PS client:\t\t\t"+$script+" -U -C -d ubuntu1310vm01"
    puts
  end
  if examples.match(/client|js/)
    puts "Jumpstart client related examples:"
    puts
    puts "List JS clients:\t\t"+$script+" -J -C -L"
    puts "Create JS client:\t\t"+$script+" -J -C -c sol10u11vm01 -e 00:0C:29:FA:0C:7F -a i386 -i 192.168.1.195 -n sol_10_11"
    puts "Delete JS client:\t\t"+$script+" -J -C -d sol10u11vm01"
    puts
  end
  if examples.match(/client|ay/)
    puts "AutoYast client related examples:"
    puts
    puts "List AY clients:\t\t\t"+$script+" -Y -C -L"
    puts "Create AY client:\t\t\t"+$script+" -Y -C -c sles11sp2vm01 -e 08:00:27:BA:34:7D -a x86_64 -i 192.168.1.197 -n sles_11_2_x86_64"
    puts "Delete AY client:\t\t\t"+$script+" -Y -C -d sles11sp2vm01"
    puts
  end
  if examples.match(/client|vs/)
    puts "ESX/VSphere client related examples:"
    puts
    puts "List VS clients:\t\t"+$script+" -E -C -L"
    puts "Create VS client:\t\t"+$script+" -E -C -c vmware55vm01 -e 08:00:27:61:B7:AD -i 192.168.1.195 -n vmware_5_5_0_x86_64"
    puts "Delete VS client:\t\t"+$script+" -E -C -d vmware55vm01"
    puts
  end
  exit
end
