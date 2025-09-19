output "container_ip" {
  value = proxmox_lxc.wg.network[0].ip
}

output "container_id" {
  value = proxmox_lxc.wg.vmid
}