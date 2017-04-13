#
# Cookbook Name:: ipmi
# Attributes:: default
#

case node['platform_family']
when 'rhel'
  default['ipmi_cookbook']['packages']  = %w(OpenIPMI-tools freeipmi)
when 'debian'
  default['ipmi_cookbook']['packages']  = %w(ipmitool openipmi freeipmi-tools)
end

default['ipmi_cookbook']['kernel_modules'] = %w(ipmi_si ipmi_devintf ipmi_msghandler ipmi_watchdog)

default['ipmi_cookbook']['users'] = {}
default['ipmi_cookbook']['lan'] = {}
