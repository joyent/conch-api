#
# Cookbook Name:: ohai
# Plugin:: llpd
#
# "THE BEER-WARE LICENSE" (Revision 42):
# <john@dewey.ws> wrote this file. As long as you retain this notice you
# can do whatever you want with this stuff. If we meet some day, and you think
# this stuff is worth it, you can buy me a beer in return John-B Dewey Jr.
#

provides "linux/llpd" 

lldp Mash.new

def hashify h, list
  if list.size == 1
    return list.shift
  end 

  key    = list.shift
  h[key] ||= {}
  h[key] = hashify h[key], list
  h
end

begin
  cmd = "lldpctl -f keyvalue" 
  status, stdout, stderr = run_command(:command => cmd)

  stdout.split("\n").each do |element|
    key, value = element.split(/=/)
    elements = key.split(/\./)[1..-1].push value

    hashify lldp, elements
  end 

  lldp
rescue => e
  Chef::Log.warn "Ohai llpd plugin failed with: '#{e}'" 
end
