terraform {
  required_providers {
    proxmox-bgp = {
      source  = "bpg/proxmox"
      version = "0.83.2"
    }
    proxmox-telmate = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

# BPG Proxmox Provider
provider "proxmox-bgp" {
  alias     = "bpg"
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

# Telmate Proxmox Provider
provider "proxmox-telmate" {
  alias               = "telmate"
  pm_api_url          = "https://${var.pm_fqdn}/api2/json"
  pm_api_token_id     = "${var.pm_user_realm}!${var.pm_api_token_id}"
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = true
}
