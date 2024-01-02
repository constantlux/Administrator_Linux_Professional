#Вариант 1
sudo add-apt-repository ppa:cappelikan/ppa -y
sudo apt update -y
sudo apt install mainline -y
sudo mainline download 6.6
sudo mainline install 6.6
sudo apt --fix-broken install -y

#Вариант 2
# sudo mkdir update_kernel && cd update_kernel
# sudo wget https://kernel.ubuntu.com/mainline/v6.6-rc5/amd64/linux-headers-6.6.0-060600rc5_6.6.0-060600rc5.202310081731_all.deb
# sudo wget https://kernel.ubuntu.com/mainline/v6.6-rc5/amd64/linux-image-unsigned-6.6.0-060600rc5-generic_6.6.0-060600rc5.202310081731_amd64.deb
# sudo wget https://kernel.ubuntu.com/mainline/v6.6-rc5/amd64/linux-modules-6.6.0-060600rc5-generic_6.6.0-060600rc5.202310081731_amd64.deb
# sudo dpkg -i *.deb