# Introduction 
Helm chart template to deploy cronJobs for FLOW

# Configuration
The chart can be configured using the following values in the values.yaml file:

- `projectName`: Project name. It will be used as prefix for the cronjob name. (Mandatory separated by hyphens)
- `image`: Image name for the cronjob to use.
- `version`: Image version.
- `imagePullSecrets`: Secret used to pull the image from Azure Container Registry.
- `jobName`: Job name.
- `schedule`: Schedule in "* * * * *" format.
- `suspend`: Boolean to indicate wether the cronjob should be suspended or not.
- `command`: Job command to execute.
- `args`: Job arguments to add.
- `envFrom`: If enabled, either configMapRef or secretRef or both should be defined. The configmap created by `configuration` is not required to be added here.  configMapRef or secretRef should exist in same namespace.
- `tolerations`: If enabled, both key and value must be defined.
- `affinity`: If enabled, both key and value must be defined.
- `resources`: If enabled, both requests and limits must be defined.
- `configuration`: If defined, it adds environment variables to the cronjob.
- `persistence`: If enabled, a mountPath volume will be generated and associated to the Azure Blob Storage set in its configuration.
- `customScriptSupport`: If enabled, support for adding a custom script to the cronjob will be added. The script is stored in the / path with the fileName given.

```yaml
projectName: msw-egm-backend-ror
image: busybox
version: latest

imagePullSecrets: amsdvpallacratlantis-auth

jobName: "echo-hello"
schedule: "*/5 * * * *"
suspend: false

command: '["echo", "Hello"]'
args: '' 

envFrom:
  enabled: false

tolerations:
  enabled: true
  key: enterprise
  value: egm

affinity:
  enabled: true
  key: agentpool
  value: egmcronjobs

resources:
  enabled: true
  requests:
    cpu: 150m
    memory: 256Mi
  limits:
    cpu: 300m
    memory: 512Mi

secrets:
  CONNECTION_STRING: AZURE_KEY_VAULT_KEY

configuration:
  MONGO_URL: dummy
  MONGO_PORT: dummy

persistence:
  enabled: false 
  storages:
    - name: "" # storage account name
      secretName: "" # Kubernetes secret name where the credentials to connect the storage account are mapped
      containers:
        storageClassName: "" # optional storageClass to be used
        items:
          - name: "" # name of the container
            mountPath: "" # final mount path in the container
      fileShares:
        storageClassName: ""
        items:
          - name: "" # name of the file share
            mountPath: ""

customScriptSupport:
  enabled: false
  fileName: ""
  script: |
    #!/bin/bash
    echo "Hello world."
```

# Deploy
To generate a new version of the chart, once our changes have been pushed, we will run the deploy pipeline that will automatically upload the version, tag it and push to the ACR 

When running the pipeline, we will be asked for the type of upload we want to perform, in which the [semantic versioning](https://semver.org/) is followed

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [5.0.1] - 2024-08-29
### Fixed
- Force quotes in container name and fileshare name in PersistentVolume to avoid errors.


## [5.0.0] - 2024-08-29
### Feature
- Added initContainer and app sections.

## [4.0.0] - 2024-07-24
### Changed
- Update PV, PVC and cronjob templates to be able to work with multiples containers and file shares from different storage accounts.
- Include new external secrets implementation. Used under the `.secrets` seccion in values file and creates a single external secret file to map all the keys defined in the `.secret` section 

## [3.0.0] - 2024-04-17
### Changed
- Remove enterprise variable and use projectName instead.

## [2.1.0] - 2024-02-14
### Added
- Added support for envFrom configuration, either configMapRef or secretRef or both.

## [2.0.0] - 2024-02-14
### Changed
- Refactor cronjobs manifest to be a template of general use. Previously for flow only. Non backward compatible change.
