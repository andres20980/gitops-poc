# GitOps Proof of Concept (PoC)  
**Version: 3.0.0**

---

## 1. Introduction

This repository demonstrates a modern GitOps workflow using a robust stack of Cloud Native tools. It showcases best practices for application composition, continuous deployment, and progressive delivery on Kubernetes.

**Core Technologies:**
- **Argo CD:** GitOps agent that continuously syncs the Kubernetes cluster state to match the desired state in Git.
- **Helm:** Used as the base templating engine for creating standard, reusable application definitions.
- **Kustomize:** Declarative management and customization of the Helm-generated manifests, enabling environment-specific configurations.
- **Argo Rollouts:** Advanced deployment strategies (Canary, Blue-Green) for safe, progressive delivery, now integrated into the base Helm chart.

**Applications:**
- `world`
- `space`

Each is composed of several microservices and configured for different deployment strategies and environments (dev, pre).

---

## 2. Core Concepts

### 2.1. GitOps with Argo CD ("App of Apps" per Environment)

- **Source of Truth:** This repository is the single source of truth. All cluster changes are made via commits.
- **Environment-Driven Management:** We use the **"App of Apps" per Environment** pattern. A root application exists for each environment (e.g., `root-app-dev`), which in turn discovers and manages all applications belonging to that environment.
- **Automated Sync:** `syncPolicy: automated` ensures Argo CD automatically applies detected changes, keeping the cluster state in sync with Git.

### 2.2. Component Management with Helm & Kustomize

This PoC uses a powerful combination of Helm for templating and Kustomize for customization.

- **Base Helm Chart (`helm-base/`):** A single, standardized Helm chart located in `helm-base/` defines the "shape" of all our applications. It contains templates for Kubernetes resources like `Deployments`, `Rollouts`, `Services`, `HPA`, etc.
- **Components (`kustomize/components/`):** Each microservice is defined as a Kustomize component. However, instead of containing raw YAML, the `base` of each component now primarily contains two files:
  1. `kustomization.yaml`: Points to the local Helm chart in `helm-base/`.
  2. `values.yaml`: Provides the specific configuration values for that component (e.g., image name, port, rollout strategy).
- **Application Overlays (`kustomize/apps/`):** These still compose complete applications from components and apply environment-specific patches (e.g., different image tags for `dev` vs. `pre`, replica counts, etc.).

---

## 3. Advanced Deployment Strategies with Argo Rollouts

Progressive delivery is now built into our base Helm chart and can be enabled and configured via each component's `values.yaml` file.

### 3.1. Canary Release

**Configuration:** In a component's `values.yaml`, set:

```yaml
rollout:
  enabled: true
  strategy: "Canary"
```

This instructs the Helm chart to generate a Rollout resource with a Canary strategy and its required services.

### 3.2. Blue-Green Deployment

**Configuration:** In a component's `values.yaml`, set:

```yaml
rollout:
  enabled: true
  strategy: "BlueGreen"
```

This instructs the Helm chart to generate a Rollout resource with a Blue-Green strategy and its required active and preview services.

---

## 4. Project Structure

```
.
├── argo-cd/
│   ├── apps/
│   │   ├── dev/            # Argo CD Application manifests for DEV
│   │   └── pre/            # Argo CD Application manifests for PRE
│   └── roots/
│       ├── root-app-dev.yaml # Root App that manages everything in dev/
│       └── root-app-pre.yaml # Root App that manages everything in pre/
├── helm-base/                # The single, shared Helm Chart for all components
│   ├── Chart.yaml
│   ├── templates/
│   └── values.yaml
├── kustomize/
│   ├── apps/                 # Application definitions
│   │   └── ...
│   ├── components/           # Reusable components
│   │   └── custom/
│   │      └── helloworld/
│   │          └── base/
│   │              ├── kustomization.yaml # -> Points to helm-base
│   │              └── values.yaml      # -> Configures helloworld
│   └── ...
└── services/                 # Docker build context and source code
  └── ...
```

---

## 5. How to Deploy

**Prerequisites:**
- Running Kubernetes cluster
- Argo CD and Argo Rollouts installed

**Deployment Commands:**

With the new "App of Apps" per environment structure, you only need to apply the root application for the environment you want to deploy.

```bash
# Deploy EVERYTHING for the DEV environment
kubectl apply -f argo-cd/roots/root-app-dev.yaml

# Deploy EVERYTHING for the PRE environment
kubectl apply -f argo-cd/roots/root-app-pre.yaml
```

Argo CD will detect the root application, which will then automatically discover and deploy all child applications defined in the corresponding `argo-cd/apps/` subdirectory.

---

### Managing Applications

- **To add a new app to an environment:** Add its `app-name.yaml` manifest to the correct subdirectory (e.g., `argo-cd/apps/dev/`) and commit. The root app will deploy it automatically.
- **To remove an app from an environment:** Delete its `app-name.yaml` manifest from the Git repository and commit. The root app, thanks to `prune: true`, will remove it from the cluster automatically.