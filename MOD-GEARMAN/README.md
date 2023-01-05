# Mod-Gearman Server/Worker Installation and Configuration

## **Mod-Gearman Server** `(on Nagios XI server)`

Install Nagios Repository _(if not yet already)_

**CentOS/RockyLinux/RHEL 8 (64 bit)**
```
rpm -Uvh https://repo.nagios.com/nagios/8/nagios-repo-8-1.el8.noarch.rpm
```
Create a temporary directory
```
mkdir ~/misc
```

Enter the temporary directory
```
cd ~/misc
```

Download Mod-German install script
```
wget https://assets.nagios.com/downloads/nagiosxi/scripts/ModGearmanInstall.sh
```
Perform Mod-Gearman Worker installation
```
/bin/bash ./ModGearmanInstall.sh --type=server
```
Allow port on firewall
```
firewall-cmd --add-port=4730/tcp --permanent
firewall-cmd --add-port=4730/udp --permanent
firewall-cmd --reload
```
In **/etc/mod_gearman/module.conf**

_- Ensure that we already configured host groups that Mod-Gearman should exclude from sending local checks to workers, i.e. the Nagios XI server itself, etc. separated by a comma_
```
localhostgroups=NAGIOS
```
In **/etc/mod_gearman/worker.conf**

_- Disable worker from executing hosts and services checks_
```
services=no
hosts=no
```
Convert SysV init scripts to Systemd unit file
```
cp /run/systemd/generator.late/mod-gearman-worker.service /etc/systemd/system
vi  /etc/systemd/system/mod-gearman-worker.service
```
Add in the following line _(this makes it installable)_:
```
[Install]
WantedBy=multi-user.target
```
Enable the service
```
systemctl enable --now mod-gearman-worker
```
You can then remove the SysV script by running
```
chkconfig mod-gearman-worker off && chkconfig --del mod-gearman-worker
```
Restart gearmand and Nagios
```
systemctl stop npcd
systemctl stop Nagios
systemctl stop mod-gearman-worker
systemctl stop gearmand
systemctl stop httpd
```
```
systemctl start httpd
systemctl start gearmand
systemctl stop mod-gearman-worker
systemctl start nagios
systemctl start npcd
```
<br />

## **For Mod-Gearman Worker side** `(on Worker server)`

Install EPEL Repository
```
yum -y install epel-release
yum -y --enablerepo=extras install epel-release
```
Install some useful packages
```
yum -y install net-tools mlocate net-snmp net-snmp-perl rsync telnet htop wget nmap nmap-ncat perl-CPAN gcc libgcc jq sshpass firewalld
```
Install Nagios Repository _(if not yet already)_

**CentOS/RockyLinux/RHEL 8 (64 bit)**
```
rpm -Uvh https://repo.nagios.com/nagios/8/nagios-repo-8-1.el8.noarch.rpm
```
Create a temporary directory
```
mkdir ~/misc
```
Enter the temporary directory
```
cd ~/misc
```
Download Mod-German install script
```
wget https://assets.nagios.com/downloads/nagiosxi/scripts/ModGearmanInstall.sh
```
Perform Mod-Gearman Worker installation
```
/bin/bash ./ModGearmanInstall.sh --type=worker
```
_* Enter the IP address of the Nagios XI server when asked_

Disable nagios user expiry
```
chage -m -1 -M -1 -E -1 -W -1 -I -1 nagios
```
Disable selinux permanently
```
setenforce 0

sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/selinux/config /etc/selinux/config
```
***Note: Restart the host after everything completed***

Check and confirm SSH to Nagios XI server is successful _(change the Nagios XI IP address accordingly)_ `[ if output = 0, then SSH successful ]`
```
/usr/bin/nc -z -w5 <NAGIOSXI_IP_ADDRESS> 22; echo $?
```
Create the plugin executable directory
```
mkdir -p /usr/local/nagios/libexec
```
Change directory permissions accordingly
```
chown -R nagios:nagios /usr/local/nagios
```
Install Python
```
yum -y install python3
alternatives --set python /usr/bin/python3
```
Sync plugins from Nagios XI server _(change the `user` and `Nagios XI IP address` accordingly)_
```
/usr/bin/rsync --ignore-existing -avz --progress user@<NAGIOSXI_IP_ADDRESS>:/usr/local/nagios/libexec/* /usr/local/nagios/libexec/
```
Change file permissions accordingly
```
cd /usr/local/nagios/libexec && ls | grep -v check_dhcp | grep -v check_icmp | xargs -n1 chown -R nagios.nagios
```
Configure the mod-gearman worker to only do checks for `hostgroup-sitea` client _(change the `client` accordingly)_
```
sed -i 's/^services=yes/services=no/' /etc/mod_gearman/worker.conf

sed -i 's/^hosts=yes/hosts=no/' /etc/mod_gearman/worker.conf

sed -i '/^#hostgroups=name2,name3/a hostgroups=hostgroup-sitea' /etc/mod_gearman/worker.conf
```
Convert SysV init scripts to Systemd unit file
```
cp /run/systemd/generator.late/mod-gearman-worker.service /etc/systemd/system

vi  /etc/systemd/system/mod-gearman-worker.service
```
Add in the following line _(this makes it installable)_:
```
[Install]
WantedBy=multi-user.target
```
Enable the service
```
systemctl enable --now mod-gearman-worker
```
You can then remove the SysV script by running
```
chkconfig mod-gearman-worker off && chkconfig --del mod-gearman-worker
```
Restart mod-gearman worker service
```
systemctl restart mod-gearman-worker
```
<br />

### IMPORTANT NOTE

**For Gearman Server side** `(on Nagios XI server)`

In **/etc/mod_gearman/module.conf**

- Ensure that we already configured host groups that Mod-Gearman should exclude from sending local checks to workers, i.e. the Nagios XI server itself, etc.
```
localhostgroups=hostgroup1,hostgroup2,hostgroup3
```
- If worker is to only perform for specific hostgroups: Everytime there is a new external remote worker set up, ensure we also add the host groups that we want Mod-Gearman to use as a queue _(this must be the same hostgroups that we added on the Worker node config)_
```
hostgroups=hostgroup-sitea, hostgroup-siteb, hostgroup-sitec
```
- The Catch:

  - Ensure that ALL plugins on Nagios XI server (under **/usr/local/nagios/libexec**) **MUST** also be available on Worker node (under **/usr/local/nagios/libexec**) – so, every time you add a new plugin **MAKE SURE** you also add it or copy it on to the Worker node
  - Ensure that ALL the plugin dependency requirements are installed as well – i.e. if the plugin requires Perl, then Perl must be installed on the Worker node as well

