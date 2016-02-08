#!/bin/bash

ANSIBLE_PLAYBOOK=$1
ANSIBLE_HOSTS=$2
ANSIBLE_EXTRA_VARS="$3"
TEMP_HOSTS="/tmp/ansible_hosts"

VAGRANT_ROOT_PATH="${VAGRANT_ROOT_PATH:-/vagrant}"
ANSIBLE_PLAYBOOK_PATH="$VAGRANT_ROOT_PATH/$ANSIBLE_PLAYBOOK"
ANSIBLE_HOSTS_PATH="$VAGRANT_ROOT_PATH/$ANSIBLE_HOSTS"

if [ ! -f $ANSIBLE_PLAYBOOK_PATH ]; then
        echo "ERROR: Cannot find the given Ansible playbook."
        exit 1
fi

if [ ! -f $ANSIBLE_HOSTS_PATH ]; then
        echo "ERROR: Cannot find the given Ansible hosts file."
        exit 2
fi

if ! command -v ansible >/dev/null; then
        echo "Installing Ansible dependencies and Git."
        if command -v yum >/dev/null; then
                sudo yum install -y gcc git python python-devel
        elif command -v apt-get >/dev/null; then
                sudo apt-get update -qq
                #sudo apt-get install -y -qq git python-yaml python-paramiko python-jinja2
                sudo apt-get install -y -qq git python python-dev
        else
                echo "neither yum nor apt-get found!"
                exit 1
        fi
        echo "Installing pip via easy_install."
        wget http://peak.telecommunity.com/dist/ez_setup.py
        sudo python ez_setup.py && rm -f ez_setup.py
        sudo easy_install pip
        # Make sure setuptools are installed crrectly.
        sudo pip install setuptools --no-use-wheel --upgrade
        echo "Installing required python modules."
        sudo pip install paramiko pyyaml jinja2 markupsafe
        sudo pip install ansible
fi

if [ ! -z "$ANSIBLE_EXTRA_VARS" -a "$ANSIBLE_EXTRA_VARS" != " " ]; then
        ANSIBLE_EXTRA_VARS=" --extra-vars $ANSIBLE_EXTRA_VARS"
fi

# stream output
export PYTHONUNBUFFERED=1
# show ANSI-colored output
export ANSIBLE_FORCE_COLOR=true

cp ${ANSIBLE_HOSTS_PATH} ${TEMP_HOSTS} && chmod -x ${TEMP_HOSTS}
echo "Running Ansible as $USER:"
ansible-playbook ${ANSIBLE_PLAYBOOK_PATH} --inventory-file=${TEMP_HOSTS} --connection=local $ANSIBLE_EXTRA_VARS
rm ${TEMP_HOSTS}
