# Keycloak Production Troubleshooting & Issue Resolution Guide

This document provides a post-mortem troubleshooting runbook of all technical issues encountered during the **Keycloak 26.x (Quarkus distribution)** deployment on **AWS EKS** and **Amazon RDS PostgreSQL**, detailing the exact error symptoms, root cause analysis, and step-by-step resolutions.

---

## Technical Issues Faced, Root Cause Analysis & Solutions

### Problem 1: `ERROR: Failed to obtain JDBC connection` (Network Timeout)
* **Error Log / Symptom:**
  ```text
  org.postgresql.util.PSQLException: The connection attempt failed / Connection timed out
  ERROR: Failed to obtain JDBC connection
  ```
* **Root Cause:** The RDS Security Group (`sg-0e829cc2fbec0bc66`) was missing an inbound rule allowing TCP port `5432` from the EKS worker node subnet CIDR (`10.10.0.0/16`).
* **Resolution Step:** Added an inbound security group rule on the RDS Security Group allowing TCP port `5432` from source CIDR `10.10.0.0/16` (or EKS worker node security group ID).

---

### Problem 2: `FATAL: database "keycloak" does not exist`
* **Error Log / Symptom:**
  ```text
  FATAL: database "keycloak" does not exist
  unable to obtain isolated JDBC connection
  ```
* **Root Cause:** The Amazon RDS PostgreSQL instance was provisioned with default database `appdb` (or `postgres`). The logical database `keycloak` was not created automatically upon RDS startup.
* **Resolution Step:** Ran a temporary container to execute database creation on the master RDS instance:
  ```bash
  kubectl run create-db --rm -it \
    --image=postgres:16-alpine \
    --overrides='{"spec":{"tolerations":[{"operator":"Exists"}]}}' \
    -- sh -c 'PGPASSWORD="<POSTGRES_PASSWORD>" psql \
    "host=<POSTGRES_HOST> user=<POSTGRES_USER> dbname=appdb sslmode=require" \
    -c "CREATE DATABASE keycloak;"'
  ```

---

### Problem 3: Pods Stuck in `Pending` or `CreateContainerConfigError`
* **Error Log / Symptom:**
  ```text
  kubectl get pods -n keycloak
  NAME                        READY   STATUS                       RESTARTS   AGE
  keycloak-558ffbb79b-7dd74   0/1     CreateContainerConfigError   0          2m26s
  ```
* **Root Cause:**
  1. Worker nodes were tainted with `dedicated=application:NoSchedule`, but the deployment spec lacked matching node tolerations.
  2. The target secret `keycloak-db-secret` did not exist because External Secrets Operator (ESO) failed to sync credentials.
* **Resolution Step:** Added explicit node tolerations block in [`chart/templates/deployment.yaml`](file:///c:/Users/lenovo/OneDrive/Desktop/Keycloak/chart/templates/deployment.yaml) and fixed ESO secret sync permissions.

---

### Problem 4: CRD Missing Error (`no matches for kind "ExternalSecret"`)
* **Error Log / Symptom:**
  ```text
  Error: resource mapping not found for name: "keycloak-secrets" namespace: "keycloak" from "": 
  no matches for kind "ExternalSecret" in version "external-secrets.io/v1"
  ```
* **Root Cause:** External Secrets Operator helm chart was installed without enabling Custom Resource Definitions (CRDs).
* **Resolution Step:** Installed ESO with CRDs explicitly enabled:
  ```bash
  helm install external-secrets external-secrets/external-secrets \
    -n external-secrets \
    --create-namespace \
    --set installCRDs=true
  ```

---

### Problem 5: Webhook Call Failure (`failed calling webhook "validate.externalsecret.external-secrets.io"`)
* **Error Log / Symptom:**
  ```text
  Internal error occurred: failed calling webhook "validate.externalsecret.external-secrets.io": 
  Post "https://external-secrets-webhook.external-secrets.svc:443/validate-...": Service Unavailable
  ```
* **Root Cause:** The ESO Webhook pod could not be scheduled onto EKS worker nodes because the nodes had taint `dedicated=application:NoSchedule`, while the webhook deployment lacked node tolerations.
* **Resolution Step:** Reinstalled ESO with webhook tolerations enabled:
  ```bash
  helm upgrade --install external-secrets external-secrets/external-secrets \
    -n external-secrets \
    --set installCRDs=true \
    --set webhook.tolerations[0].key=dedicated \
    --set webhook.tolerations[0].operator=Equal \
    --set webhook.tolerations[0].value=application \
    --set webhook.tolerations[0].effect=NoSchedule
  ```

---

### Problem 6: Access Denied to KMS Key (`Access to KMS is not allowed`)
* **Error Log / Symptom:**
  ```text
  kubectl describe externalsecret keycloak-secrets -n keycloak
  Warning UpdateFailed: operation error Secrets Manager: GetSecretValue, 
  api error AccessDeniedException: Access to KMS is not allowed
  ```
* **Root Cause:** AWS RDS automated secret (`rds!db-591e0ce4...`) was encrypted using AWS managed KMS key `negd-dev1-rds-postgres`. The IAM Role `KeycloakSecretsManagerRole` had `secretsmanager:*` permissions but lacked `kms:Decrypt` permission for the KMS key.
* **Resolution Step:** Updated IAM Policy `KeycloakSecretsManagerPolicy` to add `"kms:Decrypt"` on resource `"*"`.

---

### Problem 7: Missing Secret Key Error (`err: key host does not exist in secret`)
* **Error Log / Symptom:**
  ```text
  Warning UpdateFailed: error processing spec.data[0] (key: rds!db-591e0ce4...), 
  err: key host does not exist in secret
  ```
* **Root Cause:** AWS RDS automated managed secrets store JSON with keys `username`, `password`, `engine`, `port`, `dbInstanceIdentifier`, but **do not** include a `host` key inside the secret JSON.
* **Resolution Step:** Updated [`chart/templates/externalsecret.yaml`](file:///c:/Users/lenovo/OneDrive/Desktop/Keycloak/chart/templates/externalsecret.yaml) with `if not .Values.database.host` conditional logic so `db-host` is only fetched from Secrets Manager if not specified directly in `values.yaml`.

---

## Diagnostic & Debugging Cheat Sheet

### 1. Debug Keycloak Startup Errors
```bash
kubectl logs -f deployment/keycloak -n keycloak
```

### 2. Debug ExternalSecret Sync Failures
```bash
# Check status summary
kubectl get externalsecret,secretstore,secret -n keycloak

# Inspect detailed sync errors
kubectl describe externalsecret keycloak-secrets -n keycloak
```

### 3. Debug Pod Scheduling & Taint Failures
```bash
kubectl describe pod -l app.kubernetes.io/name=keycloak -n keycloak
```

### 4. Test RDS Connection & Database List
```bash
kubectl run check-db --rm -it --image=postgres:16-alpine \
  --overrides='{"spec":{"tolerations":[{"operator":"Exists"}]}}' \
  -- psql "host=<POSTGRES_HOST> user=<POSTGRES_USER> dbname=appdb sslmode=require" -c "\l"
```
