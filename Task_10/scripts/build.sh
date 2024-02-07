debconf-set-selections <<< "postfix postfix/mailname string examle.org"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Local only'"
sudo apt update -y
sudo apt install mailutils -y
sudo apt install cron -y
sudo su
chmod +x /home/vagrant/script.sh
echo "*/1 * * * *   vagrant /usr/bin/flock -xn /var/lock/my_lock -c '/home/vagrant/script.sh'" >> /etc/crontab