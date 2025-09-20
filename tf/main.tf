resource "proxmox_lxc" "wg" {
  provider = proxmox-telmate.telmate

  depends_on = [
    proxmox_virtual_environment_file.cloud_init_config,
    proxmox_virtual_environment_download_file.cloud_image,
    proxmox_virtual_environment_file.startup_hook
  ]

  target_node = var.pm_node
  hostname    = "wg"
  ostemplate  = "${var.pm_datastore}:vztmpl/${var.root_fs_image_name}"
  #   password     = // Using ssh keys
  unprivileged = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = var.pm_datastore
    size    = "8G"
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "dhcp"
    ip6    = "dhcp"
  }

  features {
    nesting = true
    fuse    = true
    mount   = "fuse"
  }

  onboot = true

  ssh_public_keys = trimspace(data.http.github_ssh_keys.response_body)

  hookscript = "${var.pm_datastore}:snippets/wg-startup-hook.sh"

}

resource "proxmox_virtual_environment_download_file" "cloud_image" {
  provider     = proxmox-bgp.bpg
  content_type = "vztmpl"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node
  url          = var.root_fs_image_url
  file_name    = var.root_fs_image_name
  overwrite_unmanaged  = true
}

resource "proxmox_virtual_environment_file" "cloud_init_config" {
  provider     = proxmox-bgp.bpg
  content_type = "snippets"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node

  source_file {
    path = "../wg-init.yaml"
  }
}

resource "proxmox_virtual_environment_file" "startup_hook" {
  provider     = proxmox-bgp.bpg
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