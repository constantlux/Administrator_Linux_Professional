# ДЗ 12 | SELinux - когда все запрещено
**Задача:** 
Что нужно сделать?

1. Запустить nginx на нестандартном порту 3-мя разными способами:- 
    - переключатели setsebool;
    - добавление нестандартного порта в имеющийся тип;
    - формирование и установка модуля SELinux.

  
    К сдаче:
    - README с описанием каждого решения (скриншоты и демонстрация приветствуются).- 

2. Обеспечить работоспособность приложения при включенном selinux.
    - развернуть приложенный стенд https://github.com/mbfx/otus-linux-adm/tree/master/selinux_dns_problems;
    - выяснить причину неработоспособности механизма обновления зоны (см. README);
    - педложить решение (или решения) для данной проблемы;
    - выбрать одно из решений для реализации, предварительно обосновав выбор;
    - реализовать выбранное решение и продемонстрировать его работоспособность.- 
    
    К сдаче:
    - README с анализом причины неработоспособности, возможными способами решения и обоснованием выбора одного из них;
    - исправленный стенд или демонстрация работоспособной системы скриншотами и описанием.

## 1. NGINX на нестандартном порту

Работаем с предоставленным [Vagrantfile](Vagrantfile) CentOS7

Проверяем, что исключено влияние фаервола 
```
[root@selinux vagrant]# systemctl status firewalld.service 
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; disabled; vendor preset: enabled)
   Active: inactive (dead)
     Docs: man:firewalld(1)
[root@selinux vagrant]# iptables -L -v -n
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
[root@selinux vagrant]# 

```

Конфиг NGINX корректный
```
root@selinux vagrant]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@selinux vagrant]# 

```
Ну, а SELinux пакостничает, как и надо. 
```
[root@selinux vagrant]# getenforce
Enforcing
[root@selinux vagrant]# 
```
### Вариант 1 | setsebool

``` 
[root@selinux vagrant]# grep 4881 /var/log/audit/audit.log 
type=AVC msg=audit(1708071128.995:872): avc:  denied  { name_bind } for  pid=3015 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0
```
Докиним в систему утил
```
yum install policycoreutils-python
```

Кормим вывод лога audit2why и  следуем рекомендациям
``` 
[root@selinux vagrant]# grep 1708071128.995:872 /var/log/audit/audit.log | audit2why
type=AVC msg=audit(1708071128.995:872): avc:  denied  { name_bind } for  pid=3015 comm="nginx" src=4881 scontext=system_u:system_r:httpd_t:s0 tcontext=system_u:object_r:unreserved_port_t:s0 tclass=tcp_socket permissive=0

	Was caused by:
	The boolean nis_enabled was set incorrectly. 
	Description:
	Allow nis to enabled

	Allow access by executing:
	# setsebool -P nis_enabled 1
[root@selinux vagrant]# 

```

```
root@selinux vagrant]# setsebool -P nis_enabled 1
```
Перезапускаем сервер и проверяем
```
[root@selinux vagrant]# systemctl restart nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-02-16 09:55:14 UTC; 7s ago
  Process: 22129 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22127 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22126 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22131 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22131 nginx: master process /usr/sbin/nginx
           └─22133 nginx: worker process

Feb 16 09:55:14 selinux systemd[1]: Starting The nginx HTTP and reverse pro.....
Feb 16 09:55:14 selinux nginx[22127]: nginx: the configuration file /etc/ng...ok
Feb 16 09:55:14 selinux nginx[22127]: nginx: configuration file /etc/nginx/...ul
Feb 16 09:55:14 selinux systemd[1]: Started The nginx HTTP and reverse prox...r.
Hint: Some lines were ellipsized, use -l to show in full.
[root@selinux vagrant]# 
[root@selinux vagrant]# exit
exit
[vagrant@selinux ~]$ curl -I 127.0.0.1:4881
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Fri, 16 Feb 2024 09:57:32 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes

[vagrant@selinux ~]$ 
```
Откатываемся

```
[root@selinux vagrant]# setsebool -P nis_enabled 0
[root@selinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Fri 2024-02-16 09:59:32 UTC; 3s ago
  Process: 22129 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22170 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 22169 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22131 (code=exited, status=0/SUCCESS)

```

### Вариант 2 | Правим список портов

```
root@selinux vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989
[root@selinux vagrant]# semanage port -a -t http_port_t -p tcp 4881
[root@selinux vagrant]# semanage port -l | grep http
http_cache_port_t              tcp      8080, 8118, 8123, 10001-10010
http_cache_port_t              udp      3130
http_port_t                    tcp      4881, 80, 81, 443, 488, 8008, 8009, 8443, 9000
pegasus_http_port_t            tcp      5988
pegasus_https_port_t           tcp      5989

```

Проверяем

```
[root@selinux vagrant]# systemctl restart nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Fri 2024-02-16 10:06:15 UTC; 3s ago
  Process: 22209 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22207 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 22206 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22211 (nginx)
   CGroup: /system.slice/nginx.service
           ├─22211 nginx: master process /usr/sbin/nginx
           └─22213 nginx: worker process

Feb 16 10:06:15 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 16 10:06:15 selinux nginx[22207]: nginx: the configuration file /etc/nginx/nginx.... ok
Feb 16 10:06:15 selinux nginx[22207]: nginx: configuration file /etc/nginx/nginx.conf...ful
Feb 16 10:06:15 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@selinux vagrant]# exit
[vagrant@selinux ~]$ exit
logout
lux@lab:~/OTUS_LINUX_PRO/Task_12$ curl -I 127.0.0.1:4881
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Fri, 16 Feb 2024 10:07:25 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes

```

Откатываемся

```
[root@selinux vagrant]# semanage port -d -t http_port_t -p tcp 4881
[root@selinux vagrant]# systemctl restart nginx
Job for nginx.service failed because the control process exited with error code. See "systemctl status nginx.service" and "journalctl -xe" for details.
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: failed (Result: exit-code) since Fri 2024-02-16 10:08:28 UTC; 3s ago
  Process: 22209 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 22274 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=1/FAILURE)
  Process: 22273 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 22211 (code=exited, status=0/SUCCESS)
```
### Вариант 3 | Создадим модуль

Утилой audit2allow создаем свой модуль, отдав на вход лог
```
[root@selinux vagrant]# grep nginx /var/log/audit/audit.log | audit2allow -M nginx_4881
******************** IMPORTANT ***********************
To make this policy package active, execute:

semodule -i nginx_4881.pp


```

Импортируем созданный модуль  и проверяем
```
[root@selinux vagrant]# semodule -i nginx_4881.pp 
[root@selinux vagrant]# systemctl start nginx
[root@selinux vagrant]# systemctl status nginx
● nginx.service - The nginx HTTP and reverse proxy server
   Loaded: loaded (/usr/lib/systemd/system/nginx.service; disabled; vendor preset: disabled)
   Active: active (running) since Mon 2024-02-19 19:30:27 UTC; 4s ago
  Process: 985 ExecStart=/usr/sbin/nginx (code=exited, status=0/SUCCESS)
  Process: 982 ExecStartPre=/usr/sbin/nginx -t (code=exited, status=0/SUCCESS)
  Process: 981 ExecStartPre=/usr/bin/rm -f /run/nginx.pid (code=exited, status=0/SUCCESS)
 Main PID: 987 (nginx)
   CGroup: /system.slice/nginx.service
           ├─987 nginx: master process /usr/sbin/nginx
           └─989 nginx: worker process

Feb 19 19:30:27 selinux systemd[1]: Starting The nginx HTTP and reverse proxy server...
Feb 19 19:30:27 selinux nginx[982]: nginx: the configuration file /etc/nginx/nginx.conf sy... ok
Feb 19 19:30:27 selinux nginx[982]: nginx: configuration file /etc/nginx/nginx.conf test i...ful
Feb 19 19:30:27 selinux systemd[1]: Started The nginx HTTP and reverse proxy server.
Hint: Some lines were ellipsized, use -l to show in full.
[root@selinux vagrant]# 
[root@selinux vagrant]# curl -I localhost:4881
HTTP/1.1 200 OK
Server: nginx/1.20.1
Date: Mon, 19 Feb 2024 19:31:23 GMT
Content-Type: text/html
Content-Length: 4833
Last-Modified: Fri, 16 May 2014 15:12:48 GMT
Connection: keep-alive
ETag: "53762af0-12e1"
Accept-Ranges: bytes

[root@selinux vagrant]# 


```

## 2. Обеспечить работоспособность приложения 

Разворачиваем стенд

```
lux@lab:~/OTUS_LINUX_PRO/Task_12$ git clone https://github.com/mbfx/otus-linux-adm.git
Cloning into 'otus-linux-adm'...
remote: Enumerating objects: 558, done.
remote: Counting objects: 100% (456/456), done.
remote: Compressing objects: 100% (303/303), done.
remote: Total 558 (delta 125), reused 396 (delta 74), pack-reused 102
Receiving objects: 100% (558/558), 1.38 MiB | 4.62 MiB/s, done.
Resolving deltas: 100% (140/140), done.
lux@lab:~/OTUS_LINUX_PRO/Task_12$ ls
otus-linux-adm  README.md  Vagrantfile
```
Поднимаем тачки..


```
lux@lab:~/OTUS_LINUX_PRO/Task_12/otus-linux-adm/selinux_dns_problems$ vagrant status
Current machine states:

ns01                      running (virtualbox)
client                    running (virtualbox)


```

Правим

```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10       
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
update failed: SERVFAIL
> q
incorrect section name: q
> quit
[vagrant@client ~]$ 
```

Чекаем проблемы на клиенте
```
[vagrant@client ~]$ sudo grep denied /var/log/audit/audit.log
[vagrant@client ~]$ 
[vagrant@client ~]$ sudo iptables -L -n -V
iptables v1.4.21
[vagrant@client ~]$ sudo iptables -L -n -v
Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         
[vagrant@client ~]$ 

```

На сервере

```
[vagrant@ns01 ~]$ sudo iptables -vnL
Chain INPUT (policy ACCEPT 969 packets, 88081 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain FORWARD (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 706 packets, 82590 bytes)
 pkts bytes target     prot opt in     out     source               destination         


```
По умолчанию политика SELinux не позволяет имени записывать какие-либо файлы базы данных главной зоны. Только пользователь root может создавать файлы в каталоге файлов базы данных
![Alt text](<Screenshot from 2024-02-27 11-38-33.png>)
```
[vagrant@ns01 ~]$ sudo grep denied /var/log/audit/audit.log
type=AVC msg=audit(1708973761.804:1959): avc:  denied  { create } for  pid=5326 comm="isc-worker0000" name="named.ddns.lab.view1.jnl" scontext=system_u:system_r:named_t:s0 tcontext=system_u:object_r:etc_t:s0 tclass=file permissive=0
[vagrant@ns01 ~]$ 
```
К тому же, как я понимаю, файлы бд предполагаются по другому пути  ```/var/named/*```. Что собственно логично, не мешать данные с конфигами.

Работаем с тем что есть, поэтому изменим контекст безопасности.
```
[root@ns01 vagrant]# chcon -R -t named_zone_t /etc/named
[root@ns01 vagrant]# ls -laZ /etc/named
drw-rwx---. root named system_u:object_r:named_zone_t:s0 .
drwxr-xr-x. root root  system_u:object_r:etc_t:s0       ..
drw-rwx---. root named unconfined_u:object_r:named_zone_t:s0 dynamic
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.50.168.192.rev
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.dns.lab.view1
-rw-rw----. root named system_u:object_r:named_zone_t:s0 named.newdns.lab
[root@ns01 vagrant]# 
```

Вносим изменения с клиента и проверяем
```
[vagrant@client ~]$ nsupdate -k /etc/named.zonetransfer.key
> server 192.168.50.10
> zone ddns.lab
> update add www.ddns.lab. 60 A 192.168.50.15
> send
> quit
[vagrant@client ~]$ nslookup www.ddns.lab
Server:		192.168.50.10
Address:	192.168.50.10#53

Name:	www.ddns.lab
Address: 192.168.50.15

[vagrant@client ~]$ 

```

Грузимся и перепроверяем.

...и не получаем результат. По всей видимости через второй интерфейс dhcp гипервизора запушил другой сервер
```
[vagrant@client ~]$ nslookup www.ddns.lab
Server:		10.0.2.3
Address:	10.0.2.3#53

** server can't find www.ddns.lab: NXDOMAIN
   
[vagrant@client ~]$ cat /etc/resolv.conf 
# Generated by NetworkManager
search mshome.net
nameserver 10.0.2.3

```

Правим и проверяем

```
[vagrant@client ~]$ sudo  vi /etc/resolv.conf
[vagrant@client ~]$ cat /etc/resolv.conf
# Generated by NetworkManager
search mshome.net
nameserver 192.168.50.10
[vagrant@client ~]$ nslookup www.ddns.lab
Server:		192.168.50.10
Address:	192.168.50.10#53

Name:	www.ddns.lab
Address: 192.168.50.15


```

Всё ок

## Заметки