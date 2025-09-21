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
  
  depends_on = [ proxmox_virtual_environment_file.cloud_init_config ]
  content_type = "snippets"
  datastore_id = var.pm_datastore
  node_name    = var.pm_node

  source_raw {
    data      = <<-EOT
      #!/bin/bash
      sleep 2
      set -xe

      id=$1
      echo "[hook] Running cloud-init for container $id"

      # Copy cloud-init config
      sudo pct exec $id -- mkdir -p /var/lib/cloud/seed/nocloud
      sudo pct push $id /var/lib/vz/snippets/${proxmox_virtual_environment_file.cloud_init_config.file_name} /var/lib/cloud/seed/nocloud/user-data
      printf 'instance-id: %s\nlocal-hostname: wg\n' "$id" > /tmp/_meta
      sudo pct push $id /tmp/_meta /var/lib/cloud/seed/nocloud/meta-data
      rm -f /tmp/_meta

      # Ensure nocloud
      sudo pct exec "$id" -- /bin/sh -c 'cat > /etc/cloud/cloud.cfg.d/99-lxc.cfg <<EOF
datasource_list: [ NoCloud ]
datasource:
  NoCloud:
    seedfrom: file:///var/lib/cloud/seed/nocloud
EOF
'

      # Apply CI
      sudo pct exec $id -- cloud-init clean
      sudo pct exec $id -- cloud-init init
      sudo pct exec $id -- cloud-init modules --mode=config
      sudo pct exec $id -- cloud-init modules --mode=final
    EOT
    file_name = "wg-startup-hook.sh"
  }
}

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
  unprivileged = false

  disk {
    datastore_id = var.pm_datastore
    size    = 8
  }

  network_interface {
    name   = "eth0"
    bridge = "vmbr0"
  }

  started = true
  start_on_boot = true

  # hook_script_file_id = "${var.pm_datastore}:snippets/wg-startup-hook.sh" // there is bug

}

resource "null_resource" "cloud_init_setup" {
  depends_on = [
    proxmox_virtual_environment_container.wg,
    proxmox_virtual_environment_file.cloud_init_config
  ]

  triggers = {
    container_id       = proxmox_virtual_environment_container.wg.id
    cloud_init_checksum = filemd5("../wg-init.yaml")
  }

  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      host        = var.pm_ssh_host
      port        = var.pm_ssh_port
      user        = var.pm_ssh_user
      private_key = var.pm_ssh_key
    }

    inline = [
      "bash /var/lib/vz/snippets/${proxmox_virtual_environment_file.startup_hook.file_name} ${proxmox_virtual_environment_container.wg.id}",
      "sudo pct set ${proxmox_virtual_environment_container.wg.id} --cgroup2 'lxc.cgroup2.devices.allow=c 10:200 rwm",
      "sudo pct set ${proxmox_virtual_environment_container.wg.id} --device /dev/net/tun"
    ]
  }
}

data "http" "github_ssh_keys" {
  url = "https://github.com/${var.github_username}.keys"
}