# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.4.2"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.60"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.19"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.9"
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
