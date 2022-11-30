**Step 1: Add AnyDesk repository**
Add the AnyDesk repository to your Rocky Linux 8 system by using the following command on the terminal:

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

Add AnyDesk Repository Don’t worry about the word CentOS here, the CentOS repository from AnyDesk and the AnyDesk version is fully compatible with Rocky Linux.

**Step 2: Update the system**
Update your dnf repository by typing the following command on the terminal:

```
dnf -y update
```

**Step 3: Install AnyDesk**
Once the AnyDesk repository has been successfully added to your Rocky Linux 8 system, then you will install the AnyDesk on your system using the yum or dnf package manager. Using the following commands you can easily install AnyDesk on your Rocky Linux 8 system.

Run the below-shared command on the terminal.

```
dnf makecache
```

The above command will import the GPG key of AnyDesk on your system. Enter ‘y’ to continue the process. In the end, you will see the message ‘Metadata cache created’.

Now, you will install the redhat-lsb core packages by using the below-given command:

```
dnf -y install redhat-lsb-core
```

It will take some time to install all packages on your system.


Finally, execute the following command to install AnyDesk application along with all dependencies:

```
dnf -y install anydesk
```

Press ‘y’ to agree to import the GPG key and again enter ‘y’ to start the installation of AnyDesk on your Rocky Linux 8 system.

Proceed with installation

**Step 4: Check AnyDesk version**
You can check the AnyDesk Installed version on your system by using the following command:

```
rpm -qi anydesk
```

**Step 5: Install GUI if it has not been installed**

```
yum groupinstall "Server with GUI"
systemctl set-default graphical
shutdown -r now
```


**Step 5: Launch AnyDesk**
AnyDesk services automatically restart after a successful installation of AnyDesk application. You can check the status of the service by using the below-given command:

```
systemctl status anydesk.service
```

AnyDesk services should be enabled on your system as well. Check this by use of the following command:

```
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
then, change and make sure under [daemon] looks like below:
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

- Click on the top-right menu and then click 'Settings'
- Go to 'Security' --> 'Unlock Security Settings'
- Then, set the 'Unattended Access'
- Then, right-click on the Address, and select 'Choose Alias' - set your preferred alias


**DONE!**

