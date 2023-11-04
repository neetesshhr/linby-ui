#!/bin/bash
while getopts "k:d:p:a:i:t:r:s:e:" opt; do
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
    a)
      APP_NAME="$OPTARG"
      ;;
    i)
      SERVERNAME="$OPTARG"
      ;;
    t)
      INSTANCETYPE="$OPTARG"
      ;;
    r)
      DEPLOY_REGION="$OPTARG"
      ;;
    s)
      ACCESS_KEY="$OPTARG"
      ;;
    e)
      SECRET_KEY="$OPTARG"
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

if [[ -z $SSH_PRIVATE_KEY_PATH ]] || [[ -z $DISTRO ]] || [[ -z $PUB_KEY ]] || [[ -z $APP_NAME ]] || [[ -z $SERVERNAME ]] || [[ -z $INSTANCETYPE ]] || [[ -z $DEPLOY_REGION ]] || [[ -z $ACCESS_KEY ]] || [[ -z $SECRET_KEY ]]; then
    echo "All -k (for key) and -d (for distro) and -p (for public key) flags are required."
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

AMI_ID=$(python3 ami_id.py -id ${DISTRO} -rg ${DEPLOY_REGION})

echo "AMI ID is $AMI_ID"
cd server
terraform init
terraform apply -var="ami_id=$AMI_ID" -var="public_key_path=$PUB_KEY" -var="instancetype=$INSTANCETYPE" -var="ServerName=$SERVERNAME" -var="deployregion=$DEPLOY_REGION" -var="access_key=$ACCESS_KEY" -var="secret_key=$SECRET_KEY" --auto-approve

export EC2_IP=$(terraform output instance_public_ip)

cat instance_info.txt
ls


case $APP_NAME in 
     "Jenkins")
        echo "###### RUNNING JENKINS SETUP NOW #####"
        cd ../jenkinsSetup
        export EC2_IP
        export SSH_PRIVATE_KEY_PATH
        export EC2_USER
        FILE="inventory.yml"
        if [ -f "$FILE" ]; then
            rm inventory.yml
        else
            echo "### Moving ### "
        fi
        
        echo "[linux]" > inventory.yml
        echo "$EC2_IP ansible_user=$EC2_USER ansible_ssh_private_key_file=$SSH_PRIVATE_KEY_PATH" >> inventory.yml
        
        sleep 30
        
        echo "######Running ansible playbook to setup jenkins ######"
        sleep 30
        ansible-playbook -i inventory.yml main.yml
        echo "###### Your Jenkins Initial Admin Password is ######"
        cat initialAdminPassword
        rm initialAdminPassword
        rm inventory.yml
        ;;
      "RabbitMQ")
        echo "###### RUNNING RABBITMQ SETUP NOW #####"
        ;;
      *)
        echo "Unsupported APP_NAME value"
        exit 1
        ;;
esac
