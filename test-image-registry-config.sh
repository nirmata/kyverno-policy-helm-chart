#!/bin/bash
set -euo pipefail

CHART_PATH="charts/dynamic-policies"

function print_header() {
  echo
  echo "=============================="
  echo "$1"
  echo "=============================="
}

function test_case() {
  local description="$1"
  shift
  print_header "$description"
  helm template test $CHART_PATH "$@" | grep -A 30 "restrict-image-registries" || true
}

# 1. Test with default values (should use default global/legacy)
test_case "Default values (should use default global/legacy)"

# 2. Test with legacy allowedRegistries only
test_case "Legacy allowedRegistries only" \
  --set allowedRegistries="docker.io/* | gcr.io/*"

# 3. Test with global imageRegistries only
test_case "Global imageRegistries only" \
  --set imageRegistries.global="docker.io/* | gcr.io/*"

# 4. Test with per-container-type imageRegistries
test_case "Per-container-type imageRegistries" \
  --set imageRegistries.global="docker.io/* | gcr.io/*" \
  --set imageRegistries.initContainers="docker.io/* | gcr.io/* | quay.io/*" \
  --set imageRegistries.ephemeralContainers="docker.io/*"

# 5. Test with only containers set (others fallback to global)
test_case "Only containers set (others fallback to global)" \
  --set imageRegistries.global="docker.io/* | gcr.io/*" \
  --set imageRegistries.containers="docker.io/* | gcr.io/* | quay.io/*"

# 6. Test with all per-container-type set (no global)
test_case "All per-container-type set (no global)" \
  --set imageRegistries.containers="docker.io/* | quay.io/*" \
  --set imageRegistries.initContainers="gcr.io/*" \
  --set imageRegistries.ephemeralContainers="eu.gcr.io/*"

# 7. Test with validationFailureAction=Enforce
test_case "Enforce mode with per-container-type" \
  --set validationFailureAction=Enforce \
  --set imageRegistries.global="docker.io/* | gcr.io/*" \
  --set imageRegistries.initContainers="docker.io/* | gcr.io/* | quay.io/*" \
  --set imageRegistries.ephemeralContainers="docker.io/*"

echo
print_header "All tests completed. Review the output above for correct registry patterns in restrict-image-registries policy." 