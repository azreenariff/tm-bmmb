**1. If not already installed, install the check_nwc_health plugin**

```
git clone git@github.com:lausser/check_nwc_health.git
cd check_nwc_health
git submodule update --init
autoreconf
./configure
make
cp plugins-scripts/check_nwc_health /usr/local/nagios/libexec
chown nagios.nagios /usr/local/nagios/libexec/check_nwc_health
cpan File::Slurp
cpan JSON::XS
cd ..
```

**2. Install the latest check_bigip plugins to `/usr/local/nagios/libexec`**

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
chown nagios.nagios /usr/local/nagios/libexec/check_bigip*
cd ..
```

**3. Add commands into Nagios**

```
cd config
cp commands.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
```


**4. Add hosts into Nagios**

```
cd hosts
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```


**5. Add services into Nagios**

```
cd services
cp *.cfg /usr/local/nagios/etc/import/
/usr/local/nagiosxi/scripts/reconfigure_nagios.sh
cd ..
```

**NOTE:** After this, make sure to change the necessary argument variables as necessary in Nagios XI!


**DONE!**

