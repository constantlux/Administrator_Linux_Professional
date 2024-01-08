sudo su
apt update
apt install nfs-kernel-server iptables -y
iptables -A INPUT -s 192.168.57.151 -p tcp --match multiport  --dport 111,2049,32764:32769  -j ACCEPT
iptables -A INPUT -p tcp --match multiport  --dport 111,2049,32764:32769  -j REJECT
iptables-save > /etc/iptables/rules.v4
echo "#!/bin/sh" > /etc/network/if-up.d/00-iptables
echo "iptables-restore < /etc/iptables/rules.v4" >> /etc/network/if-up.d/00-iptables
sudo chmod +x /etc/network/if-up.d/00-iptables
mkdir -p /srv/share/upload
chown -R nobody:nogroup /srv/share/
chmod 0777 /srv/share/upload/
echo Hello_NFS > /srv/share/upload/TEST
echo "/srv/share 192.168.57.151(rw,no_subtree_check,no_root_squash)" > /etc/exports
exportfs -r
sed -i 's/# vers4=y/vers4=n/g' /etc/nfs.conf
systemctl start nfs-server.service
systemctl enable nfs-server.service