# 0.Install
sudo su
apt update
apt install zfsutils-linux -y
modprobe zfs
# 1.Определить лучшее сжатие
lsblk
zpool create otus_lzjb mirror /dev/sdb /dev/sdc
zpool create otus_lz4 mirror /dev/sdd /dev/sde
zpool create otus_gzip-9 mirror /dev/sdf /dev/sdg
zpool create otus_zle mirror /dev/sdh /dev/sdi
zpool list
for i in lzjb lz4 gzip-9 zle; do zfs set compression=$i otus_$i; done
zfs get all | grep compression
dd if=/dev/urandom of=test bs=100M count=1
wget https://gutenberg.org/cache/epub/2600/pg2600.converter.log
for i in lzjb lz4 gzip-9 zle; do cp pg2600.converter.log test /otus_$i;done
rm test pg2600.converter.log
zfs list 
# 2.Определить настройки пула
wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
tar -xf archive.tar.gz
zpool import -d zpoolexport/
zpool import -d zpoolexport/ otus
zpool status otus
zfs get all otus
zfs get available otus
zfs get readonly otus
zfs get recordsize otus
zfs get compression otus
zfs get checksum otus
# 3.Работа со снепшотами
wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI&export=download
zfs receive otus/test@today < otus_task2.file
cat `find /otus/test -name secret_message`