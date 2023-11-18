#!/usr/bin/env bash
sudo mkdir -pm 700 /home/vagrant/.ssh
sudo sh -c "curl -L https://raw.github.com/mitchellh/vagrant/master/keys/vagrant.pub -o /home/vagrant/.ssh/authorized_keys"
sudo chmod 0600 /home/vagrant/.ssh/authorized_keys
sudo chown -R vagrant /home/vagrant/.ssh