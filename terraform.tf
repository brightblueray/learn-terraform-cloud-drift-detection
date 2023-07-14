terraform {
  cloud {
    organization = "brightblueray"

    workspaces {
      name = "learn-terraform-cloud-drift-detection"
    }
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
