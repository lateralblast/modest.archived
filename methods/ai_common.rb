#!/usr/bin/env ruby

# Common routines for server and client configuration

# Question/config structure

Ai=Struct.new(:question, :value, :valid, :eval)

# Get the running repository version
# If running in test mode use a default version so client creation
# code can be tested

def get_repo_version(publisher_url,publisher_host,publisher_port)
  publisher_url=get_publisher_url(publisher_host,publisher_port)
  if $test_mode == 1
    repo_version="0.175.1"
  else
    message="Determining:\tIf available repository version from "+publisher_url
    command="pkg info -g #{publisher_url} entire |grep Branch |awk '{print $2}'"
    repo_version=execute_command(message,command)
    repo_version=repo_version.chomp
    repo_version=repo_version.split(/\./)[0..2].join(".")
  end
  return repo_version
end

# Get the repository URL

def get_repo_url(publisher_url,publisher_host,publisher_port)
  repo_version=get_repo_version(publisher_url,publisher_host,publisher_port)
  repo_url="pkg:/entire@0.5.11-"+repo_version
  return repo_url
end

# Get the publisher URL
# If running in test mode use the default Oracle one

def get_publisher_url(publisher_host,publisher_port)
  publisher_url="http://"+publisher_host+":"+publisher_port
  return publisher_url
end

def get_service_name(client_arch)
  message="Determining:\tService name for "+client_arch
  command="installadm list |grep -v default |grep '#{client_arch}' |awk '{print $1}'"
  service_name=execute_command(message,command)
  service_name=service_name.chomp
  return service_name
end

def get_service_base_name(service_name)
  service_base_name=service_name
  if service_base_name.match(/i386|sparc/)
    service_base_name=service_base_name.gsub(/i386/,"")
    service_base_name=service_base_name.gsub(/sparc/,"")
    service_base_name=service_base_name.gsub(/_$/,"")
  end
  return service_base_name
end
