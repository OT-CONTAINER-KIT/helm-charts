# sentryfuse

One chart for all SentryFuse services. Each workload is an entry under `services` in values
(`consumer`, `consumer-gitlab`, `consumer-pr`, `api`, `webhook`, `frontend`, `pr-reviewer`);
shared templates render a Deployment, Service, ConfigMap, HPA, Ingress and ServiceAccount per
enabled entry. See the comment block in `values.yaml` for the per-service fields.

```
helm upgrade --install sf charts/sentryfuse -n sentryfuse -f <env-values>.yaml
```

Keep environment values (DB, Slack, hosts, credentials) in your own values file, not in git.
Set `services.<key>.name` to control object names (default `<release>-<key>`).
