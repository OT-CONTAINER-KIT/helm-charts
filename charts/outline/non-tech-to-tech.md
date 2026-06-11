### 1. How the web actually works

**1.1 What is the web?**
Not the internet the web. Understand the difference. HTTP, browsers, servers, clients. What is a request? What is a response? Keep it simple for now.

**1.2 How does it work?**
Follow a single HTTP request from your browser to a server and back. DNS → TCP → HTTP → HTML. Just know the flow for now. Don't memorize, understand.

**1.3 Where does a website actually come from?**
Hosting. Servers. Datacenters. What does it mean to "host" something? Shared hosting vs VPS vs cloud high level only.

**1.4 DNS Resolution**

**1.5 Project: Make your own "DNS" on Windows**
Edit your `hosts`

---

### 2: How applications are built and deployed

**2.1 Different types of applications**
You've heard React, Node.js, Python, Java. They're all just different tools for building apps. At this stage, don't learn them just understand that each has its own runtime, its own way of running.

**2.2 The build deploy cycle**
Every app goes through roughly the same process: write [ code install dependencies build run ]. The commands differ, the concept doesn't.

**2.3 Dependencies**
Every app relies on external code it didn't write. Python has `pip`. Node has `npm`/`yarn`. Java has `Maven`/`Gradle`. Ruby has `bundler`. These are all package managers they pull in code your app needs to function.

**2.4 Package managers cheatsheet**

| Language | Manager | Install command |
|----------|---------|----------------|
| Node.js | npm | `npm install` |
| Python | pip | `pip install -r requirements.txt` |
| Java | Maven | `mvn install` |
| Ruby | Bundler | `bundle install` |
| Go | Go modules | `go mod tidy` |

**2.5 Artifacts**
After you build an app, you get an artifact — a packaged, ready-to-run version of your code. A `.jar` for Java. A `/dist` folder for React. A Docker image later. The artifact is what you actually deploy, not the source code.

**Project: Build and host a React app**
- Clone any simple React repo (or use `create-react-app`)
- Run `npm install` — watch it pull 800 packages
- Run `npm run build` — observe what lands in `/dist`
- Serve the `/dist` folder using any static file server (`npx serve dist`)
- That's a deployment. You just deployed something.

---

## 3. Linux

This is the most important month. Everything in DevOps runs on Linux. Don't skip anything here.

### 3.1: OS fundamentals

under the hood is kernal.

In production, you'll mostly see Ubuntu or RHEL variants. Get comfortable with both.

### 3.2: Core Linux commands

Don't memorize. Use these every day until they're muscle memory.

```bash
# Navigation
ls, cd, pwd, tree

# Files
cp, mv, rm, touch, mkdir, cat, less, head, tail, nano, vim

# Permissions
chmod, chown, ls -la

# Processes
ps aux, top, htop, kill, killall, systemctl

# Networking
ip a, netstat, ss, curl, ping, traceroute

# Searching
grep, find, awk, sed

# Users
whoami, su, sudo, useradd, passwd, groups
```

### 3.3: Partitions and the filesystem

**3.x Partitions**

**The Linux filesystem hierarchy (important)**

**3.x /proc filesystem**

**3.x Scheduling jobs via crontab and systemd by creating service**

---

## 4 Networking, Proxies, and Bare-Metal

### 4.1 Networking basics

- **IP addressing:** IPv4 vs IPv6. Private vs public IPs. CIDR notation (`192.168.1.0/24`).
- **Ports:** What they are, common ones (80, 443, 22, 3306, 5432, 6379).
- **TCP vs UDP:** Connection-oriented vs connectionless.
- **Firewalls:** `ufw`, `iptables` basics. Allow/deny rules.
- **SSH:** How it works, key-based auth, `~/.ssh/config` for shortcuts.

```bash
# Essential tools
curl -I https://example.com       # HTTP headers
nmap -p 80,443 <IP>               # port scan
ss -tulpn                          # listening ports
tcpdump -i eth0 port 80            # packet capture
```

### 4.2: Reverse proxies

**What is a proxy?**

- **Forward proxy:** 
- **Reverse proxy:** 

**Why use a reverse proxy?**
- just give the basic security reason.


### 5: Project Host a website on bare-metal

**Goal:** Take a plain Linux server (VirtualBox, a cheap VPS, or even a spare laptop) and host a website behind Nginx or Apache. No containers. No shortcuts.

Optional but highly recommended: get a free domain from Freenom or Cloudflare, point it at your server's IP, and add SSL with Certbot (`certbot --nginx`).

---

## 6 Docker

Docker is where things click. All the Linux knowledge you built pays off here.

### Project 1: Docker CLI to Docker daemon communication

Understanding this matters when you get to CI/CD — many pipelines mount `/var/run/docker.sock` into a container to give it Docker access. That has security implications you should know about.

### Project 2: Rootless Docker

By default, Docker runs as root. That's a security risk — a container breakout gives an attacker root on the host. Rootless Docker runs the daemon as a non-root user. 

Understand the tradeoffs. Rootless has limitations (some port bindings, cgroup v2 required, etc.). Know when you'd use it.

### Project 3: Multi-stage Dockerfile

### Project 4: Edit a file in a running container without exec

---

## 7: CI/CD, Ansible, and Kubernetes intro

### 7.1: CI/CD

CI/CD is just automation. [ You push code  something runs automatically your app is built, tested, and deployed ].

**Continuous Integration (CI)

**Continuous Deployment (CD)

**Core concepts:**
- Pipeline: a sequence of steps
- Trigger: what starts a pipeline (push, PR, schedule)
- Runner/agent: the machine that executes the pipeline
- Artifact: output of a build (Docker image, .jar, /dist folder)
- Environment: where you deploy (dev / staging / prod)

### 7.2 Tools that will be used for CI/CD.
### 7.3 Create the workflows and build your application and deploy it on self hosted server.

### 8: Ansible

### 9: Kubernetes intro

## 10 Terraform.

## 11 Gitops

### 12 Mega Project

Build and deploy a real application end-to-end using everything you've learned. Suggested stack:

**The project:** A simple Python/Node.js web app with a database, deployed to a Kubernetes cluster on a cloud provider.

**Requirements:**
- [ ] App runs in Docker (multi-stage Dockerfile, minimal image size)
- [ ] Infrastructure provisioned with Terraform (VPC, K8s cluster, RDS or managed DB)
- [ ] Kubernetes manifests for Deployment, Service, Ingress, ConfigMap, Secret
- [ ] Nginx ingress controller in front
- [ ] CI/CD pipeline via GitHub Actions: test → build image → push to registry → deploy to K8s
- [ ] Ansible playbook for any config that isn't Kubernetes-native
- [ ] GitOps: Argo CD watching your manifest repo, auto-syncing on merge to main
- [ ] Monitoring: at minimum, get logs flowing somewhere (Loki, CloudWatch, Datadog free tier)

Don't rush this. If it takes 3 weeks instead of 2, that's fine. This project is your portfolio.

---

## What comes next

After this curriculum, you are not a senior DevOps engineer. You're someone who can contribute, troubleshoot, and keep learning independently. That's the goal.

**Project-only phase (no more theory):**
- Pick a real open-source project and contribute to its CI/CD
- Try to break your own infrastructure and fix it
- Get comfortable with cloud cost optimization
- Learn observability seriously: Prometheus, Grafana, distributed tracing
- Study for a certification if it matters in your market: CKA, AWS SAA, Terraform Associate

At this stage, every hour should be spent building and breaking things. Not watching videos.

---