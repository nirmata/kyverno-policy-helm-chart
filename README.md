# Kyverno policy Helm chart (`custom-kyverno-cpol`)

Helm chart that installs a **single catalog** of Kyverno policies (pod security, workload defaults, deprecations, image registries, and related checks). Policy sources live in **`files/policies/`** (40 YAML files in this version).

**Chart name:** `custom-kyverno-cpol` (see `Chart.yaml`).

## Prerequisites

- Kubernetes cluster with **Kyverno** already installed, including CRDs for the policy kinds you use (**`ClusterPolicy`**, and **`ValidatingPolicy`** from `policies.kyverno.io` if those resources are in the catalog).
- **Helm 3**.

## What this chart does

| Mechanism | Details |
|-----------|---------|
| **Bulk policies** | Renders every `files/policies/*.yaml` except `restrict-image-registries.yaml`, which is handled by a dedicated template. |
| **`validationFailureAction`** | For manifests that contain a top-level `validationFailureAction:` line (typically **`ClusterPolicy`**), that line is **replaced** with the value from `values.yaml` / `--set`. |
| **`ValidatingPolicy`** | Uses **`spec.validationActions`** in the YAML files. This chart **does not** rewrite those; edit the files or use Kyverno-native mechanisms if you need different actions. |
| **Image registries** | `restrict-image-registries` is built from `files/policies/restrict-image-registries.yaml` with placeholders **`__GLOBAL_PATTERN__`**, **`__CONTAINERS_PATTERN__`**, etc., filled from `values.yaml`. |

## Kyverno admission webhook timeout (before or during large installs)

Installing many policies at once can exceed the default **10s** API-server timeout on Kyverno’s **policy** validating webhook (`kyverno-policy-validating-webhook-cfg`), which surfaces as timeouts or `context deadline exceeded` during `helm install`.

**Recommended (persistent):** On the **Kyverno** release (not this chart), set the admission controller flag **`--webhookTimeout=30`**, for example:

```yaml
# In the Kyverno / N4K values.yaml used to install Kyverno
admissionController:
  container:
    extraArgs:
      webhookTimeout: "30"
```

Then upgrade Kyverno and confirm:

```bash
kubectl get validatingwebhookconfiguration kyverno-policy-validating-webhook-cfg \
  -o jsonpath='{.webhooks[0].timeoutSeconds}{"\n"}'
```

**Note:** A **`config.webhooks.timeoutSeconds`** (or similar) value on some Kyverno charts is **not** the same as `timeoutSeconds` on the `ValidatingWebhookConfiguration`; it does not replace `--webhookTimeout`.

**Emergency-only:** `kubectl patch` on the webhook object can help briefly, but Kyverno may **reconcile** webhooks and revert the value unless `webhookTimeout` is set on the controller.

## Installation

### From the chart directory (local)

From the repository root (the directory that contains `Chart.yaml`):

```bash
helm install kyverno-policies . --namespace kyverno --create-namespace --timeout=10m --wait
```

### From a Helm repository

Adjust the repo URL and chart reference to match your publishing setup, for example:

```bash
helm repo add kyverno-policies https://nirmata.github.io/kyverno-policy-helm-chart
helm repo update
helm install kyverno-policies kyverno-policies/custom-kyverno-cpol \
  --namespace kyverno --create-namespace --timeout=10m --wait
```

### Audit vs enforce (`ClusterPolicy` only)

Default is **Audit** (see `values.yaml`). To **block** violating resources for policies that use `validationFailureAction`:

```bash
helm install kyverno-policies . --namespace kyverno \
  --set validationFailureAction=Enforce --timeout=10m --wait
```

Upgrades:

```bash
helm upgrade kyverno-policies . --namespace kyverno --timeout=10m --wait
```

## Configuration (`values.yaml`)

| Parameter | Description | Default |
|-----------|-------------|---------|
| `validationFailureAction` | `Audit` or `Enforce` for lines named `validationFailureAction` in rendered policy YAML (primarily **`ClusterPolicy`**) | `Audit` |
| `imageRegistries.global` | Registry allow patterns as a **YAML list** (joined with ` \| ` for Kyverno) | See `values.yaml` |
| `imageRegistries.containers` | Override list for containers | `[]` (inherits global) |
| `imageRegistries.initContainers` | Override list for init containers | `[]` |
| `imageRegistries.ephemeralContainers` | Override list for ephemeral containers | `[]` |
| `allowedRegistries` | Legacy single string with ` \| ` separators | Deprecated; prefer `imageRegistries.global` |

## Policy catalog

All policies are under **`files/policies/`** (one primary Kubernetes resource per file; unique `metadata.name` per policy).

This revision includes a mix of **`ClusterPolicy`** and **`ValidatingPolicy`** resources. To extend the catalog, add or remove `.yaml` files there. No template change is required unless you need new Helm logic (as for `restrict-image-registries`).

**Deprecated APIs policy:** `check-deprecated-apis` matches APIs that were removed or migrated across Kubernetes versions. **`PodSecurityPolicy`** is **not** listed under `match.kinds` because the API is removed in Kubernetes **1.25+**; including it caused admission warnings (`unable to convert GVK to GVR … resource not found`) on modern clusters.

## Image registry policy

Configure **`imageRegistries`** with **one pattern per list element**. Do not embed ` \| ` inside a single string.

**Good:**

```yaml
imageRegistries:
  global:
    - "registry.company.com:5000/*"
    - "registry.company.com:6000/*"
```

**Bad:**

```yaml
imageRegistries:
  global:
    - "registry.company.com:5000/* | registry.company.com:6000/*"
```

## Adding policies

1. Add a new `.yaml` under **`files/policies/`** with one Kyverno policy resource.
2. Ensure **`metadata.name`** is unique in the catalog.
3. For **`ClusterPolicy`**, you may include `spec.validationFailureAction`; the chart overwrites matching `validationFailureAction:` lines from `values.yaml`.
4. For **`ValidatingPolicy`**, set **`spec.validationActions`** in the file; the chart does not change it.

## Troubleshooting

**`Unknown image registry` or wrong allow list**  
Use YAML lists for registries, not one string with ` \| `.

**`context deadline exceeded` / webhook timeouts during `helm install`**  
Raise Kyverno **`--webhookTimeout`** (see above). Use a generous **`--timeout`** and **`--wait`** only after the admission webhook can sustain the apply burst.

**Client warnings during install (non-fatal if release is `deployed`)**  
Helm may print Kubernetes warnings such as:

- **`kyverno-reports-controller` … `Node` … get/list/watch** — the reports controller may need RBAC to **`nodes`** for some policies or reports; extend the Kyverno chart’s reports-controller **`ClusterRole`** if your vendor docs require it.
- **`PodSecurityPolicy` / GVR** — should not appear if the chart’s `check-deprecated-apis` policy omits PSP in `match.kinds` (current behavior). Upgrade this chart or re-apply policies if you still see it.

**Policies not evaluating**  
Confirm Kyverno pods are healthy and policies are not excluded by Kyverno **`ConfigMap`** `resourceFilters`.

**`no matches for kind "GeneratingPolicy"`**  
This catalog does not ship `GeneratingPolicy`. If the error appears, your client or chart version may be out of sync with the cluster CRDs; align Kyverno / CRD versions with the policy kinds you install.

## Contributing

Pull requests are welcome.

## License

Apache License 2.0 (see the repository’s license terms if a `LICENSE` file is present).
