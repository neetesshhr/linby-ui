#!/bin/bash
while getopts "k:d:p:" opt; do
  case $opt in
    k)
      SSH_PRIVATE_KEY_PATH="$OPTARG"
      ;;
    d)
      DISTRO="$OPTARG"
      ;;
    p)
      PUB_KEY="$OPTARG"
      ;; 
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [[ -z $SSH_PRIVATE_KEY_PATH ]] || [[ -z $DISTRO ]] || [[ -z $PUB_KEY ]]; then
    echo "All -k (for key) and -d (for distro) and -pubkey (for public key) flags are required."
    exit 1
fi

#!/bin/bash

case $DISTRO in
    "amazon-linux2")
        EC2_USER="ec2-user"
        ;;
    "ubuntu")
        EC2_USER="ubuntu"
        ;;
    *)
        echo "Unsupported DISTRO value"
        exit 1
        ;;
esac

export EC2_USER
echo "User set to: $EC2_USER"

echo "#### Running terraform script ####"

AMI_ID=$(python3 ami_id.py -id ${DISTRO})

echo "AMI ID is $AMI_ID"
cd server
terraform init
terraform apply -var="ami_id=$AMI_ID" -var="public_key_path=$PUB_KEY" -var="instancetype=t2.micro" -var="ServerName=JenkinsMainDeployment" -var="deployregion=ap-south-1" -auto-approve

export EC2_IP=$(terraform output instance_public_ip)

cat instance_info.txt
ls
cd ../jenkinsSetup
pwd


export EC2_IP
export SSH_PRIVATE_KEY_PATH
export EC2_USER
rm inventory.yml
echo "[linux]" > inventory.yml
echo "$EC2_IP ansible_user=$EC2_USER ansible_ssh_private_key_file=$SSH_PRIVATE_KEY_PATH" >> inventory.yml
echo "######Running ansible galaxy to install java package ######" 
sleep 30
ansible-galaxy install ansiblebit.oracle-java
echo "######Running ansible playbook to setup jenkins ######"
sleep 30
ansible-playbook -i inventory.yml main.yml
echo "###### Your Jenkins Initial Admin Password is ######"
cat initialAdminPassword