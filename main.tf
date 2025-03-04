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

 ## Kubernetes provider configuration 
provider "kubernetes" {
  host                   = data.ibm_container_cluster_config.cluster_config.host
  token                  = data.ibm_container_cluster_config.cluster_config.token
  cluster_ca_certificate = data.ibm_container_cluster_config.cluster_config.ca_certificate
}

data "ibm_container_vpc_cluster" "cluster" {
  name              = "ibm-openshift-pruebas"
  resource_group_id = var.resource_group
}
 
data "ibm_container_cluster_config" "cluster_config" {
  depends_on = [ data.ibm_container_vpc_cluster.cluster ]
  cluster_name_id   = data.ibm_container_vpc_cluster.cluster.id
  resource_group_id = data.ibm_container_vpc_cluster.cluster.resource_group_id
  admin             = true
}

## Permissions management for Stemdo Wiki project 

resource "ibm_iam_access_group" "stemdowiki" {
 name        = "stemdo_WIKI"
 description = "New access group"
}

resource "kubernetes_namespace" "stemdo-wiki" {
  metadata {
    name = "stemdo-wiki"
  }
}

resource "ibm_iam_user_policy" "policy" {
  ibm_id = "acajas@stemdo.io"
  roles  = ["Viewer","Editor"]

  resources {
    service           = "containers-kubernetes"
    resource_group_id = var.resource_group
  }
}