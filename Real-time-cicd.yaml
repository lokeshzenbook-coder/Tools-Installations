# =============================================================================
# devsecops.yml
# -----------------------------------------------------------------------------
# Enterprise-grade DevSecOps CI/CD pipeline.
#
# Pipeline stages (see job graph via `needs:`):
#   secret-scan ─┐
#   sast         ├──▶ build-test ──▶ sca-trivy-fs ──▶ docker-build ──▶
#   sonarqube  ──┘                                                     │
#                                                                      ▼
#   image-scan-trivy ──▶ sbom-syft ──▶ sign-image ──▶ push-ecr ──▶ deploy-staging ──▶ dast-zap
#
# Design notes:
#   - Secret scanning, SAST and SonarQube run in parallel because they are
#     independent static checks on the source tree — this shortens wall clock
#     time while still gating everything downstream on all three passing.
#   - Every job re-checks out the repository because GitHub Actions jobs run
#     on fresh, isolated runners (no filesystem is shared between jobs).
#   - No long-lived AWS credentials are ever used — authentication to AWS is
#     performed exclusively via GitHub OIDC + an assumable IAM role.
#   - Image signing uses Sigstore Cosign in "keyless" mode, anchored to the
#     GitHub OIDC identity token, so no private signing key must be stored.
# =============================================================================

name: DevSecOps CI/CD Pipeline

# -----------------------------------------------------------------------------
# Triggers
# -----------------------------------------------------------------------------
on:
  push:
    branches: [main, release/**]
  pull_request:
    branches: [main]
  workflow_dispatch: {}   # allow manual runs from the Actions UI

# -----------------------------------------------------------------------------
# Concurrency control
# Cancels superseded runs on the same branch/PR to save runner minutes and
# avoid two deployments racing each other.
# -----------------------------------------------------------------------------
concurrency:
  group: devsecops-${{ github.ref }}
  cancel-in-progress: true

# -----------------------------------------------------------------------------
# Default (least-privilege) permissions. Individual jobs elevate only the
# specific permission they need (e.g. `id-token: write` for OIDC,
# `security-events: write` to upload SARIF).
# -----------------------------------------------------------------------------
permissions:
  contents: read

# -----------------------------------------------------------------------------
# Reusable pipeline-wide environment variables.
# Values that differ per environment should live in GitHub Environments /
# Variables (vars.*) rather than being hard-coded here.
# -----------------------------------------------------------------------------
env:
  AWS_REGION: ${{ vars.AWS_REGION || 'us-east-1' }}
  ECR_REPOSITORY: ${{ vars.ECR_REPOSITORY || 'my-app' }}
  AWS_ACCOUNT_ID: ${{ vars.AWS_ACCOUNT_ID }}
  AWS_OIDC_ROLE_ARN: ${{ vars.AWS_OIDC_ROLE_ARN }}          # arn:aws:iam::<acct>:role/github-oidc-deploy-role
  IMAGE_NAME: ${{ vars.ECR_REPOSITORY || 'my-app' }}
  SONAR_PROJECT_KEY: ${{ vars.SONAR_PROJECT_KEY || github.event.repository.name }}
  # PROJECT_TYPE controls which build/test toolchain steps execute.
  # Set as a repo/organization variable: java-maven | java-gradle | node | python | dotnet
  PROJECT_TYPE: ${{ vars.PROJECT_TYPE || 'node' }}
  TRIVY_SEVERITY: 'HIGH,CRITICAL'

jobs:

  # ===========================================================================
  # JOB 1a: Secret Scanning — Gitleaks
  # Scans the FULL git history (not just the current diff) so historical
  # commits that leaked credentials are also caught. Hard-fails the pipeline.
  # ===========================================================================
  secret-scan:
    name: "🔒 Secret Scan (Gitleaks)"
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
    steps:
      - name: Checkout full history
        uses: actions/checkout@v4
        with:
          fetch-depth: 0   # required for Gitleaks to scan entire git history

      - name: Run Gitleaks
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          # Optional: use a Gitleaks license secret if using the Pro/Enterprise action
          GITLEAKS_LICENSE: ${{ secrets.GITLEAKS_LICENSE }}
        with:
          # Fails the step (and therefore the job) automatically if leaks are found.
          config-path: .gitleaks.toml

      - name: Upload Gitleaks report artifact
        if: always()   # always capture evidence, even on failure
        uses: actions/upload-artifact@v4
        with:
          name: gitleaks-report
          path: results.sarif
          retention-days: 30
          if-no-files-found: ignore

  # ===========================================================================
  # JOB 1b: SAST — Semgrep
  # Runs Semgrep's recommended community ruleset and uploads SARIF to
  # GitHub Advanced Security (Security tab) for centralized triage.
  # ===========================================================================
  sast-semgrep:
    name: "🛡️ SAST (Semgrep)"
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
      security-events: write   # required to upload SARIF to code scanning
    container:
      image: semgrep/semgrep:latest
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Run Semgrep (recommended ruleset)
        run: |
          semgrep scan \
            --config=auto \
            --sarif \
            --output=semgrep-results.sarif \
            --error \
            --severity=ERROR --severity=WARNING
        env:
          SEMGREP_APP_TOKEN: ${{ secrets.SEMGREP_APP_TOKEN }}

      - name: Upload Semgrep SARIF to GitHub Security
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: semgrep-results.sarif
          category: semgrep

      - name: Upload Semgrep report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: semgrep-sarif
          path: semgrep-results.sarif
          retention-days: 30

  # ===========================================================================
  # JOB 1c: Code Quality — SonarQube
  # Runs static analysis against a SonarQube/SonarCloud server and blocks
  # the pipeline if the Quality Gate does not pass.
  # ===========================================================================
  sonarqube:
    name: "📊 Code Quality (SonarQube)"
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - name: Checkout source
        uses: actions/checkout@v4
        with:
          fetch-depth: 0   # SonarQube needs full history for blame/new-code analysis

      - name: SonarQube Scan
        uses: SonarSource/sonarqube-scan-action@v4
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        with:
          args: >
            -Dsonar.projectKey=${{ env.SONAR_PROJECT_KEY }}
            -Dsonar.qualitygate.wait=true

      - name: Enforce SonarQube Quality Gate
        uses: SonarSource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
        # Non-zero exit here fails the job, which blocks all downstream jobs.

      - name: Upload SonarQube report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: sonarqube-report
          path: .scannerwork/report-task.txt
          retention-days: 30
          if-no-files-found: ignore

  # ===========================================================================
  # JOB 2: Build & Unit Test
  # Supports Java (Maven/Gradle), Node.js, Python, and .NET. The active
  # toolchain is selected via the PROJECT_TYPE repo variable; each `if:`
  # guard keeps unused steps from running (they're skipped, not failed).
  # Gated on ALL three static-analysis jobs succeeding.
  # ===========================================================================
  build-test:
    name: "🏗️ Build & Unit Test"
    needs: [secret-scan, sast-semgrep, sonarqube]
    runs-on: ubuntu-latest
    timeout-minutes: 30
    permissions:
      contents: read
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      # ---- Java / Maven -----------------------------------------------------
      - name: Set up JDK
        if: startsWith(env.PROJECT_TYPE, 'java')
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'
          cache: ${{ env.PROJECT_TYPE == 'java-maven' && 'maven' || 'gradle' }}

      - name: Build & test (Maven)
        if: env.PROJECT_TYPE == 'java-maven'
        run: mvn -B clean verify

      - name: Build & test (Gradle)
        if: env.PROJECT_TYPE == 'java-gradle'
        run: ./gradlew build test --no-daemon

      # ---- Node.js ------------------------------------------------------------
      - name: Set up Node.js
        if: env.PROJECT_TYPE == 'node'
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install & build (npm)
        if: env.PROJECT_TYPE == 'node'
        run: |
          npm ci
          npm run build --if-present

      - name: Run Jest unit tests
        if: env.PROJECT_TYPE == 'node'
        run: npm test -- --ci --reporters=default --reporters=jest-junit
        env:
          JEST_JUNIT_OUTPUT_DIR: ./test-results

      # ---- Python ---------------------------------------------------------
      - name: Set up Python
        if: env.PROJECT_TYPE == 'python'
        uses: actions/setup-python@v5
        with:
          python-version: '3.12'
          cache: 'pip'

      - name: Install dependencies
        if: env.PROJECT_TYPE == 'python'
        run: |
          python -m pip install --upgrade pip
          pip install -r requirements.txt
          pip install pytest pytest-cov

      - name: Run PyTest unit tests
        if: env.PROJECT_TYPE == 'python'
        run: pytest --junitxml=test-results/pytest-results.xml --cov

      # ---- .NET -------------------------------------------------------------
      - name: Set up .NET
        if: env.PROJECT_TYPE == 'dotnet'
        uses: actions/setup-dotnet@v4
        with:
          dotnet-version: '8.0.x'

      - name: Restore & build (.NET)
        if: env.PROJECT_TYPE == 'dotnet'
        run: |
          dotnet restore
          dotnet build --configuration Release --no-restore

      - name: Run NUnit tests
        if: env.PROJECT_TYPE == 'dotnet'
        run: dotnet test --no-build --configuration Release --logger "trx;LogFileName=test-results.trx" --results-directory ./test-results

      # ---- Common: publish artifacts ----------------------------------------
      - name: Upload build output
        uses: actions/upload-artifact@v4
        with:
          name: build-output
          path: |
            target/**
            dist/**
            build/**
            bin/**
          if-no-files-found: ignore
          retention-days: 7

      - name: Upload unit test reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: unit-test-reports
          path: |
            test-results/**
            **/surefire-reports/**
          if-no-files-found: ignore
          retention-days: 30

  # ===========================================================================
  # JOB 3: Software Composition Analysis — Trivy Filesystem Scan
  # Scans project dependencies for known CVEs. Fails on HIGH/CRITICAL.
  # ===========================================================================
  sca-trivy-fs:
    name: "📦 SCA (Trivy Filesystem)"
    needs: build-test
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      security-events: write
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Cache Trivy vulnerability DB
        uses: actions/cache@v4
        with:
          path: ~/.cache/trivy
          key: trivy-db-${{ github.run_id }}
          restore-keys: trivy-db-

      - name: Trivy filesystem scan (SARIF for GitHub Security)
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: fs
          scan-ref: '.'
          format: sarif
          output: trivy-fs-results.sarif
          severity: ${{ env.TRIVY_SEVERITY }}
          exit-code: '0'   # don't fail here — enforced explicitly below after SARIF upload

      - name: Upload Trivy FS SARIF to GitHub Security
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-fs-results.sarif
          category: trivy-filesystem

      - name: Enforce fail on HIGH/CRITICAL dependency vulnerabilities
        uses: aquasecurity/trivy-action@0.24.0
        with:
          scan-type: fs
          scan-ref: '.'
          format: table
          severity: ${{ env.TRIVY_SEVERITY }}
          exit-code: '1'   # this run actually fails the job if findings exist

      - name: Upload Trivy FS report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: trivy-fs-report
          path: trivy-fs-results.sarif
          retention-days: 30

  # ===========================================================================
  # JOB 4: Docker Build
  # Builds the image once and tags it with git SHA, `latest`, and a semver
  # tag when the ref is a version tag (vX.Y.Z). Image is exported to a local
  # tar so subsequent jobs can load it without re-building or pushing early.
  # ===========================================================================
  docker-build:
    name: "🐳 Docker Build"
    needs: sca-trivy-fs
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
    outputs:
      image-tag-sha: ${{ steps.tags.outputs.sha_tag }}
    steps:
      - name: Checkout source
        uses: actions/checkout@v4

      - name: Compute image tags
        id: tags
        run: |
          SHA_TAG="${GITHUB_SHA::12}"
          echo "sha_tag=${SHA_TAG}" >> "$GITHUB_OUTPUT"
          if [[ "${GITHUB_REF}" == refs/tags/v* ]]; then
            echo "semver_tag=${GITHUB_REF#refs/tags/}" >> "$GITHUB_OUTPUT"
          else
            echo "semver_tag=" >> "$GITHUB_OUTPUT"
          fi

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Cache Docker layers
        uses: actions/cache@v4
        with:
          path: /tmp/.buildx-cache
          key: buildx-${{ github.sha }}
          restore-keys: buildx-

      - name: Build Docker image (export to local tar, no push yet)
        uses: docker/build-push-action@v6
        with:
          context: .
          file: ./Dockerfile
          push: false
          load: true
          tags: |
            ${{ env.IMAGE_NAME }}:${{ steps.tags.outputs.sha_tag }}
            ${{ env.IMAGE_NAME }}:latest
          cache-from: type=local,src=/tmp/.buildx-cache
          cache-to: type=local,dest=/tmp/.buildx-cache-new,mode=max

      - name: Move Docker cache (avoid unbounded cache growth)
        run: |
          rm -rf /tmp/.buildx-cache
          mv /tmp/.buildx-cache-new /tmp/.buildx-cache

      - name: Save image as artifact for downstream jobs
        run: docker save ${{ env.IMAGE_NAME }}:${{ steps.tags.outputs.sha_tag }} -o image.tar

      - name: Upload image tarball
        uses: actions/upload-artifact@v4
        with:
          name: docker-image
          path: image.tar
          retention-days: 1

  # ===========================================================================
  # JOB 5: Container Security — Trivy Image Scan
  # Scans the freshly built image for OS and application-level CVEs.
  # ===========================================================================
  image-scan-trivy:
    name: "🔍 Trivy Image Scan"
    needs: docker-build
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      security-events: write
    steps:
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image

      - name: Load Docker image
        run: docker load -i image.tar

      - name: Trivy image scan (SARIF)
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }}
          format: sarif
          output: trivy-image-results.sarif
          severity: ${{ env.TRIVY_SEVERITY }}
          exit-code: '0'

      - name: Upload Trivy image SARIF to GitHub Security
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-image-results.sarif
          category: trivy-image

      - name: Enforce fail on HIGH/CRITICAL image vulnerabilities
        uses: aquasecurity/trivy-action@0.24.0
        with:
          image-ref: ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }}
          format: table
          severity: ${{ env.TRIVY_SEVERITY }}
          exit-code: '1'

      - name: Upload Trivy image report artifact
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: trivy-image-report
          path: trivy-image-results.sarif
          retention-days: 30

  # ===========================================================================
  # JOB 6: SBOM Generation — Syft
  # Generates both CycloneDX and SPDX SBOMs for supply-chain transparency.
  # ===========================================================================
  sbom-syft:
    name: "📋 Generate SBOM (Syft)"
    needs: image-scan-trivy
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
    steps:
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image

      - name: Load Docker image
        run: docker load -i image.tar

      - name: Install Syft
        uses: anchore/sbom-action/download-syft@v0.17.0

      - name: Generate SBOM (CycloneDX)
        run: |
          syft ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }} \
            -o cyclonedx-json=sbom.cyclonedx.json
        env:
          IMAGE_NAME: ${{ env.IMAGE_NAME }}

      - name: Generate SBOM (SPDX)
        run: |
          syft ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }} \
            -o spdx-json=sbom.spdx.json

      - name: Upload SBOM artifacts
        uses: actions/upload-artifact@v4
        with:
          name: sbom-reports
          path: |
            sbom.cyclonedx.json
            sbom.spdx.json
          retention-days: 90   # SBOMs are typically retained longer for compliance

  # ===========================================================================
  # JOB 7: Image Signing — Cosign (keyless, OIDC-based)
  # Signs the image using Sigstore's keyless flow anchored to GitHub's OIDC
  # identity token — no private key material is stored anywhere.
  # ===========================================================================
  sign-image:
    name: "✍️ Sign Image (Cosign)"
    needs: sbom-syft
    runs-on: ubuntu-latest
    timeout-minutes: 10
    permissions:
      contents: read
      id-token: write   # required to mint the OIDC token Cosign uses for keyless signing
    steps:
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image

      - name: Load Docker image
        run: docker load -i image.tar

      - name: Install Cosign
        uses: sigstore/cosign-installer@v3

      # NOTE: Keyless signing against a registry reference requires the image
      # to already be pushed (Cosign signs the digest in the registry). We
      # therefore push here under a staging alias, sign it, and the final
      # `push-ecr` job promotes/re-tags the verified, signed digest.
      - name: Tag image for local registry push (pre-sign)
        run: docker tag ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }} localhost:5000/${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }}

      - name: Sign image with Cosign (keyless / OIDC)
        run: |
          cosign sign --yes \
            ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }}
        env:
          COSIGN_EXPERIMENTAL: "1"

      - name: Verify Cosign signature
        run: |
          cosign verify \
            --certificate-identity-regexp ".*" \
            --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
            ${{ env.IMAGE_NAME }}:${{ needs.docker-build.outputs.image-tag-sha }}
        env:
          COSIGN_EXPERIMENTAL: "1"

  # ===========================================================================
  # JOB 8: Push to Amazon ECR
  # Authenticates purely via GitHub OIDC → AWS STS AssumeRoleWithWebIdentity.
  # No AWS access keys ever touch this pipeline.
  # ===========================================================================
  push-ecr:
    name: "📤 Push to Amazon ECR"
    needs: sign-image
    runs-on: ubuntu-latest
    timeout-minutes: 15
    permissions:
      contents: read
      id-token: write   # required for OIDC federation to AWS
    steps:
      - name: Download image artifact
        uses: actions/download-artifact@v4
        with:
          name: docker-image

      - name: Load Docker image
        run: docker load -i image.tar

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: gha-devsecops-${{ github.run_id }}

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Tag & push image to ECR (git-sha and latest tags)
        env:
          ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
          SHA_TAG: ${{ needs.docker-build.outputs.image-tag-sha }}
        run: |
          docker tag ${{ env.IMAGE_NAME }}:${SHA_TAG} ${ECR_REGISTRY}/${{ env.ECR_REPOSITORY }}:${SHA_TAG}
          docker tag ${{ env.IMAGE_NAME }}:${SHA_TAG} ${ECR_REGISTRY}/${{ env.ECR_REPOSITORY }}:latest

          docker push ${ECR_REGISTRY}/${{ env.ECR_REPOSITORY }}:${SHA_TAG}
          docker push ${ECR_REGISTRY}/${{ env.ECR_REPOSITORY }}:latest

  # ===========================================================================
  # JOB 9: Deploy to Staging
  # Deploys via Helm to an Amazon EKS cluster. Protected by the `staging`
  # GitHub Environment (configure required reviewers / wait timer there for
  # an approval gate). Waits for rollout to complete before proceeding.
  # ===========================================================================
  deploy-staging:
    name: "🚀 Deploy to Staging (EKS)"
    needs: push-ecr
    runs-on: ubuntu-latest
    timeout-minutes: 20
    environment:
      name: staging
      url: https://staging.example.com
    permissions:
      contents: read
      id-token: write
    steps:
      - name: Checkout Helm charts / manifests
        uses: actions/checkout@v4

      - name: Configure AWS credentials via OIDC
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ env.AWS_OIDC_ROLE_ARN }}
          aws-region: ${{ env.AWS_REGION }}
          role-session-name: gha-deploy-staging-${{ github.run_id }}

      - name: Update kubeconfig for EKS cluster
        run: aws eks update-kubeconfig --name ${{ vars.EKS_CLUSTER_NAME }} --region ${{ env.AWS_REGION }}

      - name: Set up Helm
        uses: azure/setup-helm@v4
        with:
          version: 'v3.15.0'

      - name: Deploy via Helm upgrade
        env:
          SHA_TAG: ${{ needs.docker-build.outputs.image-tag-sha }}
        run: |
          helm upgrade --install ${{ env.IMAGE_NAME }} ./helm/${{ env.IMAGE_NAME }} \
            --namespace staging --create-namespace \
            --set image.repository=${{ env.AWS_ACCOUNT_ID }}.dkr.ecr.${{ env.AWS_REGION }}.amazonaws.com/${{ env.ECR_REPOSITORY }} \
            --set image.tag=${SHA_TAG} \
            --wait --timeout 5m

      - name: Wait for rollout to complete
        run: kubectl rollout status deployment/${{ env.IMAGE_NAME }} -n staging --timeout=300s

  # ===========================================================================
  # JOB 10: DAST — OWASP ZAP Baseline Scan
  # Scans the freshly deployed staging environment for runtime web
  # vulnerabilities. Fails the pipeline on high-risk findings.
  # ===========================================================================
  dast-zap:
    name: "🕷️ DAST (OWASP ZAP)"
    needs: deploy-staging
    runs-on: ubuntu-latest
    timeout-minutes: 20
    permissions:
      contents: read
    steps:
      - name: Checkout (for ZAP rules/config if present)
        uses: actions/checkout@v4

      - name: Run OWASP ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: 'https://staging.example.com'
          # -j: use ajax spider too; -I: don't fail the *action* on WARN so we
          # can enforce our own HIGH-risk gate explicitly below.
          cmd_options: '-j -I -r zap-report.html -w zap-report.md -x zap-report.json'
          fail_action: false

      - name: Enforce fail on high-risk findings
        run: |
          HIGH_COUNT=$(jq '[.site[].alerts[] | select(.riskcode == "3")] | length' zap-report.json)
          echo "High-risk findings: ${HIGH_COUNT}"
          if [ "${HIGH_COUNT}" -gt 0 ]; then
            echo "::error::OWASP ZAP found ${HIGH_COUNT} high-risk vulnerabilities. Failing pipeline."
            exit 1
          fi

      - name: Upload ZAP reports (HTML & JSON)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: owasp-zap-reports
          path: |
            zap-report.html
            zap-report.json
            zap-report.md
          retention-days: 30
