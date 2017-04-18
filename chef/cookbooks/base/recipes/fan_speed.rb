if node[:dmi][:system][:product] == "Joyent-Compute-Platform-3301" || node[:dmi][:system][:product] == "Joyent-Compute-Platform-3302"
  execute "set_fan_speed" do
    command "/bin/racadm set system.thermalsettings.FanSpeedOffset 1"
  end
end

if node[:dmi][:system][:product] == "Joyent-Storage-Platform-7001" || node[:dmi][:system][:product] == "Joyent-Storage-Platform-7201"
  execute "set_fan_speed" do
    command "ipmitool raw 0x30 0x45 1 1"
  end
end
