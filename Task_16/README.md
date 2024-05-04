# ДЗ 16 | Основы сбора и хранения логов 
**Задача:** 
Что нужно сделать?

- в вагранте поднимаем 2 машины web и log:

    -   на web поднимаем nginx

    - на log настраиваем центральный лог сервер на любой системе на выбор:
        - journald;
        - rsyslog;
        - elk.

- настраиваем аудит, следящий за изменением конфигов нжинкса
- Все критичные логи с web должны собираться и локально и удаленно.
- Все логи с nginx должны уходить на удаленный сервер (локально только критичные).
- Логи аудита должны также уходить на удаленную систему.
- Формат сдачи ДЗ - vagrant + ansible

## 0. Описние
VM на Ubuntu Server 22.04 LTS. Использовался vagrant box собранный в [первом задании](https://github.com/constantlux/Administrator_Linux_Professional/tree/main/Task_1)

Деплой обеих ВМ в [Vagrantfile](Vagrantfile). После поднятия VM выполняется сценарий.

За основу взят playbook из [второго задания](https://github.com/constantlux/Administrator_Linux_Professional/tree/main/Task_2). Установка NGNIX из репозитория разработчиков.

В playbook добавлено:
- установка rsyslog, auditd  на ВМ web 
- установка rsyslog на ВМ log
- конфигурация rsyslog на ВМ log посредством shell echo 
- конфигурация rsyslog на ВМ web посредством [шаблона jinja2](templates/rsyslog.conf.j2)
- внесены правки в шаблон конфига [NGINX](templates/nginx.conf.j2). Добален стрим логов
- Добавлена переменная ansible хранящая ip log-сервера
- Правила для auditd добавляются вызывом хендлера add_auditd_rule. Для записей добавляется ключ NGINX_CONF_AUDIT, но парсинг отсутствует.

## 1. Результаты
[Vagrantfile](Vagrantfile) поднимает рабочий стенд. 
Достаточно сделать события. 

Для теста получил http коды 200 404. И изменение файла конифга NGINX
![alt text](<img/Screenshot from 2024-05-04 16-13-44.png>)

## Заметки