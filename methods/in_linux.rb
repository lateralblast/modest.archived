# Linux related services

def restart_linux_service(service)
  message = "Restarting\tService "+service
  command = "service #{service restart}"
  output  = execute_command(message,command)
  return output
end