# nimbusserver-ansible
All notable changes to this project will be documented in this file. The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)

# [2019.R1] - 2019-04-10

### Added
- nimbus-server-update to run ansible-pull and update the system

### Changed
- All file paths in nimbusserver.yml are now relative, enabling ansible-playbook and ansible-pull to run from any git clone

# [2018.09] - 2018-09-28

### Added
- Added docker-app
- Added nimbusapp script to support docker-app
- Added nimbus-docker-proxy script for setting up docker proxy settings

### Changed
- Build is now performed using Ansible and Packer
- Build is now under version control

### Removed
- LeanFT Viewer icon is now gone
- README.txt is now gone, in favour of quickstart.html

# [2018.05] - 2018-05-10

### Added
- Installed Filezilla, xRDP, Telnet client, dos2unix and exFAT utilities
- Added desktop icon for Firefox and System Monitor
- Enabled automatic login

### Changed
- Created new base image from CentOS-7-x86_64-DVD-1708.iso
- Configured maximum disk size of 300GB (user expandable)

# [2.01] - 2017-12-01

### Changed
- Disabled the firewall
- Removed aos.com domain from Jenkins Chrome bookmark

# [2.0] - 2017-10-15

### Added
- Added aos.com domain to Internet favorites

### Changed
- Configured and renamed Remote Desktop Viewer to LeanFT Viewer 