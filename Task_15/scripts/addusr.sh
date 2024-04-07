sudo su
useradd otusadm 
useradd otus
echo "otusadm:Otus2024" | chpasswd
echo "otus:Otus2024"  | chpasswd
groupadd -f admin
usermod otusadm -a -G admin
usermod root -a -G admin 
usermod vagrant -a -G admin
cp /home/vagrant/login.sh /usr/local/bin/login.sh
chmod +x /usr/local/bin/login.sh
echo "auth required pam_exec.so debug /usr/local/bin/login.sh" >> /etc/pam.d/common-auth