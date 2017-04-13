include_recipe 'ipmi'

node['ipmi_cookbook']['users'].each_pair do |id, user|
  ipmi_user id.to_i do
    username user['username']
    level user['level']
    password user['password']
    if user['enable']
      action [:modify, :enable]
    else
      action [:modify, :disable]
    end
  end
end
