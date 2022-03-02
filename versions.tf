# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.6"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.3"
    }

    kubernetes = {
      version = "~> 2.8"
    }

    local = {
      source = "hashicorp/local"
      version = ">= 2.1"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.1"
    }

    template = {
      source = "hashicorp/template"
      version = ">= 2.2"
    }
  }
}
