# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.53"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.17"
    }

    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.8"
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
