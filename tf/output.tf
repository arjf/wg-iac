output "container_ipv4_addresses" {
  value = proxmox_virtual_environment_container.wg.ipv4
}

output "container_ipv6_addresses" {
  value = proxmox_virtual_environment_container.wg.ipv6
}

output "container_id" {
  value = proxmox_virtual_environment_container.wg.id
}