# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.2.9"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.29"
    }

    kubernetes = {
      version = "~> 2.13"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.4"
    }
  }
}
