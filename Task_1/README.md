# ДЗ 1 
**Задача:**  Собрать образ для vagrant с обновленным ядром

## Результаты

Создан образ для [Ubuntu Server 22.04 LTS](https://releases.ubuntu.com/22.04.3/) 
ядро обновлено до 6.6.1, начальное ядро не удалял осталось в `/boot/`

Результат размещен в [Vagrant cloud](https://app.vagrantup.com/constantlux/boxes/ubuntu-20.04_kernel-6.6.1)

Образ создается с помощью packer и [Cloud-init](https://cloudinit.readthedocs.io/en/latest/index.html)

Обновление ядра с помощью [scripts/kernel.sh](scripts/kernel.sh) задействована утила [mainline](https://github.com/bkw777/mainline). В заметках предложены альтернативные варианты


```bash
$ vagrant box add constantlux/ubuntu-20.04_kernel-6.6.1 
$ vagrant init constantlux/ubuntu-20.04_kernel-6.6.1
$ vagrant ssh

vagrant@ubuntu-otus:~$ uname -a
Linux ubuntu-otus 6.6.1-060601-generic #202311151749 SMP PREEMPT_DYNAMIC Thu Nov 16 03:15:36 UTC 2023 x86_64 x86_64 x86_64 GNU/Linux
vagrant@ubuntu-otus:~$ lsb_release -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
```

## С чем работал:

Версии ПО на хостовой ОС
```bash
$ packer --version
1.9.4
$ vagrant --version
Vagrant 2.4.0
$ virtualbox --help
Oracle VM VirtualBox VM Selector v7.0.12
```

Хостовая ОС (поднята на VMware player)
```bash
$ uname -a
Linux lab 6.2.0-36-generic #37~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Mon Oct  9 15:34:04 UTC 2 x86_64 x86_64 x86_64 GNU/Linux

$ lsb_release  -a
No LSB modules are available.
Distributor ID:	Ubuntu
Description:	Ubuntu 22.04.3 LTS
Release:	22.04
Codename:	jammy
```


Собираем  Ubuntu Server 22.04 LTS. Автоматическая установка будет произодиться с помощью cloud-init (уже присутствует в системе)
```bash
$ vagrant ssh
...
vagrant@ubuntu-otus:~$ cloud-init --version
/usr/bin/cloud-init 23.2.1-0ubuntu0~22.04.1

```
## Особенности и заметки
### Автоустановка
С самого начала решил отойти от centos (поскольку ее по факту похоронили), в сторону deb. 
В ubuntu заметил, что по дефолту присутствует утилка Cloud-init, которая позволяет задать параметры для автоматической установки в yaml формате. 

Параметры установки описаны в [http/user-data](http/user-data). Там же оставил несколько комментариев

Так же есть пустой файл http/meta-data - требуется его наличие, как я понял туда вносятся переменные, например при развертывании инфраструктуры у IaaS-поставщика туда могут вносится имена сетевых интерфейсов. 
#### Сloud-init и shell
Так же есть возможность выполнить shell-команды в рамках одного конфигурационного файла 

- `early-commands` - команды которые будут выполнены в начале установки (пока не инициированы сетевые устройства)
- `late-commands `- команды которые будут выполнены после успешной устанвки
- `error-commands` - команды выполняемые в случае сбоя установки
- `bootcmd` - команды выполняемыепри каждой загрузке системы
- `runcmd` -  команды выполняемые при первой загрузке системы


> К сожалению, таким образом мне не удалось выполнить обновление ядра. Все изменения НЕ применялись к целовой системе. Либо я упорно оступался путая пространство установщика с пространством будующей системы либо присутствует баг. Потратил много времени и решил вернуться к этому позже

### Обновлене ядра:
Вижу три способа 
- из дефолтых репозиторев прямо в конфигурационном файле 
``` yaml
autoinstall:
...
  packages:
    - linux-generic-hwe-22.04 
```
- или собранные из исходников mainline, что собственно и требуется
    -  в скрипте scripts/kernel.sh первый вариант - с помощью утилки mainline, которая устанавливается из подключаемого репозитория
    - второй вариант (закомментирован в скрипте) - скачать собранное и упакованное в deb пакет ядро с https://kernel.ubuntu.com/mainline/  и следом установить скаченные пакеты


