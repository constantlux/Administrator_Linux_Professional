# ДЗ8 | Работа с загрузчиком
**Задача:** 
- Попасть в систему без пароля несколькими способами.
- Установить систему с LVM, после чего переименовать VG.
- Добавить модуль в initrd.

## Решение
Продолжаем работать с ubuntu 22.04.

[Vagrantfile](Vagrantfile)
### 0. Попасть в систему без пароля несколькими способами.

![Alt text](<img/Screenshot from 2024-01-13 19-02-39.png>)

#### Вариант 1 single user mode


![Alt text](<img/Screenshot from 2024-01-13 19-34-28.png>) 

![Alt text](<img/Screenshot from 2024-01-13 19-34-48.png>)

![Alt text](<img/Screenshot from 2024-01-13 19-41-28.png>) 

![Alt text](<img/Screenshot from 2024-01-13 19-41-36.png>) 

![Alt text](<img/Screenshot from 2024-01-13 19-42-42.png>) 

![Alt text](<img/Screenshot from 2024-01-13 19-43-24.png>)


#### Вариант 2 emergency mode 

Добавляем 
systemd.unit=rescue.target или systemd.unit=emergency.target

![Alt text](<img/Screenshot from 2024-01-13 19-54-48.png>) 
![Alt text](<img/Screenshot from 2024-01-13 19-55-28.png>) 
![Alt text](<img/Screenshot from 2024-01-13 19-57-46.png>) 
![Alt text](<img/Screenshot from 2024-01-13 19-59-39.png>)

#### Вариант 3 single user mode + rw
Повторим вариант 1, но сразу зададим rw режим

![Alt text](<img/Screenshot from 2024-01-13 20-06-01.png>)

 ![Alt text](<img/Screenshot from 2024-01-13 20-06-26.png>)


**Вывод:**

Разница примерно в следующем в single user мы получаем нашу ОС, но без сервисов которые стартуют в многопользовательском режиме (Например сеть и иксы) мы их можем запустить при необходимости.

emergency mode - по сути должна быть временная система (init ram fs) из которой мы можем сделать chroot в нашу предположительно не рабочую, но как я понял в образе в котором проводилась работа я всё равно сразу оказался в нашей обычной (предполодительно некорректно работающей) ОС и chroot не понядобился.

### 1. Установить систему с LVM, после чего переименовать VG.

Смотрим существующуе volume groups

```bash
root@nginx:/home/vagrant# vgs
  VG        #PV #LV #SN Attr   VSize VFree
  ubuntu-vg   1   1   0 wz--n- 8.01g    0 

```

Переименовываем и проверяем
```bash
root@nginx:/home/vagrant# vgrename ubuntu-vg OTUS-task8
  Volume group "ubuntu-vg" successfully renamed to "OTUS-task8"
root@nginx:/home/vagrant# vgs
  VG         #PV #LV #SN Attr   VSize VFree
  OTUS-task8   1   1   0 wz--n- 8.01g    
```

Правим fstab и grub

```bash
root@nginx:/home/vagrant# cat /boot/grub/grub.cfg | grep ubuntu--vg-ubuntu--lv
	linux	/vmlinuz-5.15.0-91-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro  autoinstall ds=nocloud-net;s=http://10.0.2.2:8112/
		linux	/vmlinuz-5.15.0-91-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro  autoinstall ds=nocloud-net;s=http://10.0.2.2:8112/
		linux	/vmlinuz-5.15.0-91-generic root=/dev/mapper/ubuntu--vg-ubuntu--lv ro single nomodeset dis_ucode_ldr 

root@nginx:/home/vagrant# sed -i 's/ubuntu--vg-ubuntu--lv/OTUS--task8-ubuntu--lv/g' /boot/grub/grub.cfg

root@nginx:/home/vagrant# cat /etc/fstab 
# /etc/fstab: static file system information.
#
# Use 'blkid' to print the universally unique identifier for a
# device; this may be used with UUID= as a more robust way to name devices
# that works even if disks are added and removed. See fstab(5).
#
# <file system> <mount point>   <type>  <options>       <dump>  <pass>
# / was on /dev/ubuntu-vg/ubuntu-lv during curtin installation
/dev/mapper/OTUS--task8-ubuntu--lv / ext4 defaults 0 1
# /boot was on /dev/sda2 during curtin installation
/dev/mapper/OTUS--task8-ubuntu--lv /boot ext4 defaults 0 1
/swap.img	none	swap	sw	0	0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
vagrant /vagrant vboxsf uid=1000,gid=1000,_netdev 0 0
#VAGRANT-END

```
Грузимся и проверяем 
```bash
root@nginx:/home/vagrant# reboot 
Connection to 127.0.0.1 closed by remote host.

lux@lab:~/OTUS_LINUX_PRO/Task_8$ vagrant ssh
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Sat Jan 20 12:26:17 2024 from 10.0.2.2

vagrant@nginx:~$ sudo vgs
  VG         #PV #LV #SN Attr   VSize VFree
  OTUS-task8   1   1   0 wz--n- 8.01g    0 
```

### 2. Добавить модуль в initrd

Скриптик можем запустить в разные моменты загрузки системы. Для этого достаточно разместить в соответствующем каталоге 
```bash
vagrant@nginx:~$ ll /etc/initramfs-tools/scripts/
total 48
drwxr-xr-x 12 root root 4096 Aug 10 03:20 ./
drwxr-xr-x  5 root root 4096 Aug 10 03:20 ../
drwxr-xr-x  2 root root 4096 Jun 14  2023 init-bottom/
drwxr-xr-x  2 root root 4096 Jun 14  2023 init-premount/
drwxr-xr-x  2 root root 4096 Jun 14  2023 init-top/
drwxr-xr-x  2 root root 4096 Jun 14  2023 local-bottom/
drwxr-xr-x  2 root root 4096 Jun 14  2023 local-premount/
drwxr-xr-x  2 root root 4096 Jun 14  2023 local-top/
drwxr-xr-x  2 root root 4096 Jun 14  2023 nfs-bottom/
drwxr-xr-x  2 root root 4096 Jun 14  2023 nfs-premount/
drwxr-xr-x  2 root root 4096 Jun 14  2023 nfs-top/
drwxr-xr-x  2 root root 4096 Jun 14  2023 panic/

```

```bash
vagrant@nginx:~$ cat /etc/initramfs-tools/scripts/init-top/test01
#!/bin/sh
PREREQ=""
prereqs()
{
        echo "$PREREQ"
}

case $1 in
prereqs)
        prereqs
        exit 0
        ;;
esac
exec 0<>/dev/console 1<>/dev/console 2<>/dev/console
cat <<'msgend'
Hello!
This first script to be executed after sysfs and procfs have been mounted.
 ___________________
< I'm initramfs script >
 -------------------
   \
    \
        .--.
       |o_o |
       |:_/ |
      //   \ \
     (|     | )
    /'\_   _/`\
    \___)=(___/
msgend
sleep 30
echo " continuing..."


```
Делаем скрипт исполняемым и обнавляем initramfs

```bash
vagrant@nginx:~$ sudo chmod +x /etc/initramfs-tools/scripts/init-top/test01
vagrant@nginx:~$ sudo update-initramfs -v -u -k all
```
Гразимся и проверяем. 

Править в загрузчике ничего не надо по умолчанию в болтливом режиме.

![Alt text](<img/Screenshot from 2024-01-21 14-14-39.png> )
## Заметки