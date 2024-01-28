# ДЗ 9 | Инициализация системы. Systemd
**Задача:** 
Выполнить следующие задания и подготовить развёртывание результата выполнения с использованием Vagrant и Vagrant shell provisioner (или Ansible, на Ваше усмотрение):

-  Написать service, который будет раз в 30 секунд мониторить лог на предмет наличия ключевого слова (файл лога и ключевое слово должны задаваться в /etc/sysconfig или в /etc/default).
- Установить spawn-fcgi и переписать init-скрипт на unit-файл (имя service должно называться так же: spawn-fcgi).
- Дополнить unit-файл httpd (он же apache2) возможностью запустить несколько инстансов сервера с разными конфигурационными файлами.
## Решение
Продолжаем работать с ubuntu 22.04.
### 1.Мониторинг лога на предмет наличия ключевого слова
Чуть инвертируем задание.

Предложенный файл [лога apache](files/apache_logs) будем проверять на коды откличные от **200 ОК**
И если тиакие имеются выведем их

[Скрипт](scripts/create_unit.sh) который раскидывает файлы по тестовой ВМ и поднимает сервис

По [пути fales](files/) лежат файлы относящиеся к сервису и файл логов

**Результат наблюдаем в journalctl:**
```
Jan 28 15:39:29 nginx systemd[1]: showlog.service: Deactivated successfully.
Jan 28 15:39:29 nginx systemd[1]: Finished My showlog service.
Jan 28 15:40:39 nginx systemd[1]: Starting My showlog service...
Jan 28 15:40:39 nginx root[1692]:   count http                                          
                                       45 206
                                      164 301
                                      445 304
                                        2 403
                                      213 404
                                        2 416
                                        3 500
Jan 28 15:40:39 nginx systemd[1]: showlog.service: Deactivated successfully.
Jan 28 15:40:39 nginx systemd[1]: Finished My showlog service.
Jan 28 15:41:39 nginx systemd[1]: Starting My showlog service...
Jan 28 15:41:39 nginx root[1699]:   count http                                          
                                       45 206
                                      164 301
                                      445 304
                                        2 403
                                      213 404
                                        2 416
                                        3 500
Jan 28 15:41:39 nginx systemd[1]: showlog.service: Deactivated successfully.
Jan 28 15:41:39 nginx systemd[1]: Finished My showlog service.
Jan 28 15:42:29 nginx systemd[1]: Starting My showlog service...
Jan 28 15:42:29 nginx root[1706]:   count http                                          
                                       45 206
                                      164 301
                                      445 304
                                        2 403
                                      213 404
                                        2 416
                                        3 500

```

### 2. Переписать init-скрипт на unit-файл

По всей видимости на ubuntu 22.04 из репозитория мы получаем только бинарник. Нет ни unit-файла ни init-скрипта. Напишем...

Установка пакетов в [скрипте](scripts/create_unit.sh), там же поднимаем сервисы и создаем юзера *apache*. 

Файлы с конфигурацией и юнит-файл [тут](files/)

**Результат:**
```
vagrant@nginx:~$ sudo systemctl status spawn-fcgi
● spawn-fcgi.service - Spawn-fcgi startup service by Otus
     Loaded: loaded (/etc/systemd/system/spawn-fcgi.service; disabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-01-28 17:32:09 MSK; 4s ago
   Main PID: 10460 (php-cgi)
      Tasks: 33 (limit: 2220)
     Memory: 14.2M
        CPU: 20ms
     CGroup: /system.slice/spawn-fcgi.service
             ├─10460 /usr/bin/php-cgi
             ├─10461 /usr/bin/php-cgi
             ├─10462 /usr/bin/php-cgi
             ├─10463 /usr/bin/php-cgi
             ├─10464 /usr/bin/php-cgi
             ├─10465 /usr/bin/php-cgi
             ├─10466 /usr/bin/php-cgi
             ├─10467 /usr/bin/php-cgi
             ├─10468 /usr/bin/php-cgi
             ├─10469 /usr/bin/php-cgi
             ├─10470 /usr/bin/php-cgi
             ├─10471 /usr/bin/php-cgi
             ├─10472 /usr/bin/php-cgi
             ├─10473 /usr/bin/php-cgi
             ├─10474 /usr/bin/php-cgi
             ├─10475 /usr/bin/php-cgi
             ├─10476 /usr/bin/php-cgi
             ├─10477 /usr/bin/php-cgi
             ├─10478 /usr/bin/php-cgi
             ├─10479 /usr/bin/php-cgi
             ├─10480 /usr/bin/php-cgi
             ├─10481 /usr/bin/php-cgi
             ├─10482 /usr/bin/php-cgi
             ├─10483 /usr/bin/php-cgi
             ├─10484 /usr/bin/php-cgi
             ├─10485 /usr/bin/php-cgi
             ├─10486 /usr/bin/php-cgi
             ├─10487 /usr/bin/php-cgi
             ├─10488 /usr/bin/php-cgi
             ├─10489 /usr/bin/php-cgi
             ├─10490 /usr/bin/php-cgi
             ├─10491 /usr/bin/php-cgi
             └─10492 /usr/bin/php-cgi

Jan 28 17:32:09 nginx systemd[1]: Started Spawn-fcgi startup service by Otus.
```

### 3. Дополнить unit-файл httpd
Дополнять не нужно, рядом лежит уже готовый юнит-файл

```
agrant@nginx:~$ cat /usr/lib/systemd/system/apache2@.service
[Unit]
Description=The Apache HTTP Server
After=network.target remote-fs.target nss-lookup.target
ConditionPathIsDirectory=/etc/apache2-%i
Documentation=https://httpd.apache.org/docs/2.4/

[Service]
Type=forking
Environment=APACHE_CONFDIR=/etc/apache2-%i APACHE_STARTED_BY_SYSTEMD=true
ExecStart=/usr/sbin/apachectl start
ExecStop=/usr/sbin/apachectl graceful-stop
ExecReload=/usr/sbin/apachectl graceful
KillMode=mixed
PrivateTmp=true
Restart=on-abort

[Install]
WantedBy=multi-user.target

```
Дублируем и оздаем путь под логи (узнаем об этом при неуспешном запуске:) ). И не забываем унести на другой порт.
```
vagrant@nginx:~$ sudo cp -r /etc/apache2 /etc/apache2-otus
vagrant@nginx:~$ sudo mkdir /var/log/apache2-otus/
vagrant@nginx:~$ cat /etc/apache2-otus/ports.conf 
# If you just change the port or add more ports here, you will likely also
# have to change the VirtualHost statement in
# /etc/apache2/sites-enabled/000-default.conf

Listen 8080

<IfModule ssl_module>
	Listen 8443
</IfModule>

<IfModule mod_gnutls.c>
	Listen 8443
</IfModule>

# vim: syntax=apache ts=4 sw=4 sts=4 sr noet
```
Поднимаем сервис
```
vagrant@nginx:~$ sudo systemctl daemon-reload
vagrant@nginx:~$ sudo systemctl start apache2@otus
vagrant@nginx:~$ sudo systemctl status apache2@otus
● apache2@otus.service - The Apache HTTP Server
     Loaded: loaded (/lib/systemd/system/apache2@.service; disabled; vendor preset: enabled)
     Active: active (running) since Sun 2024-01-28 20:04:15 MSK; 5min ago
       Docs: https://httpd.apache.org/docs/2.4/
    Process: 11557 ExecStart=/usr/sbin/apachectl start (code=exited, status=0/SUCCESS)
   Main PID: 11561 (apache2)
      Tasks: 7 (limit: 2220)
     Memory: 12.1M
        CPU: 55ms
     CGroup: /system.slice/system-apache2.slice/apache2@otus.service
             ├─11561 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             ├─11562 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             ├─11563 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             ├─11564 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             ├─11565 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             ├─11566 /usr/sbin/apache2 -d /etc/apache2-otus -k start
             └─11567 /usr/sbin/apache2 -d /etc/apache2-otus -k start

Jan 28 20:04:15 nginx systemd[1]: Starting The Apache HTTP Server...
Jan 28 20:04:15 nginx apachectl[11560]: AH00558: apache2: Could not reliably determine the server's fully qualified domain name, using 127.0.2.1. Set the 'ServerName' directive globally to suppress this message
Jan 28 20:04:15 nginx systemd[1]: Started The Apache HTTP Server.

```
Проверяем
```
vagrant@nginx:~$ ss -tan | grep 80
LISTEN 0      511                *:8080            *:*           
LISTEN 0      511                *:80              *:*      

vagrant@nginx:~$ curl 127.0.0.1:8080 -I
HTTP/1.1 200 OK
Date: Sun, 28 Jan 2024 17:06:45 GMT
Server: Apache/2.4.52 (Ubuntu)
Last-Modified: Sun, 28 Jan 2024 16:31:52 GMT
ETag: "29af-61004110e81d6"
Accept-Ranges: bytes
Content-Length: 10671
Vary: Accept-Encoding
Content-Type: text/html
 
```