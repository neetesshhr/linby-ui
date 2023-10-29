import subprocess
import os

def main(pubkey, privkey, distro, instance_type, server_name, deploy_region):

    if not pubkey or not distro or not privkey:
        print("pubkey, distro, and privkey are required.")
        return

    if distro == "amazon-linux2":
        ec2_user = "ec2-user"
    elif distro == "ubuntu":
        ec2_user = "ubuntu"
    else:
        print("Unsupported DISTRO value")
        return

    print(f"User set to: {ec2_user}")

    os.chdir('server')
    subprocess.run(["terraform", "init"])

    ami_id_output = subprocess.run(["python3", "ami_id.py", "-id", distro], capture_output=True, text=True)
    ami_id = ami_id_output.stdout.strip()
    print(f"AMI ID is {ami_id}")

    subprocess.run(["terraform", "apply",
                    f"-var=ami_id={ami_id}",
                    f"-var=public_key_path={pubkey}",
                    f"-var=instancetype={instance_type}",
                    f"-var=ServerName={server_name}",
                    f"-var=deployregion={deploy_region}",
                    "-auto-approve"])

    ec2_ip_output = subprocess.run(["terraform", "output", "instance_public_ip"], capture_output=True, text=True)
    ec2_ip = ec2_ip_output.stdout.strip()

    with open('instance_info.txt', 'r') as f:
        print(f.read())
    subprocess.run(["pwd"])
    os.chdir('jenkinsSetup')

    with open('inventory.yml', 'w') as f:
        f.write("[linux]\n")
        f.write(f"{ec2_ip} ansible_user={ec2_user} ansible_ssh_private_key_file={privkey}\n")

    print("###### Running ansible galaxy to install java package ######")
    subprocess.run(["ansible-galaxy", "install", "ansiblebit.oracle-java"])
    print("###### Running ansible playbook to setup jenkins ######")
    subprocess.run(["sleep", "30"])
    subprocess.run(["ansible-playbook", "-i", "inventory.yml", "main.yml"])

    print("###### Your Jenkins Initial Admin Password is ######")
    with open('initialAdminPassword', 'r') as f:
        print(f.read())
        
    output = "Setup executed successfully!"  # This is a mock output
    return output

import argparse

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description="Deploy Jenkins on EC2 using Terraform and Ansible")
    parser.add_argument("pubkey", help="Public key path")
    parser.add_argument("privkey", help="Private key path")
    parser.add_argument("distro", help="Distribution (e.g., ubuntu, amazon-linux2)")
    parser.add_argument("instance_type", help="Instance type (e.g., t2.micro)")
    parser.add_argument("server_name", help="Server name")
    parser.add_argument("deploy_region", help="Deployment region (e.g., ap-south-1)")

    args = parser.parse_args()

    main(args.pubkey, args.privkey, args.distro, args.instance_type, args.server_name, args.deploy_region)

# Example Usage
# main(pubkey='path_to_pubkey', privkey='path_to_privkey', distro='ubuntu')
