https://www.claudiokuenzler.com/monitoring-plugins/check_mysql_slavestatus.php

## Requirements
- The following shell commands must exist and be executable by your Nagios user: `grep`, `cut`
- The mysql (client) command must be available *(this command usually comes from the mysql-client or mariadb-client package)*
- The MySQL user you want to use for this plugin needs **REPLICATION CLIENT** privileges.

Here is an example how to grant the necessary privileges to a user nagios:
```
GRANT REPLICATION CLIENT on *.* TO 'nagios'@'%' IDENTIFIED BY 'secret';
```

**1. Copy the plugin into `/usr/local/nagios/libexec`**

```
cp check_mysql_slavestatus.sh /usr/local/nagios/libexec
chown apache.nagios /usr/local/nagios/libexec/check_mysql_slavestatus.sh
chmod 755 /usr/local/nagios/libexec/check_mysql_slavestatus.sh
```

**3. Add commands into Nagios**
```
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```

**4. Add hosts into Nagios**

**_NOTE:_** *For this, it is assumed the host(s) is/are already added. If not, REMEMBER to add them first*


**5. Add services into Nagios**
- Make sure to change `port`, `username`, `passwd` accordingly
- Don't forget to change the host assignments accordingly

```
cp MYSQL-REPLICATION.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```

**DONE!**

