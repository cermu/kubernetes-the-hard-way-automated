# kubernetes-the-hard-way-automated
*This guide deploys the infrastructure on AWS cloud using the IaC(Infrastructure as Code) tool, CloudFormation, and installs Kubernetes components(the hard way) using Ansible server configuration tool.*

# Audience
*This is for you if you are looking to setup Kubernetes quickly in an automated way for the purpose of learning and playing around with Kubernetes.*

# Credits
This work is an automation on top of Kelsey's [kubernetes-the-hard-way](https://github.com/kelseyhightower/kubernetes-the-hard-way/blob/master/README.md) tutorial.

Special thanks to [Kelsey Hightower](https://github.com/kelseyhightower)

# Assumptions
- Prior knowledge and understanding of Kubernetes is in place.
- Local computer runs Linux or MacOs

# Disclaimer
- This guide is not intended for setting up Kubernetes on production.
- If you wish to follow along, please note that you will incur charges on AWS (EC2 instances and NAT Gateway) for the deployed infrastructure.

# Pre-requisites:
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) 
- [AWS Account](https://aws.amazon.com/premiumsupport/knowledge-center/create-and-activate-aws-account/)

# Cluster Details
- kubernetes v1.31.2
- containerd v2.0.0
- cni v1.6.0
- etcd v3.4.34
- weavenetwork v2.8.1
- helm v3.16.4

# Node/EC2 instance Details
DISTRIB_ID=Ubuntu
DISTRIB_RELEASE=24.04
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Ubuntu 24.04.1 LTS"
PRETTY_NAME="Ubuntu 24.04.1 LTS"
NAME="Ubuntu"
VERSION_ID="24.04"
VERSION="24.04.1 LTS (Noble Numbat)"
VERSION_CODENAME=noble
ID=ubuntu
ID_LIKE=debian
HOME_URL="https://www.ubuntu.com/"
SUPPORT_URL="https://help.ubuntu.com/"
BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
UBUNTU_CODENAME=noble
LOGO=ubuntu-logo

# Usage Instructions


## Deploying the Infrastructure on AWS using CloudFormation

- Login to AWS Console
- Select your preferred Region (e.g. eu-west-1)
- Search for and select CloudFormation service
- Click Create stack button
- Select `With new resources (standard)` option
- Select `Upload a template file`
- Upload the CloudFormation Yaml templates in *kubernetes-the-hard-way-automated/infrastructure/* folder one at a time
- Repeat the above steps to create CloudFormation stacks for each Yaml template. See the order of deployment below.

## Order of deploying the CloudFormation templates.
1. Create the VPC stack by deploying the `aws_k8s_vpc_environment.yaml`.
2. Create the control node stack by deploying the `control_plane_instance.yaml`.
3. Create the worker nodes stack by deploying the `worker_node_instance.yaml`.
4. Create the Ansible bastion instance stack by deploying the `jumpbox_node_instance.yaml`.

## Pointers.
- If need be, be sure to replace the default values in each template while deploying the CloudFormation stacks.
- For the instance stacks, please select an existing keypair for parameter, `KeyName`.
- For the Ansible bastion instance, deploy it in a public subnet created by the VPC stack. The control and worker nodes are to be deployed in private subnets(this is not mandatory though).


## Gearing up for Ansible deployments
- To create Ansible inventory file, edit the *create_inventory.sh* and update the variable *SSH_KEY_FILE* and *REGION* accordingly and run it using bash.

```
vi ansible/create_inventory.sh
chmod +x ansible/create_inventory.sh
bash ansible/create_inventory.sh
```

## Accessing the Ansible EC2 instances
- From the AWS EC2 console, get the Public IP of the Ansible EC2 instance.
- Download the Key pair attached to the created EC2 instances.
- Use *ssh* to access the Ansible instance `ssh -i ~/path/to/keypair.pem ubuntu@<ANSIBLE_SERVER_PUBLIC_IP>`

```
ssh -i ~/path/to/keypair.pem ubuntu@1.1.1.1
```

- Create *kubernetes_the_hard_way/ansible* directory in the Ansible EC2 instance

```
cd ~
mkdir -p kubernetes_the_hard_way/ansible
```

- Edit the `append_hosts.yaml` Ansible playbook and replace the following place holders with the actual Private IPs of the individual EC2 instances.
- <controlnode1_Private_IP_Here>
- <workernode1_Private_IP_Here>
- <workernode2_Private_IP_Here>

- Transfer Ansible playbooks in *kubernetes-the-hard-way-automated/ansible* directory to the Ansible EC2 instance
```
scp -i ~/path/to/keypair.pem *.yaml inventory ansible.cfg ca.conf ubuntu@<ANSIBLE_SERVER_PUBLIC_IP>:~/kubernetes_the_hard_way/ansible
```

- Transfer the Key pair attached to the created EC2 instances to the Ansible EC2 instance
```
scp -i ~/path/to/keypair.pem keypair.pem ubuntu@<ANSIBLE_SERVER_PUBLIC_IP>:~/
```

- Connect to the Ansible Server
```
ssh -i ~/path/to/keypair.pem ubuntu@${ANSIBLE_SERVER_PUBLIC_IP}
```

- Test if all hosts are reachable
1.  list all hosts to confirm that the *inventory* file is properly configured
```
cd ~/kubernetes_the_hard_way/ansible
ansible all --list-hosts -i inventory
```

2.  Test ping on all the hosts
```
cd ~/kubernetes_the_hard_way/ansible
ansible -i inventory -m ping all
```

## Configuring the control and worker nodes with Ansible
**From the Ansible EC2 instance, run the Ansible playbooks in the following order:**
*change directory to ~/kubernetes_the_hard_way/ansible*

1. Install K8s client tools
    `ansible-playbook -i inventory -v client_tools.yaml`
2. Append nodes to /etc/hosts
    `ansible-playbook -i inventory -v append_hosts.yaml`
3. Provision the CA
    `ansible-playbook -i inventory -v certificate_authority.yaml`
4. Create client and server certificates
    `ansible-playbook -i inventory -v client_server_certificates.yaml`
5. Distribute the certificates
    `ansible-playbook -i inventory -v distribute_certificates.yaml`
6. Generate Kubernetes Configuration Files for Authentication
    `ansible-playbook -i inventory -v create_kubeconfigs.yaml`
7. Distribute the Kubernetes Configuration Files
    `ansible-playbook -i inventory -v distribute_kubeconfigs.yaml`
8. Bootstrapping the etcd Cluster
    `ansible-playbook -i inventory -v bootstrap_etcd_cluster.yaml`
9. Bootstrapping the Kubernetes Control Plane
    `ansible-playbook -i inventory -v bootstrap_control_plane.yaml`
10. Configure RBAC permissions to allow the Kubernetes API Server to access the Kubelet API on each worker node. 
    `ansible-playbook -i inventory -v rbac_auth.yaml`
11. Bootstrapping the worker nodes
    `ansible-playbook -i inventory -v bootstrap_worker_nodes.yaml`
12. Configuring kubectl for Remote Access
    `ansible-playbook -i inventory -v remote_kubectl.yaml`
13. Install helm
    `ansible-playbook -i inventory -v install_helm.yaml`
14. Installing Weave Network. 
    `ansible-playbook -i inventory -v deploy_weavenet.yaml`
15. Deploy core DNS. 
    `ansible-playbook -i inventory -v deploy_coredns.yaml`


# Clean Up

*Delete the created AWS CloudFormation Stacks*
- Login to AWS Console
- Select your preferred Region (e.g. eu-west-1)
- Search for and select CloudFormation service
- Select the stack to delete
- Click the *Delete* button