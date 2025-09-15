resource "proxmox_lxc" "wg" {
  target_node  = "pve"
  hostname     = "wg"
  ostemplate   = "local:vztmpl/fedora-42-default_20250428_amd64.tar.xz"
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

  ssh_public_keys = [
    file("~/.ssh/id_rsa.pub")
  ]

  cicustom = "user=local:snippets/wg-user-data.yaml"

}