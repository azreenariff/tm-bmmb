**1. Install the latest check_bigip plugins to `/usr/local/nagios/libexec`**

```
dnf install -y perl-devel cpan make
cpan Test::More
cpan Params::Validate Math::Calc::Units Class::Accessor::Fast Config::Tiny
git clone git@github.com:nagios-plugins/nagios-plugin-perl.git
cd nagios-plugin-perl
perl Makefile.PL
make
make test
make install

cd plugins
cp check_bigip_pool_204 /usr/local/nagios/libexec/check_bigip_pool
cp check_bigip_vs_203 /usr/local/nagios/libexec/check_bigip_vs
chmod 755 /usr/local/nagios/libexec/check_bigip*
chown apache.nagios /usr/local/nagios/libexec/check_bigip*
cd ..
```

**2. Add commands into Nagios**

```
cd config
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```


**3. Add hosts into Nagios**

**NOTE:** For TM-BMMB, **SKIP** this. Make sure you do the **SNMP-NETWORK** first under **WIN-LNX-NET**

- These hosts configs are already set for TM-BMMB. If not, change them first accordingly

```
cd hosts
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```


**4. Add services into Nagios**
- Make sure to change `mycommunity`, `myswversion`, `mypoolname`, `myvirtualserver` accordingly
- Don't forget to change the host assignments accordingly

```
cd services
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```

**NOTE:** Remember to change the necessary argument variables as necessary in Nagios XI!


**5. Add hostgroup into Nagios**

**NOTE:** For TM-BMMB, **SKIP** this. Make sure you do the **SNMP-NETWORK** first under **WIN-LNX-NET**

```
cp hostgroups.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```


**DONE!**

