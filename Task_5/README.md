# ДЗ4 | Файловые системы и LVM
**Задача:** 
Что нужно сделать?

1. Определить алгоритм с наилучшим сжатием:
 - Определить какие алгоритмы сжатия поддерживает zfs (gzip, zle, lzjb, lz4);
 - создать 4 файловых системы на каждой применить свой алгоритм сжатия;
 - для сжатия использовать либо текстовый файл, либо группу файлов.

 2. Определить настройки пула.
 С помощью команды zfs import собрать pool ZFS.
 Командами zfs определить настройки:
    
 - размер хранилища;
 - тип pool;
 - значение recordsize;
 - какое сжатие используется;
 - какая контрольная сумма используется.

 3. Работа со снапшотами:
- скопировать файл из удаленной директории;
- восстановить файл локально. zfs receive;
- найти зашифрованное сообщение в файле secret_message.


Статус «Принято» ставится при выполнении следующих условий:

- Сcылка на репозиторий GitHub.
- Vagrantfile с Bash-скриптом, который будет конфигурировать сервер
- Документация по каждому заданию:
    - название выполняемого задания;
    - текст задания;
    - описание команд и их вывод;
    - особенности проектирования и реализации решения;
    - заметки, если считаете, что имеет смысл их зафиксировать в репозитории.


## Решение
### 0. Подготовка

Продолжаем работать с [Ubuntu Server 22.04 LTS](https://releases.ubuntu.com/22.04.3/), который мучали ранее (кроме 4ДЗ). 

Не удалось на ядре 6.6.1 поднять zfs. Хотя по описанию релизов должно быть совместимо.
https://github.com/openzfs/zfs/releases/download/zfs-2.2.2/zfs-2.2.2.tar.gz


Поэтому используя ДЗ 1 создал отдельный бокс исключив обновление ядра. 

 В [Vagrantfile](Vagrantfile) через шел установим необхходимые компоненты

```
            config.vm.provision "shell", inline: <<-SHELL
              # 0.Install
              sudo su
              apt update
              apt install zfsutils-linux -y
              modprobe zfs
            SHELL
```

### 1. Определить алгоритм с наилучшим сжатием

Исходное состояние блочнх устройств
```
vagrant@zfs:lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0    8G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0    8G  0 lvm  /
sdb                         8:16   0  512M  0 disk 
sdc                         8:32   0  512M  0 disk 
sdd                         8:48   0  512M  0 disk 
sde                         8:64   0  512M  0 disk 
sdf                         8:80   0  512M  0 disk 
sdg                         8:96   0  512M  0 disk 
sdh                         8:112  0  512M  0 disk 
sdi                         8:128  0  512M  0 disk 
```
Создаем пулы с разными алгоритмами сжатия
```
root@zfs:zpool create otus_lzjb mirror /dev/sdb /dev/sdc
root@zfs:zpool create otus_lz4 mirror /dev/sdd /dev/sde
root@zfs:zpool create otus_gzip-9 mirror /dev/sdf /dev/sdg
root@zfs:zpool create otus_zle mirror /dev/sdh /dev/sdi
root@zfs:for i in lzjb lz4 gzip-9 zle; do zfs set compression=$i otus_$i; done
```

Смотрим что получили то что хотели с нужными алгоритмами компрессии
```
root@zfs:/home/vagrant# zpool list
NAME          SIZE  ALLOC   FREE  CKPOINT  EXPANDSZ   FRAG    CAP  DEDUP    HEALTH  ALTROOT
otus_gzip-9   480M   118K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus_lz4      480M   118K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus_lzjb     480M   118K   480M        -         -     0%     0%  1.00x    ONLINE  -
otus_zle      480M   114K   480M        -         -     0%     0%  1.00x    ONLINE  -
root@zfs:/home/vagrant# zfs get all | grep compression
otus_gzip-9  compression           gzip-9                 local
otus_lz4     compression           lz4                    local
otus_lzjb    compression           lzjb                   local
otus_zle     compression           zle                    local
root@zfs:/home/vagrant# lsblk 
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0  9.8G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0    8G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0    8G  0 lvm  /
sdb                         8:16   0  512M  0 disk 
├─sdb1                      8:17   0  502M  0 part 
└─sdb9                      8:25   0    8M  0 part 
sdc                         8:32   0  512M  0 disk 
├─sdc1                      8:33   0  502M  0 part 
└─sdc9                      8:41   0    8M  0 part 
sdd                         8:48   0  512M  0 disk 
├─sdd1                      8:49   0  502M  0 part 
└─sdd9                      8:57   0    8M  0 part 
sde                         8:64   0  512M  0 disk 
├─sde1                      8:65   0  502M  0 part 
└─sde9                      8:73   0    8M  0 part 
sdf                         8:80   0  512M  0 disk 
├─sdf1                      8:81   0  502M  0 part 
└─sdf9                      8:89   0    8M  0 part 
sdg                         8:96   0  512M  0 disk 
├─sdg1                      8:97   0  502M  0 part 
└─sdg9                      8:105  0    8M  0 part 
sdh                         8:112  0  512M  0 disk 
├─sdh1                      8:113  0  502M  0 part 
└─sdh9                      8:121  0    8M  0 part 
sdi                         8:128  0  512M  0 disk 
├─sdi1                      8:129  0  502M  0 part 
└─sdi9                      8:137  0    8M  0 part 

```

Скачиваем файл предложенный в методичке. В дополнение сгенерируем еще рандомный файл на 100Мбайт

```
dd if=/dev/urandom of=test bs=100M count=1
```
```
root@zfs:/home/vagrant# ls -lah test 
-rw-r--r-- 1 root root 100M Dec 25 13:20 test
root@zfs:/home/vagrant# ls -lah pg2600.converter.log 
-rw-r--r-- 1 root root 40M Dec  2 12:17 pg2600.converter.log
```
И раскидаем их в разные пулы

```
for i in lzjb lz4 gzip-9 zle; do cp pg2600.converter.log test /otus_$i;done
```

Итого смотрим 
```
root@zfs:/home/vagrant# zfs list
NAME          USED  AVAIL     REFER  MOUNTPOINT
otus_gzip-9   111M   241M      111M  /otus_gzip-9
otus_lz4      118M   234M      118M  /otus_lz4
otus_lzjb     122M   230M      122M  /otus_lzjb
otus_zle      139M   213M      139M  /otus_zle
root@zfs:/home/vagrant# zfs get all | grep compressr

root@zfs:/home/vagrant# zfs get compressratio 
NAME         PROPERTY       VALUE  SOURCE
otus_gzip-9  compressratio  1.25x  -
otus_lz4     compressratio  1.18x  -
otus_lzjb    compressratio  1.14x  -
otus_zle     compressratio  1.00x  -
```
Разница уже не столь значитаельная, нежели с примером в методичке


Проверим еще время копирования в пулы с разным сжатием
```
root@zfs:/home/vagrant# dd if=/dev/urandom of=test_time bs=100M count=1
1+0 records in
1+0 records out
104857600 bytes (105 MB, 100 MiB) copied, 0.32007 s, 328 MB/s
root@zfs:/home/vagrant# for i in lzjb lz4 gzip-9 zle; do time cp test_time /otus_$i;done

real	0m1.499s
user	0m0.000s
sys	0m0.031s

real	0m1.195s
user	0m0.000s
sys	0m0.032s

real	0m3.565s
user	0m0.000s
sys	0m0.029s

real	0m1.467s
user	0m0.000s
sys	0m0.030s

```

```
root@zfs:/home/vagrant# head test | hexdump -C
00000000  b1 44 95 d4 7a 6f 1d 58  5f fa 2f 90 f9 df 2b 14  |.D..zo.X_./...+.|
00000010  c2 49 b1 3f 0f c1 20 f4  b2 5d b8 c1 17 e8 6e 38  |.I.?.. ..]....n8|
00000020  48 cb 96 76 5d a5 7c a4  62 b1 06 52 8d 67 d9 23  |H..v].|.b..R.g.#|
00000030  09 b5 7a e2 98 89 7e 36  33 17 f2 1f 8b a2 6b 12  |..z...~63.....k.|
00000040  59 4e 9d b7 a8 a9 9a bc  2a d4 6c 66 20 de ea 4b  |YN......*.lf ..K|
00000050  f9 8c ad 78 f9 c2 dd e2  40 d6 91 84 8f b1 f2 41  |...x....@......A|
00000060  e2 98 3d f8 1f f7 fd 57  a5 66 a3 b1 99 da 23 c5  |..=....W.f....#.|

```

**Как вывод** -  подбирать компрессию надо исходя из задач)
Файлы имеют различные структуры. Тестовые сгенерированные файлы вовсе не уменьяшаются в своих размерах так как, по всей видимости, не имеют достаточного вхождения "повторений данных"
Так же на выбор может вляиять не только степень сжатия, но и другие параметры такие как время сжатия или распаковки или русурсы 

```
root@zfs:/home/vagrant# zfs list
NAME          USED  AVAIL     REFER  MOUNTPOINT
otus_gzip-9   300M  51.6M      300M  /otus_gzip-9
otus_lz4      300M  51.6M      300M  /otus_lz4
otus_lzjb     300M  51.6M      300M  /otus_lzjb
otus_zle      300M  51.6M      300M  /otus_zle
root@zfs:/home/vagrant# ls /otus*
/otus_gzip-9:
test  test2  test_time

/otus_lz4:
test  test2  test_time

/otus_lzjb:
test  test2  test_time

/otus_zle:
test  test2  test_time

```

### 2. Определить настройки пула
скачиваем и распаковываем файл 

```
vagrant@zfs:~$ sudo su
root@zfs:/home/vagrant# wget -O archive.tar.gz --no-check-certificate 'https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download'
tar -xf archive.tar.gz
--2024-01-02 13:15:13--  https://drive.usercontent.google.com/download?id=1MvrcEp-WgAQe57aDEzxSRalPAwbNN1Bb&export=download
Resolving drive.usercontent.google.com (drive.usercontent.google.com)... 74.125.131.132, 2a00:1450:4010:c0e::84
Connecting to drive.usercontent.google.com (drive.usercontent.google.com)|74.125.131.132|:443... connected.
HTTP request sent, awaiting response... 200 OK
Length: 7275140 (6.9M) [application/octet-stream]
Saving to: ‘archive.tar.gz’

archive.tar.gz                                 100%[===================================================================================================>]   6.94M  --.-KB/s    in 0.1s    

2024-01-02 13:15:18 (48.3 MB/s) - ‘archive.tar.gz’ saved [7275140/7275140]

root@zfs:/home/vagrant# ls
VBoxGuestAdditions.iso  archive.tar.gz  zpoolexport

```

проверка возмождности импорта

```
root@zfs:/home/vagrant# zpool import -d zpoolexport/
   pool: otus
     id: 6554193320433390805
  state: ONLINE
status: Some supported features are not enabled on the pool.
	(Note that they may be intentionally disabled if the
	'compatibility' property is set.)
 action: The pool can be imported using its name or numeric identifier, though
	some features will not be available without an explicit 'zpool upgrade'.
 config:

	otus                                 ONLINE
	  mirror-0                           ONLINE
	    /home/vagrant/zpoolexport/filea  ONLINE
	    /home/vagrant/zpoolexport/fileb  ONLINE

```

Импортируем

```
root@zfs:/home/vagrant# zpool import -d zpoolexport/ otus
root@zfs:/home/vagrant# zpool status
  pool: otus
 state: ONLINE
status: Some supported and requested features are not enabled on the pool.
	The pool can still be used, but some features are unavailable.
action: Enable all features using 'zpool upgrade'. Once this is done,
	the pool may no longer be accessible by software that does not support
	the features. See zpool-features(7) for details.
config:

	NAME                                 STATE     READ WRITE CKSUM
	otus                                 ONLINE       0     0     0
	  mirror-0                           ONLINE       0     0     0
	    /home/vagrant/zpoolexport/filea  ONLINE       0     0     0
	    /home/vagrant/zpoolexport/fileb  ONLINE       0     0     0

errors: No known data errors

```
Определяем интересующие нас настройки пула
```
root@zfs:/home/vagrant# zfs get available otus
zfs get readonly otus
zfs get recordsize otus
zfs get compression otus
zfs get checksum otus
NAME  PROPERTY   VALUE  SOURCE
otus  available  350M   -
NAME  PROPERTY  VALUE   SOURCE
otus  readonly  off     default
NAME  PROPERTY    VALUE    SOURCE
otus  recordsize  128K     local
NAME  PROPERTY     VALUE           SOURCE
otus  compression  zle             local
NAME  PROPERTY  VALUE      SOURCE
otus  checksum  sha256     local

```

### 3. Работа со снапшотами:

Скачиваем снапшот 
```
[1]+  Done                    wget -O otus_task2.file --no-check-certificate https://drive.usercontent.google.com/download?id=1wgxjih8YZ-cqLqaZVa0lA3h3Y029c3oI

```
Восстанавливаем из него ФС и, зная название файла, ищим его и просматриваем содержимое

```
root@zfs:/home/vagrant# zfs receive otus/test@today < otus_task2.file
root@zfs:/home/vagrant# cat `find /otus/test -name secret_message`
https://otus.ru/lessons/linux-hl/


```


## Заметки

