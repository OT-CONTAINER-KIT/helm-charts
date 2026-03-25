# Installation

## Description
The steps needed for the complete setup of Buildpiper in a K8S cluster when using LB based service is provided in the installation steps below.

### Prerequisites
- Ensure the EFS-based CSI driver setup is completed in the EKS cluster.
- Clone the repository locally.
- If license is enabled then, `exec` to `publicapi` pod, and run command `python manage.py shell < ~/.common/licence/license-setup.py`.

### Steps

1. **Update Helm Chart Values and Install**
   - Customize `loadbalancer-setup-values.yaml` based on your requirements.
   - Add helm repo
     ```bash
     helm repo add ot-helm https://ot-container-kit.github.io/helm-charts
     ```
     
   - Install the Helm chart:
     ```bash
     helm install bp ot-helm/bp-on-k8s --set optimizedRun.firstTime=true --set optimizedRun.withPermission=true -f values.yaml -f loadbalancer-setup-values.yaml
     sleep 180
     kubectl exec -n bp -it $(kubectl get pod -l io.buildpiper.app=publicapi -o=jsonpath='{.items[*].metadata.name}' -n bp) -- bash -c "mkdir -p ~/.common/licence; cp ~/.common/tmp/* ~/.common/licence/; chown -R buildpiper:buildpiper ~/.common/licence/; python manage.py shell < ~/.common/licence/license-setup.py"
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

2. **Retrieve Public API Hostname/IP from services**
   - Fetch the public hostname/IP of the `publicapi` service:
     ```bash
     publicapi_hostname=$(kubectl get svc publicapi -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') && bp_frontend_hostname=$(kubectl get svc frontend -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') && md_api_hostname=$(kubectl get svc maturity-dashboard-api -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
     ```

   - If deploying into a specific namespace (e.g., `bp`):
     ```bash
     publicapi_hostname=$(kubectl get svc publicapi -n bp -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') && bp_frontend_hostname=$(kubectl get svc frontend -n bp -o jsonpath='{.status.loadBalancer.ingress[*].hostname}') && md_api_hostname=$(kubectl get svc maturity-dashboard-api -n bp -o jsonpath='{.status.loadBalancer.ingress[*].hostname}')
     ```

3. **Upgrade Helm Chart**
   - Perform a Helm upgrade:
     ```bash
     helm upgrade bp ot-helm/bp-on-k8s --set envJson.publicapi="http://${publicapi_hostname}:9001/" --set maturityDashboard.envJson.api="http://${md_api_hostname}:9004/" --set maturityDashboard.envJson.frontend="http://${bp_frontend_hostname}:80/" -f values.yaml -f loadbalancer-setup-values.yaml
     ```

   - For upgrades within a specific namespace (e.g., `bp`):
     ```bash
     helm upgrade bp ot-helm/bp-on-k8s --set envJson.publicapi="http://${publicapi_hostname}:9001/" --set maturityDashboard.envJson.api="http://${md_api_hostname}:9004/" --set maturityDashboard.envJson.frontend="http://${bp_frontend_hostname}:80/" --namespace bp -f values.yaml -f loadbalancer-setup-values.yaml
     ```

4. **Update Frontend Pod**
   - Delete the pods to apply the updated `env.json`:
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
     kubectl delete sa buildpiper-sa
     ```
  
   - If setup deployed in namesapce `bp` 
     ```bash
     helm uninstall bp -n bp --wait
     kubectl delete sa buildpiper-sa -n bp
     ```

+91-8318-9892-64
