provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = "eu-es"
}

# Crear una VPC
resource "ibm_is_vpc" "vpc_abermudez" {
  name = "vpc_abermudez"
  resource_group = var.resource_group
}

# Crear dos subredes en la VPC
resource "ibm_is_subnet" "subnet1" {
  name                     = "subnet2"
  vpc                      = ibm_is_vpc.vpc_abermudez.id
  zone                     = "eu-es-1"
  total_ipv4_address_count = 256
  resource_group = var.resource_group  
}

resource "ibm_is_subnet" "subnet2" {
  name                     = "subnet2"
  vpc                      = ibm_is_vpc.vpc_abermudez.id
  zone                     = "eu-es-2"
  total_ipv4_address_count = 256
  resource_group = var.resource_group  
}

# Crear dos instancias (VMs) en las subredes
resource "ibm_is_instance" "vm1" {
  name    = "vm1_abermudez"
  vpc     = ibm_is_vpc.vpc_abermudez.id
  zone    = "eu-es-1"
  keys    = [ibm_is_ssh_key.ssh_key.id]
  image   = "r014-931515d2-fcc3-11e9-896d-3baa2797200f" # ID de una imagen de Ubuntu
  profile = "bx2-2x8"
  resource_group = var.resource_group

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
  }
}

resource "ibm_is_instance" "vm2" {
  name    = "vm2_abermudez"
  vpc     = ibm_is_vpc.vpc_abermudez.id
  zone    = "eu-es-2"
  keys    = [ibm_is_ssh_key.ssh_key.id]
  image   = "r014-931515d2-fcc3-11e9-896d-3baa2797200f" # ID de una imagen de Ubuntu
  profile = "bx2-2x8"
  resource_group = var.resource_group  

  primary_network_interface {
    subnet = ibm_is_subnet.subnet2.id
  }
}

# Crear un balanceador de carga
resource "ibm_is_lb" "load_balancer" {
  name    = "lb-abermudez"
  subnets = [ibm_is_subnet.subnet1.id, ibm_is_subnet.subnet2.id]
  type    = "public"
  resource_group = var.resource_group
}

# Crear un pool de backend para el balanceador de carga
resource "ibm_is_lb_pool" "backend_pool" {
  lb               = ibm_is_lb.load_balancer.id
  name             = "backend-pool"
  protocol         = "http"
  algorithm        = "round_robin"
  health_delay     = 5
  health_retries   = 2
  health_timeout   = 2
  health_type      = "http"
  health_monitor_url = "/"
  
}

# Agregar las instancias al pool de backend
resource "ibm_is_lb_pool_member" "member1" {
  lb       = ibm_is_lb.load_balancer.id
  pool     = ibm_is_lb_pool.backend_pool.id
  port     = 80
  target_address   = ibm_is_instance.vm1.primary_network_interface[0].primary_ipv4_address
  
}

resource "ibm_is_lb_pool_member" "member2" {
  lb       = ibm_is_lb.load_balancer.id
  pool     = ibm_is_lb_pool.backend_pool.id
  port     = 80
  target_address = ibm_is_instance.vm2.primary_network_interface[0].primary_ipv4_address
}