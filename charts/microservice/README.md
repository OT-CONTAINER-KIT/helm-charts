# Basic Helm Template for Deploying Microservice on K8s

## Chart Structure
```
microservice/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
    ├── deployment.yaml
    └── service.yaml
```

## Usage

You can change the Docker image by modifying the values.yaml file. For example, to use a different image, update the `image.repository` and `image.tag` fields.

The Helm chart is specifically for deploying a microservice with a Kubernetes service and deployment. You can further customize and expand this chart as needed for your application.

## Installing the Chart on K8s

```bash
helm install my-release microservice/
```