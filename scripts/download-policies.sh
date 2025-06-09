#!/bin/bash
set -euo pipefail

POLICY_DIR="charts/kyverno-policies/files"

mkdir -p "$POLICY_DIR"

echo "⬇️  Downloading Kyverno policies to $POLICY_DIR ..."

declare -A policies=(
  [disallow-capabilities]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-capabilities/disallow-capabilities.yaml"
  [disallow_cri_sock_mount]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/charts/best-practices-k8s/pols/disallow_cri_sock_mount.yaml"
  [disallow_default_namespace]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/best-practices-k8s/disallow-default-namespace/disallow-default-namespace.yaml"
  [disallow-custom-snippets]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/workload-security/disallow-custom-snippets.yaml"
  [disallow_empty_ingress_host]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/best-practices-k8s/disallow-empty-ingress-host/disallow-empty-ingress_host.yaml"
  [disallow-host-namespaces]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-host-namespaces/disallow-host-namespaces.yaml"
  [disallow-host-path]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-host-path/disallow-host-path.yaml"
  [disallow-host-ports]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-host-ports/disallow-host-ports.yaml"
  [disallow-privileged-containers]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-privileged-containers/disallow-privileged-containers.yaml"
  [disallow-privilege-escalation]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/restricted/disallow-privilege-escalation/disallow-privilege-escalation.yaml"
  [disallow-proc-mount]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-proc-mount/disallow-proc-mount.yaml"
  [disallow-selinux]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/disallow-selinux/disallow-selinux.yaml"
  [require_drop_all]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/charts/best-practices-k8s/pols/require_drop_all.yaml"
  [require_probes]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/best-practices-k8s/require_probes/require_probes.yaml"
  [require_pod_requests_limits]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/best-practices-k8s/require_pod_requests_limits/require_pod_requests_limits.yaml"
  [require-run-as-non-root-user]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/restricted/require-run-as-non-root-user/require-run-as-non-root-user.yaml"
  [restrict-service-external-ips]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/charts/best-practices-k8s/pols/restrict-service-external-ips.yaml"
  [restrict_image_registries]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/charts/best-practices-workload-security/pols/restrict_image_registries.yaml"
  [restrict_node_port]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/best-practices-k8s/restrict_node_port/restrict_node_port.yaml"
  [restrict-seccomp-strict]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/restricted/restrict-seccomp-strict/restrict-seccomp-strict.yaml"
  [restrict-sysctls]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/baseline/restrict-sysctls/restrict-sysctls.yaml"
  [restrict-apparmor-profiles]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/charts/pod-security-baseline/pols/restrict-apparmor-profiles.yaml"
  [restrict-volume-types]="https://raw.githubusercontent.com/nirmata/kyverno-policies/main/pod-security/restricted/restrict-volume-types/restrict-volume-types.yaml"
  [restrict-controlplane-scheduling]="https://raw.githubusercontent.com/kyverno/policies/main/other/restrict-controlplane-scheduling/restrict-controlplane-scheduling.yaml"
)

for name in "${!policies[@]}"; do
  url="${policies[$name]}"
  file="$POLICY_DIR/${name}.yaml"
  echo "📥 Downloading $name"
  curl -sSL -f -o "$file" "$url"
done

echo "✅ All policies downloaded successfully."
