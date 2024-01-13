sudo su
dpkg -i nginx_1.24.0_amd64.deb
nginx
mkdir /usr/local/nginx/html/repo
cp nginx_1.24.0_amd64.deb /usr/local/nginx/html/repo
apt update
apt install dpkg-dev -y
cd /usr/local/nginx/html/repo/
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
echo "deb [trusted=yes] http://localhost/repo /" >> /etc/apt/sources.list