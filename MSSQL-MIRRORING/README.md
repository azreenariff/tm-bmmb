## MSSQL Mirroring Plugin Installation and Configuration

https://exchange.nagios.org/directory/Plugins/Databases/SQLServer/Check-MSSQL-Database-Mirroring/details

**NOTE:** For MSSQL user requirements, refer to the PDF file `MonitoringMSSQLwithNagios.pdf`

**1. Install the `nagios-plugins-perl` package**
```
dnf -y install epel-release
dnf -y install nagios-plugins-perl
```

**2. Edit `check_dbmirroring.pl` and change the library location**
```
vi ./check_dbmirroring.pl
```
- Change the `use lib "/usr/lib/nagios/plugins";` to `use lib "/usr/lib64/nagios/plugins";`


**3. Copy the plugin into `/usr/local/nagios/libexec`**

```
cp check_dbmirroring.pl /usr/local/nagios/libexec
chown apache.nagios /usr/local/nagios/libexec/check_dbmirroring.pl
chmod 755 /usr/local/nagios/libexec/check_dbmirroring.pl
```

**3. Add commands into Nagios**
```
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```

**4. Add hosts into Nagios**

**_NOTE:_** *For this, it is assumed the host(s) is/are already added. If not, REMEMBER to add them first*


**5. Add services into Nagios**
- Make sure to change `databasename`, `user`, `password` accordingly
- Don't forget to change the host assignments accordingly

```
cp MSSQL-MIRRORING.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```

**DONE!**

