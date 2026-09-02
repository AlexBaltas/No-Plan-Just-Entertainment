terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "cloudflare" {}

resource "azurerm_resource_group" "npje" {
  name     = "rg-npje-web"
  location = "eastus2"
  tags = {
    project     = "No Plan Just Entertainment"
    environment = "prod"
    managed_by  = "terraform"
  }
}

resource "azurerm_static_web_app" "npje" {
  name                = "swa-npje"
  location            = "eastus2"
  resource_group_name = azurerm_resource_group.npje.name
  sku_tier            = "Free"
  sku_size            = "Free"
  tags = {
    project     = "No Plan Just Entertainment"
    environment = "prod"
    managed_by  = "terraform"
  }
}


resource "cloudflare_dns_record" "www" {
  zone_id = var.cloudflare_zone_id
  name    = "www"
  type    = "CNAME"
  content = azurerm_static_web_app.npje.default_host_name
  ttl     = 1
  proxied = false
}

resource "azurerm_static_web_app_custom_domain" "www" {
  static_web_app_id = azurerm_static_web_app.npje.id
  domain_name       = "www.noplanjustentertainment.com"
  validation_type   = "cname-delegation"

  depends_on = [
    cloudflare_dns_record.www
  ]
}

resource "cloudflare_dns_record" "root" {
  zone_id = var.cloudflare_zone_id
  name    = "@"
  type    = "CNAME"
  content = azurerm_static_web_app.npje.default_host_name
  ttl     = 1
  proxied = false
}

resource "azurerm_static_web_app_custom_domain" "root" {
  static_web_app_id = azurerm_static_web_app.npje.id
  domain_name       = "noplanjustentertainment.com"
  validation_type   = "dns-txt-token"
}

resource "cloudflare_dns_record" "root_validation" {
  zone_id = var.cloudflare_zone_id
  name    = "_dnsauth"
  type    = "TXT"
  content = azurerm_static_web_app_custom_domain.root.validation_token
  ttl     = 300
  proxied = false
}