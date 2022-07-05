# Variables ----------------------------------------------------------------------------------------
variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-west-1"
}

variable "aws_vpc_cidr_block" {
  description = "The CIDR block for the VPC."
  type    = string
  default = "172.20.0.0/22"
}

variable "aws_vpc_public_subnets" {
  description = "A list of public subnets inside the VPC."
  type    = list(string)
  default = ["172.20.0.0/24", "172.20.1.0/24", "172.20.2.0/24"]
}

variable "aws_vpc_private_subnets" {
  description = "A list of private subnets inside the VPC."
  type    = list(string)
  default = ["172.20.3.0/24"]
}

variable "aws_ssh_ingress_cidr_blocks" {
  description = "The ingress CIDR blocks for inbound ssh traffic external to AWS."
  type        = string
  default     = "0.0.0.0/0"
}

variable "cisco_ssh_ingress_cidr_blocks" {
  description = "The ingress CIDR blocks for inbound ssh traffic from Cisco networks."
  type        = string
  default     = "128.107.248.205/32,72.163.220.53/32,209.234.175.138/32,173.38.208.173/32"
}

variable "aws_cloud9_ssh_ingress_cidr_blocks" {
  description = "The ingress CIDR blocks for inbound ssh traffic from AWS Cloud9 System Manager and EC2 Instance Connect."
  type        = string
  default     = "13.52.232.224/27,18.144.158.0/27,13.52.6.112/29"
}

variable "cisco_tgw_owner_id" {
  description = "Cisco SRE AWS account ID that owns the EC2 Transit Gateway."
  type    = list(string)
  default = ["496972728175"]
}

variable "cisco_tcp_ingress_cidr_blocks" {
  description = "The ingress CIDR blocks for inbound TCP traffic from the Cisco data center."
  type        = string
  default     = "10.20.0.0/16"
}

variable "cisco_tgw_route_cidr_block" {
  description = "CIDR block to route traffic to the Cisco data center via the Transit Gateway."
  type        = string
  default     = "10.0.0.0/8"
}

variable "aws_ec2_vm_hostname_prefix" {
  description = "AWS EC2 VM hostname prefix."
  type        = string
  default     = "fso-lab"
}

variable "aws_ec2_domain" {
  description = "AWS EC2 domain name."
  type        = string
  default     = "localdomain"
}

variable "aws_ec2_user_name" {
  description = "AWS EC2 user name."
  type        = string
  default     = "ec2-user"
}

variable "aws_ec2_ssh_pub_key_name" {
  description = "AWS EC2 SSH public key for Lab VMs."
  type        = string
  default     = "FSO-Lab-DevOps"
}

variable "aws_ec2_source_ami_filter" {
  description = "AWS EC2 source AMI disk image filter."
  type        = string
  default     = "FSO-LPAD-AL2-AMI-*"
}

variable "aws_ec2_instance_type" {
  description = "AWS EC2 instance type."
  type        = string
# default     = "t2.micro"
  default     = "t2.large"
}

variable "lab_number" {
  description = "Lab number for incrementally naming resources."
  type        = number
  default     = 1
}

# NOTE: If set to 'false', ensure to have a proper private access with 'cluster_endpoint_private_access = true'.
variable "aws_eks_endpoint_public_access" {
  description = "Indicates whether or not the Amazon EKS public API server endpoint is enabled."
  type        = bool
  default     = true
}

variable "aws_eks_endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the EKS public API server endpoint."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "aws_eks_desired_node_count" {
  description = "Desired number of EKS worker nodes."
  type        = number
  default     = 2
}

variable "aws_eks_min_node_count" {
  description = "Minimum number of EKS worker nodes."
  type        = number
  default     = 1
}

variable "aws_eks_max_node_count" {
  description = "Maximum number of EKS worker nodes."
  type        = number
  default     = 3
}

variable "aws_eks_instance_type" {
  description = "AWS EKS Node Group instance type."
  type        = list(string)
# default     = ["m5a.large"]
  default     = ["m5a.xlarge"]
}

# valid aws eks versions are: 1.19, 1.20, 1.21, and 1.22.
variable "aws_eks_kubernetes_version" {
  description = "Kubernetes version to use for the EKS cluster."
  type        = string
  default     = "1.21"
}

variable "lab_ssh_pub_key_name" {
  description = "Name of SSH public key for EKS worker nodes."
  type        = string
  default     = "FSO-Lab-DevOps"
}

variable "resource_name_prefix" {
  description = "Resource name prefix."
  type        = string
  default     = "FSO-Lab"
}

variable "resource_environment_home_tag" {
  description = "Resource environment home tag."
  type        = string
  default     = "Cisco One Lab"
}

variable "resource_owner_tag" {
  description = "Resource owner tag."
  type        = string
  default     = "Cisco APO Cross-Architectural and AppDynamics Cloud Channel Sales Teams"
}

variable "resource_event_tag" {
  description = "Resource event tag."
  type        = string
  default     = "FSO Lab Demo"
}

variable "resource_project_tag" {
  description = "Resource project tag."
  type        = string
  default     = "FSO Lab DevOps"
}

variable "resource_owner_email_tag" {
  description = "Resource owner email tag."
  type        = string
  default     = "ed.barberis@appdynamics.com"
}

variable "resource_cost_center_tag" {
  description = "Resource cost center tag."
  type        = string
  default     = "020430800"
}

variable "map_roles" {
  description = "Additional IAM roles to add to the aws-auth configmap."
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      rolearn  = "arn:aws:iam::66666666666:role/role1"
      username = "role1"
      groups   = ["system:masters"]
    }
  ]
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))

  default = [
    {
      userarn  = "arn:aws:iam::66666666666:user/user1"
      username = "user1"
      groups   = ["system:masters"]
    }
  ]
}
