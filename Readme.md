# Archlinux Installation Guide

This guide features the installation process on *a)* a relative old-fation desktop with SATA3 RAID0 SSD, using traditional BIOS boot mode and *b)* an HP Spectre 13 laptop, with Skylake processor and single NVMe SSD disk, using UEFI mode, respectively.

### USB Flash Bootloader

If you need w3m to resolve the captivate portal
```
sudo pacman -S archiso
sudo cp -r /usr/share/archiso/configs/releng/ ~/archlive
cd ~/archlive
sudo vim packages.both # add w3m
sudo ./build.sh -v
```
Normally to make a bootloader using an existing archlinux system
```
lsblk
umount /dev/sdx
sudo dd bs=4M if=out/archlinux-*.iso of=/dev/sdx && sync
sudo dd count=1 bs=512 if=/dev/zero of=/dev/sdx && sync
```
Otherwise if you have no access to a Unix system, you can use [rufus](https://rufus.akeo.ie/) for Windows.

### Intel RST

* Press ESC/F2/F11/F12/DEL to enter BIOS
* disable "Quiet Boot"
* set sata mode to "RAID"
* ctrl-I to enter and create raid volume

### Partition for EFI+NVMe
First check the following command populates
```
ls /sys/firmware/efi/efivars
```
Part the device then
```
parted /dev/nvme0n1
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 513MiB
(parted) set 1 boot on
(parted) mkpart primary linux-swap 514MiB 4610MiB
(parted) mkpart primary ext4 4611MiB 100%
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
(parted) mkpart primary ext4 1MiB 100MiB
(parted) set 1 boot on
(parted) mkpart primary ext4 100MiB 100%
mkfs.ext4 /dev/md/zero_0p1
mkfs.ext4 /dev/md/zero_0p2
mount /dev/md/zero_0p2 /mnt
mkdir -p /mnt/boot
mount /dev/md/zero_0p1 /mnt/boot/
```

### Pacstrap

```
timedatectl set-ntp true
genfstab -U /mnt > /mnt/etc/fstab
wifi-menu
vim /etc/pacman.d/mirrorlist
(vim) copy 163.com kernel.org columbia.edu mirror to head
pacstrap -i /mnt base base-devel
```

### Bootloader for EFI+NVMe

* **By the time of mid July 2016, NVMe is not supported by EFISTUB, hence efibootmgr and grub will not work on such disks. The two possible solution are grub-git and systemd at the moment.**
* This section features the later
```
arch-chroot /mnt /bin/bash
echo en_US.UTF-8 UTF-8 >> /etc/locale.gen
echo LANG=en_US.UTF-8 >> /etc/locale.conf
locale-gen
(UTC-4)$ ln -s /usr/share/zoneinfo/America/New_York /etc/localtime
(UTC-4)$ ln -s /usr/share/zoneinfo/Asia/Hong_Kong /etc/localtime
pacman -S iw wpa_supplicant dialog vim
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

### Bootloader for BIOS+RAID
* **For RAID reference only; you should no longer use BIOS**
```
arch-chroot /mnt /bin/bash
pacman -S grub
mdadm --detail --scan >> /etc/mdadm.conf
vim /etc/mkinitcpio.conf
(vim) add mdadm_udev to HOOKS=
(vim) add ext4 to MODULES=
grub-install --recheck /dev/md/ZERO_0
grub-mkconfig -o /boot/grub/grub.cfg
mkinitcpio -p linux
exit
umount -R /mnt
reboot
```

### Gnome
```
hostnamectl set-hostname myhostname
passwd
useradd -m wangbx
passwd wangbx
visudo
(visudo) wangbx ALL=(ALL) ALL
(lan)$ ip link set eno1 up
(lan)$ dhcpcd eno1
(wifi)$ ip link set wlo1 up
(wifi)$ iw dev wlo1 link
(wifi)$ iw dev wlo1 connect [essid] key 0:[key]
(wifi)$ dhcpcd wlo1
(nvidia)$ pacman -S nvidia nvidia-libgl
(intel)$ pacman -S xf86-video-intel mesa-ibgl
pacman -S gnome gedit seahorse
(laptop/touchscreen) choose xf86-input-libinput
vim /etc/gdm/custom.conf
(vim) WaylandEnable=false
systemctl enable gdm
systemctl enable NetworkManager
reboot
```

### Quick Boot for GRUB
Enter BIOS and enable quietboot, then
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
```
vim /etc/pacman.conf
(vim) [multilib]
(vim) Include = /etc/pacman.d/mirrorlist
pacman -Syyu
pacman -S multilib-devel lib32-alsa-plugins steam
```

### Cuda
```
pacman -S cuda
cd /opt/cuda/sample
make
cd bin/x86_64/linux/release
./deviceQuery
./bandwidthTest
yaourt -S cudnn
```

### Chinese Font and Input
```
pacman -S ttf-liberation wqy-zenhei ttf-dejavu wqy-microhei
pacman -S ibus-libpinyin
ibus-daemon -d -x
```
Then set input source in Gnome>Language

### Touchscreen/Keyboard/Lid
* **From this point on, you should *su wangbx* and use sudo if needed**
```
gsettings set org.gnome.settings-daemon.peripherals.touchpad tap-to-click true
(deprecated)$ sudo pacman -S xf86-input-libinput
(deprecated)$ sudo pacman -S xorg-xinput
(deprecated)$ sudo libinput-list-devices
(deprecated)$ xinput list-props "SynPS/2 Synaptics TouchPad"
(deprecated) (bashrc) xinput set-prop  "SynPS/2 Synaptics TouchPad" "libinput Tapping Enabled" 1
(Spectre)$ xmodmap -pke
(Spectre)$ vim ~/.Xmodmap
(Spectre) (vim) keycode 105 Delete NoSymbol Delete
(bashrc) xmodmap ~/.Xmodmap
sudo vim /etc/systemd/logind.conf
(vim) HandleLidSwitch=suspend
(vim) HandleLidSwitchDocked=suspend
sudo restart systemd-logind
```

### Personalization
Firstly set the following
* Gnome>Power
* Gnome>Shortcut>  
Add *Ctrl-Alt-T* shortcut refers to *gnome-terminal --window --maximize &*
* Terminal>Preference
* Gedit>Preference
* Chrome>Settings>Zoom
* Gnome>Users>Auto Login

Then conduct the following settings in terminal
```
gsettings set org.gnome.desktop.interface clock-show-date true
gsettings set org.gnome.settings-daemon.plugins.power power-button-action 'nothing'
gsettings set org.gnome.settings-daemon.plugins.power idle-brightness 0
gsettings set org.gnome.settings-daemon.plugins.power idle-dim true
gsettings set org.gnome.desktop.lockdown disable-lock-screen true
sudo pacman -S bash-completion
sudo pacman -S gedit-code-assistance
sudo pacman -S gedit-plugins
sudo pacman -S aspell-en
(hdajack)$ sudo pacman -S alsa-utils
(hdajack)$ hdajackretask
```
After that, update keyring passphrase using command *seahorse*, rightclick *login*, then click *change password*. Finally configure git and proxy/printer according to their separate notes.

### Autostart Terminal
* Take *gnome-terminal*as an example, what you need is to initialize a *~/.config/autostart/terminal.desktop* file, the cat the following content to it
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
pip install --upgrade --user scipy
yaourt -S google-chrome
yaourt -S lightscreen
yaourt -S overdue
yaourt -S electronic-wechat
```
