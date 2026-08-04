terraform {
  required_providers {
    routeros = {
      source = "terraform-routeros/routeros"
      version = "1.62.0" # Сучасний провайдер
    }
  }
}

# Налаштування підключення (використовує API через HTTP/HTTPS)
provider "routeros" {
  hosturl  = "http://192.168.99.1" # Увага: цей провайдер використовує http (порт 80), а не 8728
  username = "admin"
  password = "1"
  insecure = true # Дозволити без SSL сертифіката
}

# --- 1. IP АДРЕСА ---
resource "routeros_ip_address" "lan_address" {
  address   = "192.168.11.1/24"
  interface = "vlan1"
}
resource "routeros_ip_address" "lan_address2" {
  address   = "192.168.6.1/24"
  interface = routeros_interface_wireguard.wg1.name
}
# --- 2. DHCP (Пул, Сервер, Мережа) ---
resource "routeros_ip_pool" "dhcp_pool" {
  name   = "dhcp_vlan1"
  ranges = ["192.168.11.2-192.168.11.254"]
}

resource "routeros_ip_dhcp_server" "server" {
  name         = "vlan1_dhcp"
  interface    = "vlan1"
  address_pool = routeros_ip_pool.dhcp_pool.name
  disabled     = false
}

resource "routeros_ip_dhcp_server_network" "vlan1_net" {
  address    = "192.168.11.0/24"
  gateway    = "192.168.11.1"
  dns_server = ["8.8.8.8", "1.1.1.1"]
}

# --- 3. WIREGUARD ---
resource "routeros_interface_wireguard" "wg1" {
  name        = "wgvpn"
  listen_port = 13231
}

resource "routeros_interface_wireguard_peer" "wg1_1" {
  interface  = routeros_interface_wireguard.wg1.name
  public_key = "d0P2T0AtgFzjc6iCqr5L/ia7z21Y7G0bi99F/Y/iMgc="
  
  # Цей провайдер дозволяє писати endpoint разом з портом
  endpoint_address = "172.105.199.4"
  endpoint_port    = 51820
  
  allowed_address  = ["192.168.6.2/32", "192.168.10.0/24", "192.168.2.0/24", "224.0.0.0/4"]
}