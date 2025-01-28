terraform {
  required_providers {
    ibm = {
      source = "IBM-Cloud/ibm"
      version = ">= 1.12.0"
    }
  }
}

provider "ibm" {
  ibmcloud_api_key = var.api_key
  region           = "eu-es"
}

# Crear una VPC
resource "ibm_is_vpc" "vpc_abermudez" {
  name = "vpc-abermudez"
  resource_group = var.resource_group
}

# Crear dos subredes en la VPC
resource "ibm_is_subnet" "subnet1" {
  name                     = "subnet1"
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
  name    = "vm1-abermudez"
  vpc     = ibm_is_vpc.vpc_abermudez.id
  zone    = "eu-es-1"
  keys    = [ibm_is_ssh_key.ssh_key.id]
  image   = "r050-b98611da-e7d8-44db-8c42-2795071eec24" # ID de una imagen de Ubuntu
  profile = "bx2-2x8"
  resource_group = var.resource_group

  primary_network_interface {
    subnet = ibm_is_subnet.subnet1.id
    security_groups = [ibm_is_security_group.ssh_abermudez_security_group.id]

  }
}

resource "ibm_is_instance" "vm2" {
  name    = "vm2-abermudez"
  vpc     = ibm_is_vpc.vpc_abermudez.id
  zone    = "eu-es-2"
  keys    = [ibm_is_ssh_key.ssh_key.id]
  image   = "r050-b98611da-e7d8-44db-8c42-2795071eec24" # ID de una imagen de Ubuntu
  profile = "bx2-2x8"
  resource_group = var.resource_group  

  primary_network_interface {
    subnet = ibm_is_subnet.subnet2.id
    security_groups = [ibm_is_security_group.ssh_abermudez_security_group.id]
  }
}

# Crear un balanceador de carga
resource "ibm_is_lb" "load_balancer" {
  name    = "lb-abermudez"
  subnets = [ibm_is_subnet.subnet1.id, ibm_is_subnet.subnet2.id]
  type    = "public"
  resource_group = var.resource_group
  security_groups = [ ibm_is_security_group.ssh_abermudez_security_group.id]
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



resource "ibm_is_security_group" "ssh_abermudez_security_group" {
  name            = "ssh-security-group"
  vpc          =  ibm_is_vpc.vpc_abermudez.id
  resource_group  = var.resource_group  
}



resource "ibm_is_security_group_rule" "ssh_rule" {
  group     = ibm_is_security_group.ssh_abermudez_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 22
    port_max = 22
  }
}


resource "ibm_is_security_group_rule" "http_rule" {
  group     = ibm_is_security_group.ssh_abermudez_security_group.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "internet_rule" {
  group     = ibm_is_security_group.ssh_abermudez_security_group.id
  direction = "outbound"
  remote    = "0.0.0.0/0"

}



resource "ibm_is_ssh_key" "ssh_key" {
  name       = "ssh-key-abermudez"
  public_key = <<-EOF
 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDQYePYr1IxSOGxJ6+lKuD4onsLK8jxU93BvYAB2lxTgomteXCpdHnKK3jix8hxadmANkG/k9kEjxWwKQR7ZVyw8eQul3aLCfMnHGqplVQH3JSsz5bKMaCNx8r2P5SYGLeTmbixZUmjlFxeacEQ7/8RPvVESZ5IvrOpNtsW0kF3IsxXZndLhZlC+a69xIw2UTDVYRjwSFcB4BLl2Z3YPIwcFNWyDQdThmSWJkfdXxOmunaVRVK+OFhEAJmIf8TJ6JVBbsBf1RU2khD8M3zGpxTKF6W0rb9seEkfHERhJbYpv8NmyWST8vgyCYRElKQK+IWmT4qMua+q6eXcrUtalyZa1m8rIytze10sa4kBsN/fdr/rtACDo+hx/e1lU5GnwodPscFaVHHH5nIOF1iq4llRevoPsTvSwViAE9Se1BrLZC1MrpyxF8l7LTDqCYbRuWoTXP5w5ElbqKIEbaBvv3xhd8V7jW0VYvg/vSbD9ZApAmb7QRnzzjGLCKS9k5/rOvhtcT/FP7XXxivnc+tRp7Q+FRjHAPgmhd9unk/LTUjXhaD9+M30nDol39jT+jwBZ8JOW1rFEFQJkGM7wfqSzbJRQutH5VMCX3XSk1+qv2hz5Sza1IJJPfeleetFRT9b1AbU/TCRpOg7ZwrcvMd9xyWFacHTqaUR2/oXF2c6FzT6FQ== abermudez@stemdo
  EOF
  resource_group = var.resource_group
  
}


resource "ibm_is_floating_ip" "public_ip1" {
  name   = "public-ip1-abermudez"
  target = ibm_is_instance.vm1.primary_network_interface[0].id
  resource_group = var.resource_group
  depends_on = [ibm_is_instance.vm1]

}


resource "ibm_is_floating_ip" "public_ip2" {
  name   = "public-ip2-abermudez"
  target = ibm_is_instance.vm2.primary_network_interface[0].id
  resource_group = var.resource_group
  depends_on = [ibm_is_instance.vm2]

}