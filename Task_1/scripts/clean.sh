#!/usr/bin/env bash
#чистим неиспользуемые пакеты и зависимости
sudo apt autoclean
sudo apt autoremove
sudo apt clean
sudo rm -rf /tmp/*
sudo rm -rf /usr/share/doc/*
sudo rm -rf /run/log/journal/*
sudo rm  -f ~/.bash_history
sudo history -c
# если пробежаться по пустому пространству и записать нулямями сжатие пройдет эффективнее в моем случае примерно на 600Мбайт меньше вышел box
sudo dd if=/dev/zero of=/EMPTY bs=1M
sudo rm -f /EMPTY
sudo sync
sudo sync
sudo sync