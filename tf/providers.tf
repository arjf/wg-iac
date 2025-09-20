terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.83.2"
    }
  }
}

# BPG Proxmox Provider
provider "proxmox" {
  endpoint  = "https://${var.pm_fqdn}/api2/json"
  api_token = "${var.pm_user_realm}!${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure  = true
  
  ssh {
    agent    = false
    username = var.pm_ssh_user
    private_key = var.pm_ssh_key
    node {
      name = var.pm_node
      address = var.pm_ssh_host
      port = var.pm_ssh_port
    }
  }
}
