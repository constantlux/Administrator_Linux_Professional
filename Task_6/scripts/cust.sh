sudo su
apt update
apt install nfs-kernel-server -y
mkdir nfs
echo "192.168.57.150:/srv/share/ /home/vagrant/nfs nfs vers=3,proto=tcp,noauto,x-systemd.automount 0 0" >> /etc/fstab
systemctl daemon-reload 
systemctl restart remote-fs.target