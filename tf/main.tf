resource "proxmox_lxc" "wg" {
  provider = proxmox-telmate.telmate
  target_node  = "pve"
  hostname     = "wg"
  ostemplate   = proxmox_virtual_environment_download_file.fedora_cloud_image.id
#   password     = // Using ssh keys
  unprivileged = true

  // Terraform will crash without rootfs defined
  rootfs {
    storage = "local-zfs"
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

  # ssh_public_keys = file("~/.ssh/id_rsa.pub") // Cloud-init handles this

  cicustom = "user=local:snippets/wg-init.yaml"

}

resource "proxmox_virtual_environment_download_file" "fedora_cloud_image" {
  provider = proxmox-bgp.bpg
  content_type="import"
  datastore_id="local"
  node_name="pve"
  url=var.fedora_root_fs_image_url
  file_name="fedora-42-cloud_20250916_amd64.tar.xz"
}

resource "proxmox_virtual_environment_file" "cloud_init_config" {
  provider = proxmox-bgp.bpg
  content_type = "snippets"
  datastore_id = "local"
  node_name    = "pve"

  source_file {
    path = "wg-init.yaml"
  }
}
