# ДЗ 15 | PAM
**Задача:** 
Запретить всем пользователям, кроме группы admin логин в выходные (суббота и воскресенье), без учета праздников


## 0. Подготовка
Работем с vagrant box созданном в первых занятиях constantlux/ubuntu-22.04. 
[Vagrantfile](Vagrantfile) с [разрешенной](scripts/build.sh) авторизацией по паролю

```
vagrant@PAM:~$ lsb_release  -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
vagrant@PAM:~$ uname -a
Linux PAM 5.15.0-91-generic #101-Ubuntu SMP Tue Nov 14 13:30:08 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
vagrant@PAM:~$ 

```
## 1. Решение

Сразу в Vagrantfile [создаем пользователей](scripts/addusr.sh)

otusadm:Otus2024

otus:Otus2024

Проверяем
```
lux@lab:~$ ssh otus@192.168.57.150
otus@192.168.57.150's password: 
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

...

Could not chdir to home directory /home/otus: No such file or directory
$ bash
otus@PAM:/$ 
```

Проверяем группу
```
vagrant@PAM:~$ cat /etc/group | grep admin
admin:x:1003:otusadm,root,vagrant
```

В том же [скрипте](scripts/addusr.sh) где добавляем пользователя скорректируем конфигурацию PAM.
Проверяем (на календаре воскресенье)
```
lux@lab:~$ ssh otus@192.168.57.150
otus@192.168.57.150's password: 
Permission denied, please try again.
otus@192.168.57.150's password: 
Permission denied, please try again.
otus@192.168.57.150's password: 

lux@lab:~$ ssh otusadm@192.168.57.150
otusadm@192.168.57.150's password: 
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)


```

```
vagrant@PAM:~$ date 
Sun Apr  7 15:37:50 MSK 2024

```
Сходим в будующее 
```
vagrant@PAM:~$ timedatectl 
               Local time: Sun 2024-04-07 15:43:47 MSK
           Universal time: Sun 2024-04-07 12:43:47 UTC
                 RTC time: Sun 2024-04-07 12:42:22
                Time zone: Europe/Moscow (MSK, +0300)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
vagrant@PAM:~$ sudo systemctl stop systemd-timesyncd.service
vagrant@PAM:~$ 
vagrant@PAM:~$ 
vagrant@PAM:~$ sudo date --set "Apr 8 15:37:50 MSK 2024"
Mon Apr  8 15:37:50 MSK 2024
vagrant@PAM:~$ date 
Mon Apr  8 15:37:57 MSK 2024
vagrant@PAM:~$ 

```

Проверим как там обстоят дела.
```
lux@lab:~$ ssh otus@192.168.57.150
otus@192.168.57.150's password: 
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)
...
$ exit
Connection to 192.168.57.150 closed.
lux@lab:~$ ssh otusadm@192.168.57.150
otusadm@192.168.57.150's password: 
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

```
Оба пользователя могу авторизоваться

## Заметки