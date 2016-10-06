# Archlinux Proxy/WiFi/Printer Setting

This notes records the handling on archlinux, in order to get a smooth experience between a Lan with a proxy and a WiFi with a captivate portal. Also assiciated with the Lan we work out the SMB printer.

### Basic IPV4 Config
```
ipv6 off
ipv4 137.189.90.84
netmask 255.255.252.0
gateway 137.189.91.254
dns 137.189.91.187/137.189.91.188
```

### Set Default Proxy
Use the following manual setting to make the desktop work with Lan by default
```
gsettings set org.gnome.system.proxy mode 'manual'
gsettings set org.gnome.system.proxy.http host 'proxy.cse.cuhk.edu.hk'
gsettings set org.gnome.system.proxy.http port 8000
gsettings set org.gnome.system.proxy.https host 'proxy.cse.cuhk.edu.hk'
gsettings set org.gnome.system.proxy.https port 8000
gsettings set org.gnome.system.proxy.socks host socks.cse.cuhk.edu.hk
gsettings set org.gnome.system.proxy.socks port 1080
gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.0/8', '10.0.0.0/8', '192.168.0.0/16', '172.16.0.0/12' , '*.localdomain.com' ]"
```
Alternatively,
```
gsettings set org.gnome.system.proxy mode 'auto'
gsettings set org.gnome.system.proxy autoconfig-url 'http://proxy.cse.cuhk.edu.hk/proxy/cse.pac'
```
Then tell the terminal
```
echo export http_proxy=http://proxy.cse.cuhk.edu.hk:8000/ >> ~/.bashrc
echo export HTTP_PROXY=\$http_proxy >> ~/.bashrc
echo export https_proxy=\$http_proxy >> ~/.bashrc
echo export HTTPS_PROXY=\$https_proxy >> ~/.bashrc
echo export ftp_proxy=\$http_proxy >> ~/.bashrc
echo export FTP_PROXY=\$ftp_proxy >> ~/.bashrc
echo export rsync_proxy=\$http_proxy >> ~/.bashrc
echo export RSYNC_PROXY=\$rsync_proxy >> ~/.bashrc
echo export socks_proxy=socks.cse.cuhk.edu.hk:1080 >> ~/.bashrc
echo export SOCKS_PROXY=\$socks_proxy >> ~/.bashrc
```
Finally keep whatever proxies when using sudo
```
sudo visudo
(visudo) Defaults env_keep += "http_proxy https_proxy ftp_proxy rsync_proxy socks_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY RSYNC_PROXY SOCKS_PROXY"
```

### Setup SMB Printer
Firstly install the *cups* library for printer management
```
sudo pacman -S libcups
sudo pacman -S cups
sudo systemctl disable cups.service
sudo systemctl enable org.cups.cupsd.service
sudo systemctl daemon-reload
sudo systemctl start org.cups.cupsd.service
```
Also *samba* for SMB
```
sudo pacman -S samba
sudo vim /etc/samba/smb.conf.default (edit MyGroup->home)
(vim) Change MyGroup to home
sudo cp /etc/samba/smb.conf.default /etc/samba/smb.conf
```
For *hp* printer, install the library and driver
```
sudo pacman -S hplip
sudo cp /usr/share/ppd/HP/hp-laserjet_4000_series-* /usr/share/cups/model
sudo systemctl daemon-reload
sudo systemctl start org.cups.cupsd.service
```
Finally configure the printer using *cups*. Note these steps should have to be executed everytime for a Linux kernel update
* Open chrome and go [http://127.0.0.1:631/](http://127.0.0.1:631/)
* Login using *root* and the passphrase of root
* Choose printer type, for *lp131* it's Windows Samba
* Go to the connectivity tab, and enter the printer address, for example,  *smb://bxwang:[psw]@137.189.91.116/lp131*
* Choose driver, for *lp131* it's *HP LaserJet 4000 Series hpijs pcl3*

### Set up WiFi 8812driver
Install the driver
```
git clone https://github.com/abperiasamy/rtl8812AU_8821AU_linux
cd rtl8812AU_8821AU_linux
sudo cp -R . /usr/src/rtl8812AU_8821AU_linux-1.0
sudo dkms add -m rtl8812AU_8821AU_linux -v 1.0
```
Then build it and associate it with the system. Note these steps should have to be executed everytime for a Linux kernel update
```
sudo dkms build -m rtl8812AU_8821AU_linux -v 1.0
sudo dkms install -m rtl8812AU_8821AU_linux -v 1.0
sudo modprobe 8812au
```
Unblock the *wifi* daemon
```
sudo rfkill unblock wifi
```
For insecured WiFi with captivate portal, checkout the [ERGWAVE](https://github.com/wangbx66/ergwave) project. For WPA, we have the following example
```
sudo ifconfig wlp8s0u2 up
wpa_supplicant -B -i wlp8s0u2 -c < (wpa_passphrase eeap eleg+bmeg)
sudo dhcpcd wlp8s0u2
```
