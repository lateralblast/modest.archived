
# Common routines for server and client configuration

# Question/config structure

Ks = Struct.new(:type, :question, :ask, :parameter, :value, :valid, :eval)

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

def build_ks_alt_rpm_list(service_name,client_arch)
  rpm_list = []
  base_url = "http://yum.puppetlabs.com/el/5/"
  dep_url  = base_url+"/dependencies/"+client_arch
  prod_url = base_url+"/products/"+client_arch
  if service_name.match(/[A-z]_[5,6]/)
    rpm_suffix    = "el5."+client_arch+".rpm"
    noarch_suffix = "el5.noarch.rpm"
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-augeas-0.4.1-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-rgen-0.6.5-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-shadow-1.4.1-8.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-libs-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/rubygem-json-1.5.5-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/augeas-libs-0.10.0-4.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/rubygems-1.3.7-1.#{noarch_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-rdoc-1.8.7.374-2.#{rpm_suffix}")
    rpm_list.push("#{dep_url}/#{client_arch}/ruby-irb-1.8.7.374-2.#{rpm_suffix}")
  end
  rpm_list.push("#{prod_url}/facter-#{$facter_version}-1.#{rpm_suffix}")
  hiera_url = prod_url.gsub(/x86_64/,"i386")
  rpm_list.push("#{hiera_url}/hiera-#{$hiera_version}-1.#{noarch_suffix}")
  rpm_list.push("#{prod_url}/puppet-#{$puppet_version}-1.#{noarch_suffix}")
  return rpm_list
end
