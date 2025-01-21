terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

# Configure the IBM Provider
provider "ibm" {
  region = "eu-es"
  ibmcloud_api_key=var.api_key
}



resource "ibm_is_vpc" "vpc_module_abermudez" {
  name = "vpc-abermudez"
  resource_group = var.resource_group

}

resource "ibm_is_subnet" "subnet_module_abermudez" {
  name = "subnet-abermudez"
  vpc = ibm_is_vpc.vpc_module_abermudez.id
  zone = "eu-es-1"
  ipv4_cidr_block = ""

}
