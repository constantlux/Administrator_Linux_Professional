# ДЗ 14 | 14
**Задача:** 
Описание/Пошаговая инструкция выполнения домашнего задания:

Что нужно сделать?

Настроить дашборд с 4-мя графиками

-    память;
-    процессор;
-    диск;
-    сеть.
Настроить на одной из систем:
- zabbix (использовать screen (комплексный экран);
- prometheus - grafana.


    В качестве результата прислать скриншот экрана - дашборд должен содержать в названии имя приславшего.

## 0. Установка

### Zabbix server
https://www.zabbix.com/download?zabbix=6.4&os_distribution=ubuntu&os_version=22.04&components=server_frontend_agent&db=pgsql&ws=nginx

+PostgeSQL

```
lux@zabbix:~$ zabbix_server --version
zabbix_server (Zabbix) 6.4.13
Revision 6e531c40ff3 25 March 2024, compilation time: Mar 25 2024 15:12:00

Copyright (C) 2024 Zabbix SIA
License GPLv2+: GNU GPL version 2 or later <https://www.gnu.org/licenses/>.
This is free software: you are free to change and redistribute it according to
the license. There is NO WARRANTY, to the extent permitted by law.

This product includes software developed by the OpenSSL Project
for use in the OpenSSL Toolkit (http://www.openssl.org/).

Compiled with OpenSSL 3.0.2 15 Mar 2022
Running with OpenSSL 3.0.2 15 Mar 2022
lux@zabbix:~$ 
lux@zabbix:~$ psql --version 
psql (PostgreSQL) 14.11 (Ubuntu 14.11-0ubuntu0.22.04.1)

```


```
lux@zabbix:~$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.4 LTS
Release:	22.04
Codename:	jammy


lux@zabbix:~$ uname -a
Linux zabbix 5.15.0-101-generic #111-Ubuntu SMP Tue Mar 5 20:16:58 UTC 2024 x86_64 x86_64 x86_64 GNU/Linux

```

```
lux@zabbix:~$ ip add
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:c3:10:12 brd ff:ff:ff:ff:ff:ff
    altname enp2s1
    inet 10.10.10.182/24 metric 100 brd 10.10.10.255 scope global dynamic ens33
       valid_lft 596306sec preferred_lft 596306sec
    inet6 fe80::20c:29ff:fec3:1012/64 scope link 
       valid_lft forever preferred_lft forever
lux@zabbix:~$ 

```

### Хост (Zabbix agent 2)
```
lux@msk1:~$ lsb_release  -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 20.04.5 LTS
Release:	20.04
Codename:	focal
lux@msk1:~$ uname -a
Linux msk1 5.4.0-137-generic #154-Ubuntu SMP Thu Jan 5 17:03:22 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
lux@msk1:~$ 
```

```
lux@msk1:~$ ip route list 10.10.10.0/24
10.10.10.0/24 via 10.58.1.1 dev gre-my proto bird metric 32 
lux@msk1:~$ 
```

правим /etc/zabbix/zabbix_agent2.conf
```
ServerActive=10.10.10.182
Hostname=msk1

```
Рестарт
```
lux@msk1:~$ sudo systemctl restart zabbix-agent2.service 
lux@msk1:~$ sudo systemctl status zabbix-agent2.service 
● zabbix-agent2.service - Zabbix Agent 2
     Loaded: loaded (/lib/systemd/system/zabbix-agent2.service; enabled; vendor preset: enabled)
     Active: active (running) since Thu 2024-04-04 00:17:39 MSK; 10s ago
   Main PID: 388063 (zabbix_agent2)
      Tasks: 8 (limit: 2310)
     Memory: 6.0M
     CGroup: /system.slice/zabbix-agent2.service
             └─388063 /usr/sbin/zabbix_agent2 -c /etc/zabbix/zabbix_agent2.conf

Apr 04 00:17:39 msk1 systemd[1]: Started Zabbix Agent 2.
Apr 04 00:17:39 msk1 zabbix_agent2[388063]: Starting Zabbix Agent 2 (6.4.13)
Apr 04 00:17:39 msk1 zabbix_agent2[388063]: Zabbix Agent2 hostname: [msk1]
Apr 04 00:17:39 msk1 zabbix_agent2[388063]: Press Ctrl+C to exit.
lux@msk1:~$ 

```


## 1. Дашборд
Добавляем хост с шаблоном Zabbix agent active. 

![alt text](<img/Screenshot from 2024-04-07 12-33-37.png>)

Всё взлетело без какаих-либо трудностей. Создаём дашборд по заданию
![alt text](<img/Screenshot from 2024-04-07 12-33-43.png>)

На vps msk1 развернут мониторинг prometheus, поэтому есть с чем сравнить. Для сравнения воспользуемся дашбордом [Node Exporter Full](https://grafana.com/grafana/dashboards/1860-node-exporter-full/)

![alt text](<img/Screenshot from 2024-04-07 12-38-22.png>)



