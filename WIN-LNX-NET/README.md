## Adding Windows and Linux NCPA Monitoring into Nagios XI
## Adding Network Devices SNMP Monitoring into Nagios XI

**1. If not already installed, install the check_nwc_health plugin**

```
git clone https://github.com/lausser/check_nwc_health.git
cd check_nwc_health
git submodule update --init
autoreconf
./configure
make
cp plugins-scripts/check_nwc_health /usr/local/nagios/libexec
chown apache.nagios /usr/local/nagios/libexec/check_nwc_health
cpan File::Slurp
cpan JSON::XS
cd ..
```

**2. Add the Windows NCPA monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd NCPA-WIN
./my-register-ncpa.bash
cd ..
```

**3. Add the Linux NCPA monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd NCPA-LNX
./my-register-ncpa.bash
cd ..
```

**4. Add the Windows disk monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd DISK-WIN
./my-client-register-disks.bash
cd ..
```

**5. Add the Linux disk monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd DISK-LNX
./my-client-register-disks.bash
cd ..
```

**6. Add the Windows network interface monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd NET-WIN
./my-client-register-interfaces.bash
cd ..
```

**7. Add the Linux network interface monitoring**
- Make sure to change the NCPA token to the correct one in `mytoken` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd NET-LNX
./my-client-register-interfaces.bash
cd ..
```

**8. Add the Network Devices monitoring**
- Make sure to change the SNMP community string to the correct one in `mysnmpcomstring` file
- These hosts are already set for TM-BMMB. If not, change them first in `myhostlist` file accordingly

```
cd SNMP-NETWORK
./my-register-network.bash
cd ..
```


**DONE!**
