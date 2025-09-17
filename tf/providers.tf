terraform {
  required_providers {
    proxmox_bgp = {
      source  = "bpg/proxmox"
      version = "0.83.2"
    }
    proxmox_telmate = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
  }
}

# BPG Proxmox Provider
provider "proxmox_bgp" {
  alias    = "bpg"
  endpoint = "https://${var.pm_fqdn}/api2/json"
  api_token = "${var.pm_api_token_id}=${var.pm_api_token_secret}"
  insecure = true
}

# Telmate Proxmox Provider
provider "proxmox_telmate" {
  alias              = "telmate"
  pm_api_url         = "https://${var.pm_fqdn}/api2/json"
  pm_api_token_id    = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure    = true
}
