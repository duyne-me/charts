# charts

## CI/CD in this repository
This repo currently has three CI/CD workflows:

- **Lint and Test Helm Charts** (`.github/workflows/run-lint.yaml`)
  - Runs `helm lint` for all charts.
  - Runs `ct lint` (chart-testing).
  - Regenerates docs with `helm-docs` and fails if docs are outdated.
- **Chart Render Validation** (`.github/workflows/chart-validate.yaml`)
  - Renders all charts with `helm template`.
  - Validates rendered manifests with `kubeconform`.
- **Release charts** (`.github/workflows/release.yaml`)
  - Generates release notes/changelog updates.
  - Publishes charts and OCI artifacts.

## How to add more CI/CD
If you want to add more CI/CD stages, use this checklist:

1. **Choose the quality gate type**
   - Lint (YAML/Helm style)
   - Render/Schema validation
   - Security scanning
   - Integration tests (install chart in a real cluster)
2. **Create a dedicated workflow** under `.github/workflows/`
   - Keep each workflow focused and independently debuggable.
3. **Use path filters**
   - Trigger only when `charts/**` or workflow files change.
4. **Fail fast on generated-file drift**
   - Continue using `git diff --exit-code` for generated docs.
5. **Keep tool versions pinned**
   - Pin action and binary versions to reduce CI drift.

### Suggested next CI/CD additions
- Add **Trivy** for container/config scanning on rendered manifests.
- Add **Kind-based smoke install**:
  - create cluster
  - `helm install` each chart
  - wait for resources
  - run chart tests
- Add **policy-as-code** checks (Kyverno or OPA/Conftest).
