# Anydesk Installation

**Step 1: Add AnyDesk repository**

```
cat > /etc/yum.repos.d/AnyDesk-CentOS.repo << "EOF"
[anydesk]
name=AnyDesk CentOS - stable
baseurl=http://rpm.anydesk.com/centos/$basearch/
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://keys.anydesk.com/repos/RPM-GPG-KEY
EOF
```


**Step 2: Update the system (OPTIONAL)**

```
dnf -y update
```

**Step 3: Install AnyDesk**

```
dnf makecache
dnf -y install redhat-lsb-core
dnf -y install anydesk
```


**Step 4: Check AnyDesk version**

```
rpm -qi anydesk
```

**Step 5: Install GUI (if it has not already been installed)**

```
dnf -y groupinstall "Server with GUI"
systemctl set-default graphical
shutdown -r now
```

**Step 5: Check AnyDesk Status**

```
systemctl status anydesk.service
systemctl is-enabled anydesk.service
```


**Step 6: Create normal user and add to sudoers**

```
useradd khopu
passwd khopu
usermod -aG wheel khopu
```

**Step 7: Configure Automatic Login in GDM**

```
vi /etc/gdm/custom.conf
```
then, change and make sure under [daemon] section looks like below:
```
[daemon]
# Uncomment the line below to force the login screen to use Xorg
WaylandEnable=false
AutomaticLoginEnable=True
AutomaticLogin=khopu
```
then, restart the Linux machine
```
shutdown -r now
```


Now, launch the AnyDesk using the desktop GUI. Click on the ‘Activities’ and type AnyDesk in the application search bar. You will see the icon of AnyDesk on the screen as follows:

Click on the AnyDesk to launch it. The following window will display on the system:

- Click on the top-right menu and then click `Settings`
- Go to `Security` --> `Unlock Security Settings`
- Then, set the `Unattended Access`
- Then, right-click on the Address, and select `Choose Alias` - set your preferred **_alias_**


**DONE!**

