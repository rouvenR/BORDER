#!/bin/bash

apt-get install moreutils

# Docker
/grid5000/code/bin/g5k-setup-docker

# Ansible
apt-get install ansible

cd ..
cd ..
mkdir border-project
cd border-project

git clone https://github.com/containernet/containernet.git
cd containernet
mkdir BORDER
ansible-playbook -i "localhost," -c local -e "ansible_python_interpreter=/usr/bin/python3 force_install=true" ./ansible/install.yml

echo "pip installations"
apt-get install python3-venv
python3 -m venv venv
./venv/bin/python3 -m pip install .

sudo usermod -a -G sudo randerer
echo 'randerer ALL=(ALL) NOPASSWD: ALL' | sudo EDITOR='tee' visudo -f /etc/sudoers.d/randerer-nopasswd
sudo chmod 440 /etc/sudoers.d/randerer-nopasswd
sudo usermod -a -G docker randerer
sudo chmod -R a+rwx /border-project