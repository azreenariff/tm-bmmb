**1. Install JAVA**

```
dnf install -y java-1.8.0-openjdk
```


**2. Install check_as400 plugin**

```
cd check_as400-master
./install.sh
```

----------------------------------------------------------------------------------------
```
Nagios Check_AS400 Plugin Installation Script

Please type the full path to nagios directory (ex. /usr/local/nagios): /usr/local/nagios
Please type the full path to your java executable (ex. /usr/bin/java): /usr/bin/java

Detected nagios user as 'nagios' and the group as 'nagios'...
Generating check_as400 script based on your paths...
Installing java classes...
Installing check script...
Installing .as400 security file...
Setting permissions...

Install Complete!

 !!!!! Be sure and modify your /usr/local/nagios/libexec/.as400
 !!!!! with the correct user and password.

Also add the contents of the checkcommands.example file
into your /etc/checkcommands.cfg
```
----------------------------------------------------------------------------------------


**3. Modify `/usr/local/nagios/libexec/.as400` with the correct `user` and `password`**

```
vi /usr/local/nagios/libexec/.as400
```
- Change the `user` and `password` to correct one accordingly


**3. Add commands into Nagios**

```
cd ../config
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```


**4. Add hosts into Nagios**
- These hosts configs are already set for TM-BMMB. If not, change them first accordingly

```
cd hosts
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```


**5. Add services into Nagios**
- Don't forget to change the host assignments accordingly

```
cd services
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```


**DONE!**



**_ADDITIONAL NOTE:_** If the console requires `ENTER` to be pressed after login, use customized check_as400

**Perform as below:**

**1. Copy the AS400-ENTER directory to `/usr/local/nagios/libexec`**

**[Assuming you are at tm-bmmb/CHECK-AS400 directory]**

```
cp -R AS400-ENTER /usr/local/nagios/libexec/
chmod -R g-s /usr/local/nagios/libexec/AS400-ENTER
chown -R nagios.nagios /usr/local/nagios/libexec/AS400-ENTER
```

Then, make sure to change the commands to use `$USER1$/AS400-ENTER/check_as400`

**DONE!**

