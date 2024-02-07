# ДЗ 10 | Bash
**Задача:** 
Написать скрипт для CRON, который раз в час будет формировать письмо и отправлять на заданную почту.

Необходимая информация в письме:

- Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;
- Ошибки веб-сервера/приложения c момента последнего запуска;
- Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.
- Скрипт должен предотвращать одновременный запуск нескольких копий, до его завершения.
- В письме должен быть прописан обрабатываемый временной диапазон.

Критерии оценки:
Трапы и функции, а также sed и find +1 балл.


## 0. Формализация 
Работаем с предложенным на задании [логом apache](files/apache_logs)
### Чтение лога
В нашем случае чтение будет из файла

Чекнуть наличие
```bash
vagrant@nginx:~$ find /home/vagrant/apache_logs
/home/vagrant/apache_logs
```

### Откуда продолжать при следующем запуске?
Фиксируем полную последюю обработанную строку т.к. времени не достаточно для продолжения обработки  при следующем вызове. Фиксируем именно содержание, а не номер строки (При ротации непонятно с какого файла начинать)

Пример повтора, если по времени
```bash
lux@lab:~/OTUS_LINUX_PRO/Task_10$ grep 17/May/2015:10:05:59 files/apache_logs
83.149.9.216 - - [17/May/2015:10:05:59 +0000] "GET /presentations/logstash-monitorama-2013/images/logstashbook.png HTTP/1.1" 200 54662 "http://semicomplete.com/presentations/logstash-monitorama-2013/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.77 Safari/537.36"
87.169.99.232 - - [17/May/2015:10:05:59 +0000] "GET /presentations/puppet-at-loggly/puppet-at-loggly.pdf.html HTTP/1.1" 200 24747 "https://www.google.de/" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36"
```

Для дальнейшей обработки найти строку, определить её номер +1 и вывести файл до конца

```bash


lux@lab:~/OTUS_LINUX_PRO/Task_10$ nl files/apache_logs | grep -F '63.140.98.80 - - [20/May/2015:21:05:50 +0000] "GET /blog/geekery/solving-good-or-bad-problems.html?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+semicomplete%2Fmain+%28semicomplete.com+-+Jordan+Sissel%29 HTTP/1.1" 200 10756 "-" "Tiny Tiny RSS/1.11 (http://tt-rss.org/)"'
  9997	63.140.98.80 - - [20/May/2015:21:05:50 +0000] "GET /blog/geekery/solving-good-or-bad-problems.html?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+semicomplete%2Fmain+%28semicomplete.com+-+Jordan+Sissel%29 HTTP/1.1" 200 10756 "-" "Tiny Tiny RSS/1.11 (http://tt-rss.org/)"

lux@lab:~/OTUS_LINUX_PRO/Task_10$ tail -n+9997 files/apache_logs
63.140.98.80 - - [20/May/2015:21:05:50 +0000] "GET /blog/geekery/solving-good-or-bad-problems.html?utm_source=feedburner&utm_medium=feed&utm_campaign=Feed%3A+semicomplete%2Fmain+%28semicomplete.com+-+Jordan+Sissel%29 HTTP/1.1" 200 10756 "-" "Tiny Tiny RSS/1.11 (http://tt-rss.org/)"
66.249.73.135 - - [20/May/2015:21:05:00 +0000] "GET /?flav=atom HTTP/1.1" 200 32352 "-" "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
180.76.6.56 - - [20/May/2015:21:05:56 +0000] "GET /robots.txt HTTP/1.1" 200 - "-" "Mozilla/5.0 (Windows NT 5.1; rv:6.0.2) Gecko/20100101 Firefox/6.0.2"
46.105.14.53 - - [20/May/2015:21:05:15 +0000] "GET /blog/tags/puppet?flav=rss20 HTTP/1.1" 200 14872 "-" "UniversalFeedParser/4.2-pre-314-svn +http://feedparser.org/"

```
Вывод нового "куска" лога предлагаю сохранить во временный файл.
После удалим временный файл.
Зачем? Лог может быть дополнен приложением, а у нас несколько раз будет обращение к файлу лога в том числе чтоб зафиксировать последнюю обработанную строку. 

### Временной интервал обработанного лога
Берем первую и последнюю строку из временного файла
```bash
vagrant@nginx:~$ head -n 1 apache_logs | awk '{print $4" "$5}' | sed -r 's/(\[|\])//g'
17/May/2015:10:05:03 +0000
vagrant@nginx:~$ tail -n 1 apache_logs | awk '{print $4" "$5}' | sed -r 's/(\[|\])//g'
20/May/2015:21:05:15 +0000

```

### Структура лога и парсинг
```bash
72.4.104.94 - - [20/May/2015:15:05:01 +0000] "GET /images/web/2009/banner.png HTTP/1.1" 200 52315 "http://www.semicomplete.com/blog/geekery/python-method-call-wrapper.html" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36"
```
по порядку
| значение   | описание|
| ----------- | ----------- |
| 72.4.104.94      | ip src       |
| -   | id клиента        |
| -   | имя пользователя, если аутентификация пройдена        |
| [20/May/2015:15:05:01 +0000]  | время запроса       |
| "GET /images/web/2009/banner.png HTTP/1.1"   | строка запроса. HTTP-метод, URL, Версия      |
| 200  | http код ответа        |
| 52315  | размер ответа в байтах без http заголовка       |
| ``"http://www.semicomplete.com/blog/geekery/python-method-call-wrapper.html"``  | Откуда обращение/кто ссылается       |
| "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/32.0.1700.107 Safari/537.36"   | описание клиента пользователя       |


Список IP адресов (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего запуска скрипта;

Топ 20
```bash
agrant@nginx:~$ cat apache_logs | awk '{print $1}'  | sort | uniq -c | sort -r | head -n 20
    482 66.249.73.135
    364 46.105.14.53
    357 130.237.218.86
    273 75.97.9.59
    113 50.16.19.13
    102 209.85.238.199
     99 68.180.224.225
     84 100.43.83.137
     83 208.115.111.72
     82 198.46.149.143
     74 208.115.113.88
     65 108.171.116.194
     60 65.55.213.73
     60 208.91.156.11
     56 66.249.73.185
     52 50.139.66.106
     50 86.76.247.183
     50 14.160.65.22
     43 93.17.51.134
     42 208.43.252.200

```
Список запрашиваемых URL (с наибольшим кол-вом запросов) с указанием кол-ва запросов c момента последнего 
запуска скрипта;

Топ 20
```bash
vagrant@nginx:~$ cat apache_logs | awk '{print $7}'  | sort | uniq -c | sort -r | head -n 20
    807 /favicon.ico
    546 /style2.css
    538 /reset.css
    533 /images/jordan-80.png
    516 /images/web/2009/banner.png
    488 /blog/tags/puppet?flav=rss20
    224 /projects/xdotool/
    217 /?flav=rss20
    197 /
    180 /robots.txt
    154 /projects/xdotool/xdotool.xhtml
    137 /?flav=atom
    135 /articles/dynamic-dns-with-dhcp/
    128 /presentations/logstash-scale11x/images/ahhh___rage_face_by_samusmmx-d5g5zap.png
    101 /images/googledotcom.png
     77 /blog/geekery/ssl-latency.html
     61 /files/logstash/logstash-1.3.2-monolithic.jar
     58 /blog/tags/firefox?flav=rss20
     55 /articles/ssh-security/
     51 /presentations/logstash-puppetconf-2012/
```

Список всех кодов HTTP ответа с указанием их кол-ва с момента последнего запуска скрипта.

Топ 20
```bash
vagrant@nginx:~$ cat apache_logs | awk '{print $9}'  | sort | uniq -c | sort -r | head -n 20
   9126 200
    445 304
    213 404
    164 301
     45 206
      3 500
      2 416
      2 403

```
Ошибки веб-сервера/приложения c момента последнего запуска;

```bash
cat apache_logs | awk '{print $9}' | grep -P "^5\d\d" | sort | uniq -c | sort -r
      3 500
```


### Имитация mail
```bash
vagrant@nginx:~$ echo "Результаты" | mail -s "Поставка парсинга" my@examle.org
vagrant@nginx:~$ tail -n 15 /var/mail/vagrant 

Return-Path: <vagrant@nginx>
Received: by nginx.mshome.net (Postfix, from userid 1000)
	id 3C7253F255; Thu,  1 Feb 2024 23:25:51 +0300 (MSK)
Subject: Поставка парсинга
To: <my@examle.org>
User-Agent: mail (GNU Mailutils 3.14)
Date: Thu,  1 Feb 2024 23:25:51 +0300
Message-Id: <20240201202551.3C7253F255@nginx.mshome.net>
From: vagrant <vagrant@nginx>

Результаты

--3C7253F255.1706819151/nginx.mshome.net--

```




## 1. Решение
Всё упаковано в [Vagrantfile](Vagrantfile) 
Через пару минут можно посмотреть, что отправилось.
Первое должно быть со всем выводом. Последующие с инфой что лог не обновляется **/var/mail/vagrant**

Поведение можно поменять путем изменения данных о последней прочитанной строке лога - файл рядом со скриптом **last_row** или дополнить лог
### Скрипт
Парсинг лога и отправка отчёта реализован в [скрипте](files/script.sh)

### Крон с защитой от повторного запуска.
Для контроля повторного запуска будем использовать утилу flock. Ей передаем лок файл и запускаемое приложение.

Для таста будем выполнять не каждый час, а каждую минуту
```bash
echo "*/1 * * * *   vagrant /usr/bin/flock -xn /var/lock/my_lock -c '/home/vagrant/script.sh'" >> /etc/crontab
```
Лог файл и то что касается скрипта оставим в домашней дериктории.

### Проверка скрипта

В полученных значениях те же данные что при формализации


### Проверка всего ДЗ 
```
...
Subject: Поставка парсинга
To: <my@examle.org>
User-Agent: mail (GNU Mailutils 3.14)
Date: Wed,  7 Feb 2024 16:06:01 +0300
Message-Id: <20240207130601.24CE53F5ED@nginx.mshome.net>
From: vagrant <vagrant@nginx>


        Обработаны логи за интервал
        17/May/2015:10:05:03 +0000 -  20/May/2015:21:05:15 +0000
        ТОП 20 ip
          count ip
            482 66.249.73.135
    364 46.105.14.53
    357 130.237.218.86
    273 75.97.9.59
    113 50.16.19.13
    102 209.85.238.199
     99 68.180.224.225
     84 100.43.83.137
и тд
...
Subject: Поставка парсинга
To: <my@examle.org>
User-Agent: mail (GNU Mailutils 3.14)
Date: Wed,  7 Feb 2024 16:07:01 +0300
Message-Id: <20240207130701.2DD9E3F266@nginx.mshome.net>
From: vagrant <vagrant@nginx>

Нет новых записей

```

## Заметки
По хорошему учесть ротацию логов и скрипт натравливать на файл со свежей ротации, вместо костылей с временным файлом