# ДЗ 13 | Docker 
**Задача:** 
Разобраться с основами docker, с образом, эко системой docker в целом;
**Описание домашнего задания:**
- Установите Docker на хост машину https://docs.docker.com/engine/install/ubuntu/
- Установите Docker Compose - как плагин, или как отдельное приложение
- Создайте свой кастомный образ nginx на базе alpine. После запуска nginx должен отдавать кастомную страницу (достаточно изменить дефолтную страницу nginx)
- Определите разницу между контейнером и образом
- Вывод опишите в домашнем задании.
- Ответьте на вопрос: Можно ли в контейнере собрать ядро?
- Собранный образ необходимо запушить в docker hub и дать ссылку на ваш репозиторий.

## 0. Подготовка
- установка Docker по документации [скриптом](https://docs.docker.com/engine/install/ubuntu/#install-using-the-convenience-script)
- Установка Docker Compose как плагина.  По [документации из git](https://docs.docker.com/compose/install/linux/#install-the-plugin-manually)
- [Создаем пользователя, группу ...](https://docs.docker.com/engine/install/linux-postinstall/)

Docker
```
lux@lab:~$ docker compose version
Docker Compose version v2.25.0
```

Docker compose
```
lux@lab:~$ docker --version
Docker version 26.0.0, build 2ae903e
```

Проверка
```
lux@lab:~$ docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
c1ec31eb5944: Pull complete 
Digest: sha256:53641cd209a4fecfc68e21a99871ce8c6920b2e7502df0a20671c6fccc73a7c6
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.
...

```

## 1. Кастомный образ nginx на базе alpine
### Краткое описание
NGINX ставим из репозитория alpine

Копируем [настройки веб-сервера](nginx_instance.conf) и кастомный [index](index.html)

[Итоговый Dockerfile](Dockerfile)

### Проверка

```
lux@lab:~/OTUS_LINUX_PRO/Task_13$ docker build -t alpine_nginx_otus .
[+] Building 0.1s (9/9) FINISHED                                                                                                     ...                                                                                       


lux@lab:~/OTUS_LINUX_PRO/Task_13$ docker run -dt -p 8081:80 alpine_nginx_otus
406add7f42471c6e069cfd4d487c3a9d9dcfe98ccdf54105b8dcd6633b6bfeed

lux@lab:~/OTUS_LINUX_PRO/Task_13$ docker ps
CONTAINER ID   IMAGE               COMMAND                  CREATED         STATUS         PORTS                                   NAMES
406add7f4247   alpine_nginx_otus   "nginx -g 'daemon of…"   6 seconds ago   Up 5 seconds   0.0.0.0:8081->80/tcp, :::8081->80/tcp   ecstatic_curran

lux@lab:~/OTUS_LINUX_PRO/Task_13$ curl localhost:8081
<html>
    <body>
        <div>
            <h1>
                HELLO WORLD!
            </h1>
            <p>
                OTUS Task 13
            </p>
        </div>
    </body>
</html>
lux@lab:~/OTUS_LINUX_PRO/Task_13$ 

```

### Docker hub

И отправляем на Docker хаб [alpine_nginx_otus](https://hub.docker.com/r/constantlux/alpine_nginx_otus)

*ps предварительно добавив тег constantlux/alpine_nginx_otus*


## 2. Ответы на вопросы
### Определите разницу между контейнером и образом
Docker-container - работающее приложение созданое на основе образа

Docker-image - шаблон/балванка на основе которой мы можем создать экземпляр приложения.


### Ответьте на вопрос: Можно ли в контейнере собрать ядро?
Собрать ядро - можно. Компилятор, нужные либы и в путь ...
Использовать - нет, так как контейнер по сути является приложением и ОС отсутствует. 

## Заметки
Хост
```
lux@lab:~/OTUS_LINUX_PRO/Task_13$ lsb_release  -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
lux@lab:~/OTUS_LINUX_PRO/Task_13$ uname -a
Linux lab 6.5.0-18-generic #18~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Feb  7 11:40:03 UTC 2 x86_64 x86_64 x86_64 GNU/Linux
lux@lab:~/OTUS_LINUX_PRO/Task_13$ 

```
Docker
```
lux@lab:~$ docker compose version
Docker Compose version v2.25.0
```

Docker compose
```
lux@lab:~$ docker --version
Docker version 26.0.0, build 2ae903e
```