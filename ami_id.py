import boto3
import argparse
import os

def find_ami_id(choice, region):
    ec2 = boto3.client(
        'ec2',
        region_name = region
        )

    if choice == 'amazon-linux2':
        owners = ['amazon']
        filters = [
            {
                'Name': 'name',
                'Values': ['amzn2-ami-hvm-2.0.*-x86_64-gp2']
            }
        ]
    elif choice == 'ubuntu':
        owners = ['099720109477']  # Canonical's owner ID for Ubuntu images
        filters = [
            {
                'Name': 'name',
                'Values': ['ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*']
            },
            {
                'Name': 'virtualization-type',
                'Values': ['hvm']
            }
        ]
    else:
        print("Invalid choice. Please choose either 'amazon-linux2' or 'ubuntu'.")
        return

    response = ec2.describe_images(Owners=owners, Filters=filters)

    images = sorted(response['Images'], key=lambda x: x['CreationDate'], reverse=True)
    if not images:
        print(f"No AMIs found for {choice}.")
        return

    latest_ami = images[0]
    print(f"{latest_ami['ImageId']}")

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Find AMI ID for Amazon Linux 2 or Ubuntu.')
    parser.add_argument('-id', type=str, required=True, choices=['amazon-linux2', 'ubuntu'],
                        help="Choose 'amazon-linux2' or 'ubuntu' to get the respective AMI ID.")
    
    parser.add_argument(
        '-rg',
        type=str,
        required=True,
        default=os.environ.get('AWS_DEFAULT_REGION'),
        help='The aws region to use'
    )
    args = parser.parse_args()
    find_ami_id(args.id, args.rg)
