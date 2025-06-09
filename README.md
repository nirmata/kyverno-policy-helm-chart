# Custom-Kyverno-cpol-helm-chart

##Installation Instructions

### 1. Add the repo: 
`helm repo add <name> https://nirmata.github.io/kyverno-policy-helm-chart`
Example: 
`helm repo add my-kyverno-cpol https://nirmata.github.io/kyverno-policy-helm-chart`

### 2. Update the repo:
`helm repo update`

### 3. Fetch the charts:
`helm search repo <repo-name>`
Example:
```
helm search repo my-kyverno-cpol
NAME                                    CHART VERSION   APP VERSION     DESCRIPTION
my-kyverno-cpol/custom-kyverno-cpol     0.1.1           1.0             Kyverno policies for pod security and workload ...
```

### 4. Install in Audit mode (example):
`helm install my-policies my-kyverno-cpol/custom-kyverno-cpol`

5. Install in Enforce mode (example):
`helm install my-policies my-kyverno-cpol/custom-kyverno-cpol --set validationFailureAction=Enforce`
