# ДЗ6 | NFS, FUSE
**Задача:**  Развернуть сервис NFS и подключить к нему клиента.

- vagrant up должен поднимать 2 виртуалки: сервер и клиент;
- на сервер должна быть расшарена директория;
- на клиента она должна автоматически монтироваться при старте (fstab или autofs);
- в шаре должна быть папка upload с правами на запись;
- требования для NFS: NFSv3 по UDP, включенный firewall.

- Задание со звездочкой*

    - Настроить аутентификацию через KERBEROS (NFSv4)


Критерии оценки:

Статус "Принято" ставится при выполнении основных требований.
Доп. задание выполняется по желанию.

## Решение
## 0. Vagrantfile на две vm
[Vagrantfile](Vagrantfile) создает три VM. Сервер - srv, клиента - cust и третью, которая не должна иметь доступ к серверу-forbidden.

Использую бокс без обновления ядра  [constantlux/ubuntu-22.04 ](https://app.vagrantup.com/constantlux/boxes/ubuntu-22.04)

В ubuntu 22.04 нет модуля NFS, поэтому тут же в Vagrantfile установим.
## 1. Готовим сервер

Стартуем демон

```
root@srv:/home/vagrant# systemctl start nfs-server.service
nit nfs-server.servic.service could not be found.
root@srv:/home/vagrant# systemctl status nfs-server.service
● nfs-server.service - NFS server and services
     Loaded: loaded (/lib/systemd/system/nfs-server.service; enabled; vendor preset: enabled)
     Active: active (exited) since Tue 2024-01-02 15:11:46 MSK; 3h 27min ago
   Main PID: 2419 (code=exited, status=0/SUCCESS)
        CPU: 4ms

Jan 02 15:11:46 srv systemd[1]: Starting NFS server and services...
Jan 02 15:11:46 srv exportfs[2418]: exportfs: can't open /etc/exports for reading
Jan 02 15:11:46 srv systemd[1]: Finished NFS server and services.

```

Созжаем директорию для шары
```
root@srv:/home/vagrant# mkdir -p /srv/share/upload
root@srv:/home/vagrant# chown -R nobody:nogroup /srv/share/
root@srv:/home/vagrant# chmod 0777 /srv/share/upload/
root@srv:/home/vagrant# ls -lah /srv/share/
total 12K
drwxr-xr-x 3 nobody nogroup 4.0K Jan  2 18:43 .
drwxr-xr-x 3 root   root    4.0K Jan  2 18:37 ..
drwxrwxrwx 2 nobody nogroup 4.0K Jan  2 18:43 upload

```

Настройка экспорта
```
root@srv:/home/vagrant# echo "/srv/share 192.168.57.151(rw,no_subtree_check,no_root_squash)" > /etc/exports
root@srv:/home/vagrant# 
root@srv:/home/vagrant# 
root@srv:/home/vagrant# cat /etc/exports
/srv/share 192.168.57.151(rw,no_subtree_check,no_root_squash)
root@srv:/home/vagrant# exportfs -r
root@srv:/home/vagrant# exportfs -s
/srv/share  192.168.57.151(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,no_root_squash,no_all_squash)

```

```
root@srv:/home/vagrant# sudo echo Hello_NFS > /srv/share/upload/TEST

```
## 2. Готовим клиентскую сторону

Создаем директорию для монтирования
```
root@cust:/home/vagrant# mkdir nfs
```

Монтируем и проверяем 
```
root@cust:/home/vagrant# mount 192.168.57.150:/srv/share nfs/
root@cust:/home/vagrant# cat nfs/upload/TEST 
Hello_NFS

```

Записывать можем
```
root@cust:/home/vagrant# echo "customer write" > nfs/upload/TEST2
root@cust:/home/vagrant# cat nfs/upload/TEST2
customer write

```
добавляем в fstab
```
echo "192.168.57.150:/srv/share/ /home/vagrant/nfs nfs vers=3,proto=tcp,noauto,x-systemd.automount 0 0" >> /etc/fstab
```

## 3. Only NFSv3 

По умолчанию запущен сервис версии 3 и 4
```
root@srv:/home/vagrant# rpcinfo -p 127.0.0.1 | grep nfs
    100003    3   tcp   2049  nfs
    100003    4   tcp     nfs
```

Отключим v4 изменив  /etc/nfs.conf
```
root@srv:/home/vagrant# sed -i 's/# vers4=y/vers4=n/g' /etc/nfs.conf
root@srv:/home/vagrant# systemctl restart nfs-server
root@srv:/home/vagrant# rpcinfo -p 127.0.0.1 | grep nfs
    100003    3   tcp   2049  nfs

```

Без пересборки ядра по UDP работать не будет на нашем дистрибютиве 
```
root@srv:/home/vagrant# cat /boot/config-5.15.0-91-generic | grep NFS | grep DISA
CONFIG_NFS_DISABLE_UDP_SUPPORT=y

```

## 4. ACL
В server-minimal нет предустановленного файрвола 0_о

```
root@srv:/home/vagrant# apt install iptables 
```
```
root@srv:/home/vagrant# iptables -A INPUT -s 192.168.57.151 -p tcp --match multiport  --dport 111,2049,32764:32769  -j ACCEPT
root@srv:/home/vagrant#  iptables -A INPUT -p tcp --match multiport  --dport 111,2049,32764:32769  -j REJECT
root@srv:/home/vagrant# iptables -n -v -L
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  156 17160 ACCEPT     tcp  --  *      *       192.168.57.151       0.0.0.0/0            multiport dports 111,2049,32764:32769
    0     0 REJECT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            multiport dports 111,2049,32764:32769 reject-with icmp-port-unreachable
...

```

Повторим подключение с клиентской стороны
```
...
192.168.57.150:/srv/share on /home/vagrant/nfs type nfs4 (rw,relatime,vers=4.2,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=192.168.57.151,local_lock=none,addr=192.168.57.150)
root@cust:/home/vagrant# umount /home/vagrant/nfs
root@cust:/home/vagrant# mount 192.168.57.150:/srv/share nfs/
root@cust:/home/vagrant# ls nfs/upload/
TEST  TEST2
```


С ВМ котороя не внесена в правила 

```
vagrant@forbidden:~$ mkdir nfs
vagrant@forbidden:~$ sudo su
root@forbidden:/home/vagrant# mount 192.168.57.150:/srv/share nfs/
mount.nfs: Connection refused
root@forbidden:/home/vagrant# 
```

## Итог
После развертывания стенда в домашнем катологе будет шара c правами на запись
```
vagrant@cust:~$ ls -lah nfs/upload/
total 12K
drwxrwxrwx 2 nobody nogroup 4.0K Jan  8 13:28 .
drwxr-xr-x 3 nobody nogroup 4.0K Jan  8 13:28 ..
-rw-r--r-- 1 root   root      10 Jan  8 13:28 TEST
vagrant@cust:~$ 

```

```
vagrant@srv:~$ ls /srv/share/upload/
TEST

```

NFSv4 отключен. Исползуется v3, но TCP, так как ядро не пересобирал
```
vagrant@cust:~$ mount | grep 150
192.168.57.150:/srv/share/ on /home/vagrant/nfs type nfs (rw,relatime,vers=3,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,mountaddr=192.168.57.150,mountvers=3,mountport=42577,mountproto=tcp,local_lock=none,addr=192.168.57.150)

```

На сервере присутствуют правила, разрешающие обращения на порты NFS только с хоста 192.168.57.151
```
vagrant@srv:~$ sudo iptables -v -L -n
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
   73  7516 ACCEPT     tcp  --  *      *       192.168.57.151       0.0.0.0/0            multiport dports 111,2049,32764:32769
    0     0 REJECT     tcp  --  *      *       0.0.0.0/0            0.0.0.0/0            multiport dports 111,2049,32764:32769 reject-with icmp-port-unreachable

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
vagrant@srv:~$ 
```

## Заметки

