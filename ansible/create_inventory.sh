#!/bin/bash

REGION=eu-west-1 # update this when necessary
SSH_KEY_FILE="/path/to/key_pair.pem" # update this to point to a valid existing keypair from AWS

# set the private IP addresses of the instances as Environment variables
# Add as many instances as you wish
WorkerNode1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=WorkerNode1" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})    
WorkerNode2_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=WorkerNode2" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})    
ControlNode1_PRIVATE_IP=$(aws ec2 describe-instances --filters "Name=tag-value,Values=ControlNode1" "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].[PrivateIpAddress]' --output text --region ${REGION})

# - Confirm the set Envrionment variables
echo "ControlNode1_PRIVATE_IP=${ControlNode1_PRIVATE_IP}" 
echo "WorkerNode1_PRIVATE_IP=${WorkerNode1_PRIVATE_IP}"
echo "WorkerNode2_PRIVATE_IP=${WorkerNode2_PRIVATE_IP}"
echo "SSH_KEY_FILE=${SSH_KEY_FILE}"


# create the default ansible inventory file
cat << EOF | tee inventory
[local]
localhost           ansible_host=127.0.0.1                      ansible_connection=local    ansible_user=ubuntu   ansible_become=yes

[allnodes]
localhost           ansible_host=127.0.0.1                      ansible_connection=local    ansible_user=ubuntu   ansible_become=yes
controlnode1        ansible_host=${ControlNode1_PRIVATE_IP}     ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes    
workernode1         ansible_host=${WorkerNode1_PRIVATE_IP}      ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
workernode2         ansible_host=${WorkerNode2_PRIVATE_IP}      ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes

[controller]
controlnode1        ansible_host=${ControlNode1_PRIVATE_IP}     ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes    

[workers]
workernode1         ansible_host=${WorkerNode1_PRIVATE_IP}      ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
workernode2         ansible_host=${WorkerNode2_PRIVATE_IP}      ansible_connection=ssh      ansible_user=ubuntu   ansible_ssh_private_key_file="${SSH_KEY_FILE}"    ansible_become=yes
EOF