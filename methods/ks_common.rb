
# Common routines for server and client configuration

# Question/config structure

Ks=Struct.new(:type, :question, :parameter, :value, :valid, :eval)

# Client Linux distribution

def check_linux_distro(linux_distro)
  if !linux_distro.match(/redhat|centos/)
    puts "Warning:\tNo Linux distribution given"
    puts "Use redhat or centos"
    exit
  end
  return
end

# Build alternate RPM list

def build_ks_alt_rpm_list(service_name)
  rpm_list=[]
  if service_name.match(/[A-z]_5/)
    base_url="http://yum.puppetlabs.com/el/5/products/x86_64"
    rpm_suffix="el5.x86_64.rpm"
    noarch_suffix="el5.noarch.rpm"
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-1.8.7.374-2.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-augeas-0.4.1-2.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-rgen-0.6.5-1.el5.noarch.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-shadow-1.4.1-7.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-libs-1.8.7.374-2.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/rubygem-json-1.5.5-2.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/augeas-libs-0.10.0-4.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/rubygems-1.3.7-1.el5.noarch.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-rdoc-1.8.7.374-2.el5.x86_64.rpm")
    rpm_list.push("http://yum.puppetlabs.com/el/5/dependencies/x86_64/ruby-irb-1.8.7.374-2.el5.x86_64.rpm")
  end
  if service_name.match(/[A-z]_6/)
    base_url="http://yum.puppetlabs.com/el/6/products/x86_64"
    rpm_suffix="el6.x86_64.rpm"
    noarch_suffix="el6.noarch.rpm"
  end
  rpm_list.push("#{base_url}/facter-#{$facter_version}-1.#{rpm_suffix}")
  hiera_url=base_url.gsub(/x86_64/,"i386")
  rpm_list.push("#{hiera_url}/hiera-#{$hiera_version}-1.#{noarch_suffix}")
  rpm_list.push("#{base_url}/puppet-#{$puppet_version}-1.#{noarch_suffix}")
  return rpm_list
end
