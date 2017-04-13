name             'ipmi'
maintainer       'Paul Thomas'
maintainer_email 'paul+github@paulthomas.eu'
license          'Apache 2.0'
description      'Installs/Configures ipmi'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.0.2'

%w(debian ubuntu freebsd redhat oracle scientific).each do |os|
  supports os
end

depends 'ohai'
