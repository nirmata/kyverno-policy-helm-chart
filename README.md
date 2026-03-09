# Kyverno Policy Helm Chart

A Helm chart that deploys Kyverno policies for security best practices and workload standards in Kubernetes. You can install **common policies only**, **common + production** policies, or **common + non-production** policies.

## Prerequisites

- Kubernetes cluster with **Kyverno** already installed
- **Helm 3**

## Installation

Before installing the chart, increase Kyverno webhook timeouts (default 10s can be too low for many policies):

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

For **common only** or **common + non-production**, add the same `--set` flags as in the local examples (e.g. `--set installProfilePolicies=false` or `--set policyProfile=non-production`).

### From the chart in this repo (local path)

Run from the repository root. Choose one of the three policy sets below.

| What you want | Policies installed |
|---------------|---------------------|
| **Common only** | Baseline security only (`files/common/`) |
| **Common + production** | Common + production-only policies (stricter, full compliance) |
| **Common + non-production** | Common + non-production-only policies (lighter, dev/test) |

#### 1. Common policies only

```bash
helm install kyverno-policies . --namespace kyverno --set installProfilePolicies=false --timeout=300s
```

#### 2. Common + production policies (default)

```bash
helm install kyverno-policies . --namespace kyverno --timeout=300s
```

Or explicitly:

```bash
helm install kyverno-policies . --namespace kyverno --set installProfilePolicies=true --set policyProfile=production --timeout=300s
```

#### 3. Common + non-production policies

```bash
helm install kyverno-policies . --namespace kyverno --set policyProfile=non-production --timeout=300s
```

#### Switching after install

Use `helm upgrade` with the same flags as for a fresh install:

```bash
helm upgrade kyverno-policies . --namespace kyverno --set installProfilePolicies=false   # common only
helm upgrade kyverno-policies . --namespace kyverno --set policyProfile=production        # common + production
helm upgrade kyverno-policies . --namespace kyverno --set policyProfile=non-production     # common + non-production
```

### Audit vs Enforce

Policies default to **Audit** (report only). The `validationFailureAction` value in `values.yaml` (or via `--set`) applies to **all** policies. To **Enforce** (block violating resources):

```bash
helm install kyverno-policies . --namespace kyverno --set validationFailureAction=Enforce --timeout=300s
```

You can also set `validationFailureAction: Enforce` in `values.yaml` before install or upgrade.

---

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `installProfilePolicies` | Install profile (production/non-production) policies in addition to common | `true` |
| `policyProfile` | `production` or `non-production` (used when `installProfilePolicies` is true) | `production` |
| `validationFailureAction` | `Audit` (report) or `Enforce` (block). Applied to every policy. | `Audit` |
| `imageRegistries.global` | Allowed image registries for all container types (YAML list) | See `values.yaml` |
| `imageRegistries.containers` | Override for containers | `[]` (uses global) |
| `imageRegistries.initContainers` | Override for initContainers | `[]` (uses global) |
| `imageRegistries.ephemeralContainers` | Override for ephemeralContainers | `[]` (uses global) |
| `allowedRegistries` | Legacy single string (deprecated) | See `values.yaml` |

**How policy selection works:** Common policies (`files/common/`) are always installed. When `installProfilePolicies` is `true`, the chart also installs policies from either `files/production/` or `files/non-production/` depending on `policyProfile`.

---

## Image registry configuration

The **restrict-image-registries** policy (common) limits which image registries can be used. Configure it via `values.yaml`.

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

You can override per container type with `imageRegistries.containers`, `imageRegistries.initContainers`, and `imageRegistries.ephemeralContainers`. Legacy `allowedRegistries` (single string with ` | `) is supported but deprecated.

---

## Adding more Kyverno policies

Add a new **`.yaml` file** in the appropriate folder; no template or values changes are required for profile policies.

| Folder | When used |
|--------|-----------|
| `files/common/` | Always (shared baseline) |
| `files/production/` | When `installProfilePolicies: true` and `policyProfile: production` |
| `files/non-production/` | When `installProfilePolicies: true` and `policyProfile: non-production` |

**Requirements:**

- Each file must be a single Kyverno **ClusterPolicy**.
- Include `spec.validationFailureAction` in the policy; the chart overwrites it with the value from `values.yaml`.
- `metadata.name` must be unique across all policies.

**Common policies:** Files in `files/common/` also need a corresponding template in `templates/` that loads the file and patches `validationFailureAction` (see existing `templates/common-*.yaml`). Profile policies in `files/production/` and `files/non-production/` are included automatically via glob.

---

## Troubleshooting

**"Unknown image registry" or registries list looks wrong**  
Use a YAML list for registries (one entry per line), not a single string containing ` | `.

**Policies not applied**  
Confirm Kyverno is running and the release is in the expected namespace (e.g. `kyverno`). Check `policyProfile` and `installProfilePolicies` match the desired set (common only, production, or non-production).

---

## Contributing

Contributions are welcome. Please open a Pull Request.

## License

Apache License 2.0. See the LICENSE file for details.
