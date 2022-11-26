# check_snmp_ibm_imm-ng

This is a script for monitoring sensors (temperature, fans and voltage) and overall health of IBM servers.
The script uses SNMPv1 to communicate with the Integrated Management Module (IMM).


The script was initially released by Ulric Eriksson.
I have only made a few minor changes. Some of these changes were suggested by other users as comments on the [Nagios Exchange](https://exchange.nagios.org/directory/Plugins/Hardware/Server-Hardware/IBM/check_snmp_ibm_imm-2Esh/details) for the original plugin by ulric.

I have tested the script with Op5 Monitor. It should work with other Nagios compatible products as well.

Tested with System X3550 M4 and System X3650 M3. Should work with other models as well.

### Examples

```
./check_snmp_ibm_imm-ng.sh -H hostname -C comminuty -T health
Health status: Normal|
```
```
./check_snmp_ibm_imm-ng.sh -H hostname -C community -T temperature
Ambient Temp = 21
CPU 1 Temp = 39
CPU 2 Temp = 0
PCI Riser 1 Temp = 43
PCI Riser 2 Temp = 36
Mezz Card Temp = 0
CPU1 VR Temp = 34
CPU2 VR Temp = 31
DIMM AB VR Temp = 29
DIMM CD VR Temp = 33
DIMM EF VR Temp = 30
DIMM GH VR Temp = 29
PCH Temp = 54
|'Ambient Temp'=21;43;46;; 'CPU 1 Temp'=39;0;0;; 'CPU 2 Temp'=0;0;0;; 'PCI Riser 1 Temp'=43;70;80;; 'PCI Riser 2 Temp'=36;70;80;; 'Mezz Card Temp'=0;0;0;; 'CPU1 VR Temp'=34;95;100;; 'CPU2 VR Temp'=31;95;100;; 'DIMM AB VR Temp'=29;95;100;; 'DIMM CD VR Temp'=33;95;100;; 'DIMM EF VR Temp'=30;95;100;; 'DIMM GH VR Temp'=29;95;100;; 'PCH Temp'=54;93;98;;
```
```
./check_snmp_ibm_imm-ng.sh -H hostname -C comminuty -T voltage
SysBrd 3.3V = 3308
SysBrd 5V = 5039
SysBrd 12V = 12150
CMOS Battery = 3136
|'SysBrd 3.3V'=3308;;;; 'SysBrd 5V'=5039;;;; 'SysBrd 12V'=12150;;;; 'CMOS Battery'=3136;;;;
```
```
./check_snmp_ibm_imm-ng.sh -H hostname -C comminuty -T fans
Fan 1A Tach = 46%
Fan 1B Tach = 47%
Fan 2A Tach = 45%
Fan 2B Tach = 47%
Fan 3A Tach = 47%
Fan 3B Tach = 49%
Fan 4A Tach = offline
Fan 4B Tach = offline
Fan 5A Tach = 45%
Fan 5B Tach = 48%
Fan 6A Tach = offline
Fan 6B Tach = offline
|'Fan 1A Tach'=46%;;;; 'Fan 1B Tach'=47%;;;; 'Fan 2A Tach'=45%;;;; 'Fan 2B Tach'=47%;;;; 'Fan 3A Tach'=47%;;;; 'Fan 3B Tach'=49%;;;; 'Fan 4A Tach'=0;;;; 'Fan 4B Tach'=0;;;; 'Fan 5A Tach'=45%;;;; 'Fan 5B Tach'=48%;;;; 'Fan 6A Tach'=0;;;; 'Fan 6B Tach'=0;;;;
```


___

Licensed under the [__Apache License Version 2.0__](https://www.apache.org/licenses/LICENSE-2.0)

Partially written by __farid@joubbi.se__

http://www.joubbi.se/monitoring.html

