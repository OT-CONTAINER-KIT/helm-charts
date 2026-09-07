# keycloak

Hand-written Helm chart for self-hosted [Keycloak](https://www.keycloak.org/) using the
**official** `quay.io/keycloak/keycloak` image, backed by an **external** PostgreSQL
database. Styled after `charts/postgres-16`.

Renders a `Deployment` + `Service`, plus an optional `Secret` (self-created unless
`existingSecret` is set), `ServiceAccount`, and realm-import `ConfigMap`. No subcharts,
no bundled database, no namespace hardcoded in the templates.

## Usage

    helm install keycloak ./charts/keycloak -n <namespace> -f my-values.yaml

or, for a GitOps / BuildPiper apply:

    helm template keycloak ./charts/keycloak -n <namespace> -f my-values.yaml \
      | kubectl apply -n <namespace> -f -

## Required values

| Value | Purpose |
| ----- | ------- |
| `image.repository` (+ `image.registry`) | Keycloak image location |
| `db.host` / `db.name` / `db.user` | External PostgreSQL coordinates |
| `db.password` **or** `existingSecret` | DB password source |
| `auth.adminPassword` **or** `existingSecret` | Bootstrap admin password source |

Every key in `values.yaml` is commented.

## Notes

- Runs `kc.sh start` (production, auto-build) by default. `start --optimized` needs a
  pre-built derived image.
- Single replica only unless you configure Infinispan/JGroups (`cache: ispn` + RBAC).
- Health/metrics live on the management port (9000); the probes target it and it is not
  published by the Service.
- Behind a TLS-terminating LB set `proxy: xforwarded` and `http.enabled: true`. Phase 1
  (in-cluster): `hostnameStrict: false`, `hostname: ""`. Phase 2 (public): set both.
- The bootstrap admin (`auth.adminUser` / admin password) is created only on the first
  start against an empty database.

## Maintainers

| Name | Email | Url |
| ---- | ----- | --- |
| Samyak Jain | samyak.jain@opstree.com | https://github.com/samyakjain1908 |
