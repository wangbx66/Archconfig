# Archlinux Installation Guide

This guide features the installation process on  
*a)* A relative old-fashion desktop with supermicro Xeon E5-1620v2 /DDR3, SATA3 RAID0 SSD, with Pascal Titan X, using BIOS mode (2015)  
*b)* HP Spectre 13 laptop, with Skylake i7 and NVMe SSD, using UEFI mode (2016)  
*c)* Dell XPS 13 9365 laptop, with Kobelake i7 and NVMe SSD (2017)  
*d)* Desktop with AMD X570 board, Radeon RX 6900 XT GPU, and AMD 5950x CPU, running with DDR4 RAM and NVMe SSD (2020)  

### USB Flash Bootloader

If you need w3m to resolve the ~~stupid and insecure~~ captivate portal
```
sudo pacman -S archiso
sudo cp -r /usr/share/archiso/configs/releng/ ~/archlive
cd ~/archlive
vim packages.both
(vim) append "w3m" to the list
sudo ./build.sh -v
```
Normally to make a bootloader using an existing archlinux system
```
lsblk
umount /dev/sdx
sudo dd bs=4M if=out/[iso] of=/dev/sdx status=progress && sync
```
Alternatively on a Mac, 
```
diskutil list
diskutil partitionDisk /dev/diskx 1 "Free Space" "unused" "100%"
dd if=[iso] of=/dev/diskx bs=1m
diskutil eject /dev/diskx
```
Otherwise if you have no access to a Unix system, you can use [rufus](https://rufus.akeo.ie/) for Windows.

If you need to retrive something from the machine, first boot from the usb installation media, then chroot into the existing system. After that, format the installation media disk into *ext4*, and mount it to */mnt*. Finally copy things to /mnt and umount the disk, and re-make the installation media.

After that you could turn the drive back into storage device if it's not already. To do this,
```
sudo parted /dev/sdx
(parted) mklabel gpt
(parted) quit
sudo mkfs.ext4 /dev/sdx
```

### Intel RST

* Press ESC/F2/F11/F12/DEL to enter BIOS
* Disable "Quiet Boot"
* Set sata mode to "RAID"
* Ctrl-I to enter and create raid volume

### Partition for EFI+NVMe
Make sure the secure boot option has been disabled and the SATA mode has been set to ACHI or RAID whichever it should be. Also disable legacy boot just in case. Boot, if necessary, with the following boot option
```
nomodeset nouveau.modeset=0
```
First check if the following command populates
```
ls /sys/firmware/efi/efivars
```
Then, check the disk availability using
```
lsblk
```
or
```
fdisk -l
```

Part the device then
```
parted /dev/nvme0n1
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 513MiB
(parted) set 1 boot on
(parted) mkpart primary linux-swap 514MiB 8706MiB
(parted) mkpart primary ext4 8707MiB 100%
(parted) quit
mkfs.fat -F32 /dev/nvme0n1p1
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2
mkfs.ext4 /dev/nvme0n1p3
mount /dev/nvme0n1p3 /mnt
mkdir -p /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot
```

### Partition for BIOS+RAID
```
parted /dev/md/zero_0
(parted) mklabel msdos
(parted) mkpart primary ext4 1MiB 513MiB
(parted) set 1 boot on
(parted) mkpart primary linux-swap 514MiB 16898MiB
(parted) mkpart primary ext4 16899MiB 100%
(parted) quit
mkfs.ext4 /dev/md/zero_0p1
mkswap /dev/md/zero_0p2
swapon /dev/md/zero_0p2
mkfs.ext4 /dev/md/zero_0p3
mount /dev/md/zero_0p3 /mnt
mkdir -p /mnt/boot
mount /dev/md/zero_0p1 /mnt/boot/
```

### Pacstrap

```
timedatectl set-ntp true
(static) ip addr add 137.189.90.84/22 dev eno1
(static) ip route add default via 137.189.91.254
(static) vim /etc/resolve.conf
(static, vim) nameserver 137.189.91.187
(static, vim) nameserver 137.189.91.188
(static) export http_proxy=http://proxy.cse.cuhk.edu.hk:8000/
(wifi) iwctl
(iwctl) device list
(iwctl) station [wlan] scan
(iwctl) station [wlan] get-networks
(iwctl) station [wlan] connect [ssid]
(iwctl) station [wlan] show
(wifi) w3m www.baidu.com
vim /etc/pacman.d/mirrorlist
(vim) copy 163.com kernel.org columbia.edu mirror to head
pacstrap -i /mnt base base-devel linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
```

### Locale
```
arch-chroot /mnt /bin/bash
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
locale-gen
(UTC-4)$ ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
(UTC+8)$ ln -s /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
pacman -S iw wpa_supplicant dialog w3m vi vim wireless_tools net-tools iwd dhcpcd
```

## Bootloader for AMD NVMe

* **At the moment of Dec 2020, AMD CPU/GPU failed to find the Linux system image through the bootloader installed by Systemd. We use grub from Pacman instead.**
```
arch-chroot /mnt /bin/bash
pacman -S grub
vim /etc/mkinitcpio.conf
(vim) add "nvme ext4" to MODULES=
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
exit
umount -R /mnt
reboot
```


### Bootloader for EFI+NVMe

* **By the time of mid July 2016, NVMe is not supported by EFISTUB, hence *efibootmgr* and *grub* will not work on such disks. The two possible solution are *grub-git* and *systemd* at the moment.**
* This section features the later
```
bootctl --path=/boot install
cp /usr/share/systemd/bootctl/arch.conf /boot/loader/entries
blkid -s PARTUUID -o value /dev/nvme0n1p3 >> /boot/loader/entries/arch.conf
vim /boot/loader/entries/arch.conf
(vim) modify root=PARTUUID=[UUID] add_efi_memmap
vim /etc/mkinitcpio.conf
(vim) add "nvme ext4" to MODULES=
mkinitcpio -p linux
exit
umount -R /mnt
reboot
```

For Dell 9360 or 9365, force s2idle to be the default suspend method by using instead
```
(vim) modify root=PARTUUID=[UUID] add_efi_memmap mem_sleep_default=s2idle
```

### Bootloader for BIOS+RAID
* **For RAID reference only; you should no longer use BIOS**
```
arch-chroot /mnt /bin/bash
pacman -S grub
(raid) mdadm --detail --scan >> /etc/mdadm.conf
vim /etc/mkinitcpio.conf
(vim,raid) add mdadm_udev to HOOKS=
(vim) add ext4 to MODULES=
grub-install --force --recheck /dev/md/zero_0
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
exit
umount -R /mnt
reboot
```

### Desktop
```
hostnamectl set-hostname myhostname
passwd
useradd -m bxiangwang
passwd bxiangwang
visudo
(visudo) bxiangwang ALL=(ALL) ALL
ip link list
(lan)$ ip link set eno1 up
(lan)$ dhcpcd eno1
(wifi)$ ip link set wlo1 up
(wifi)$ iw dev wlo1 link
(wifi)$ iw dev wlo1 connect [essid] key 0:[key]
(wifi)$ dhcpcd wlo1
(nvidia)$ pacman -S nvidia nvidia-libgl
(intel)$ pacman -S xf86-video-intel mesa-libgl
pacman -S gnome gedit seahorse
(laptop/touchscreen) choose xf86-input-libinput
vim /etc/gdm/custom.conf
(vim) WaylandEnable=false
systemctl enable gdm
systemctl enable NetworkManager
reboot
```

### Quick Boot for GRUB
Set this if you're using *grub*. Enter BIOS and enable quietboot, then
```
vim /etc/default/grub
(vim) GRUB_TIMEOUT=0
(vim) GRUB_HIDDEN_TIMEOUT=0
(vim) GRUB_HIDDEN_TIMEOUT_QUIET=TRUE
grub-mkconfig -o /boot/grub/grub.cfg
```

### Yaourt
```
mkdir build-repo
cd build-repo
git clone https://aur.archlinux.org/package-query.git
cd package-query
makepkg -sri
cd ..
git clone https://aur.archlinux.org/yaourt.git
cd yaourt
makepkg -sri
cd ../..
rm -rf build-repo
```

### Steam and Lib32
```••••
sudo pacman -S xf86-video-amdgpu mesa
vim /etc/pacman.conf
(vim) [multilib]
(vim) Include = /etc/pacman.d/mirrorlist
pacman -Syyu
pacman -S multilib-devel lib32-alsa-plugins lib32-mesa steam
```
For Nvidia cards, carefully install the latest version *lib32-nvidia-utils* instead of whatever provided with the multilib-devel package. To remove the packages, call
```
sudo pacman -S pacman-contrib
sudo pacman -R $(paclist multilib | cut -f1 -d' ')
```
and switch back the *pacman.conf*

### Cuda
```
pacman -S cuda
cd /opt/cuda/samples
make
cd bin/x86_64/linux/release
./deviceQuery
./bandwidthTest
yaourt -S cudnn
```

### AMDGPU Pro
```
sudo pacman -S mesa
sudo pacman -S xf86-video-amdgpu
yaourt -S amdgpu-pro-libgl
(check if vulkan-amdgpu-pro, amf-amdgpu-pro, and lib32 versions are included)
yaourt -S opencl-amd
sudo reboot
(check current driver; should show AMD)
glxinfo | grep "OpenGL vendor string" | cut -f2 -d":" | xargs
(check GPU and driver)
sudo pacman -S mesa-demos
glxinfo
```

### Cisco AnyConnect

```
sudo pacman -S openconnect
printf 'password' | sudo openconnect --authgroup='CUHK(SZ)' --user='bxiangwang' --passwd-on-stdin --background vpn.cuhk.edu.cn
```

For aliases, append to bashrc
```
alias vpn="printf 'password' | sudo openconnect --authgroup='CUHK(SZ)' --user='bxiangwang' --passwd-on-stdin --background vpn.cuhk.edu.cn"
alias devpn='sudo pkill openconnect'
```

### Ethereum

```
sudo systemctl enable ntp
sudo systemctl start ntp
sudo pacman -S mist
```

### Chinese Font and Input
```
pacman -S ttf-liberation wqy-zenhei ttf-dejavu wqy-microhei
pacman -S libpinyin ibus-libpinyin
ibus-daemon -d -x
```
Then set input source in Gnome>Language

### Touchpad/Keyboard/Lid
* **From this point on, you should *su username* and use sudo whenever needed**
```
gsettings set org.gnome.settings-daemon.peripherals.touchpad tap-to-click true
(deprecated)$ sudo pacman -S xf86-input-libinput
(deprecated)$ sudo pacman -S xorg-xinput
(deprecated)$ sudo libinput-list-devices
(deprecated)$ xinput list-props "SynPS/2 Synaptics TouchPad"
(deprecated) (bashrc) xinput set-prop  "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1
(Spectre)$ xmodmap -pke
(Spectre)$ vim ~/.Xmodmap
(Spectre) (vim) keycode 105 = Delete NoSymbol Delete
(.bashrc) xmodmap ~/.Xmodmap
(.profile) source .bashrc
sudo vim /etc/systemd/logind.conf
(vim) HandleLidSwitch=suspend
(vim) HandleLidSwitchDocked=suspend
sudo restart systemd-logind
```

### Bluetooth

```
sudo pacman -S bluez bluez-utils
sudo pacman -S gnome-bluetooth gnome-shell gnome-control-center
sudo systemctl start bluetooth
sudo systemctl enable bluetooth.service
```

Then pair and config the device through Gnome bluetooth tools. To auto-connect, we borrow from the yaourt package. Be aware tha the third command should not have sudo prefix
```
yaourt -S bluetooth-autoconnect
sudo systemctl enable bluetooth-autoconnect 
systemctl --user enable pulseaudio-bluetooth-autoconnect
```

It is recommended to install the de facto Arch Linux tool for voice management, PauseAudio
```
sudo pacman -S pulseaudio pulseaudio-alsa pulseaudio-bluetooth pavucontrol
```

### Touchscreen

To disable touchscreen, edit */etc/X11/xorg.conf.d/99-no-touchscreen.conf*, with the following content

```
Section "InputClass"
    Identifier         "Touchscreen catchall"
    MatchIsTouchscreen "on"

    Option "Ignore" "on"
EndSection
```

### Display Scale

The following apps are known to **not** scale with the system display settings. It happens when the resolution is high (e.g. 3200x1800) with a 200% scale.

- lightscreen (deprecated). It can be replaced by deepin-screenshot.
- libpinyin

### Redshift

* Firstly install using
```
sudo pacman -S redshift
```
* Copy the example configuration file into *~/.config/redshift.conf*, then modify e.g. for 40N 74W
```
[manual]
lat=40.3573
lon=-74.6672
[randr]
screen=0
```
* Start the app with
```
redshift-gtk
```
and right-click on the redshift icon on system notification tray, check *autostart*

### Personalization
Firstly set the following
* Gnome>Power
* Gnome>Shortcut>  
Add *Ctrl-Alt-T* shortcut refers to *gnome-terminal --window --maximize &*  
(deprecated) Add *Alt-Q* shortcut refers to *gnome-terminal -x bash -c "xmodmap /home/wangbx/.Xmodmap"*
Add *Alt-A* shortcut refers to *deepin-screenshot*  
* Terminal>Preference
* Gedit>Preference
* Chrome>Settings>Zoom
* Gnome>Users>Auto Login

Then conduct the following settings in terminal
```
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.desktop.interface document-font-name 'Sans 14'
gsettings set org.gnome.desktop.interface font-name 'Cantarell 14'
gsettings set org.gnome.desktop.interface monospace-font-name 'Monospace 14'
gsettings set org.gnome.nautilus.desktop font 'Cantarell 14'
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 0
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
gsettings set org.gnome.desktop.screensaver lock-enabled false
sudo pacman -S bash-completion
sudo pacman -S gedit-code-assistance
sudo pacman -S gedit-plugins
sudo pacman -S aspell-en
sudo pacman -S file-roller
sudo pacman -S android-file-transfer
sudo pacman -S exfat-utils
sudo pacman -S alsa-utils
sudo pacman -S gtk3
sudo hdajackretask
(monero) sudo vim /etc/sysctl.conf
"vm.nr_hugepages=128"
```
After that, update keyring passphrase using command *seahorse*, rightclick *login*, then click *change password*. Finally configure git and proxy/printer according to their separate notes.

### Autostart Terminal
* Take *gnome-terminal* as an example, what you need is to initialize a *~/.config/autostart/terminal.desktop* file, the cat the following content to it
```
[Desktop Entry]
Type=Application
Exec=/usr/bin/gnome-terminal --window --maximize
Hidden=false
X-GNOME-Autostart-enabled=true
Name[en_US]=gnome-terminal
Name=gnome-terminal
Comment[en_US]=gnome-terminal
Comment=gnome-terminal
```

### Additional Packages
```
sudo pacman -S smplayer
sudo pacman -S texlive-most
sudo pacman -S python-pip
sudo pacman -S deepin-screenshot
pip install --upgrade --user scipy
yaourt -S google-chrome
yaourt -S overdue
yaourt -S electronic-wechat
```
