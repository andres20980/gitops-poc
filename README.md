# GitOps Proof of Concept (PoC)  
**Version: 2.2.0**

---

## 1. Introduction

This repository demonstrates a modern GitOps workflow using a robust stack of Cloud Native tools. It showcases best practices for application composition, continuous deployment, and progressive delivery on Kubernetes.

**Core Technologies:**
- **Argo CD:** GitOps agent that continuously syncs the Kubernetes cluster state to match the desired state in Git.
- **Kustomize:** Declarative management and customization of Kubernetes manifests, enabling environment-specific configurations.
- **Argo Rollouts:** Advanced deployment strategies (Canary, Blue-Green) for safe, progressive delivery.

**Applications:**
- `kustomiworld`
- `kustomispace`

Each is composed of several microservices and configured for different deployment strategies.

---

## 2. Core Concepts

### 2.1. GitOps with Argo CD

- **Source of Truth:** This repository is the single source of truth. All cluster changes are made via commits.
- **Declarative Manifests:**  
  `argo-cd/apps/` contains Argo CD `Application` custom resources, specifying:
  - Manifest location (`path`)
  - Target Kubernetes `server`
  - Deployment `namespace`
- **Automated Sync:**  
  `syncPolicy: automated` ensures Argo CD automatically applies detected changes, keeping the cluster state in sync with Git.

### 2.2. Application Composition with Kustomize

- **Components (Bases):**  
  `kustomize/components/` holds base, environment-agnostic manifests for each microservice (e.g., `helloworld`, `sun`, `carbone`).
- **Applications:**  
  `kustomize/apps/` composes complete applications from components.
  - **Base:** (e.g., `kustomize/apps/kustomiworld/base/`) lists required components.
  - **Overlays:** (e.g., `kustomize/apps/kustomiworld/overlays/dev/`) inherit from base and apply environment-specific patches (replica counts, image tags, labels, etc.).

---

## 3. Advanced Deployment Strategies with Argo Rollouts

This PoC implements progressive delivery strategies for safe, controlled releases using the `Rollout` custom resource.

### 3.1. Canary Release

**Used for:** `helloworld`, `carbone` components  
**Strategy:** Gradually shifts a percentage of traffic to the new version before full rollout.

**Configuration:**
- `stableService`: Receives production traffic.
- `canaryService`: Receives test traffic for the new version.
- `steps`:
  1. `setWeight: 20` — Send 20% of traffic to the new version.
  2. `pause: {}` — Pause rollout indefinitely for manual validation.

**Example: `helloworld` Rollout**
```yaml
# kustomize/components/custom/helloworld/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: helloworld
spec:
  # ... pod template ...
  strategy:
    canary:
      stableService: helloworld-service
      canaryService: helloworld-service-canary
      steps:
        - setWeight: 20
        - pause: {}
```

---

### 3.2. Blue-Green Deployment

**Used for:** `sun`, `moon` components  
**Strategy:** Deploys new version (Green) alongside old (Blue) without initial production traffic.

**Configuration:**
- `activeService`: Points to the stable (Blue) version.
- `previewService`: Points to the new (Green) version for isolated testing.
- `autoPromotionEnabled: false`: Pauses rollout after Green is available; manual promotion required to switch traffic.

**Example: `sun` Rollout**
```yaml
# kustomize/components/custom/sun/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: sun
spec:
  # ... pod template ...
  strategy:
    blueGreen:
      activeService: sun-service
      previewService: sun-service-preview
      autoPromotionEnabled: false
```

---

## 4. Project Structure

```
.
├── argo-cd/apps/               # Argo CD Application manifests (entrypoint)
│   ├── app-kustomiworld-dev.yaml
│   ├── app-kustomiworld-pre.yaml
│   └── ...
├── kustomize/
│   ├── apps/                   # Application definitions
│   │   ├── kustomiworld/
│   │   │   ├── base/           # Composes app from components
│   │   │   └── overlays/       # Environment-specific customizations
│   │   │       ├── dev/
│   │   │       └── pre/
│   │   └── ...
│   └── components/             # Reusable base manifests for each microservice
│       ├── custom/
│       │   ├── byebyeworld/
│       │   ├── helloworld/
│       │   └── ...
│       └── third-party/
│           └── carbone/
└── services/                   # Docker build context and other resources
    └── carbone-ee-docker/
```

---

## 5. How to Deploy

**Prerequisites:**
- Running Kubernetes cluster
- Argo CD and Argo Rollouts installed

**Deployment Commands:**
```bash
# Deploy 'kustomiworld' to DEV
kubectl apply -f argo-cd/apps/app-kustomiworld-dev.yaml

# Deploy 'kustomispace' to DEV
kubectl apply -f argo-cd/apps/app-kustomispace-dev.yaml
```
Argo CD will detect the Application resource and synchronize all Kubernetes resources as defined in the `kustomize/` path.

---

### Triggering a New Rollout

A new rollout can be triggered by:
- **Changing the container image:** Update the image tag in the component's `rollout.yaml`.
- **Changing the Pod Template:** Any change to the pod template in the Rollout spec triggers a new release.

**Tip:**  
Dev overlays apply a patch to add a `rollout-timestamp` label. Changing its value in a commit triggers a new deployment, even without a new image.

**Example patch (`kustomispace/overlays/dev`):**
```yaml
# kustomize/apps/kustomispace/overlays/dev/kustomization.yaml
patches:
  - patch: |-
      - op: add
        path: /spec/template/metadata/labels/rollout-timestamp
        value: "2025-06-26T13-15-00Z"
    target:
      kind: Rollout
      name: sun
```