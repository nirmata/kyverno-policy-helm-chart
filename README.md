# Kyverno Policy Helm Chart

A Helm chart that deploys Kyverno policies for security best practices and workload standards in Kubernetes. You can install **common policies only**, or **common + production** policies, or **common + non-production** policies.

## Prerequisites

- Kubernetes cluster with **Kyverno** already installed
- **Helm 3**

## Installation

Increase the validatingwebhook and mutatingwebhook values from the default 10sec to 30seconds.
```bash
kubectl patch validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg --type='json' -p='[{"op": "replace", "path": "/webhooks/0/timeoutSeconds", "value": 30}]'

kubectl patch mutatingwebhookconfiguration kyverno-policy-mutating-webhook-cfg --type='json' -p='[{"op": "replace", "path": "/webhooks/0/timeoutSeconds", "value": 30}]'
```

### From a Helm repository

```bash
helm repo add my-kyverno-cpol https://nirmata.github.io/kyverno-policy-helm-chart
helm repo update
helm install kyverno-policies my-kyverno-cpol/custom-kyverno-cpol --namespace kyverno --timeout=300s
```

For **common only** or **common + non-production**, add the same `--set` flags as in the local path examples below (e.g. `--set installProfilePolicies=false` or `--set policyProfile=non-production`).

### From the chart in this repo (local path)

Run from the repository root (this directory is the chart). Choose one of the three installation options below.

---

### How to install: choose one of three policy sets

You can install one of three combinations. Use the command that matches what you want.

| What you want | Policies installed | Approx. count |
|---------------|--------------------|----------------|
| **Common only** | Baseline security only (`files/common/`) | 9 |
| **Common + production** | Common + production-only policies (stricter, full compliance) | 25 |
| **Common + non-production** | Common + non-production-only policies (lighter, dev/test) | 10 |

---

#### 1. Common policies only

Installs only the shared baseline policies (e.g. image registry, capabilities, default namespace). No production or non-production profile policies.

```bash
helm install kyverno-policies . --namespace kyverno --set installProfilePolicies=false --timeout=300s
```

**Example:** After install, `kubectl get cpol` shows 9 policies (e.g. `disallow-capabilities`, `disallow-default-namespace`, `restrict-image-registries`, …).

---

#### 2. Common + production policies

Installs common policies plus all production-only policies (stricter set for full compliance). This is the **default** if you do not set `policyProfile`.

```bash
helm install kyverno-policies . --namespace kyverno --timeout=300s
```

Or explicitly:

```bash
helm install kyverno-policies . --namespace kyverno --set installProfilePolicies=true --set policyProfile=production --timeout=300s
```

**Example:** After install, `kubectl get cpol` shows 25 policies (9 common + 16 production, e.g. `require-requests-limits`, `restrict-nodeport`, `disallow-host-ports`, …).

---

#### 3. Common + non-production policies

Installs common policies plus non-production-only policies (lighter set for dev/test).

```bash
helm install kyverno-policies . --namespace kyverno --set policyProfile=non-production --timeout=300s
```

**Example:** After install, `kubectl get cpol` shows 10 policies (9 common + 2 non-production: `require-pod-probes`, `require-requests-limits`).

---

#### Switching after install

To change what is installed (e.g. from common+production to common only, or to non-production), use `helm upgrade` with the same flags you would use for a fresh install:

```bash
# Switch to common only
helm upgrade kyverno-policies . --namespace kyverno --set installProfilePolicies=false

# Switch to common + production
helm upgrade kyverno-policies . --namespace kyverno --set installProfilePolicies=true --set policyProfile=production

# Switch to common + non-production
helm upgrade kyverno-policies . --namespace kyverno --set policyProfile=non-production
```

### Audit vs Enforce

Policies default to **Audit** (report only). To **Enforce** (block violating resources):

```bash
helm install kyverno-policies . --namespace kyverno --set validationFailureAction=Enforce --timeout=300s
```

---

## How policy installation works

- **Common** policies (`files/common/`) are always installed. They are the shared baseline (e.g. image registry, capabilities, default namespace).
- **Profile** policies are optional. When **`installProfilePolicies`** is `true` (default), the chart also installs either production or non-production policies, depending on **`policyProfile`**.

| `installProfilePolicies` | `policyProfile`   | What gets installed                                      |
|--------------------------|-------------------|----------------------------------------------------------|
| `false`                  | (ignored)         | **Common** policies only                                 |
| `true`                   | `production`      | **Common** + **Production-only** policies                 |
| `true`                   | `non-production`  | **Common** + **Non-production-only** policies             |

Production-only and non-production-only policies live in `files/production/` and `files/non-production/`; only the folder matching `policyProfile` is used when profile policies are installed.

---

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installProfilePolicies` | Install profile (production/non-production) policies in addition to common | `true` |
| `policyProfile` | `production` or `non-production` (used when `installProfilePolicies` is true) | `production` |
| `validationFailureAction` | `Audit` (report) or `Enforce` (block) | `Audit` |
| `imageRegistries.global` | Allowed image registries for all container types (YAML list) | See `values.yaml` |
| `imageRegistries.containers` | Override for containers | `[]` (uses global) |
| `imageRegistries.initContainers` | Override for initContainers | `[]` (uses global) |
| `imageRegistries.ephemeralContainers` | Override for ephemeralContainers | `[]` (uses global) |
| `allowedRegistries` | Legacy single string (deprecated) | See `values.yaml` |

Configure via `values.yaml` or `--set`:

```yaml
# values.yaml
policyProfile: non-production
validationFailureAction: Enforce
imageRegistries:
  global:
    - "docker.io/*"
    - "gcr.io/*"
```

---

## Adding more Kyverno policies

Policies are plain YAML files in the chart. Add a new **`.yaml` file** in the right folder; no template or values changes are required.

### Policy folders

| Folder | When used | Use for |
|--------|-----------|--------|
| `files/common/` | Always | Policies shared by all installs (common-only, production, non-production) |
| `files/production/` | When `installProfilePolicies: true` and `policyProfile: production` | Production-only policies |
| `files/non-production/` | When `installProfilePolicies: true` and `policyProfile: non-production` | Non-production-only policies |

### Add a production-only policy

1. Create a new file: `files/production/<your-policy-name>.yaml`
2. Put a valid Kyverno **ClusterPolicy** in it. Include `spec.validationFailureAction` (the chart overwrites it from `values.yaml`):

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: my-production-policy
spec:
  validationFailureAction: Audit
  rules:
    # your rules
```

3. Install or upgrade with production profile; the new policy is included automatically.

### Add a non-production-only policy

1. Create: `files/non-production/<your-policy-name>.yaml`
2. Same ClusterPolicy format as above.
3. Install or upgrade with `policyProfile: non-production`.

### Add a policy for both environments (common)

1. Create: `files/common/<your-policy-name>.yaml`
2. Same ClusterPolicy format.
3. It will be installed for both production and non-production.

**Requirements:** Each file must be a single ClusterPolicy. `metadata.name` must be unique across all policies. The chart will replace `validationFailureAction` with the value from `values.yaml` for every policy.

---

## Image registry configuration

The **restrict-image-registries** policy (in common) limits which image registries can be used. Configure it via `values.yaml`.

- Use **YAML lists** for registries; the chart joins them with ` | ` for Kyverno.
- Do **not** put ` | ` inside a single string.

**Correct:**

```yaml
imageRegistries:
  global:
    - "registry.company.com:5000/*"
    - "registry.company.com:6000/*"
```

**Incorrect:**

```yaml
imageRegistries:
  global:
    - "registry.company.com:5000/* | registry.company.com:6000/*"  # wrong
```

You can override per container type:

```yaml
imageRegistries:
  global:
    - "docker.io/*"
  containers:
    - "docker.io/*"
    - "gcr.io/*"
  initContainers:
    - "docker.io/*"
    - "quay.io/*"
```

Legacy `allowedRegistries` (single string with ` | `) is still supported but deprecated.

---

## Troubleshooting

**Error about “Unknown image registry” or allowed registries list looks wrong**  
Use a YAML list for registries (one entry per line), not a single string containing ` | `.

**Policies not applied**  
Confirm Kyverno is running in the cluster and the release is installed in the expected namespace (e.g. `kyverno`). Check `policyProfile` matches the environment you want (production vs non-production).

---

## Contributing

Contributions are welcome. Please open a Pull Request.

## License

Apache License 2.0. See the LICENSE file for details.
