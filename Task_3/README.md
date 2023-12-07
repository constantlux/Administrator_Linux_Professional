# ДЗ 3  Дисковая подсистема
**Задача:** 
- Добавить в Vagrantfile еще дисков.
- Собрать RAID-массив уровня 0/5/10 на выбор.
- Прописать собранный массив в конфиг, чтобы он собирался при загрузке
- Сломать/починить RAID.
- Создать GPT-таблицу и 5 разделов поверх массива, смонтировать их в системе.
    * Доп. задание — Vagrantfile, который сразу собирает систему с подключенным рейдом.
    
В качестве проверки принимается — измененный Vagrantfile, скрипт для создания рейда, конфиг для автосборки рейда при загрузке.

## Решение
Продолжаем работать на Ubuntu Server 22.04 LTS. Используя vagrant box собранный в [первом задании](https://github.com/constantlux/Administrator_Linux_Professional/tree/main/Task_1)

### Vagrantfile
1) Добавить в Vagrantfile еще дисков.
[Vagrantfile](Vagrantfile)

### Создаем RAID 
2) Объединим raid-массив разные блочные устройства - физические диски и разделы. Так вышло:) что у нас диски разного размера.

```

vagrant@nginx:~$ lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0    8G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm  /
sdb                         8:16   0  100M  0 disk 
sdc                         8:32   0  250M  0 disk 
sdd                         8:48   0  100M  0 disk 
sde                         8:64   0  250M  0 disk 
```


```
vagrant@nginx:~$ sudo mdadm --zero-superblock /dev/sd{b,c,d,e}
```

Утилкой `gdisk`  на дисках объемом 250М создаем разделы в 100М и 150М

```
vagrant@nginx:~$ lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0    8G  0 part 
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm  /
sdb                         8:16   0  100M  0 disk 
sdc                         8:32   0  250M  0 disk 
├─sdc1                      8:33   0  100M  0 part 
└─sdc2                      8:34   0  148M  0 part 
sdd                         8:48   0  100M  0 disk 
sde                         8:64   0  250M  0 disk 
├─sde1                      8:65   0  100M  0 part 
└─sde2                      8:66   0  148M  0 part 
```

Собираем рейд
```
vagrant@nginx:~$ sudo mdadm --create RAID10 -l 10 -n 4 /dev/sdb /dev/sdc1 /dev/sdd /dev/sde1
mdadm: Defaulting to version 1.2 metadata
mdadm: array /dev/md/RAID10 started.
```

На sdc2 и sde2  сберем RAID1.

Итого
```
vagrant@nginx:~$ cat /proc/mdstat 
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sde2[1] sdc2[0]
      150464 blocks super 1.2 [2/2] [UU]
      
md127 : active raid10 sde1[3] sdd[2] sdc1[1] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]

```
### Добавление в конфиг
в конфиг добавляем
```
vagrant@nginx:~$ cd /etc/mdadm/
vagrant@nginx:/etc/mdadm$ sudo su
root@nginx:/etc/mdadm# echo "DEVICE partitions" >> mdadm.conf
root@nginx:/etc/mdadm# mdadm --detail --scan --verbose | awk '/ARRAY/ {print}' >> mdadm.conf

```
Гузим машинку и убеждаемся что массивы на месте
```
vagrant@nginx:~$ sudo reboot
Connection to 127.0.0.1 closed by remote host.
lux@lab:~/OTUS_LINUX_PRO/Task_3$ vagrant ssh
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 6.6.1-060601-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.
Last login: Mon Dec  4 12:32:54 2023 from 10.0.2.2
vagrant@nginx:~$ cat /proc/mdstat 
Personalities : [raid10] [raid1] [linear] [multipath] [raid0] [raid6] [raid5] [raid4] 
md126 : active raid1 sde2[1] sdc2[0]
      150464 blocks super 1.2 [2/2] [UU]
      
md127 : active raid10 sdc1[1] sde1[3] sdd[2] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
```
### Ломаем / чиним
Создав разделы, фаловую систему и примонтировав, по примеру с лекции заполняем чем-нибудь

```
vagrant@nginx:~$ df -h
Filesystem                         Size  Used Avail Use% Mounted on
tmpfs                              198M  728K  197M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv  7.8G  4.3G  3.1G  59% /
tmpfs                              986M     0  986M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
/dev/sda2                          1.7G  271M  1.4G  17% /boot
vagrant                             98G   45G   54G  46% /vagrant
tmpfs                              198M  4.0K  198M   1% /run/user/1000
/dev/md126p1                       5.4M  5.2M     0 100% /raid/part1
/dev/md126p2                        15M   24K   14M   1% /raid/part2
/dev/md126p3                        25M   24K   22M   1% /raid/part3
/dev/md126p4                        34M   24K   31M   1% /raid/part4
/dev/md126p5                        40M   24K   37M   1% /raid/part5
/dev/md127                         168M   18M  137M  12% /raid/raid10
vagrant@nginx:~$ cat /raid/part1
cat: /raid/part1: Is a directory
vagrant@nginx:~$ ls /raid/part1
alternatives.log  apt  bootstrap.log  btmp  cloud-init-output.log  cloud-init.log  dist-upgrade  dpkg.log  faillog  fontconfig.log  installer  journal  lastlog  lost+found  wtmp
vagrant@nginx:~$ ls /raid/raid10
alternatives.log  bootstrap.log  cloud-init-output.log  dist-upgrade  faillog         installer  lastlog     private              wtmp
apt               btmp           cloud-init.log         dpkg.log      fontconfig.log  journal    lost+found  unattended-upgrades

```

Отмечаем блочные устройства как сбойные
```
vagrant@nginx:~$ sudo mdadm  /dev/md127 --fail /dev/sdc1
mdadm: set /dev/sdc1 faulty in /dev/md127
vagrant@nginx:~$ sudo mdadm  /dev/md126 --fail /dev/sdc2
mdadm: set /dev/sdc2 faulty in /dev/md126
vagrant@nginx:~$ cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sde2[1] sdc2[0](F)
      151488 blocks super 1.2 [2/1] [_U]
      
md127 : active raid10 sde1[3] sdd[2] sdc1[1](F) sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/3] [U_UU]
      
unused devices: <none>

```

```
vagrant@nginx:~$ sudo mdadm -D /dev/md126
/dev/md126:
           Version : 1.2
     Creation Time : Thu Dec  7 14:29:54 2023
        Raid Level : raid1
        Array Size : 151488 (147.94 MiB 155.12 MB)
     Used Dev Size : 151488 (147.94 MiB 155.12 MB)
      Raid Devices : 2
     Total Devices : 2
       Persistence : Superblock is persistent

       Update Time : Thu Dec  7 15:15:12 2023
             State : clean, degraded 
    Active Devices : 1
   Working Devices : 1
    Failed Devices : 1
     Spare Devices : 0

Consistency Policy : resync

              Name : nginx:RAIDE1  (local to host nginx)
              UUID : e66c4b48:a0a7e610:42078167:c85bf065
            Events : 19

    Number   Major   Minor   RaidDevice State
       -       0        0        0      removed
       1       8       66        1      active sync   /dev/sde2

       0       8       34        -      faulty   /dev/sdc2


vagrant@nginx:~$ cat /proc/mdstat
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sde2[1]
      151488 blocks super 1.2 [2/1] [_U]
      
md127 : active raid10 sde1[3] sdd[2] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/3] [U_UU]
      


```

"Меняем" диск

```
vagrant@nginx:~$ sudo dd if=/dev/sda of=/dev/sdc
dd: writing to '/dev/sdc': No space left on device
512001+0 records in
512000+0 records out
262144000 bytes (262 MB, 250 MiB) copied, 28.7572 s, 9.1 MB/s
vagrant@nginx:~$ lsblk 
NAME                      MAJ:MIN RM   SIZE RO TYPE   MOUNTPOINTS
sda                         8:0    0   9.8G  0 disk   
├─sda1                      8:1    0     1M  0 part   
├─sda2                      8:2    0   1.8G  0 part   /boot
└─sda3                      8:3    0     8G  0 part   
  └─ubuntu--vg-ubuntu--lv 252:0    0     8G  0 lvm    /
sdb                         8:16   0   100M  0 disk   
└─md127                     9:127  0   196M  0 raid10 /raid/raid10
sdc                         8:32   0   250M  0 disk   
sdd                         8:48   0   100M  0 disk   
└─md127                     9:127  0   196M  0 raid10 /raid/raid10
sde                         8:64   0   250M  0 disk   
├─sde1                      8:65   0   100M  0 part   
│ └─md127                   9:127  0   196M  0 raid10 /raid/raid10
└─sde2                      8:66   0   149M  0 part   
  └─md126                   9:126  0 147.9M  0 raid1  
    ├─md126p1             259:1    0    10M  0 part   /raid/part1
    ├─md126p2             259:6    0    20M  0 part   /raid/part2
    ├─md126p3             259:9    0    30M  0 part   /raid/part3
    ├─md126p4             259:12   0    40M  0 part   /raid/part4
    └─md126p5             259:13   0  46.9M  0 part   /raid/part5

```

Саздаем ту же схему разделов 

```
vagrant@nginx:~$ sudo ./gpt_250 /dev/sdc
Warning! Disk size is smaller than the main header indicates! Loading
secondary header from the last sector of the disk! You should use 'v' to
verify disk integrity, and perhaps options on the experts' menu to repair
the disk.
Caution: invalid backup GPT header, but valid main header; regenerating
backup header from main header.

Warning! One or more CRCs don't match. You should repair the disk!
Main header: OK
Backup header: ERROR
Main partition table: OK
Backup partition table: ERROR

****************************************************************************
Caution: Found protective or hybrid MBR and corrupt GPT. Using GPT, but disk
verification and recovery are STRONGLY recommended.
****************************************************************************
The operation has completed successfully.
The operation has completed successfully.
The operation has completed successfully.

```

и возвращаем диски на место

```
vagrant@nginx:~$ cat /proc/mdstat 
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sde2[1]
      151488 blocks super 1.2 [2/1] [_U]
      
md127 : active raid10 sdc1[4] sde1[3] sdd[2] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
vagrant@nginx:~$ cat /proc/mdstat 
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sde2[1]
      151488 blocks super 1.2 [2/1] [_U]
      
md127 : active raid10 sdc1[4] sde1[3] sdd[2] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>
vagrant@nginx:~$ sudo mdadm /dev/md126 --add /dev/sdc2
mdadm: added /dev/sdc2
vagrant@nginx:~$ cat /proc/mdstat 
Personalities : [linear] [multipath] [raid0] [raid1] [raid6] [raid5] [raid4] [raid10] 
md126 : active raid1 sdc2[2] sde2[1]
      151488 blocks super 1.2 [2/1] [_U]
      [===================>.]  recovery = 98.9% (150016/151488) finish=0.0min speed=150016K/sec
      
md127 : active raid10 sdc1[4] sde1[3] sdd[2] sdb[0]
      200704 blocks super 1.2 512K chunks 2 near-copies [4/4] [UUUU]
      
unused devices: <none>

```
### Создать GPT-таблицу и 5 разделов поверх массива, смонтировать их в системе.
[В скрипте](scripts/gpt5)

```
vagrant@nginx:~$ lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk   
├─sda1                      8:1    0    1M  0 part   
├─sda2                      8:2    0  1.8G  0 part   /boot
└─sda3                      8:3    0    8G  0 part   
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm    /
sdb                         8:16   0  100M  0 disk   
└─md127                     9:127  0  196M  0 raid10 
  ├─md127p1               259:0    0   10M  0 part   
  ├─md127p2               259:3    0   20M  0 part   
  ├─md127p3               259:4    0   30M  0 part   
  ├─md127p4               259:7    0   40M  0 part   
  └─md127p5               259:8    0   95M  0 part   
sdc                         8:32   0  250M  0 disk   
├─sdc1                      8:33   0  100M  0 part   
│ └─md127                   9:127  0  196M  0 raid10 
│   ├─md127p1             259:0    0   10M  0 part   
│   ├─md127p2             259:3    0   20M  0 part   
│   ├─md127p3             259:4    0   30M  0 part   
│   ├─md127p4             259:7    0   40M  0 part   
│   └─md127p5             259:8    0   95M  0 part   
└─sdc2                      8:34   0  149M  0 part   
sdd                         8:48   0  100M  0 disk   
└─md127                     9:127  0  196M  0 raid10 
  ├─md127p1               259:0    0   10M  0 part   
  ├─md127p2               259:3    0   20M  0 part   
  ├─md127p3               259:4    0   30M  0 part   
  ├─md127p4               259:7    0   40M  0 part   
  └─md127p5               259:8    0   95M  0 part   
sde                         8:64   0  250M  0 disk   
├─sde1                      8:65   0  100M  0 part   
│ └─md127                   9:127  0  196M  0 raid10 
│   ├─md127p1             259:0    0   10M  0 part   
│   ├─md127p2             259:3    0   20M  0 part   
│   ├─md127p3             259:4    0   30M  0 part   
│   ├─md127p4             259:7    0   40M  0 part   
│   └─md127p5             259:8    0   95M  0 part   
└─sde2                      8:66   0  149M  0 part   

```

### Vagrantfile, который сразу собирает систему с подключенным рейдом.

[Vagrantfile](Vagrantfile)
```
vagrant@nginx:~$ mount | grep raid
/dev/md127p1 on /raid/part1 type ext4 (rw,relatime,stripe=256)
/dev/md127p2 on /raid/part2 type ext4 (rw,relatime,stripe=256)
/dev/md127p3 on /raid/part3 type ext4 (rw,relatime,stripe=256)
/dev/md127p4 on /raid/part4 type ext4 (rw,relatime,stripe=256)
/dev/md127p5 on /raid/part5 type ext4 (rw,relatime,stripe=256)
```

```
vagrant@nginx:~$ lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE   MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk   
├─sda1                      8:1    0    1M  0 part   
├─sda2                      8:2    0  1.8G  0 part   /boot
└─sda3                      8:3    0    8G  0 part   
  └─ubuntu--vg-ubuntu--lv 252:0    0    8G  0 lvm    /
sdb                         8:16   0  100M  0 disk   
└─md127                     9:127  0  196M  0 raid10 
  ├─md127p1               259:0    0   10M  0 part   
  ├─md127p2               259:3    0   20M  0 part   
  ├─md127p3               259:4    0   30M  0 part   
  ├─md127p4               259:7    0   40M  0 part   
  └─md127p5               259:8    0   95M  0 part   
sdc                         8:32   0  250M  0 disk   
├─sdc1                      8:33   0  100M  0 part   
│ └─md127                   9:127  0  196M  0 raid10 
│   ├─md127p1             259:0    0   10M  0 part   
│   ├─md127p2             259:3    0   20M  0 part   
│   ├─md127p3             259:4    0   30M  0 part   
│   ├─md127p4             259:7    0   40M  0 part   
│   └─md127p5             259:8    0   95M  0 part   
└─sdc2                      8:34   0  149M  0 part   
sdd                         8:48   0  100M  0 disk   
└─md127                     9:127  0  196M  0 raid10 
  ├─md127p1               259:0    0   10M  0 part   
  ├─md127p2               259:3    0   20M  0 part   
  ├─md127p3               259:4    0   30M  0 part   
  ├─md127p4               259:7    0   40M  0 part   
  └─md127p5               259:8    0   95M  0 part   
sde                         8:64   0  250M  0 disk   
├─sde1                      8:65   0  100M  0 part   
│ └─md127                   9:127  0  196M  0 raid10 
│   ├─md127p1             259:0    0   10M  0 part   
│   ├─md127p2             259:3    0   20M  0 part   
│   ├─md127p3             259:4    0   30M  0 part   
│   ├─md127p4             259:7    0   40M  0 part   
│   └─md127p5             259:8    0   95M  0 part   
└─sde2                      8:66   0  149M  0 part   

```

## Заметки

