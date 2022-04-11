# Providers ----------------------------------------------------------------------------------------
provider "aws" {
  region  = var.aws_region
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
# token                  = data.aws_eks_cluster_auth.cluster.token
# config_path            = "~/.kube/config"

  exec {
    api_version = "client.authentication.k8s.io/v1alpha1"
    command = "aws"
    args = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.cluster.name]
  }
}

# Locals -------------------------------------------------------------------------------------------
locals {
  # format current date for convenience.
  current_date = formatdate("YYYY-MM-DD", timestamp())

  # create formatted hostname and resource prefixes with lab number.
  lab_hostname_prefix = var.lab_number > 0 ? format("%s-%02d", var.aws_ec2_vm_hostname_prefix, var.lab_number) : var.aws_ec2_vm_hostname_prefix
  lab_resource_prefix = var.lab_number > 0 ? format("%s-%02d", var.resource_name_prefix, var.lab_number) : var.resource_name_prefix

  # create vm ssh ingress cidr block list without duplicates.
  vm_ssh_ingress_cidr_blocks = join(",", distinct(tolist([var.aws_ssh_ingress_cidr_blocks, var.cisco_ssh_ingress_cidr_blocks, var.aws_cloud9_ssh_ingress_cidr_blocks])))

  # NOTE: the eks remote ssh ingress security group contains a "0.0.0.0/0" cidr block rule by default.
  #       when adding our custom cidr blocks, we need to strip off "0.0.0.0/0" (if it exists) to
  #       avoid creating a duplicate rule.
  ssh_ingress_cidr_blocks = sort(toset(split(",", join(",", tolist([var.aws_ssh_ingress_cidr_blocks, var.cisco_ssh_ingress_cidr_blocks, "0.0.0.0/0"])))))
  ssh_ingress_cidr_blocks_length = length(local.ssh_ingress_cidr_blocks)
  eks_remote_ssh_ingress_cidr_blocks = slice(local.ssh_ingress_cidr_blocks, 1, local.ssh_ingress_cidr_blocks_length)

  # define resource names here to ensure standardized naming conventions.
  vpc_name                  = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-VPC"
  security_group_name       = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-Security-Group"
  vm_name                   = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-VM"
  cluster_name              = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-EKS"
  tgw_attachment_name       = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-TGW-Attachment"
  ec2_access_role_name      = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-EC2-Access-Role"
  ec2_access_policy_name    = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-EC2-Access-Policy"
  ec2_instance_profile_name = "${local.lab_resource_prefix}-${lower(random_string.suffix.result)}-EC2-Instance-Profile"

  # define resource tagging here to ensure standardized naming conventions.
  # fso lab tag names for aws resources.
  fso_resource_tags = {
    EnvironmentHome = var.resource_environment_home_tag
    Owner           = var.resource_owner_tag
    Event           = var.resource_event_tag
    Project         = var.resource_project_tag
    Date            = local.current_date
  }

  # appdynamics tag names for aws resources.
  appd_resource_tags = {
    ResourceOwner         = var.resource_owner_email_tag
    CiscoMailAlias        = var.resource_owner_email_tag
    JIRAProject           = "NA"
    DataClassification    = "Cisco Public"
    JIRACreation          = "NA"
    SecurityReview        = "NA"
    Exception             = "NA"
    Environment           = "NonProd"
    DeploymentEnvironment = "NonProd"
    DataTaxonomy          = "Cisco Operations Data"
    CreatedBy             = data.aws_caller_identity.current.arn
    IntendedPublic        = "True"
    ContainsPII           = "False"
    Service               = "FSOLab"
    ApplicationName       = var.resource_project_tag
    CostCenter            = var.resource_cost_center_tag
  }

  # if this environment is for appdynamics, merge in 'appd_resource_tags'; otherwise, use 'fso_resource_tags'.
  resource_tags = substr(var.resource_name_prefix, 0, 4) == "AppD" ? merge(local.fso_resource_tags, local.appd_resource_tags) : local.fso_resource_tags
}

# Data Sources -------------------------------------------------------------------------------------
data "aws_caller_identity" "current" {
}

data "aws_availability_zones" "available" {
}

data "aws_ami" "fso_lab_ami" {
  most_recent = true
  owners      = ["self"]

  filter {
    name = "name"
    values = [var.aws_ec2_source_ami_filter]
  }
}

data "aws_ec2_transit_gateway" "tgw" {
  filter {
    name   = "owner-id"
    values = var.cisco_tgw_owner_id
  }
}

data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_id
}

data "aws_security_group" "eks_remote" {
  vpc_id  = module.vpc.vpc_id

  filter {
    name   = "tag:eks"
    values = toset([module.eks.node_groups.node-group.node_group_name])
  }
}

# Modules ------------------------------------------------------------------------------------------
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = ">= 3.14"

  name = local.vpc_name
  cidr = var.aws_vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  public_subnets  = var.aws_vpc_public_subnets
  private_subnets = var.aws_vpc_private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = local.resource_tags

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = ">= 4.9"

  name        = local.security_group_name
  description = "Security group for LPAD VM EC2 instance"
  vpc_id      = module.vpc.vpc_id

  tags = local.resource_tags

  ingress_cidr_blocks               = ["0.0.0.0/0"]
  ingress_rules                     = ["http-80-tcp", "http-8080-tcp", "https-443-tcp", "all-icmp"]
  egress_rules                      = ["all-all"]
  ingress_with_self                 = [{rule = "all-all"}]
  computed_ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "Allow SSH access."
      cidr_blocks = local.vm_ssh_ingress_cidr_blocks
    },
    {
      from_port   = 0
      to_port     = 65535
      protocol    = "tcp"
      description = "Allow TCP traffic from Cisco data center."
      cidr_blocks = var.cisco_tcp_ingress_cidr_blocks
    }
  ]
  number_of_computed_ingress_with_cidr_blocks = 2
}

module "vm" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = ">= 3.5"

  name                 = local.vm_name
  ami                  = data.aws_ami.fso_lab_ami.id
  instance_type        = var.aws_ec2_instance_type
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.id
  key_name             = var.aws_ec2_ssh_pub_key_name

  tags = local.resource_tags

  subnet_id                   = tolist(module.vpc.public_subnets)[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true

  user_data_base64 = base64encode(templatefile("${path.module}/templates/user-data-sh.tmpl", {
    aws_ec2_user_name      = var.aws_ec2_user_name
    aws_ec2_hostname       = "${local.lab_hostname_prefix}-vm"
    aws_ec2_domain         = var.aws_ec2_domain
    aws_region_name        = var.aws_region
    use_aws_ec2_num_suffix = "true"
    aws_eks_cluster_name   = local.cluster_name
    iks_cluster_name       = "${local.lab_resource_prefix}-IKS"
    iks_kubeconfig_file    = "${local.lab_resource_prefix}-IKS-kubeconfig.yml"
    lab_number             = var.lab_number
  }))
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "= 17.24"

  cluster_name    = local.cluster_name
  cluster_version = var.aws_eks_kubernetes_version
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets

  cluster_endpoint_public_access       = var.aws_eks_endpoint_public_access
  cluster_endpoint_public_access_cidrs = var.aws_eks_endpoint_public_access_cidrs

  tags = local.resource_tags

  node_groups_defaults = {
    ami_type  = "AL2_x86_64"
    disk_size = 80
  }

  node_groups = {
    "node-group" = {
      desired_capacity = var.aws_eks_desired_node_count
      min_capacity     = var.aws_eks_min_node_count
      max_capacity     = var.aws_eks_max_node_count
      instance_types   = var.aws_eks_instance_type
      key_name         = var.lab_ssh_pub_key_name

      k8s_labels = {
        GithubRepo  = "terraform-aws-eks"
        GithubOrg   = "terraform-aws-modules"
      }

      additional_tags = local.resource_tags
    }
  }

  map_roles = [
    {
      rolearn  = aws_iam_role.ec2_access_role.arn
      username = "fsolabuser"
      groups   = ["system:masters"]
    }
  ]

# map_users    = var.map_users
# map_accounts = var.map_accounts
}

# Resources ----------------------------------------------------------------------------------------
resource "random_string" "suffix" {
  length  = 5
  special = false
}

resource "aws_ec2_transit_gateway_vpc_attachment" "tgw_attachment" {
  transit_gateway_id = data.aws_ec2_transit_gateway.tgw.id
  vpc_id             = module.vpc.vpc_id
  subnet_ids         = tolist([module.vpc.public_subnets[0], module.vpc.public_subnets[1]])

  tags = merge({ Name = local.tgw_attachment_name }, local.resource_tags)
}

resource "aws_route" "tgw_route" {
  route_table_id         = module.vpc.public_route_table_ids[0]
  destination_cidr_block = var.cisco_tgw_route_cidr_block
  transit_gateway_id     = data.aws_ec2_transit_gateway.tgw.id
}

resource "aws_iam_role" "ec2_access_role" {
  name               = local.ec2_access_role_name
  assume_role_policy = file("${path.module}/policies/ec2-assume-role-policy.json")

  tags = local.resource_tags
}

resource "aws_iam_role_policy" "ec2_access_policy" {
  name   = local.ec2_access_policy_name
  role   = aws_iam_role.ec2_access_role.id
  policy = file("${path.module}/policies/ec2-access-policy.json")
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = local.ec2_instance_profile_name
  role = aws_iam_role.ec2_access_role.name
}

resource "aws_security_group_rule" "eks_remote_ssh_ingress" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  description       = "Allow SSH access."
  cidr_blocks       = local.eks_remote_ssh_ingress_cidr_blocks
  security_group_id = data.aws_security_group.eks_remote.id
}

resource "aws_security_group_rule" "eks_remote_ssh_ingress_for_vm" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  description              = "Allow SSH access from the LPAD VM security group."
  source_security_group_id = module.security_group.security_group_id
  security_group_id        = data.aws_security_group.eks_remote.id
}

resource "aws_security_group_rule" "eks_remote_icmp_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  description       = "Allow ping traffic to EKS cluster."
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.eks_remote.id
}

resource "aws_security_group_rule" "eks_remote_tcp_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  description       = "Allow all TCP traffic from Cisco data center."
  cidr_blocks       = toset([var.cisco_tcp_ingress_cidr_blocks])
  security_group_id = data.aws_security_group.eks_remote.id
}

resource "aws_security_group_rule" "eks_worker_icmp_ingress" {
  type              = "ingress"
  from_port         = -1
  to_port           = -1
  protocol          = "icmp"
  description       = "Allow ping traffic to EKS worker nodes."
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.eks.worker_security_group_id
}

resource "aws_security_group_rule" "eks_worker_tcp_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  description       = "Allow all TCP traffic from Cisco data center."
  cidr_blocks       = toset([var.cisco_tcp_ingress_cidr_blocks])
  security_group_id = module.eks.worker_security_group_id
}

resource "aws_security_group_rule" "eks_worker_all_ingress" {
  type                     = "ingress"
  from_port                = -1
  to_port                  = -1
  protocol                 = "all"
  description              = "Allow all traffic from the LPAD VM Security Group."
  source_security_group_id = module.security_group.security_group_id
  security_group_id        = module.eks.worker_security_group_id
}

resource "null_resource" "kubectl_trigger" {
  # fire the trigger when the eks cluster requires re-provisioning.
  triggers = {
    eks_cluster_id = module.eks.cluster_id
  }

  # execute the following 'local-exec' provisioners each time the trigger is invoked.
  # run aws cli to retrieve the kubernetes config when the eks cluster is ready.
  provisioner "local-exec" {
    working_dir = "."
    command = "aws eks --region ${var.aws_region} update-kubeconfig --name ${local.cluster_name}"
  }
}

resource "null_resource" "ansible_trigger" {
  # fire the ansible trigger when the ec2 vm instance requires re-provisioning.
  triggers = {
    ec2_instance_ids = module.vm.id
  }

  # execute the following 'local-exec' provisioners each time the trigger is invoked.
  # generate the ansible aws hosts inventory using 'cat' and Heredoc.
  provisioner "local-exec" {
    working_dir = "."
    command     = <<EOD
cat <<EOF > aws_hosts.inventory
[fso_lab_vm]
${module.vm.public_dns}
EOF
EOD
  }
}
