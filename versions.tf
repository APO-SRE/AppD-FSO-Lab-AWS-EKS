# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.3.9"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.54"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.18"
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
