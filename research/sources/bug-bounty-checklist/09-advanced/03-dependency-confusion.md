# Dependency Confusion & Supply-Chain Recon

**What it is:** App builds pull an internal package name from a public registry. Publish that name publicly with a higher version → the build fetches yours → RCE in their CI/prod. **Only where the program explicitly authorizes it** — this is intrusive.

## Recon (safe, passive)
- [ ] Mine JS/webpack bundles, `package.json`, `.npmrc`, sourcemaps for internal package names (`@companyscope/...`, `internal-utils`).
- [ ] Check if those names are **unclaimed** on npm/PyPI/RubyGems/Maven.
- [ ] Look for `composer.json`, `requirements.txt`, `pom.xml`, `go.mod` leaked in `.git`/artifacts.
- [ ] Registry scoping: is `@scope` pointed at a private registry or defaulting to public?

## Proof (only if in scope, minimal)
- Publish a benign package that beacons to Collaborator on install (`preinstall` DNS lookup, **no** data exfil, no destructive code).
- A single OOB callback from their build IP proves the confusion. Stop there.

## Related supply-chain leads (recon-only unless authorized)
- [ ] Unclaimed scoped names, typosquat targets in their lockfiles.
- [ ] Public CI configs (`.github/workflows`) leaking secrets/tokens.
- [ ] Exposed `.npmrc`/`.pypirc` with auth tokens.
- [ ] Subresource without SRI loaded from a takeover-able CDN/bucket.

## Impact
RCE in build/CI/prod, secret theft. Critical.

## Report notes
Confirm before acting that the program allows supply-chain testing. Never ship code that runs beyond a benign beacon. Report the unclaimed internal name + the OOB proof.

## Deep cuts — ecosystems & adjacent supply-chain
- [ ] **Per-ecosystem name sources:** npm (`@scope/pkg`, `.npmrc` registry), PyPI (`requirements.txt`, `setup.py`, private index URL), Maven/Gradle (`groupId:artifactId`, `pom.xml`, `build.gradle`), Go (vanity import path → controllable VCS namespace, `go.mod`), NuGet (`.csproj`, `nuget.config`), RubyGems (`Gemfile`, source), Composer/Packagist (`composer.json`), Cargo (`Cargo.toml`), Docker (base image name / private registry namespace).
- [ ] **Scoped-fallback nuance:** confusion bites when the private `@scope`/index isn't pinned for *all* resolvers, or a `--extra-index-url` (pip) merges public+private and picks the highest version.
- [ ] **Starjacking / typosquat:** claim a public name matching an internal one, or a 1-char typo of a real dep in their lockfile; inflate trust with a matching `repository` field (starjacking).
- [ ] **CI/CD supply-chain (often in-scope-adjacent):** unpinned GitHub Actions (`uses: org/action@main` instead of a SHA), self-hosted runner takeover via a fork PR, `pull_request_target` + checkout of untrusted code, cacheable workflow secrets, and leaked `GITHUB_TOKEN`/OIDC trust.
- [ ] **Install-hook reality:** the beacon rides `preinstall`/`postinstall` (npm), `sitecustomize`/`setup.py` (pip), Gradle init script — keep it a DNS/HTTP callback only.
- [ ] **SRI-less external scripts / takeover CDN** referenced by the app → client-side supply chain (broken-link hijack, `08-infra/01`).

## Tools
`confused`, `snyk`, `depance`, `apkleaks` (mobile deps), manual registry checks, `trufflehog` on repos, `actionlint`/`zizmor` for CI.
