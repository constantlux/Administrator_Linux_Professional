# ДЗ7 |  Управление пакетами. Дистрибьюция софта 
**Задача:** 
Что нужно сделать?

- создать свой RPM (можно взять свое приложение, либо собрать к примеру апач с определенными опциями);
- создать свой репо и разместить там свой RPM;
- реализовать это все либо в вагранте, либо развернуть у себя через nginx и дать ссылку на репо.


## Решение
Продолжаем работать с ubuntu 22.04 и поскольку это deb-based дистрибютив разбираемся как собрать deb пакет

### 0. Собираем NGINX с ssl-модулем 

#### 0.1 Пробуем собрать из исходников
```
vagrant@nginx:~$ wget https://nginx.org/download/nginx-1.24.0.tar.gz
--2024-01-10 22:12:19--  https://nginx.org/download/nginx-1.24.0.tar.gz
Resolving nginx.org (nginx.org)... 3.125.197.172, 52.58.199.22, 2a05:d014:edb:5704::6, ...
Connecting to nginx.org (nginx.org)|3.125.197.172|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 1112471 (1.1M) [application/octet-stream]
Saving to: ‘nginx-1.24.0.tar.gz’

nginx-1.24.0.tar.gz 100%[===================>]   1.06M  5.19MB/s    in 0.2s    

2024-01-10 22:12:19 (5.19 MB/s) - ‘nginx-1.24.0.tar.gz’ saved [1112471/1112471]

vagrant@nginx:~/nginx-1.24.0$ ./configure --with-http_ssl_module
checking for OS
 + Linux 5.15.0-91-generic x86_64
checking for C compiler ... not found

./configure: error: C compiler cc is not found
```

--with-http_ssl_module
    разрешает сборку модуля для работы HTTP-сервера по протоколу HTTPS. По умолчанию модуль не собирается. Для сборки и работы этого модуля нужна библиотека OpenSSL. 

устанавливаем компилятор и доустанавливаем недостающие библиотеки 

```
sudo apt install build-essential libpcre2-dev libssl-dev zlib1g-dev
```

```
./configure --with-http_ssl_module
...

Configuration summary
  + using system PCRE2 library
  + using system OpenSSL library
  + using system zlib library

  nginx path prefix: "/usr/local/nginx"
  nginx binary file: "/usr/local/nginx/sbin/nginx"
  nginx modules path: "/usr/local/nginx/modules"
  nginx configuration prefix: "/usr/local/nginx/conf"
  nginx configuration file: "/usr/local/nginx/conf/nginx.conf"
  nginx pid file: "/usr/local/nginx/logs/nginx.pid"
  nginx error log file: "/usr/local/nginx/logs/error.log"
  nginx http access log file: "/usr/local/nginx/logs/access.log"
  nginx http client request body temporary files: "client_body_temp"
  nginx http proxy temporary files: "proxy_temp"
  nginx http fastcgi temporary files: "fastcgi_temp"
  nginx http uwsgi temporary files: "uwsgi_temp"
  nginx http scgi temporary files: "scgi_temp"


```

Внесем еще несколько ключей указав где хранить конфиги, логи, pid и бинарник
```
vagrant@nginx:~/nginx-1.24.0$ ./configure --with-http_ssl_module \
> --conf-path=/etc/nginx/nginx.conf \
> --error-log-path=/var/log/nginx/error.log \
> --http-log-path=/var/log/nginx/access.log \
> --pid-path=/var/run/nginx.pid \
> --sbin-path=/usr/sbin/nginx 

```
Вспоминаем что задача подготовить deb

#### 0.2 Собираем DEB-пакет
Сборку производил на отдельной вм - [результат](nginx_1.24.0_amd64.deb) дергаем по scp

[Файлы сборки](pkg/nginx_deb/debian) так же дернул с временной ВМ

Б**о**льшую часть процесса подсмотрел [тут](https://www.dmosk.ru/instruktions.php?object=build-deb#description-rules)

Вкратце необходимая структура файлов:
- [control](pkg/nginx_deb/debian/control) - информация о собираемом пакете. Тут же указываются необходимые библиотеки
- [rules](pkg/nginx_deb/debian/rules) - правила сборки. Что и откуда берем, как компилируем... Соответственно тут перечислены ключи компиляции из п.0.1
- [changelog](pkg/nginx_deb/debian/changelog) - лог изменений в пакете. Обязателен
- [postinst](pkg/nginx_deb/debian/postinst) - Скрипт который должен выполняться после установки. По хорошему тут задать пользователя nginx и создать unit-файл (не реализовано в рамках ДЗ). Не обязателен.
- [compat](pkg/nginx_deb/debian/compat) - Обязателен. Без него используется значение по умолчанию равное 1 и выпадает ошибка. Но не очен понял его назначение. Что-то про совместимость сборщика...

Для сборки потребуется докинуть необходимые пакеты в систему
```
apt install devscripts equivs
```
На сборке не заостряю внимание. Выше указан основной источник куда подглядывал.


```
vagrant@nginx:~/nginx_deb$ sudo mk-build-deps --install
vagrant@nginx:~/nginx_deb$ debuild -us -uc -b
```
в случае успеха получаем deb пакет

Устанавливаем (итог лежит каталогом выше) и проверяем
```
vagrant@nginx:~/nginx_deb$ sudo dpkg -i ../nginx_1.24.0_amd64.deb
vagrant@nginx:~/nginx_deb$ sudo nginx
vagrant@nginx:~/nginx_deb$ curl localhost:80
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>

```
Тут понимаю что надо бы выделить отдельного пользователя, создать unit и само собой не стартовать от рута

## 1. Создаем репозиторий
В [Vagrantfile](Vagrantfile) создаются две ВМ. Одна, где будет жить репа, а вторая для проверки в п.2.

[Скрипт](scripts/repo.sh) устанавливает необходимые пакеты для создания репозитория
```
apt install dpkg-dev -y
```
Устанавливает из переданного на ВМ пакета nginx и стартует сервер

```
$ dpkg -i nginx_1.24.0_amd64.deb
$ nginx
```
Создаем каталог для будующего репозитория и кладём туда наш nginx
```
$ mkdir /usr/local/nginx/html/repo
$ cp nginx_1.24.0_amd64.deb /usr/local/nginx/html/repo
```

И ранее установленной утилкой создаем индекс файлов
```
$ cd /usr/local/nginx/html/repo/
$ dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
```

```
vagrant@nginx:/usr/local/nginx/html/repo$ dpkg-scanpackages .
Package: nginx
Version: 1.24.0
Architecture: amd64
Maintainer: Constantinus <constantlux@gmail.com>
Installed-Size: 979
Provides: nginx
Filename: ./nginx_1.24.0_amd64.deb
Size: 347080
MD5sum: eab7fd8faf4bf56b16652db395712dbb
SHA1: 1d30c634c07d92b300f4cf3c6d9b01aec39efe1d
SHA256: dfcb94e9714e18505b11def5110466f3dea19edd3b6f1f3cd3d2caf002b993fc
Section: misc
Priority: optional
Homepage: https://nginx.org
Description: NGINX 1.24.0 with ssl

dpkg-scanpackages: info: Wrote 1 entries to output Packages file.

```

Для локальной проверки добавляем в список репозиториев
```
echo "deb [trusted=yes] http://localhost/repo /" >> /etc/apt/sources.list
```

## 2. Проверка
Установим наш пакет со второй ВМ, описанной в нашем [Vagrantfile](Vagrantfile)


```
lux@lab:~/OTUS_LINUX_PRO/Task_7$ vagrant ssh cust
vagrant@cust:~$ apt search nginx | grep 1.24.0

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

nginx/unknown 1.24.0 amd64
  NGINX 1.24.0 with ssl
```
```
vagrant@cust:~$ sudo apt install nginx
Reading package lists... Done
Building dependency tree... Done
Reading state information... Done
The following NEW packages will be installed:
  nginx
0 upgraded, 1 newly installed, 0 to remove and 43 not upgraded.
Need to get 347 kB of archives.
After this operation, 1002 kB of additional disk space will be used.
Get:1 http://192.168.57.150/repo  nginx 1.24.0 [347 kB]
Fetched 347 kB in 0s (26.0 MB/s)
debconf: delaying package configuration, since apt-utils is not installed
Selecting previously unselected package nginx.
(Reading database ... 65991 files and directories currently installed.)
Preparing to unpack .../nginx_1.24.0_amd64.deb ...
Unpacking nginx (1.24.0) ...
Setting up nginx (1.24.0) ...
debconf: unable to initialize frontend: Dialog
debconf: (No usable dialog-like program is installed, so the dialog based frontend cannot be used. at /usr/share/perl5/Debconf/FrontEnd/Dialog.pm line 78.)
debconf: falling back to frontend: Readline
Scanning processes...                                                                                                                                          
Scanning linux images...                                                                                                                                       

Running kernel seems to be up-to-date.

No services need to be restarted.

No containers need to be restarted.

No user sessions are running outdated binaries.

No VM guests are running outdated hypervisor (qemu) binaries on this host.
```
```
vagrant@cust:~$ apt search nginx | grep 1.24.0

WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

nginx/unknown,now 1.24.0 amd64 [installed]
  NGINX 1.24.0 with ssl

```

## Заметки