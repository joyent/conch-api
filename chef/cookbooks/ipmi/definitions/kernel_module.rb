# A chef definition for installing kernel modules on ubuntu/debian.
# Thanks to mikehale https://gist.github.com/181044

define :kernel_module, :action => :install do
  if params[:action] == :install
    bash "modprobe #{params[:name]}" do
      code "modprobe #{params[:name]}"
      not_if "lsmod |grep #{params[:name]}"
    end

    bash "install #{params[:name]} in /etc/modules" do
      code "echo '#{params[:name]}' >> /etc/modules"
      not_if "grep '^#{params[:name]}$' /etc/modules"
    end
  end
end
