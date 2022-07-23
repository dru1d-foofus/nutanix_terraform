terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "1.5.0-beta"
    }
  }
}

data "nutanix_cluster" "cluster" {
  name = var.cluster_name
}

data "nutanix_subnet" "subnet" {
  subnet_name = var.subnet_name
}

data "nutanix_image" "image" {
  image_name = var.image_name
}

provider "nutanix" {
  username     = var.user
  password     = var.password
  endpoint     = var.endpoint
  insecure     = true
  wait_timeout = 600
  port         = 9440
}

data "template_file" "cloud" {
  template = file("cloud-init")
  vars = {
    vm_user       = var.vm_user
    vm_password   = var.vm_password
    vm_dns1       = var.vm_dns1
    vm_dns2       = var.vm_dns2
    vm_public_key = var.vm_public_key
    vm_name       = var.vm_name
    vm_ip         = var.vm_ip
    vm_gateway    = var.vm_gateway
  }
}

resource "nutanix_virtual_machine" "vm" {
  name                 = var.vm_name
  cluster_uuid         = data.nutanix_cluster.cluster.id
  num_vcpus_per_socket = "2"
  num_sockets          = "1"
  memory_size_mib      = 8192

  guest_customization_cloud_init_user_data = base64encode(data.template_file.cloud.rendered)

  nic_list {
    subnet_uuid = data.nutanix_subnet.subnet.id
  }

  disk_list {
    data_source_reference = {
      kind = "image"
      uuid = data.nutanix_image.image.id
    }
  }

  disk_list {
    disk_size_bytes = 100 * 1024 * 1024 * 1024
    device_properties {
      device_type = "DISK"
      disk_address = {
        "adapter_type" = "SCSI"
        "device_index" = "1"
      }
    }
  }

  serial_port_list {
    index        = 0
    is_connected = "true"
  }

}
