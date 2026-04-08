# Project Deep Dive: `charts`

## Executive summary
This repository is a Helm chart mono-repo with two example application charts (`demo` and `demo2`) and CI/CD automation for linting, documentation generation, and chart release publishing. The structure is intentionally minimal and appears to be a bootstrap/template repository for chart authoring and release automation.

## Repository layout
- Root-level docs/templates:
  - `README.md` (currently minimal title-only)
  - `_index.md.gotmpl` and `_changelog.md` templates for generated chart index/changelog content.
- Chart directories:
  - `charts/demo`
  - `charts/demo2`
- CI and release configuration:
  - `.github/workflows/run-lint.yaml` for lint + docs consistency checks.
  - `.github/workflows/release.yaml` for publishing releases to chart repositories and OCI.
  - `.github/ci/*.yaml` supporting chart-releaser/chart-testing/helm-docs settings.
- Local automation:
  - `Makefile` with `gen-docs` target that runs `helm-docs` via container.

## Chart implementation deep dive
Both charts follow the Helm starter pattern and expose familiar values knobs:
- Workload: Deployment with optional HPA.
- Network: Service and optional Ingress.
- Identity: optional ServiceAccount creation.
- Health: liveness/readiness probe defaults.
- Scheduling: affinity/tolerations/nodeSelector and optional extra volumes.

### `demo`
- Chart metadata is starter-level (`version: 0.1.0`, `appVersion: 1.16.0`), suitable for sample/testing usage.
- Templating is clean and convention-compliant (helpers for fullname/labels/service account names).
- Values defaults are safe and generic (ClusterIP service, 2 replicas, nginx image).

### `demo2`
- Nearly a line-for-line copy of `demo` with chart name + helper prefixes changed from `demo.*` to `demo2.*`.
- Useful for validating multi-chart CI/release behavior, but introduces duplication that may drift over time.

## CI/CD pipeline deep dive

### Lint + documentation workflow (`run-lint.yaml`)
What it does:
1. Checks out code.
2. Installs Helm and chart-testing action.
3. Runs `helm lint` over every chart with a `Chart.yaml`.
4. Runs `helm-docs` in a container.
5. Fails if generated docs would change (`git diff --exit-code`).

Implications:
- Enforces a "docs are generated, not handwritten" workflow.
- Keeps chart README/index/changelog generated outputs synchronized in PRs.

### Release workflow (`release.yaml`)
What it does:
1. Installs Helm + `yq`.
2. Optionally adds external helm repos from `.github/ci/helm-repos.yaml`.
3. Regenerates docs (`make gen-docs`).
4. For each chart, ensures `CHANGELOG.md` has `## Next release`.
5. If chart version is unreleased:
   - Generates ArtifactHub annotations in `Chart.yaml`.
   - Generates `RELEASE_NOTES`.
   - Rewrites `CHANGELOG.md` by promoting `Next release` notes.
6. Publishes via chart-releaser and OCI (`ghcr.io/<owner>/helm-charts`).
7. Opens an automated PR with updated changelogs/readmes.

Implications:
- Release process is changelog-driven and partly stateful.
- `## Next release` is a hard contract; missing section blocks release.
- Release notes generation depends on specific text shape in changelog.

## Strengths
- Straightforward Helm chart scaffolding; easy for new maintainers to adopt.
- CI catches out-of-date generated docs before merge.
- Dual publishing path (index + OCI) broadens install options.
- Release automation enforces consistent changelog and release-note hygiene.

## Risks and maintenance concerns
1. **High duplication across charts**
   - `demo` and `demo2` are almost identical; bug fixes must be copied manually.
2. **Potentially brittle text processing in release job**
   - Heavy use of `sed`, regex capture, and section markers can fail on minor formatting changes.
3. **Mutable tooling versions**
   - `HELM_DOCS_IMAGE = ...:latest` in `Makefile` can cause non-deterministic output over time.
4. **Chart-testing lint is currently commented out**
   - Existing workflow installs ct but only uses `helm lint`.
5. **Minimal root README**
   - Onboarding context (release flow, contribution steps, docs generation) is not documented centrally.

## Recommended improvements (prioritized)
1. **Stabilize docs generation tooling**
   - Pin `helm-docs` image tag to a specific version to reduce CI drift.
2. **Add a maintainer-facing root README section**
   - Document local commands (`make gen-docs`, `helm lint charts/<name>`), release prerequisites, and changelog contract.
3. **Reduce duplicate templates**
   - Consider a shared library chart or chart scaffolding automation for new charts.
4. **Re-enable `ct lint`**
   - Restore chart-testing checks once baseline configuration is verified.
5. **Add smoke render checks**
   - CI could run `helm template` for each chart with default + a couple of override cases.

## Suggested developer workflow
1. Edit chart templates/values.
2. Run `helm lint charts/<chart>` locally.
3. Regenerate docs: `make gen-docs`.
4. Update chart `CHANGELOG.md` under `## Next release`.
5. Bump chart `version` in `Chart.yaml` when release-worthy.
6. Open PR; CI validates lint + generated docs drift.

## Bottom line
This is a clean starter-quality Helm chart repository with strong release automation foundations. Its main gaps are documentation/onboarding depth and duplicated chart maintenance cost. A small amount of structural refactoring plus deterministic tool pinning would materially improve long-term maintainability.
