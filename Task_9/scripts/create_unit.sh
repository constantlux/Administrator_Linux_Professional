#1
sudo cp files/apache_logs /var/log/
sudo cp files/showlog.conf /etc/default/
sudo cp files/showlog.sh /opt/
sudo cp files/showlog.service /etc/systemd/system/
sudo cp files/showlog.timer /etc/systemd/system/
sudo cp files/spawn-fcgi.service /etc/systemd/system/
sudo cp files/spawn-fcgi.conf /etc/default/
sudo chmod +x /opt/showlog.sh
sudo systemctl daemon-reload
sudo systemctl start showlog.timer
sudo systemctl enable showlog.timer
sudo systemctl start showlog.service
sudo systemctl enable showlog.service
#2
sudo apt install spawn-fcgi php php-cli php-cgi libapache2-mod-fcgid apache2 -y
sudo useradd --no-create-home --home-dir / --shell /bin/false apache
sudo systemctl start spawn-fcgi.service
sudo systemctl enable spawn-fcgi.service

