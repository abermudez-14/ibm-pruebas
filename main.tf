terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.75.1"
    }
  }
}

provider "ibm" {
  region = "eu-es"
  ibmcloud_api_key = var.api_key
}


resource "ibm_iam_user_invite" "wiki_user" {
  users = ["hgonzalez@stemdo.io"]
  iam_policy {
    roles = ["Viewer", "Editor"]
    resources {
      service           = "containers-kubernetes"
      resource_group_id = var.resource_group
    }
  }
}