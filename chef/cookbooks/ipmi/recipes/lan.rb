include_recipe 'ipmi'

node['ipmi_cookbook']['lan'].each_pair do |channel, settings|
  ipmi_lan channel.to_i do
    ipaddr settings['ipaddr']
    netmask settings['netmask']
    gateway settings['gateway']
    type settings['type']
    if settings['access']
      action [:modify, :enable]
    else
      action [:modify, :disable]
    end
  end
end
