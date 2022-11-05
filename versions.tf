# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.38"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.15"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.7"
    }

    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14"
    }

    null = {
      source  = "hashicorp/null"
      version = ">= 3.2"
    }

    random = {
      source  = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
