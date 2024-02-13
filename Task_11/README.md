# ДЗ 11 |  Управление процессами 
**Задача:** 

Задания на выбор:

- **написать свою реализацию ps ax используя анализ /proc**

    Результат ДЗ - рабочий скрипт который можно запустить




## 0. Формализация
Определим информацию, которую должны достать
```
vagrant@nginx:/proc$ ps ax | head
    PID TTY      STAT   TIME COMMAND
      1 ?        Ss     0:02 /lib/systemd/systemd autoinstall --system --deserialize 39
      2 ?        S      0:00 [kthreadd]
      3 ?        I<     0:00 [rcu_gp]
      4 ?        I<     0:00 [rcu_par_gp]
      5 ?        I<     0:00 [slub_flushwq]
      6 ?        I<     0:00 [netns]
      8 ?        I<     0:00 [kworker/0:0H-events_highpri]
     10 ?        I<     0:00 [mm_percpu_wq]
     11 ?        S      0:00 [rcu_tasks_rude_]
vagrant@nginx:/proc$ 

```
Информация которую нам необходимо вытащить из /proc
### PID
```
agrant@nginx:/proc$ ls | grep -E "^[0-9]+$" | head
1
10
100
101
1015
103
105
106
11
116

```
### TTY
Проверяем наличие ссылки потока ввода 
```
vagrant@nginx:/proc$ sudo ls -l */fd/0
lr-x------ 1 vagrant vagrant 64 Feb 11 22:56 1300/fd/0 -> /dev/null
lrwx------ 1 vagrant vagrant 64 Feb 11 23:02 1328/fd/0 -> /dev/pts/0
lrwx------ 1 vagrant vagrant 64 Feb 11 23:53 15134/fd/0 -> /dev/tty1
lrwx------ 1 root    root    64 Feb 12 00:20 self/fd/0 -> /dev/pts/1
lrwx------ 1 root    root    64 Feb 12 00:20 thread-self/fd/0 -> /dev/pts/1

```
### STAT
Выташить статус проще из 
```
vagrant@nginx:/proc$ cat ./1/stat | awk '{print $3}'
S
```
### TIME


Тут пришлось погуглить

- [Anton Panov hightemp | Как рассчитывается время и процент использования ЦП Linux](https://github.com/hightemp/docLinux/blob/master/articles/%D0%9A%D0%B0%D0%BA%20%D1%80%D0%B0%D1%81%D1%81%D1%87%D0%B8%D1%82%D1%8B%D0%B2%D0%B0%D0%B5%D1%82%D1%81%D1%8F%20%D0%B2%D1%80%D0%B5%D0%BC%D1%8F%20%D0%B8%20%D0%BF%D1%80%D0%BE%D1%86%D0%B5%D0%BD%D1%82%20%D0%B8%D1%81%D0%BF%D0%BE%D0%BB%D1%8C%D0%B7%D0%BE%D0%B2%D0%B0%D0%BD%D0%B8%D1%8F%20%D0%A6%D0%9F%20Linux.md)

- [stackoverflow |  https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat](https://stackoverflow.com/questions/16726779/how-do-i-get-the-total-cpu-usage-of-an-application-from-proc-pid-stat)

Пришел к такому решению Потом сравним со стандартными утилитами
```                                        
     let "u_cpu=((${stat[13]}+${stat[14]})/$CLK_TCK)"           
     mm=$((( u_cpu/60)%60))                                     
     ss=$((u_cpu%60))                                                                                        
     time="$mm:$ss"                                             

```

### COMMAND
Тут зависит от того в каком пространстве выполняется пользователя или ядра

При наличии выводим /proc/PID/cmdline 

При отсутствии 
```
vagrant@nginx:/proc$ cat 2/stat | awk '{print $2}'
(kthreadd)
```


## 1. Решение 
Сравнение выполнения [скрипта](script.sh) и ps aux
![Alt text](<Screenshot from 2024-02-14 00-51-56.png>)

Из подставы в tmux лишний пробел всплыл откуда получили неверный статус и время (из-за смещения по массиву) :) 

Целью было данной проверки было сравнить корректност подсчета времени, поэтому незначащие строки исключил.

Опции отсутствуют, утилы все дефолтные.
## Заметки
В целом есть над чем поработать...