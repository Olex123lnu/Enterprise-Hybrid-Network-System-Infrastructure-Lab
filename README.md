# Enterprise-Hybrid-Network-System-Infrastructure-Lab
Enterprise Hybrid Network &amp; System Infrastructure Lab
This project is dedicated to building a comprehensive, isolated corporate network and system infrastructure based on **VMware ESXi** virtualization, **MikroTik RouterOS** routing, and **Windows Server** based directory and security services (Active Directory, NPS/RADIUS, DNS, KMS).

The goal of the laboratory work is to implement and validate a fault-tolerant routing architecture (OSPF), secure segmentation (VLAN), centralized access control (AAA/RADIUS), and remote connection technologies (WireGuard, L2TP/IPSec VPN).

---
## 🗺️ Network topology

Below is a logical diagram of the built infrastructure, which includes three MikroTik routers (two physical/CHR and one virtual inside ESXi), domain services, and client access segments:

![Network Topology](images/topology.png)

---

## 🛠️ Technology stack

* **Virtualization Hypervisor:** VMware ESXi 7.0 Update 3
* **Routing and Switching:** MikroTik RouterOS v7.21.2 CHR (R1, R2, R3)
* **Dynamic Routing Protocol:** OSPFv2 (Single Area)
* **Network Segmentation:** IEEE 802.1Q (VLAN Trunking, Bridge VLAN Filtering)
* **Directory Services:** Active Directory Domain Services (Domain: `AmazonLeo.local`)
* **Security and AAA Services:** Windows Server Network Policy Server (NPS) / RADIUS, Active Directory Users and Computers (ADUC)
* **Network Services:** DNS (A, PTR, SRV records), DHCP Server
* **VPN Technologies:** WireGuard, L2TP/IPSec VPN (CMAK-profile with routing)
* **Activation Infrastructure:** KMS Host (autodiscovery via DNS SRV `_vlmcs`)

---
