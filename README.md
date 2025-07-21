# Custom-Kyverno-cpol-helm-chart

# Kyverno Policy Helm Chart

This repository contains a Helm chart for deploying Kyverno policies that enforce security best practices and workload standards in Kubernetes clusters.

## Overview

The Helm chart provides a collection of Kyverno policies that help enforce security best practices, workload standards, and operational requirements in Kubernetes clusters. These policies are designed to be easily deployable and configurable through Helm.

## Features

The chart includes policies that enforce:

- Pod Security Standards
- Workload Best Practices
- Network Security
- Resource Management
- Container Security
- Namespace Management

### Key Policy Categories

1. **Container Security**
   - Disallow privileged containers
   - Prevent privilege escalation
   - Enforce non-root user execution
   - Restrict container capabilities
   - Enforce AppArmor profiles
   - Restrict seccomp profiles

2. **Resource Management**
   - Require resource requests and limits
   - Enforce liveness and readiness probes
   - Restrict control plane scheduling

3. **Network Security**
   - Restrict NodePort usage
   - Disallow host ports
   - Restrict external IPs
   - Validate ingress host configurations

4. **Storage Security**
   - Disallow host path volumes
   - Restrict volume types
   - Prevent CRI socket mounts

5. **Namespace Management**
   - Disallow default namespace usage
   - Restrict custom snippets

6. **Image Security**
   - Restrict image registries (configurable per container type)

## Installation

### Prerequisites

- Kubernetes cluster
- Helm
- Kyverno installed in the cluster

### Add the Helm Repository

```bash
helm repo add my-kyverno-cpol https://nirmata.github.io/kyverno-policy-helm-chart
helm repo update
```

### Fetch the Charts
`helm search repo my-kyverno-cpol`
Example:
```bash
helm search repo my-kyverno-cpol
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
my-kyverno-cpol/custom-kyverno-cpol     0.2.0           1.0             Kyverno policies for pod security and workload ...
```

### Install the Chart

#### In Audit Mode (Default)
```bash
helm install kyverno-policies nirmata/custom-kyverno-cpol \
  --namespace kyverno \
  --create-namespace
```

#### In Enforce Mode (During the installation using a flag)
```bash
helm install kyverno-policies nirmata/custom-kyverno-cpol --namespace kyverno --create-namespace --set validationFailureAction=Enforce
```

## Configuration

The following table lists the configurable parameters of the chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `validationFailureAction` | Action to take when policy validation fails (`Audit` or `Enforce`) | `Audit` |
| `imageRegistries.global` | Global registry pattern for all container types | `"eu.foo.io/* \| bar.io/*"` |
| `imageRegistries.containers` | Registry pattern for containers (overrides global) | `""` (uses global) |
| `imageRegistries.initContainers` | Registry pattern for initContainers (overrides global) | `""` (uses global) |
| `imageRegistries.ephemeralContainers` | Registry pattern for ephemeralContainers (overrides global) | `""` (uses global) |
| `allowedRegistries` | Legacy setting for backward compatibility (deprecated) | `"eu.foo.io/* \| bar.io/*"` |

### Image Registry Configuration Examples

**Important**: The `imageRegistries` configuration expects YAML lists that will be automatically joined with ` | ` for Kyverno pattern matching. Do not include the ` | ` separator in your configuration.

#### 1. Global Registry Pattern (All Container Types)
```yaml
imageRegistries:
  global:
    - "tcr.paas.local:50??/*"
    - "tcr.paas.local:60??/*"
    - "tcr.paas.local:70??/*"
```
Or via Helm CLI:
```bash
helm install kyverno-policies nirmata/custom-kyverno-cpol \
  --namespace kyverno \
  --create-namespace \
  --set imageRegistries.global[0]="tcr.paas.local:50??/*" \
  --set imageRegistries.global[1]="tcr.paas.local:60??/*" \
  --set imageRegistries.global[2]="tcr.paas.local:70??/*"
```

#### 2. Individual Container Type Configuration
```yaml
imageRegistries:
  global:
    - "docker.io/*"
  containers:
    - "docker.io/*"
    - "gcr.io/*"
  initContainers:
    - "docker.io/*"
    - "gcr.io/*"
    - "quay.io/*"
  ephemeralContainers:
    - "docker.io/*"
    - "quay.io/*"
```

#### 3. Mixed Configuration
```yaml
imageRegistries:
  global:
    - "docker.io/*"
    - "gcr.io/*"
  containers:
    - "docker.io/*"
  initContainers: []
  ephemeralContainers:
    - "quay.io/*"
```

#### 4. Using Legacy allowedRegistries (Deprecated but Supported)
```yaml
allowedRegistries: "docker.io/* | gcr.io/* | eu.gcr.io/*"
```

### Common Configuration Patterns

#### For Enterprise Registries with Port Numbers
```yaml
imageRegistries:
  global:
    - "registry.company.com:5000/*"
    - "registry.company.com:6000/*"
    - "registry.company.com:7000/*"
```

#### For Multiple Registry Types
```yaml
imageRegistries:
  global:
    - "docker.io/*"
    - "gcr.io/*"
    - "quay.io/*"
    - "registry.company.com/*"
```

#### For Specific Container Types Only
```yaml
imageRegistries:
  containers:
    - "docker.io/*"
    - "gcr.io/*"
  initContainers:
    - "docker.io/*"
  ephemeralContainers: []
```

### Troubleshooting

**Error**: `Unknown image registry. Allowed registries: [tcr.paas.local:50??/* | tcr.paas.local:60??/* |tcr.paas.local:70??/*]`

**Cause**: You're passing a single string with ` | ` separators instead of a YAML list.

**Incorrect**:
```yaml
imageRegistries:
  global:
    - "tcr.paas.local:50??/* | tcr.paas.local:60??/* | tcr.paas.local:70??/*"
```

**Correct**:
```yaml
imageRegistries:
  global:
    - "tcr.paas.local:50??/*"
    - "tcr.paas.local:60??/*"
    - "tcr.paas.local:70??/*"
```

## Testing

### Automated Testing Script

A comprehensive testing script is provided to validate the image registry configuration functionality:

```bash
# Make the script executable
chmod +x test-image-registry-config.sh

# Run the automated tests
./test-image-registry-config.sh
```

The testing script validates:
- Default configuration behavior
- Legacy `allowedRegistries` compatibility
- Global `imageRegistries.global` configuration
- Per-container-type configurations
- Mixed configurations
- Enforce mode functionality

### Manual Testing

You can also test configurations manually:

#### 1. Test Chart Rendering
```bash
# Test with default values
helm template test charts/dynamic-policies

# Test with custom image registries (using YAML lists)
helm template test charts/dynamic-policies \
  --set imageRegistries.global[0]="docker.io/*" \
  --set imageRegistries.global[1]="gcr.io/*" \
  --set imageRegistries.initContainers[0]="docker.io/*" \
  --set imageRegistries.initContainers[1]="gcr.io/*" \
  --set imageRegistries.initContainers[2]="quay.io/*"

# Test with legacy setting
helm template test charts/dynamic-policies \
  --set allowedRegistries="docker.io/* | gcr.io/*"
```

#### 2. Test Chart Linting
```bash
helm lint charts/dynamic-policies --values charts/dynamic-policies/values.yaml
```

#### 3. Test Installation (Dry Run)
```bash
helm install kyverno-policies charts/dynamic-policies \
  --namespace kyverno \
  --create-namespace \
  --dry-run \
  --set imageRegistries.global[0]="docker.io/*" \
  --set imageRegistries.global[1]="gcr.io/*"
```

## Recent Changes

### Version 0.2.1 - Fixed Image Registry Configuration

**Bug Fixes:**
- **Fixed YAML List Processing**: The `restrict_image_registries` policy now properly handles YAML lists for `imageRegistries` configuration
- **Corrected Template Logic**: Added proper `join` function to convert YAML lists to Kyverno pattern format
- **Improved Error Messages**: Better error messages that show the actual allowed registries

**Configuration Fix:**
- **YAML Lists Required**: `imageRegistries.global`, `imageRegistries.containers`, etc. now expect YAML lists
- **Automatic Joining**: Lists are automatically joined with ` | ` for Kyverno pattern matching
- **Clear Documentation**: Added troubleshooting section and examples

**Example Fix:**
```yaml
# Before (Incorrect - caused validation errors)
imageRegistries:
  global:
    - "tcr.paas.local:50??/* | tcr.paas.local:60??/* | tcr.paas.local:70??/*"

# After (Correct - works properly)
imageRegistries:
  global:
    - "tcr.paas.local:50??/*"
    - "tcr.paas.local:60??/*"
    - "tcr.paas.local:70??/*"
```

### Version 0.2.0 - Enhanced Image Registry Configuration

**New Features:**
- **Configurable Image Registries**: The `restrict_image_registries` policy now supports flexible configuration for different container types
- **Per-Container-Type Control**: Configure different registry patterns for `containers`, `initContainers`, and `ephemeralContainers`
- **Backward Compatibility**: Legacy `allowedRegistries` setting is still supported
- **Enhanced Templating**: Improved Helm template processing for dynamic policy configuration

**Configuration Options:**
- `imageRegistries.global`: Set registry pattern for all container types
- `imageRegistries.containers`: Override for regular containers
- `imageRegistries.initContainers`: Override for init containers
- `imageRegistries.ephemeralContainers`: Override for ephemeral containers
- `allowedRegistries`: Legacy setting (deprecated but supported)

**Testing:**
- Added comprehensive testing script (`test-image-registry-config.sh`)
- Automated validation of all configuration scenarios
- Manual testing instructions provided

## Policy Details

The chart includes the following policies:

1. `disallow-privileged-containers.yaml`: Prevents the creation of privileged containers
2. `disallow-privilege-escalation.yaml`: Prevents privilege escalation in containers
3. `require-run-as-non-root-user.yaml`: Enforces non-root user execution
4. `disallow-capabilities.yaml`: Restricts container capabilities
5. `restrict-apparmor-profiles.yaml`: Enforces AppArmor profile usage
6. `restrict-seccomp-strict.yaml`: Enforces strict seccomp profiles
7. `require_pod_requests_limits.yaml`: Enforces resource requests and limits
8. `require_probes.yaml`: Enforces liveness and readiness probes
9. `restrict-controlplane-scheduling.yaml`: Restricts control plane scheduling
10. `restrict_node_port.yaml`: Restricts NodePort usage
11. `disallow-host-ports.yaml`: Prevents host port usage
12. `restrict-service-external-ips.yaml`: Restricts external IP usage
13. `disallow_empty_ingress_host.yaml`: Prevents empty ingress hosts
14. `disallow-host-path.yaml`: Prevents host path volume usage
15. `restrict-volume-types.yaml`: Restricts volume types
16. `disallow_cri_sock_mount.yaml`: Prevents CRI socket mounts
17. `disallow-default-namespace.yaml`: Prevents default namespace usage
18. `disallow-custom-snippets.yaml`: Restricts custom snippets
19. `restrict_image_registries.yaml`: Restricts image registries (configurable per container type)
20. `disallow-host-namespaces.yaml`: Prevents host namespace usage
21. `disallow-proc-mount.yaml`: Prevents proc mount usage
22. `disallow-selinux.yaml`: Prevents SELinux usage
23. `require_drop_all.yaml`: Enforces dropping all capabilities
24. `restrict-sysctls.yaml`: Restricts sysctl usage

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.