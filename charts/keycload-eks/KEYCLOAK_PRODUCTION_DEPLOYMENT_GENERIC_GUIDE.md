# Keycloak Production Deployment Guide (Generic EKS & RDS Blueprint)

This guide provides an end-to-end, step-by-step blueprint to deploy **Keycloak 26.x (Quarkus distribution)** on any **AWS EKS cluster** and **Amazon RDS PostgreSQL database** with tainted node pools (e.g. `dedicated=application:NoSchedule`).

---

## Environment Variable & Placeholder Reference

| Placeholder | Example Value | Description |
| :--- | :--- | :--- |
| `<EKS_CLUSTER_NAME>` | `my-production-eks` | Name of your AWS EKS Cluster |
| `<EKS_CLUSTER_ENDPOINT>` | `https://4535B45FEA4F6...` | API Server Endpoint URL of the EKS Cluster |
| `<OIDC_PROVIDER_ID>` | `4535B45FEA4F6FE4ACB0BDB9DFB1B7F9` | AWS EKS OIDC ID |
| `<AWS_ACCOUNT_ID>` | `724446904294` | 12-digit AWS Account ID |
| `<AWS_REGION>` | `ap-south-1` | Target AWS Region |
| `<POSTGRES_HOST>` | `dev-negd-rds-postgres...` | RDS PostgreSQL Endpoint FQDN |
| `<POSTGRES_USER>` | `postgres` | RDS Master Username |
| `<POSTGRES_PASSWORD>` | `]mDb2Qib95...` | RDS Master Password |
| `<AWS_SECRET_NAME>` | `rds!db-591e0ce4...` | Secrets Manager Secret Name for RDS |
| `<DOMAIN_NAME>` | `keycloak-aws.opstree.dev` | FQDN for Keycloak Ingress & TLS |

---

## Comprehensive Summary of Required Setup & Changes

| Component | What Needs to Change | Location / Tool |
| :--- | :--- | :--- |
| **AWS IAM Role Trust Policy** | Update OIDC Provider ID to `<OIDC_PROVIDER_ID>` | AWS IAM Console / CLI |
| **AWS IAM Policy** | Ensure `secretsmanager:GetSecretValue` and `kms:Decrypt` (for RDS KMS key) are allowed | AWS IAM Console |
| **RDS Security Group** | Allow TCP Port `5432` from EKS Cluster VPC CIDR | AWS VPC / EC2 Security Groups |
| **RDS PostgreSQL DB** | Create database `keycloak` on the RDS instance | `kubectl run` temporary Postgres pod |
| **AWS Secrets Manager** | Create/Verify secrets for DB password and admin password | AWS Secrets Manager |
| **Ingress & ESO Operators** | Install NGINX Ingress & ESO on EKS cluster with CRDs & Webhook Tolerations | Helm CLI |
| **`chart/values.yaml`** | Update `database.host`, `externalSecrets.awsSecretName`, `serviceAccount.annotations` (IAM Role ARN), `domain`/`hostname` | Helm values file |

---

## Step-by-Step Implementation Guide

### Step 1: Configure `kubectl` for the Target EKS Cluster

Connect your terminal to the target EKS cluster:

```bash
aws eks update-kubeconfig \
  --region <AWS_REGION> \
  --name <EKS_CLUSTER_NAME>
```

Verify context connection:

```bash
kubectl cluster-info
# Should display API Endpoint: <EKS_CLUSTER_ENDPOINT>
```

---

### Step 2: Create Admin Secret in AWS Secrets Manager

1. Go to **AWS Console** $\rightarrow$ **Secrets Manager** $\rightarrow$ Click **Store a new secret**.
2. Select **Other type of secret**.
3. Under Key/value pairs, enter:
   * **Key:** `admin-password`
   * **Value:** `<YOUR_KEYCLOAK_ADMIN_PASSWORD>` (e.g. `Admin@123`)
4. Click **Next** $\rightarrow$ **Secret name:** `production/keycloak/admin` $\rightarrow$ Click **Store**.

---

### Step 3: Configure AWS IAM OIDC & IRSA Role

#### 3.1 Retrieve the OIDC Issuer URL for the EKS Cluster

```bash
aws eks describe-cluster --name <EKS_CLUSTER_NAME> --region <AWS_REGION> --query "cluster.identity.oidc.issuer" --output text
```
*Expected Output:* `https://oidc.eks.<AWS_REGION>.amazonaws.com/id/<OIDC_PROVIDER_ID>`

#### 3.2 Enable IAM OIDC Identity Provider (If Not Already Enabled)

```bash
eksctl utils associate-iam-oidc-provider --cluster <EKS_CLUSTER_NAME> --region <AWS_REGION> --approve
```

#### 3.3 Create/Update IAM Trust Policy (`trust-policy.json`)

Create a trust policy file referencing your dynamic `<AWS_ACCOUNT_ID>`, `<AWS_REGION>`, and `<OIDC_PROVIDER_ID>`:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<AWS_ACCOUNT_ID>:oidc-provider/oidc.eks.<AWS_REGION>.amazonaws.com/id/<OIDC_PROVIDER_ID>"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.<AWS_REGION>.amazonaws.com/id/<OIDC_PROVIDER_ID>:sub": "system:serviceaccount:keycloak:keycloak-service-account",
          "oidc.eks.<AWS_REGION>.amazonaws.com/id/<OIDC_PROVIDER_ID>:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

#### 3.4 Create / Update the IAM Role & Attach Policy

```bash
# Update trust relationship on existing role or create new role
aws iam update-assume-role-policy \
  --role-name KeycloakSecretsManagerRole \
  --policy-document file://trust-policy.json

# Ensure KeycloakSecretsManagerPolicy is attached
aws iam attach-role-policy \
  --role-name KeycloakSecretsManagerRole \
  --policy-arn arn:aws:iam::<AWS_ACCOUNT_ID>:policy/KeycloakSecretsManagerPolicy
```

> [!IMPORTANT]
> **Policy Check:** Make sure `KeycloakSecretsManagerPolicy` includes `"kms:Decrypt"` if your AWS Secrets Manager secret is encrypted with a custom KMS key!

---

### Step 4: RDS PostgreSQL & Security Group Setup

#### 4.1 Update RDS Security Group Inbound Rule

1. Open AWS EC2 / VPC Security Groups.
2. Select the Security Group attached to your **RDS PostgreSQL Instance**.
3. Add Inbound Rule:
   * **Type:** PostgreSQL (TCP)
   * **Port:** `5432`
   * **Source:** EKS Cluster VPC CIDR (e.g. `10.10.0.0/16` or Security Group ID of worker nodes).

#### 4.2 Create `keycloak` Database in RDS

Run a temporary pod to create the database (`sslmode=require` handles RDS SSL enforcement):

```bash
kubectl run create-db --rm -it \
  --image=postgres:16-alpine \
  --overrides='{"spec":{"tolerations":[{"operator":"Exists"}]}}' \
  -- sh -c 'PGPASSWORD="<POSTGRES_PASSWORD>" psql \
  "host=<POSTGRES_HOST> user=<POSTGRES_USER> dbname=appdb sslmode=require" \
  -c "CREATE DATABASE keycloak;"'
```

---

### Step 5: Install NGINX Ingress & External Secrets Operator (ESO)

Deploy NGINX Ingress and ESO with CRDs enabled and node tolerations for tainted worker nodes (`dedicated=application:NoSchedule`):

```bash
# 1. Install External Secrets Operator
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm upgrade --install external-secrets external-secrets/external-secrets \
  --namespace external-secrets \
  --create-namespace \
  --set installCRDs=true \
  --set tolerations[0].key=dedicated \
  --set tolerations[0].operator=Equal \
  --set tolerations[0].value=application \
  --set tolerations[0].effect=NoSchedule \
  --set webhook.tolerations[0].key=dedicated \
  --set webhook.tolerations[0].operator=Equal \
  --set webhook.tolerations[0].value=application \
  --set webhook.tolerations[0].effect=NoSchedule \
  --set certController.tolerations[0].key=dedicated \
  --set certController.tolerations[0].operator=Equal \
  --set certController.tolerations[0].value=application \
  --set certController.tolerations[0].effect=NoSchedule

# 2. Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.tolerations[0].key=dedicated \
  --set controller.tolerations[0].operator=Equal \
  --set controller.tolerations[0].value=application \
  --set controller.tolerations[0].effect=NoSchedule \
  --set controller.admissionWebhooks.patch.tolerations[0].key=dedicated \
  --set controller.admissionWebhooks.patch.tolerations[0].operator=Equal \
  --set controller.admissionWebhooks.patch.tolerations[0].value=application \
  --set controller.admissionWebhooks.patch.tolerations[0].effect=NoSchedule
```

---

### Step 6: Code Changes in Helm Chart (`chart/values.yaml`)

Edit `chart/values.yaml` and update the following configuration sections:

#### A. Ingress & Hostname Section
```yaml
domain: "<DOMAIN_NAME>"                 # e.g., keycloak-aws.opstree.dev
hostname: "<DOMAIN_NAME>"               # Must match domain FQDN
```

#### B. Database Section
```yaml
database:
  vendor: postgres
  host: "<POSTGRES_HOST>"               # e.g., dev-negd-rds-postgres.cl0caskygcz8...
  port: 5432
  name: "keycloak"
  username: "<POSTGRES_USER>"           # e.g., postgres
  createSecret: false
  existingSecret: "keycloak-db-secret"
```

#### C. External Secrets Section
```yaml
externalSecrets:
  enabled: true
  awsRegion: "<AWS_REGION>"
  awsSecretName: "<AWS_SECRET_NAME>"   # e.g., rds!db-591e0ce4-d55e-46a7...
  adminPasswordSecretName: "production/keycloak/admin"
  propertyPassword: "password"
  propertyAdminPassword: "admin-password"
```

#### D. ServiceAccount & IRSA Section
```yaml
serviceAccount:
  create: true
  name: keycloak-service-account
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::<AWS_ACCOUNT_ID>:role/KeycloakSecretsManagerRole"
```

#### E. Tolerations Section (Keep Intact)
```yaml
tolerations:
  - key: "dedicated"
    operator: "Equal"
    value: "application"
    effect: "NoSchedule"
  - key: "dedicated"
    operator: "Equal"
    value: "database"
    effect: "NoSchedule"
```

---

### Step 7: Provision TLS Secret & Deploy Keycloak

#### 7.1 Create Namespace & TLS Certificate Secret
```bash
# Create target namespace
kubectl create namespace keycloak

# Upload TLS Certificate Secret
kubectl create secret tls keycloak-tls-secret \
  --cert=/path/to/fullchain.pem \
  --key=/path/to/privkey.key \
  -n keycloak
```

#### 7.2 Deploy Keycloak Helm Release
```bash
helm upgrade --install keycloak ./chart \
  --namespace keycloak \
  --create-namespace
```

---

### Step 8: Post-Deployment Verification & DNS Routing

#### 1. Verify ExternalSecret Sync Status
```bash
kubectl get externalsecret,secretstore,secret -n keycloak
```
*Verification Goal:* `STATUS: SecretSynced`, `READY: True`. Secret `keycloak-db-secret` created.

#### 2. Check Pod Scheduling & Status
```bash
kubectl get pods -n keycloak -o wide
```
*Verification Goal:* 2 Pods in `Running` status on nodes with taint `dedicated=application:NoSchedule`.

#### 3. Inspect Live Startup Logs
```bash
kubectl logs -f deployment/keycloak -n keycloak
```
*Verification Goal:* Look for `Keycloak 26.3.3 started in ...ms`. Zero DB connection errors.

#### 4. Retrieve NGINX Load Balancer External Address
```bash
kubectl get svc -n ingress-nginx
```
*Copy the `EXTERNAL-IP` (e.g. `a16807e072f9646f...ap-south-1.elb.amazonaws.com`).*

#### 5. Map CNAME Record in DNS Provider
* **Record Type:** `CNAME`
* **Host / Subdomain:** `keycloak-aws` (or `<DOMAIN_NAME>`)
* **Target Value:** `<NGINX_LOAD_BALANCER_EXTERNAL_IP>`

---

## Quick Reference Summary Checklist

- [ ] Connected `kubectl` to dynamic EKS cluster endpoint `<EKS_CLUSTER_ENDPOINT>`.
- [ ] Created admin password secret `production/keycloak/admin` in AWS Secrets Manager.
- [ ] Updated IAM Role trust relationship for OIDC provider `<OIDC_PROVIDER_ID>`.
- [ ] Added PostgreSQL 5432 inbound rule to RDS Security Group.
- [ ] Executed `CREATE DATABASE keycloak;` on RDS using `sslmode=require`.
- [ ] Installed External Secrets Operator and NGINX Ingress with CRDs & node tolerations.
- [ ] Updated `chart/values.yaml` (`database.host`, `externalSecrets.awsSecretName`, `serviceAccount.annotations`).
- [ ] Created TLS secret `keycloak-tls-secret` in namespace `keycloak`.
- [ ] Executed `helm upgrade --install keycloak ./chart -n keycloak`.
- [ ] Confirmed pods `Running` and mapped DNS CNAME to NGINX Load Balancer `EXTERNAL-IP`.
