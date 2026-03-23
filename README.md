# Kyverno Policy Helm Chart

A Helm chart that installs a **single catalog** of Kyverno policies for security and workload standards. All policy manifests live in **`files/policies/`**. Install mode is controlled by **`validationFailureAction`** in `values.yaml` (or `--set`): **Audit** (report only) or **Enforce** (block).

## Prerequisites

- Kubernetes cluster with **Kyverno** already installed (including CRDs for policy kinds you use, e.g. `policies.kyverno.io` **GeneratingPolicy** if you keep `add-ns-quota.yaml`).
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

### From the chart in this repo (local path)

Run from the repository root (this directory is the chart). This installs **all** policies under `files/policies/` (~40 resources, depending on chart version).

```bash
helm install kyverno-policies . --namespace kyverno --timeout=300s
```

#### Audit vs Enforce

Policies default to **Audit** (report only). Set **`validationFailureAction`** to **Enforce** to block violating resources:

```bash
helm install kyverno-policies . --namespace kyverno --set validationFailureAction=Enforce --timeout=300s
```

Or set `validationFailureAction: Enforce` in `values.yaml` before install or upgrade.

**Note:** The chart rewrites `spec.validationFailureAction` on **`ClusterPolicy`** resources from `values.yaml`. **`ValidatingPolicy`** resources use `spec.validationActions` in the YAML (not overridden by this chart). **`GeneratingPolicy`** (`add-ns-quota`) does not use `validationFailureAction`.

---

## Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `validationFailureAction` | `Audit` or `Enforce` for **ClusterPolicy** resources (from `values.yaml` / `--set`) | `Audit` |
| `imageRegistries.global` | Allowed image registries for all container types (YAML list) | See `values.yaml` |
| `imageRegistries.containers` | Override for containers | `[]` (uses global) |
| `imageRegistries.initContainers` | Override for initContainers | `[]` (uses global) |
| `imageRegistries.ephemeralContainers` | Override for ephemeralContainers | `[]` (uses global) |
| `allowedRegistries` | Legacy single string (deprecated) | See `values.yaml` |

**How installation works:** The chart renders every `*.yaml` file in **`files/policies/`**. **`restrict-image-registries.yaml`** is templated separately so registry allow-patterns from `values.yaml` replace placeholders. All other files get `validationFailureAction` patched from `values.yaml` when the field is present.

---

## Policy catalog

Everything is in **`files/policies/`**—there are no separate production vs non-production folders. Add or remove policies by editing that directory (one Kubernetes resource per file; unique `metadata.name`).

The catalog includes the shared baseline (pod security, image registry, quotas, deprecations, etc.), **`add-ns-quota`** (GeneratingPolicy), and additional checks that previously lived under a separate “non-production” folder (ephemeral storage checks, evicted pods, remediation policy), merged into this single set.

---

## Image registry configuration

The **restrict-image-registries** policy limits which image registries can be used. Configure it via `values.yaml`.

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

Add a new **`.yaml` file** under **`files/policies/`** with a single Kyverno resource. No template changes are required unless you need custom Helm logic.

**Requirements:**

- Each file is one policy object. Most are **`ClusterPolicy`** (`kyverno.io/v1`). **`add-ns-quota`** is a **`GeneratingPolicy`** (`policies.kyverno.io/v1`) per the [upstream gpol sample](https://github.com/nirmata/kyverno-policies/blob/main/sample/eko-test-data/gpol-policies/add-ns-quota.yaml); that API requires the matching CRDs.
- For **`ClusterPolicy`**, include `spec.validationFailureAction` in the file; the chart overwrites it from `values.yaml`.
- `metadata.name` must be unique across all policies.

---

## Troubleshooting

**"Unknown image registry" or allowed registries list looks wrong**  
Use a YAML list for registries (one entry per line), not a single string containing ` | `.

**Policies not applied**  
Confirm Kyverno is running and the release is in the expected namespace (e.g. `kyverno`).

**`no matches for kind "GeneratingPolicy"`**  
This chart version does not include `GeneratingPolicy`. If you still see this error, your checkout or chart package is stale. Pull latest `main` and retry.

**`validate-policy.kyverno.svc ... context deadline exceeded` during install**  
Kyverno admission webhook is timing out while many policies are created. Typical recovery flow:

```bash
# 1) Remove failed release
helm uninstall trinet-policies -n kyverno

# 2) Increase Kyverno admission webhook timeout to 30s
kubectl patch validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg --type='json' -p='[{"op":"replace","path":"/webhooks/0/timeoutSeconds","value":30}]'
kubectl patch mutatingwebhookconfiguration kyverno-policy-mutating-webhook-cfg --type='json' -p='[{"op":"replace","path":"/webhooks/0/timeoutSeconds","value":30}]'

# 3) Scale admission controller before reinstall
kubectl scale deploy kyverno-admission-controller -n kyverno --replicas=3

# 4) Reinstall
helm install trinet-policies . -n kyverno --timeout=10m --wait
```

---

## Contributing

Contributions are welcome. Please open a Pull Request.

## License

Apache License 2.0. See the LICENSE file for details.
