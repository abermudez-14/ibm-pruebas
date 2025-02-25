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

provider "kubernetes" {
  config_context_cluster = "ez-ibm-openshift-vpc"
}

# resource "ibm_iam_user_invite" "wiki_user" {
#   users = ["pruebasLABS@stemdo.io"]
#   iam_policy {
#     roles = ["Viewer", "Editor"]
#     resources {
#       service           = "containers-kubernetes"
#       resource_group_id = var.resource_group
#     }
#   }
# }

# resource "ibm_iam_access_group" "stemdowiki" {
#  name        = "stemdo_WIKI"
#  description = "New access group"
# }

resource "kubernetes_namespace" "stemdo-wiki" {
  metadata {
    name = "stemdo-wiki"

  }
}