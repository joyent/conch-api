Description
===========
Installs ipmitool and allows for basic configuration of IPMI users and LAN settings through included LWRP.  Also includes an IPMI Ohai plugin that adds IPMI information to your node object.

Requirements
============
A compatible IPMI interface such as a Dell DRAC, Supermicro BMC or HP iLO (only actually tested on Dell and Supermicro)

### Chef
Chef version 0.10.10+ and Ohai 7.0.0+ are required.  Ohai 7 originally shipped with Chef 11.12.0 if you use Omnibus installers

### Platform
* Debian 6
* Ubuntu 10.04, 12.04
* Red Hat Enterprise Linux (CentOS/Scientific/Oracle) 5.X, 6.X
* FreeBSD

Attributes
==========
Users and LAN settings are configured on the node such as the example below from chef-solo `dna.json`

    "ipmi": {
      "users": {
        "3": {
          "username": "powerapi",
          "password": "sdj94jggsDF",
          "level": 4,
          "enable": "true"
        }
      },
      "lan": {
        "1": {
          "type": "static",
          "ipaddr": "172.30.0.50",
          "netmask": "255.255.255.0",
          "gateway": "172.30.0.1",
          "access": "true"
        }
      }
    }

The key for `user` is userid, for `lan` it is channel. The level attribute on users is the access level which are usually 1 - Callback, 2 - User, 3 - Operator, 4 - Administrator

Usage
=====

Include `Recipe[ipmi]` in your run list
