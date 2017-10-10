#!/bin/bash

###################################################################################################################
# "123Cuckoo" - Easy setup script for cuckoo server on Ubuntu 16.04 LTS (https://github.com/krismeier/123Cuckoo)
# v5.0, 10/07/17
#
# This configuration file has been adapted from the Cuckoo Project (https://www.cuckoosandbox.org), 
# to support the "123Cuckoo" rapid installation script (https://github.com/krismeier/123Cuckoo).
#
# Cuckoo Git: https://github.com/cuckoosandbox/cuckoo/
#
# This configuration file is distributed under the MIT licensing model https://opensource.org/licenses/MIT
#
# Copyright 2017
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated 
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation 
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, 
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or 
# substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
# BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, 
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, 
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# See the file 'docs/LICENSE' for copying permission.
###################################################################################################################

#Install base packages
sudo apt-get update
sudo apt-get install python python-pip python-dev libffi-dev libssl-dev -y
sudo apt-get install python-setuptools -y
sudo apt-get install libjpeg-dev zlib1g-dev swig -y
sudo apt-get install git -y
sudo apt-get install mongodb -y
sudo apt-get install vim -y

#Needed to dump network activity
sudo apt-get install tcpdump apparmor-utils -y
sudo aa-disable /usr/sbin/tcpdump
sudo setcap cap_net_raw,cap_net_admin=eip /usr/sbin/tcpdump

#Upgrade PIP
sudo -H pip install --upgrade pip

#Install Yara
sudo -H pip install yara-python==3.5.0

#Install Volatility
mkdir /home/cuckoo/volatility
cd /home/cuckoo/volatility
git clone https://github.com/volatilityfoundation/volatility.git /home/cuckoo/volatility
cd /home/cuckoo/volatility
python setup.py build
sudo -H python setup.py install
sudo -H pip install distorm3

#Install Cuckoo
sudo -H pip install -U pip setuptools
sudo -H pip install -U cuckoo

#Launch cuckoo once to finish default install
cuckoo -d

#Fetch Cuckoo community files
sudo cuckoo community

###################################################################################################################
# We're going to try to save a few steps by having the shell script prompt the user for their sandbox values,
# and edit the config files on the fly.
#
# The install package contains versions of the default config files that we have modified with placeholder values.
# We will take the user's input to overwrite those placeholders, and then copy those config files into the 
# .cuckoo/conf directory... overwriting the default files.
#
# Of course, if the default files change in new releases of cuckoo... we may need to rebuild the install package.
#
# Note that this only works if running the shell script as a user named "cuckoo"
###################################################################################################################

#Edit cuckoo.conf
cd /home/cuckoo
#Taking input from the console to edit the confgiuration files
echo "Please enter the IP of your Cuckoo results server (this box): "
read ipaddr
#Our version of the config file has a placeholder value named "CHANGEME1/"
#Replace that with the user's real value for ipaddr
sed -i 's/CHANGEME1/'$ipaddr'/' cuckoo.setup
#Now, copy the file that now contains the user's input into the .cuckoo/conf directory, overwriting the default one.
sudo cp cuckoo.setup /home/cuckoo/.cuckoo/conf/cuckoo.conf

#Edit physical.conf
#Uses the same idea as Editing cuckoo.conf, above.
cd /home/cuckoo
echo "Please enter the username for your physical client:"
read un
echo "Please enter the password for your physical client:"
read pw
echo "Please enter the Cuckoo server network interface you'll use to communicate with the physical client (eth0, eno1, etc.):"
read iface
echo "Please enter the IP address of your physical client:"
read guestip
sed -i 's/CHANGEME2/'$un'/' physical.setup
sed -i 's/CHANGEME3/'$pw'/' physical.setup
sed -i 's/CHANGEME4/'$iface'/' physical.setup
sed -i 's/CHANGEME5/'$guestip'/' physical.setup
sudo cp physical.setup /home/cuckoo/.cuckoo/conf/physical.conf

#Edit physical.py
#No user input required here, we're just overwriting the default conf with the one from our install package.
#Our version of physical.py has commented out lines 103-111
cd /home/cuckoo
sudo cp py.setup /usr/local/lib/python2.7/dist-packages/cuckoo/machinery/physical.py

#Edit processing.conf
#Again, no user input required. Our processing.conf sets
#   [Memory]
#   Enabled = yes
#To enable Volatility

sudo cp processing.setup /home/cuckoo/.cuckoo/conf/processing.conf

#Edit MongoDB
#Our version of reporting.conf sets:
#   [MongoDB]
#   Enabled = yes
#To enable MongoDB

sudo cp reporting.setup /home/cuckoo/.cuckoo/conf/reporting.conf 

#Reboot
sudo reboot

###########################################################################
# Post Reboot...
#
# 1) Run cuckoo: cuckoo -d
# 2) Run cuckoo web: cuckoo web
# 3) Start client agent (C:\Python27 python.exe ./agent.py)
# 4) Browse to: http://127.0.0.1:8000
# 5) Profit!
###########################################################################