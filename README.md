# NGINX → Internal NLB → Microservice Chain (Terraform)

## 📌 Overview

This project demonstrates a **multi-tier microservice architecture on AWS**, provisioned entirely using **Terraform**.

The system simulates a real-world backend flow:

```
Client → NGINX (FE) → Internal NLB → App1 → App2
```

---

## 🏗️ Architecture

### Flow:

1. Client hits the **Frontend EC2 (NGINX)**
2. NGINX proxies `/api` requests to:
3. **Internal Network Load Balancer (NLB)**
4. NLB routes traffic to:
5. **App1 (Python service)**
6. App1 calls:
7. **App2 (Python downstream service)**

---

## 🧩 Components

### 🔹 Compute

* 3 EC2 Instances:

  * **FE (Frontend)** → NGINX reverse proxy
  * **App1** → Service layer
  * **App2** → Downstream service

---

### 🔹 Networking

* Default VPC
* Subnets (multi-AZ)
* Security Groups:

  * FE → public HTTP access
  * App → internal VPC-only access

---

### 🔹 Load Balancing

* **Internal Network Load Balancer**

  * Listener: TCP 8081
  * Target: App1

---

### 🔹 DNS

* Route53 A Record → FE Elastic IP

---

## ⚙️ Tech Stack

* Terraform
* AWS EC2
* AWS NLB
* AWS Route53
* NGINX
* Python (HTTPServer)

---

## 📁 Project Structure

```
.
├── main.tf
├── variables.tf
├── outputs.tf
├── .gitignore
├── README.md
│
├── userdata/
│   ├── fe.sh
│   ├── app1.sh
│   └── app2.sh
```

---

## 🔧 Setup Instructions

### 1. Clone repo

```
git clone https://github.com/<your-username>/nginx-nlb-microservice-chain.git
cd nginx-nlb-microservice-chain
```

---

### 2. Initialize Terraform

```
terraform init
```

---

### 3. Configure variables

Create `terraform.tfvars`:

```
region         = "ap-south-1"
domain_name    = "yourdomain.com"
hosted_zone_id = "ZXXXXXXXX"
```

---

### 4. Apply infrastructure

```
terraform apply
```

---

## 🌐 Testing

### ✅ Direct FE test

```
curl http://<FE_PUBLIC_IP>/fullchain
```

Expected:

```
FE Server Running
```

---

### ✅ Full chain test

```
curl http://<FE_PUBLIC_IP>/api/fullchain
```

Expected:

```
App1 -> Hello from App2 (8082)
```

---

### ✅ Internal connectivity tests

From FE:

```
curl http://<NLB_DNS>:8081/api/fullchain
```

From App1:

```
curl http://<APP2_PRIVATE_IP>:8082/api/downstream
```

---

## 🔍 Key Learnings

* Internal vs External Load Balancers
* NGINX reverse proxy configuration
* Service chaining between microservices
* Terraform dependency handling
* Debugging:

  * NGINX upstream issues
  * Health checks
  * Python runtime issues (urllib3/OpenSSL)
  * Security groups

---

## ⚠️ Common Issues Faced

### ❌ NLB target unhealthy

* App1 not running on port 8081

---

### ❌ 502 Bad Gateway (NGINX)

* NLB unreachable
* DNS resolution issues
* Incorrect proxy config

---

### ❌ Python errors

* `urllib3 v2 incompatible with OpenSSL`
* Fixed by:

```
pip3 install "requests==2.28.2" "urllib3<2"
```

---

### ❌ NGINX variable error

```
unknown "nlb_dns" variable
```

✔ Fixed by using static or `set $backend`


## Cleanup

```
terraform destroy
```

---

## Future Improvements

* Add HTTPS (ACM + ALB)
* Use Auto Scaling Groups
* Replace EC2 with ECS/EKS
* Add CI/CD pipeline
* Use S3 backend for Terraform state

---
