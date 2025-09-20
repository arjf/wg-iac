resource "proxmox_virtual_environment_container" "wg" {

  depends_on = [
    proxmox_virtual_environment_file.cloud_init_config,
    proxmox_virtual_environment_download_file.cloud_image,
    proxmox_virtual_environment_file.startup_hook
  ]

  node_name = var.pm_node
  initialization {

    hostname    = "wg"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
      ipv6 {
        address = "dhcp"
      }
    }
    
    user_account {
      keys = [
        trimspace(data.http.github_ssh_keys.response_body)
      ]
      # username     = // Ansible handles
      # password     = // Using ssh keys
    }
  }
  operating_system {
      template_file_id  = "${var.pm_datastore}:vztmpl/${var.root_fs_image_name}"
      type = "ubuntu"
  }
  unprivileged = true

  disk {
    datastore_id = var.pm_datastore
    size    = 8
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  features {
    nesting = true
    fuse    = true
    mount   = ["cifs"]
  }

  started = true

  hook_script_file_id = "${var.pm_datastore}:snippets/wg-startup-hook.sh"

}

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  content_type = "vztmpl"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node
  url          = var.root_fs_image_url
  file_name    = var.root_fs_image_name
  overwrite_unmanaged  = true
}

resource "proxmox_virtual_environment_file" "cloud_init_config" {
  content_type = "snippets"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node

  source_file {
    path = "../wg-init.yaml"
  }
}

resource "proxmox_virtual_environment_file" "startup_hook" {
  content_type = "snippets"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node

  source_raw {
    data      = <<-EOT
      #!/bin/bash
      if [ "$1" = "post-start" ]; then
        sleep 2
        # Copy cloud-init config
        pct exec $2 -- mkdir -p /var/lib/cloud/seed/nocloud-net
        pct push $2 /var/lib/vz/snippets/${proxmox_virtual_environment_file.cloud_init_config.file_name} /var/lib/cloud/seed/nocloud-net/user-data
        
        # Apply CI
        pct exec $2 -- cloud-init clean
        pct exec $2 -- cloud-init init
        pct exec $2 -- cloud-init modules --mode=config
        pct exec $2 -- cloud-init modules --mode=final
      fi
    EOT
    file_name = "wg-startup-hook.sh"
  }
}

data "http" "github_ssh_keys" {
  url = "https://github.com/${var.github_username}.keys"
}