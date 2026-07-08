#!/bin/bash

apt-get install moreutils

# Docker
# /grid5000/code/bin/g5k-setup-docker
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh

# Ansible
apt-get install ansible

cd ..
cd ..
mkdir -p border-project
cd border-project

git clone https://github.com/rouvenR/containernet.git
cd containernet
mkdir -p BORDER
ansible-playbook -i "localhost," -c local -e "ansible_python_interpreter=/usr/bin/python3 force_install=true" ./ansible/install.yml

echo "pip installations"
apt-get install python3-venv
python3 -m venv venv
./venv/bin/python3 -m pip install .

chmod -R a+rwx /border-project