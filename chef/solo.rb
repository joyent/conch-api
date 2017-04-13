cookbook_path "/var/chef/cookbooks"
file_cache_path "/tmp/chef"
node_path "/tmp/chef/nodes"
ohai.disabled_plugins = ["Packages"]
ohai.plugin_path = ["/etc/chef/ohai_plugins", "/opt/chef/embedded/lib/ruby/gems/2.3.0/gems/ohai-8.23.0/lib/ohai/plugins"]
