#!/usr/bin/env ruby

# Populate array of structs containing AI manifest questions

def populate_ai_manifest_questions(publisher_host,publisher_port)
  q_struct={}
  q_order=[]

  name="auto_reboot"
  config=Ai.new(
    question  = "Reboot after installation",
    value     = "true",
    valid     = "true,false",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="publisher_url"
  publisher_url=get_publisher_url(publisher_host,publisher_port)
  config=Ai.new(
    question  = "Publisher URL",
    value     = publisher_url,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="server_install"
  config=Ai.new(
    question  = "Server install",
    value     = "pkg:/group/system/solaris-large-server",
    valid     = "pkg:/group/system/solaris-large-server,pkg:/group/system/solaris-small-server",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="repo_url"
  repo_url=get_repo_url(publisher_url,publisher_host,publisher_port)
  config=Ai.new(
    question  = "Solaris repository version",
    value     = repo_url,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="server_install"
  config=Ai.new(
    question  = "Server install",
    value     = "pkg:/group/system/solaris-large-server",
    valid     = "pkg:/group/system/solaris-large-server,pkg:/group/system/solaris-small-server",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  if $use_alt_repo == 1
    name="alt_publisher_url"
    alt_publisher_url=get_alt_publisher_url(publisher_host,publisher_port)
    config=Ai.new(
      question  = "Alternate publisher URL",
      value     = alt_publisher_url,
      valid     = "",
      eval      = "no"
      )
    q_struct[name]=config
    q_order.push(name)

    name="puppet_install"
    config=Ai.new(
      question  = "Puppet install",
      value     = "pkg:/application/puppet",
      valid     = "",
      eval      = "no"
      )
    q_struct[name]=config
    q_order.push(name)
  end

  return q_struct,q_order
end

# Populate array of structs with profile questions

def populate_ai_profile_questions(client_ip,client_name)
  q_struct={}
  q_order=[]

  name="root_password"
  config=Ai.new(
    question  = "Root password",
    value     = $default_root_password,
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  q_struct[name]=config
  q_order.push(name)

  name="root_type"
  config=Ai.new(
    question  = "Root account type",
    value     = "role",
    valid     = "role,normal",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="root_expire"
  config=Ai.new(
    question  = "Password expiry date (0 = next login)",
    value     = "0",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_login"
  config=Ai.new(
    question  = "Account login name",
    value     = "sysadmin",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_password"
  config=Ai.new(
    question  = "Account password",
    value     = $default_admin_password,
    valid     = "",
    eval      = "get_password_crypt(answer)"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_description"
  config=Ai.new(
    question  = "Account description",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_shell"
  vaild_shells=get_valid_shells()
  config=Ai.new(
    question  = "Account shell",
    value     = "/usr/bin/bash",
    valid     = vaild_shells,
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_uid"
  config=Ai.new(
    question  = "Account UID",
    value     = "101",
    valid     = "",
    eval      = "check_valid_uid(answer)"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_gid"
  config=Ai.new(
    question  = "Account GID",
    value     = "10",
    valid     = "",
    eval      = "check_valid_gid(answer)"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_type"
  config=Ai.new(
    question  = "Account type",
    value     = "normal",
    valid     = "normal,role",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_roles"
  config=Ai.new(
    question  = "Account roles",
    value     = "root",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_profiles"
  config=Ai.new(
    question  = "Account profiles",
    value     = "System Administrator",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_sudoers"
  config=Ai.new(
    question  = "Account sudoers entry",
    value     = "ALL=(ALL) ALL",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="account_expire"
  config=Ai.new(
    question  = "Password expiry date (0 = next login)",
    value     = "0",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="system_identity"
  config=Ai.new(
    question  = "Hostname",
    value     = client_name,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="system_console"
  config=Ai.new(
    question  = "Terminal type",
    value     = $default_terminal,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="system_keymap"
  config=Ai.new(
    question  = "System keymap",
    value     = $default_keymap,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="system_timezone"
  config=Ai.new(
    question  = "System timezone",
    value     = $default_timezone,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

name="system_environment"
  config=Ai.new(
    question  = "System environment",
    value     = $default_environment,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="ipv4_interface_name"
  config=Ai.new(
    question  = "IPv4 interface name",
    value     = "#{$default_net}/v4",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="ipv4_static_address"
  config=Ai.new(
    question  = "IPv4 static address",
    value     = client_ip,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="ipv4_default_route"
  ipv4_default_route=get_ipv4_default_route(client_ip)
    config=Ai.new(
    question  = "IPv4 default route",
    value     = ipv4_default_route,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="ipv6_interface_name"
    config=Ai.new(
    question  = "IPv6 interface name",
    value     = "#{$default_net}/v6",
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="dns_nameserver"
  config=Ai.new(
    question  = "Nameserver",
    value     = $default_nameserver,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="dns_search"
  config=Ai.new(
    question  = "DNS search domain",
    value     = $default_search,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="dns_files"
  config=Ai.new(
    question  = "DNS default lookup",
    value     = $default_files,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  name="dns_hosts"
    config=Ai.new(
    question  = "DNS hosts lookup",
    value     = $default_hosts,
    valid     = "",
    eval      = "no"
    )
  q_struct[name]=config
  q_order.push(name)

  return q_struct,q_order
end

# Process questions (array of structs)

def process_questions(q_struct,q_order)
  puts ""
  q_order.each do |key|
    correct=0
    while correct != 1 do
      if q_struct[key].value.match(/^get/)
        new_value=q_struct[key].value
        new_value=eval"[#{new_value}]"
        q_struct[key].value=new_value.join
      end
      if $use_defaults == 0
        print q_struct[key].question+"? [ "+q_struct[key].value+" ] "
        answer=gets.chomp
      else
        answer=q_struct[key].value
        if $verbose_mode == 1
          puts "Setting:\t"+q_struct[key].question+" to "+q_struct[key].value
          correct=1
        end
      end
      if answer != ""
        if answer != q_struct[key].value
          if q_struct[key].valid.match(/[A-z|0-9]/)
            if q_struct[key].valid.match(/#{answer}/)
              (correct,q_struct)=evaluate_answer(q_struct,key,answer)
            end
          else
            (correct,q_struct)=evaluate_answer(q_struct,key,answer)
          end
        end
      else
        answer=q_struct[key].value
        (correct,q_struct)=evaluate_answer(q_struct,key,answer)
        correct=1
      end
    end
  end
  return q_struct
end

