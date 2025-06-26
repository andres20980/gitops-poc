# GitOps Proof of Concept (PoC)

Este repositorio es una prueba de concepto que explora diferentes enfoques para implementar GitOps utilizando Argo CD. El proyecto evoluciona a través de varias fases:

1.  **Estructura inicial con Helm**: Creación de una arquitectura basada en "umbrella charts" de Helm para componer aplicaciones a partir de microservicios.
2.  **Conversión a Kustomize**: Migración de la misma lógica de aplicación utilizando la estructura de "bases" y "overlays" de Kustomize.
3.  **Despliegues avanzados con Argo Rollouts**: Implementación de una estrategia de despliegue Canary para lanzamientos más seguros y controlados.

---

## 📂 Estructura del Proyecto

El repositorio está organizado de la siguiente manera:

-   **`/apps`**: Contiene los "umbrella charts" de Helm que definen las aplicaciones.
-   **`/components`**: Contiene los "micro-charts" de Helm para cada componente/microservicio.
-   **`/kustomize`**: Contiene la estructura equivalente a la de Helm, pero utilizando Kustomize.
    -   `kustomize/components`: Bases de Kustomize para cada microservicio.
    -   `kustomize/apps`: Aplicaciones compuestas con Kustomize, con sus bases y overlays por entorno.
-   **`/argo-cd/apps`**: Contiene los manifiestos de `Application` de Argo CD que despliegan todo en el clúster.

---

## 🚀 Fase 1: Configuración con Helm

La estructura inicial utiliza Helm para gestionar las aplicaciones.

-   **Componentes**: Micro-charts para `helloworld`, `byebyeworld`, `moon` y `sun`.
-   **Aplicaciones**: Umbrella charts `world-app` y `space-app` que agrupan los componentes.
-   **Entornos**: La configuración para cada entorno (`dev`, `pre`) se gestiona con ficheros de valores específicos (`values.yaml`, `values-pre.yaml`).

El script `setup_gitops_poc.sh` se utilizó para generar esta estructura inicial.

### Despliegue (Helm)

Para desplegar las aplicaciones basadas en Helm, se aplican sus correspondientes manifiestos de Argo CD:

```bash
# Desplegar la app 'world' en el entorno de desarrollo
kubectl apply -f argo-cd/apps/app-world-dev.yaml

# Desplegar la app 'space' en el entorno de pre-producción
kubectl apply -f argo-cd/apps/app-space-pre.yaml
✨ Fase 2: Conversión a Kustomize
Se migró la world-app a una nueva aplicación llamada kustomiworld utilizando Kustomize para demostrar un enfoque alternativo a Helm.

Bases: Se creó una "base" para cada componente en kustomize/components/ con los manifiestos de Kubernetes limpios.
Aplicación Base: Se creó una "base" para kustomiworld en kustomize/apps/kustomiworld/base que referencia a los componentes que la forman.
Overlays: Se crearon "overlays" para los entornos dev y pre en kustomize/apps/kustomiworld/overlays/ para aplicar personalizaciones (cambio de imagen, número de réplicas, etc.).
Despliegue (Kustomize)
Para desplegar la aplicación basada en Kustomize:

Bash

# Desplegar la app 'kustomiworld' en el entorno de desarrollo
kubectl apply -f argo-cd/apps/app-kustomiworld-dev.yaml

# Desplegar la app 'kustomiworld' en el entorno de pre-producción
kubectl apply -f argo-cd/apps/app-kustomiworld-pre.yaml
canary Fase 3: Despliegues Avanzados con Argo Rollouts
Para mejorar la seguridad de los despliegues, se integró Argo Rollouts.

1. Instalación de Argo Rollouts
Primero, es necesario instalar el controlador en el clúster:

Bash

# 1. Crear el namespace
kubectl create namespace argo-rollouts

# 2. Instalar el controlador
kubectl apply -n argo-rollouts -f [https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml](https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml)

# 3. (Recomendado) Instalar el plugin de kubectl
brew install argoproj/tap/kubectl-argo-rollouts # macOS con Homebrew
2. Habilitación del Dashboard
Por defecto, la UI no está activada. Se habilitó parcheando el Deployment del controlador:

Bash

kubectl patch deployment argo-rollouts -n argo-rollouts --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--ui"]}]'
Para acceder al dashboard:

Bash

kubectl argo rollouts dashboard
3. Implementación de la Estrategia Canary
Se modificó el componente helloworld para usar un Rollout en lugar de un Deployment, definiendo una estrategia canary que envía el 20% del tráfico a la nueva versión y luego pausa el despliegue para una validación manual.

YAML

# kustomize/components/helloworld/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: helloworld
spec:
  # ... (resto de la configuración del pod)
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
El siguiente paso en el proyecto es ajustar los Services para que Argo Rollouts pueda gestionar el tráfico entre la versión estable y la canaria.


¿Qué te parece? Creo que resume muy bien todo nuestro progreso.

Fuentes y contenido relacionado






recuerda, bloque de codigo y en ingles. diferenciar entre umbrella chart y kustomize y por qué tenemos los dos, etc. Tambien todo el tema de instalacion. vamos, no te dejes nada en el README.md




Ver razonamiento
De acuerdo. He preparado una versión mucho más detallada del README.md, siguiendo tus instrucciones.

Este nuevo README.md hace una distinción más clara entre Helm y Kustomize, explica por qué ambos están en el proyecto, e incluye todos los pasos de instalación y configuración que hemos realizado, sin dejar nada fuera.

Aquí tienes el fichero completo, listo para copiar y pegar.

Markdown

# GitOps Proof of Concept (PoC) v2.0.0

## Introduction

This repository is a comprehensive Proof of Concept (PoC) designed to explore and compare different methodologies for implementing GitOps with Argo CD. The project evolves through distinct phases, providing a practical guide and side-by-side comparison of popular Cloud Native tools.

The key objectives and demonstrated concepts are:

1.  **Application Composition**: Compare two mainstream approaches for composing applications from multiple microservices:
    * **Helm**: Using Umbrella Charts.
    * **Kustomize**: Using a base and overlay structure.
2.  **Progressive Delivery**: Implement advanced and safer deployment strategies (Canary releases) using **Argo Rollouts**.
3.  **GitOps Workflow**: Utilize **Argo CD** as the core engine to manage the entire lifecycle of the applications, ensuring the state of the cluster always reflects the configuration defined in this Git repository.

---

## 🆚 Helm vs. Kustomize: A Comparison

This project intentionally implements the same application using both Helm and Kustomize to offer a practical comparison.

### Helm (Umbrella Charts)

Helm is a package manager for Kubernetes. It uses a templating engine (Go templates) to generate Kubernetes manifests.

-   **Approach**: We define reusable "micro-charts" for each component. An "Umbrella Chart" then groups these component charts as dependencies to form a complete application.
-   **Pros**:
    -   **Packaging & Reusability**: Charts are easy to version, package, and share.
    -   **Dependency Management**: Explicitly manages versions of sub-charts.
    -   **Rich Functionality**: The templating engine is powerful, allowing for complex logic.
-   **Cons**:
    -   **Complexity**: Go templating can be verbose and has a learning curve.
    -   **Abstraction**: Can sometimes feel like "magic," making it harder to debug the final rendered YAML.

### Kustomize

Kustomize is a template-free tool for customizing Kubernetes manifests. It's built directly into `kubectl`.

-   **Approach**: We define a "base" containing clean, standard Kubernetes YAML files. We then create "overlays" for each environment that apply patches (e.g., changing replicas, images, or adding annotations) to this base.
-   **Pros**:
    -   **Simplicity**: Works with standard YAML, no templating language to learn.
    -   **Declarative & Explicit**: Changes are applied via explicit patch files, making customizations easy to read and review.
-   **Cons**:
    -   **Verbosity**: Applying many small changes can lead to numerous patch files.
    -   **Less of a "Package"**: It focuses purely on customization, not on packaging and distribution like Helm.

---

## 🚀 The Step-by-Step Journey

This section details the evolution of the project.

### Part 1: Initial Setup with Helm

The project started with a Helm-based structure, generated by the `setup_gitops_poc.sh` script.

-   **Structure**: Created `/components` for micro-charts and `/apps` for umbrella charts.
-   **Configuration**: Manages environment-specific settings (`dev`, `pre`) via different `values.yaml` files.

### Part 2: The Kustomize Alternative

To compare methodologies, the `world-app` was rebuilt as `kustomiworld` using Kustomize.

-   **Structure**: A new `/kustomize` directory was created, containing `components` (bases) and `apps` (bases + overlays).
-   **Process**: This involved converting Helm templates to plain YAML for the bases and creating overlays to manage environment-specific configurations.

### Part 3: Setting Up for Advanced Deployments

To enable progressive delivery, Argo Rollouts was installed and configured in the cluster.

#### 3.1. Install Argo Rollouts Controller

This is a one-time setup action in your Kubernetes cluster.

```bash
# English command block
# Step 1: Create the namespace
kubectl create namespace argo-rollouts

# Step 2: Install the controller components
kubectl apply -n argo-rollouts -f [https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml](https://github.com/argoproj/argo-rollouts/releases/latest/download/install.yaml)
3.2. Install the kubectl Plugin (Optional but Recommended)
This plugin provides a powerful CLI to manage and visualize rollouts.

Bash

# English command block
# For macOS (with Homebrew)
brew install argoproj/tap/kubectl-argo-rollouts

# For Linux
curl -LO [https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64](https://github.com/argoproj/argo-rollouts/releases/latest/download/kubectl-argo-rollouts-linux-amd64)
chmod +x ./kubectl-argo-rollouts-linux-amd64
sudo mv ./kubectl-argo-rollouts-linux-amd64 /usr/local/bin/kubectl-argo-rollouts
3.3. Enable and Access the Dashboard
The default installation does not enable the UI dashboard. The following steps were taken to enable and access it.

Bash

# English command block
# Step 1: Patch the deployment to add the --ui flag, enabling the dashboard
kubectl patch deployment argo-rollouts -n argo-rollouts --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args", "value": ["--ui"]}]'

# Step 2: Wait for the pod to restart with the new configuration
kubectl get pods -n argo-rollouts -w

# Step 3: Access the dashboard via port-forwarding
kubectl argo rollouts dashboard
Then, open http://localhost:3100 in your browser.

Part 4: Implementing a Canary Release
The helloworld component was converted from a standard Deployment to an Argo Rollout object.

File Change: deployment.yaml was replaced with rollout.yaml.
Strategy: A simple Canary strategy was defined to shift 20% of traffic to the new version and then pause for manual promotion.
<!-- end list -->

YAML

# kustomize/components/helloworld/base/rollout.yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: helloworld
spec:
  # ... (rest of the pod configuration)
  strategy:
    canary:
      steps:
      - setWeight: 20
      - pause: {}
The kustomization.yaml file for the component was updated to reference the new rollout.yaml file.

⚡ How to Deploy
All applications are defined in /argo-cd/apps. To deploy an application, apply its manifest to the cluster where Argo CD is running. Argo CD will handle the rest.

Bash

# English command block
# Deploy the Helm-based 'world' app to the 'dev' environment
kubectl apply -f argo-cd/apps/app-world-dev.yaml

# Deploy the Kustomize-based 'kustomiworld' app to the 'dev' environment
kubectl apply -f argo-cd/apps/app-kustomiworld-dev.yaml

# Deploy the Kustomize-based 'kustomiworld' app to the 'pre' environment
kubectl apply -f argo-cd/apps/app-kustomiworld-pre.yaml
The next step in this PoC is to adjust the Kubernetes Service objects to allow the Argo Rollouts controller to manage traffic shifting during a canary release.