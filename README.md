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
   - Restrict image registries

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
my-kyverno-cpol/custom-kyverno-cpol     0.1.1           1.0             Kyverno policies for pod security and workload ...
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

### Example Configuration

```yaml
validationFailureAction: Enforce
```

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
19. `restrict_image_registries.yaml`: Restricts image registries
20. `disallow-host-namespaces.yaml`: Prevents host namespace usage
21. `disallow-proc-mount.yaml`: Prevents proc mount usage
22. `disallow-selinux.yaml`: Prevents SELinux usage
23. `require_drop_all.yaml`: Enforces dropping all capabilities
24. `restrict-sysctls.yaml`: Restricts sysctl usage

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.
5. Install in Enforce mode (example):
`helm install my-policies my-kyverno-cpol/custom-kyverno-cpol --set validationFailureAction=Enforce`
