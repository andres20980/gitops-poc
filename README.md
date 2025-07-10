# GitOps PoC (Proof of Concept)

## Overview

This repository implements a GitOps Proof of Concept (PoC) using **Azure DevOps Pipelines**, **Helm**, **Docker**, and **Argo CD** (configured externally in [`msw-cic-argo-config`](https://dev.azure.com/mapal-software/CICD/_git/msw-cic-argo-config)).

The PoC automates the full CI/CD workflow for containerized applications, leveraging Git as the **single source of truth**, with Argo CD automatically deploying any changes to Kubernetes.

---

## 📁 Repository Structure

```
.pipelines/                # Reusable Azure DevOps pipeline templates (YAML)
│   └── templates/
│       └── component-build-push.yml   # Shared CI/CD logic for all services (build, push, patch)
├── apps/                  # Declarative Helm structure per environment
│   └── dev/
│       ├── app-one/       # Composite Helm chart: includes helloworld + carbone
│       │   ├── Chart.yaml         # Declares Helm dependencies
│       │   ├── values.yaml        # Shared values for the app
│       │   └── values/
│       │       ├── helloworld.yaml    # Component-specific values (image repo, tag, replicas)
│       │       └── carbone.yaml
│       └── app-two/       # Helm chart using only carbone as a dependency
│           ├── Chart.yaml
│           ├── values.yaml
│           ├── values/
│           │   └── carbone.yaml
│           └── kustomization.yaml     # Optional: Helm chart definition via Kustomize
├── services/              # Application source code and individual pipelines
│   ├── helloworld-app/    # Simple internal Python app
│   │   ├── Dockerfile
│   │   ├── app.py
│   │   └── azure-pipelines.yml    # GitOps-compliant CI pipeline
│   └── carbone-ee-docker/ # Custom Carbone image with plugins, LibreOffice, fonts
│       ├── Dockerfile
│       ├── azure-pipeline.yml
│       └── deployement/   # Optional: alternative deploy targets (ECS, ACA, docker-compose)
├── export_poc_structure.sh    # Script to export the current repo structure and contents
└── README.md                  # You're reading it!
```

---

## 🔄 GitOps Workflow

### 1. Source Code Changes

Developers commit code to `services/<name>/`.

### 2. Azure DevOps Pipeline Execution

Each service has its own pipeline file which extends the shared template:

- Builds the Docker image
- Pushes it to Azure Container Registry (ACR)
- Patches the related `apps/dev/**/values/<component>.yaml` with the new image tag
- Commits and pushes the update back to the `main` branch

### 3. Argo CD Sync

Defined in the external repo [`msw-cic-argo-config`](https://dev.azure.com/mapal-software/CICD/_git/msw-cic-argo-config), Argo CD Applications are configured like this:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
    name: app-one-dev
spec:
    source:
        repoURL: https://dev.azure.com/mapal-software/CICD/_git/msw-cic-gitops-poc
        path: apps/dev/app-one
        helm:
            valueFiles:
                - values/helloworld.yaml
                - values/carbone.yaml
    destination:
        namespace: app-one-dev
    syncPolicy:
        automated:
            prune: true
            selfHeal: true
```

Argo CD detects changes and auto-syncs to the Kubernetes cluster.

---

## 📦 Helm Usage

Each application in `apps/dev/` is a Helm composite chart with:

- A `Chart.yaml` defining dependencies
- A shared `values.yaml` (global config for the app)
- One YAML file per dependency inside the `values/` directory (e.g., `carbone.yaml`, `helloworld.yaml`)

**Rendering an app manually (for local testing):**

```bash
helm dependency build apps/dev/app-one
helm upgrade --install app-one apps/dev/app-one \
    -f apps/dev/app-one/values.yaml \
    -f apps/dev/app-one/values/helloworld.yaml \
    -f apps/dev/app-one/values/carbone.yaml
```

---

## ⚙️ Pipeline Template

The shared pipeline logic lives in:

- `.pipelines/templates/component-build-push.yml`

This template:

- Logs in to ACR
- Builds and pushes Docker images
- Automatically updates `Helm values/<component>.yaml` with the new tag
- Commits & pushes changes to main if values changed

Pipelines for each service reference this template and provide parameters like `serviceName`, `chartBaseVersion`, etc.

---

## 🛠️ Requirements

- Azure DevOps with service connections to ACR
- Azure Container Registry (with OCI Helm chart support)
- Kubernetes cluster with Argo CD installed
- Argo CD config in external repo: `msw-cic-argo-config`
- Tools: `helm`, `yq` (v4+), `kubectl`, `git`

---

## ✅ Summary

This PoC enables a production-grade GitOps workflow with:

- Declarative Helm-based app definitions
- CI/CD with image build + GitOps patching via Azure Pipelines
- Argo CD auto-sync from Git to Kubernetes

All deployments are driven by Git, and any new commit to `main` is automatically rolled out to the cluster by Argo CD.

---