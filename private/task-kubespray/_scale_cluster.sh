#!/bin/sh

###ssh-agent bash
#ssh-add ~/.ssh/id_rsa

ansible-playbook -u bond -k -i inventory/s00/hosts.ini scale.yml -b --diff
