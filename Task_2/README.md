# ДЗ 2 Ansible
**Задача:**  Подготовить стенд на Vagrant как минимум с одним сервером. На этом сервере используя Ansible необходимо развернуть nginx со следующими условиями:

- необходимо использовать модуль yum/apt;
- конфигурационные файлы должны быть взяты из шаблона jinja2 с перемененными;
- после установки nginx должен быть в режиме enabled в systemd;
- должен быть использован notify для старта nginx после установки;
- сайт должен слушать на нестандартном порту - 8080, для этого использовать переменные в Ansible.

## Выполнение

Задание выполнялось на Ubuntu Server 22.04 LTS. Использовался vagrant box собранный в [первом задании](https://github.com/constantlux/Administrator_Linux_Professional/tree/main/Task_1)

```
vagrant box add constantlux/ubuntu-20.04_kernel-6.6.1 
```

В рамках выполнения NGINX устанавливается из репозитория разработчиков, что обеспечивает последнюю стабильную версию

Таски подключения репозитория отмечены отдельным тегом, что позволяет исключить данный пункт и установить то, что нам предлагают родные репозитории ubuntu

После выполнения playbook  сервис запущен и добавлен в автозагрузку
```bash
vagrant@nginx:~$ systemctl status nginx
● nginx.service - nginx - high performance web server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since Mon 2023-11-20 00:37:30 MSK; 15min ago

```

получен 200ок на порту 8080
```bash
Task_2$ curl -I 192.168.57.150:8080
HTTP/1.1 200 OK
Server: nginx/1.24.0
Date: Sun, 19 Nov 2023 21:38:00 GMT
Content-Type: text/html
Content-Length: 615
Last-Modified: Tue, 11 Apr 2023 01:45:34 GMT
Connection: keep-alive
ETag: "6434bbbe-267"
Accept-Ranges: bytes
```

## С чем работал
```bash
Task_2$ ansible --version
ansible [core 2.15.6]
  config file = /home/lux/OTUS_LINUX_PRO/Task_2/ansible.cfg
  ...
  python version = 3.10.12 (main, Jun 11 2023, 05:26:28) [GCC 11.4.0] (/home/lux/.local/pipx/venvs/ansible/bin/python)
  jinja version = 3.1.2

$ vagrant --version
Vagrant 2.4.0

$ virtualbox --help
Oracle VM VirtualBox VM Selector v7.0.12
```

```bash
Task_2$ vagrant ssh
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 6.6.1-060601-generic x86_64)
...
vagrant@nginx:~$ nginx -version
nginx version: nginx/1.24.0
```

виртуальная сеть (host only) 192.168.57.0/24


## Заметки

### Проблема с зависимостями
Дз делал на основе системы собранной в ДЗ1. Всплыла проблема поломанных зависимостей.

```yaml
- name: fixed_dependencies
  shell: apt --fix-broken install -y
  ```

Данный момент поправил, но поскольку в vagrant cloud исправление не заливал, то оставил испрвление в playbook. 

### Установка последней стабильной версии
Поскольку в репозитории ubunut лежит весьма старая версия, выполним подключение репозитория nginx по инструкции с [оф сайта](https://nginx.org/ru/linux_packages.html#Ubuntu)

Репозиторий от ubuntu
```bash
$ apt show nginx
Package: nginx
Version: 1.18.0-6ubuntu14.4
```

После подключения репозитория nginx
```bash
$ sudo apt show nginx
Package: nginx
Version: 1.24.0-1~jammy
```
