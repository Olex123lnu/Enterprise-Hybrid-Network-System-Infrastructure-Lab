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

## 📌 Key Implementation Steps

### 1. Routing and Switching (OSPF & VLAN)

* Configured dynamic routing **OSPFv2** on three routers (R1, R2, R3) for automatic exchange of routes between subnets.
* Defined unique router IDs: R1 (`1.1.1.1`), R2 (`2.2.2.2`), R3 (`3.3.3.3`) using Loopback interfaces.
* Network segmentation using **VLAN (802.1Q)**:
* On R2, VLAN 6, 7, 8 are implemented on the basis of Bridge with VLAN filtering enabled (`VLAN Filtering`).
* On ESXi, a virtual switch `VLAN_switch` with a trunk port (VLAN ID 4095) is configured to transmit tagged traffic to R3.
* On R3, VLAN subinterfaces 11, 12, 13 are configured on the trunk port.
* To improve security and optimize OSPF traffic, the interfaces facing the clients are set to passive mode (`Passive: yes`), and MD5 authentication is enabled for OSPF sessions.

<details>
<summary>📸 Click here to view step-by-step configuration screenshots</summary>
  
![Interface R1](images/1.png)

*Interface R1*

---

![Add an address to the transit interface to R2](images/2.png)

*Add an address to the transit interface to R2*

--- 

![ospf brige](images/3.png)

---

![ospf interface R1](images/4.png)

---

![ospf area R1](images/5.png)

---

![6](images/6.png)

---

![7](images/7.png)

---

![8](images/8.png)

---

![9](images/9.png)

---

![10](images/10.png)

---

![11](images/11.png)

---

![12](images/12.png)

---

![13](images/13.png)

---

![14](images/14.png)

---

![15](images/15.png)

---

![16](images/16.png)

---

![17](images/17.png)

---

![18](images/18.png)

---

![19](images/19.png)

---

![20](images/20.png)

---

![21](images/21.png)

---

![22](images/22.png)

---

![23](images/23.png)

---

![24](images/24.png)

---

![25](images/25.png)

---

![26](images/26.png)

---

![27](images/27.png)

---

![28](images/28.png)

---

![29](images/29.png)

---

![30](images/30.png)

---

![31](images/31.png)

---

![32](images/32.png)

---

![33](images/33.png)

---

![34](images/34.png)

---

![35](images/35.png)

---

![36](images/36.png)

---

![37](images/37.png)

---

![38](images/38.png)

---

![39](images/39.png)

---

![40](images/40.png)

---

![41](images/41.png)

---

![42](images/42.png)

---

![43](images/43.png)

---

![44](images/44.png)

---

![87](images/87.png)

---

![88](images/88.png)

---

![121](images/121.png)

---

![128](images/128.png)

---

![129](images/129.png)

---

![130](images/130.png)

---

![131](images/131.png)

---

![132](images/132.png)

---

![133](images/133.png)

---

![134](images/134.png)

---

![135](images/135.png)

---

![136](images/136.png)

---
![137](images/137.png)

---

![138](images/138.png)

---

![139](images/139.png)

---

![140](images/140.png)

---

![141](images/141.png)

---

![142](images/142.png)

---

![143](images/143.png)

---

![144](images/144.png)

---

![145](images/145.png)

---
</details>

### 2. Centralized Access Control (NPS / RADIUS)
* The **NPS (Network Policy Server)** role has been deployed on Windows Server.
* MikroTik routers have been added as RADIUS clients.
* Network policies have been created to authorize router administrators via the `AMAZONLEO\routeradmin` domain group.
* **Vendor-Specific Attributes (VSA)** transfer from the RADIUS server to MikroTik (Vendor ID: `14988`, Attribute 3: `full`) has been configured to automatically assign `full` access rights to domain users when logging in via WinBox.

<details>
<summary>📸 Click here to view step-by-step configuration screenshots</summary>
  
![45](images/45.png)

---

![46](images/46.png)

---

![47](images/47.png)

---

![48](images/48.png)

---

![49](images/49.png)

---

![50](images/50.png)

---

![51](images/51.png)

---

![52](images/52.png)

---

![53](images/53.png)

---

![54](images/54.png)

---

![55](images/55.png)

---

![56](images/56.png)

---

![57](images/57.png)

---

![58](images/58.png)

---

![59](images/59.png)

---

![60](images/60.png)

---

![61](images/61.png)

---

![62](images/62.png)

---

![63](images/63.png)

---
</details>

### 3. VPN & Remote Access
* **WireGuard VPN:** Configured tunneling on R1 with automatic key generation and configuration files for clients (`vm51.conf` config generated).
* **L2TP/IPSec VPN:** Configured L2TP server on R1/R2 with mandatory IPSec encryption (Required). Authentication integrated with domain RADIUS.
* **CMAK (Connection Manager Administration Kit):** Created a connection installation profile for Windows clients that automatically configures security settings, DNS suffix (`AmazonLeo.local`) and runs a routing script (`st_99.bat`) upon successful connection.

<details>
<summary>📸 Click here to view step-by-step configuration screenshots</summary>
  
![77](images/77.png)

---

![78](images/78.png)

---

![79](images/79.png)

---

![80](images/80.png)

---

![81](images/81.png)

---

![82](images/82.png)

---

![83](images/83.png)

---

![84](images/84.png)

---

![85](images/85.png)

---

![86](images/86.png)

---

![89](images/89.png)

---

![90](images/90.png)

---

![91](images/91.png)

---

![92](images/92.png)

---

![93](images/93.png)

---

![94](images/94.png)

---

![95](images/95.png)

---

![96](images/96.png)

---

![97](images/97.png)

---

![98](images/98.png)

---

![99](images/99.png)

---

![100](images/100.png)

---

![101](images/101.png)

---

![102](images/102.png)

---

![103](images/103.png)

---

![104](images/104.png)

---

![105](images/105.png)

---

![106](images/106.png)

---

![107](images/107.png)

---

![108](images/108.png)

---

![109](images/109.png)

---

![110](images/110.png)

---

![111](images/111.png)

---

![112](images/112.png)

---

![113](images/113.png)

---

![114](images/114.png)

---

![115](images/115.png)

---

![116](images/116.png)

---
</details>

### 4. Domain Services and Hypervisor Integration
* DNS server configured with forward and reverse zones (PTR records created for KMS and DC1).
* **VMware ESXi** hypervisor successfully entered into the `AMAZONLEO.LOCAL` domain.
* ESXi administration rights delegated to the `AMAZONLEO\routeradmin` domain group (Authentication Services -> Active Directory Enabled).

<details>
<summary>📸 Click here to view step-by-step configuration screenshots</summary>
  
![117](images/117.png)

---

![118](images/118.png)

---

![119](images/119.png)

---

![120](images/120.png)

---

![122](images/122.png)

---

![123](images/123.png)

---

![124](images/124.png)

---

![125](images/125.png)

---

![126](images/126.png)

---

![127](images/127.png)

---
</details>

### 5. Licensing Infrastructure (KMS Host)
* A local **KMS** activation node has been deployed on a dedicated server in the subnet.
* An SRV record `_vlmcs._tcp` on port `1688` has been created in DNS for automatic search of the activation server by clients.
* A successful activation of the Windows 10 client VM using the local KMS host (validated via `slmgr /dlv`) has been performed.

<details>
<summary>📸 Click here to view step-by-step configuration screenshots</summary>
  
![64](images/64.png)

---

![65](images/65.png)

---

![66](images/66.png)

---

![67](images/67.png)

---

![68](images/68.png)

---

![69](images/69.png)

---

![70](images/70.png)

---

![71](images/71.png)

---

![72](images/72.png)

---

![73](images/73.png)

---

![74](images/74.png)

---

![75](images/75.png)

---

![76](images/76.png)

---
</details>
