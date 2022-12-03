# Install Nagios XI

There are two methods for installing Nagios XI, they both perform a full installation.

## Quick

Execute the following command in your terminal session:

```
curl https://assets.nagios.com/downloads/nagiosxi/install.sh | sh
```

That one command will download and install Nagios XI.

<br />

## Manual Download

Alternatively, you can install Nagios XI by issuing the following commands in your terminal session:

```
cd /tmp
wget https://assets.nagios.com/downloads/nagiosxi/xi-latest.tar.gz
tar xzf xi-latest.tar.gz
cd nagiosxi
./fullinstall
```

**Note:** If you need to install a specific version of Nagios XI, please visit the following page of Nagios XI
versions to obtain the URL, use that in the wget command above:

https://assets.nagios.com/downloads/nagiosxi/versions.php

