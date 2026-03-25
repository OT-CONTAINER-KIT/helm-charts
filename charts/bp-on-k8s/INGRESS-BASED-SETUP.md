# Installation

## Description
The steps needed for the complete setup of Buildpiper in a K8S cluster when using ingress is provided in the installation steps below.

### Prerequisites
- Ensure the EFS-based CSI driver setup is completed in the EKS cluster.
- Clone the repository locally.
- If license is enabled then, `exec` to `publicapi` pod, and run command `python manage.py shell < ~/.common/licence/license-setup.py`.

### Steps

1. **Update Helm Chart Values and Install**
   - Customize `ingress-setup-values.yaml` based on your requirements.
   - Add helm repo
     ```bash
     helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
     ```
     
   - Install the Helm chart:
     ```bash
     helm install bp ot-helm/bp-on-k8s --set optimizedRun.firstTime=true --set optimizedRun.withPermission=true -f values.yaml -f loadbalancer-setup-values.yaml
     sleep 180
     kubectl exec -it $(kubectl get pod -l io.buildpiper.app=publicapi -o=jsonpath='{.items[*].metadata.name}') -- bash -c "mkdir -p ~/.common/licence; cp ~/.common/tmp/* ~/.common/licence/; chown -R buildpiper:buildpiper ~/.common/licence/; python manage.py shell < ~/.common/licence/license-setup.py"
     ```

   - If deploying into a specific namespace (e.g., `bp`):
     ```bash
     helm install bp ot-helm/bp-on-k8s --set optimizedRun.firstTime=true --set optimizedRun.withPermission=true --namespace bp -f values.yaml -f loadbalancer-setup-values.yaml
     sleep 180
     kubectl exec -n bp -it $(kubectl get pod -l io.buildpiper.app=publicapi -o=jsonpath='{.items[*].metadata.name}' -n bp) -- bash -c "mkdir -p ~/.common/licence; cp ~/.common/tmp/* ~/.common/licence/; chown -R buildpiper:buildpiper ~/.common/licence/; python manage.py shell < ~/.common/licence/license-setup.py"
     ```

   - Check publicapi log if it is up completely
     ```bash
     kubectl logs -f $(kubectl get pod -l io.buildpiper.app=publicapi -o=jsonpath='{.items[*].metadata.name}')
     ```

   - If setup deployed in namesapce `bp` 
     ```bash
     kubectl logs -n bp -f $(kubectl get pod -n bp -l io.buildpiper.app=publicapi -o=jsonpath='{.items[*].metadata.name}')
     ```

2. **Retrieve Public API Hostname from ingress**
   - When using K8S ingress for the hostname of the `publicapi`:
     ```bash
     publicapi_hostname=$(kubectl get ingress publicapi-ingress -o jsonpath='{.spec.rules[*].host}') && bp_frontend_hostname=$(kubectl get svc frontend -o jsonpath='{.status.loadBalancer.rules[*].host}') && md_api_hostname=$(kubectl get svc maturity-dashboard-api -o jsonpath='{.status.loadBalancer.rules[*].host}')
     ```

   - If ingress is deployed into a specific namespace (e.g., `bp`):
     ```bash
     publicapi_hostname=$(kubectl get ingress publicapi-ingress -n bp -o jsonpath='{.spec.rules[*].host}') && bp_frontend_hostname=$(kubectl get svc frontend -n bp -o jsonpath='{.status.loadBalancer.rules[*].host}') && md_api_hostname=$(kubectl get svc maturity-dashboard-api -n bp -o jsonpath='{.status.loadBalancer.rules[*].host}')
     ```

3. **Upgrade Helm Chart**
   - Perform a Helm upgrade when using ingress for publicapi and frontend:
     ```bash
     helm upgrade bp ot-helm/bp-on-k8s --set envJson.publicapi="http://${publicapi_hostname}/" --set maturityDashboard.envJson.api="http://${md_api_hostname}/" --set maturityDashboard.envJson.frontend="http://${bp_frontend_hostname}/" -f values.yaml -f ingress-setup-values.yaml
     ```

   - If setup deployed in namesapce `bp`
     ```bash
     helm upgrade bp ot-helm/bp-on-k8s --set envJson.publicapi="http://${publicapi_hostname}/" --set maturityDashboard.envJson.api="http://${md_api_hostname}/" --set maturityDashboard.envJson.frontend="http://${bp_frontend_hostname}/" --namespace bp -f values.yaml -f ingress-setup-values.yaml
     ```

4. **Update Frontend Pod**
   - Delete the `frontend` pod to apply the updated `env.json`:
     ```bash
     kubectl delete pod -l 'io.buildpiper.app in (frontend, publicapi, scheduleapi, bpagent, maturity-dashboard-frontend, maturity-dashboard-agent)' 
     ```
     # bpagent, maturity-dashboard-frontend, maturity-dashboard-agent, maturity-dashboard-api,

   - If operating within the `bp` namespace:
     ```bash
     kubectl delete pod -l 'io.buildpiper.app in (frontend, publicapi, scheduleapi, bpagent, maturity-dashboard-frontend, maturity-dashboard-agent)' -n bp
     ```
     # bpagent, maturity-dashboard-frontend, maturity-dashboard-agent, maturity-dashboard-api,

   - Check frontend logs if it is up completely
     ```bash
     kubectl logs -f $(kubectl get pod -l io.buildpiper.app=frontend -o=jsonpath='{.items[*].metadata.name}')
     ```

   - If setup deployed in namesapce `bp` 
     ```bash
     kubectl logs -n bp -f $(kubectl get pod -n bp -l io.buildpiper.app=frontend -o=jsonpath='{.items[*].metadata.name}')
     ```

### Final Steps
- Wait for all pods to come up.
- Check the logs to ensure everything is running correctly.
- Use Buildpiper with the external hostname of the frontend service.


### To remove all Buildpiper K8S components
   - Uninstall buildpiper:
     ```bash
     helm uninstall bp --wait
     ```
