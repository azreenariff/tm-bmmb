**1. If not already installed, install the check_nwc_health plugin**

```
git clone git@github.com:lausser/check_nwc_health.git
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

```
cd NCPA-WIN
*Make sure to change the NCPA token to the correct one in mytoken file
./my-register-ncpa.bash
cd ..
```

**3. Add the Linux NCPA monitoring**

```
cd NCPA-LNX
*Make sure to change the NCPA token to the correct one in mytoken file
./my-register-ncpa.bash
cd ..
```

**4. Add the Windows disk monitoring**

```
cd DISK-WIN
*Make sure to change the NCPA token to the correct one in mytoken file
./my-client-register-disks.bash
cd ..
```

**5. Add the Linux disk monitoring**

```
cd DISK-LNX
*Make sure to change the NCPA token to the correct one in mytoken file
./my-client-register-disks.bash
cd ..
```

**6. Add the Windows network interface monitoring**

```
cd NET-WIN
*Make sure to change the NCPA token to the correct one in mytoken file
./my-client-register-interfaces.bash
cd ..
```

**7. Add the Linux network interface monitoring**

```
cd NET-LNX
*Make sure to change the NCPA token to the correct one in mytoken file
./my-client-register-interfaces.bash
cd ..
```

**8. Add the Network Devices monitoring**

```
cd SNMP-NETWORK
*Make sure to change the SNMP community string to the correct one in mysnmpcomstring file
./my-register-network.bash
cd ..
```


**DONE!**
