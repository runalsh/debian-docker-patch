# Debian Docker Patch Images

Automated build of Docker images for exact Debian point releases (**12.0** .. **12.15**, **13.0** .. **13.6**).

---

## ❓ Problem Statement

The official Docker Hub registry (`library/debian`) publishes **only major tags** (e.g., `debian:12`, `debian:13`, `bookworm`, `trixie`).

Official tags like `debian:12.1`, `debian:12.5`, or `debian:13.2` **do not exist**, as maintainers continuously update major tags with the latest packages.

### Key Issues:
1. **Testing on specific distribution patch versions**: Impossibility of running tests or simulating environments locked to a specific point release (e.g., `12.1` or `13.2`).
2. **Build Reproducibility**: The base `debian:12` image changes over time as packages are updated, which can mask or alter software behavior.
3. **Security Audits & Forensics**: Difficulty in reproducing system environments as they existed at a specific point release date.

---

## 🚀 Solution

This repository addresses the problem by:
- Using official root filesystem archives (**nocloud-amd64 tar.xz**) directly from Debian Cloud (`cloud.debian.org`).
- Building and validating clean Docker images for each exact Debian point release.
- Automatically validating `/etc/os-release` against the expected version tag before publishing.
- Automatically publishing ready-to-use Docker images to **Docker Hub** (`runalsh/debian-patch`) and **GitHub Container Registry** (`ghcr.io/runalsh/debian-patch`).

---

## 📦 Available Images and Registries

### Debian 12 (Bookworm)

| Tag | OS Version | Docker Hub Image Link | GHCR Package Link |
|---|---|---|---|
| `12` | `Latest Debian 12` | [`runalsh/debian-patch:12`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `bookworm` | `Latest Bookworm` | [`runalsh/debian-patch:bookworm`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:bookworm`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.0` | `Debian 12.0` | [`runalsh/debian-patch:12.0`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.0`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.1` | `Debian 12.1` | [`runalsh/debian-patch:12.1`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.1`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.2` | `Debian 12.2` | [`runalsh/debian-patch:12.2`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.2`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.4` | `Debian 12.4` | [`runalsh/debian-patch:12.4`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.4`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.5` | `Debian 12.5` | [`runalsh/debian-patch:12.5`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.5`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.6` | `Debian 12.6` | [`runalsh/debian-patch:12.6`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.6`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.7` | `Debian 12.7` | [`runalsh/debian-patch:12.7`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.7`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.8` | `Debian 12.8` | [`runalsh/debian-patch:12.8`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.8`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.9` | `Debian 12.9` | [`runalsh/debian-patch:12.9`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.9`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.10` | `Debian 12.10` | [`runalsh/debian-patch:12.10`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.10`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.11` | `Debian 12.11` | [`runalsh/debian-patch:12.11`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.11`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.12` | `Debian 12.12` | [`runalsh/debian-patch:12.12`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.12`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.13` | `Debian 12.13` | [`runalsh/debian-patch:12.13`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.13`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.14` | `Debian 12.14` | [`runalsh/debian-patch:12.14`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.14`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `12.15` | `Debian 12.15` | [`runalsh/debian-patch:12.15`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:12.15`](https://github.com/users/runalsh/packages/container/package/debian-patch) |

### Debian 13 (Trixie)

| Tag | OS Version | Docker Hub Image Link | GHCR Package Link |
|---|---|---|---|
| `13` | `Latest Debian 13` | [`runalsh/debian-patch:13`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `trixie` | `Latest Trixie` | [`runalsh/debian-patch:trixie`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:trixie`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.0` | `Debian 13.0` | [`runalsh/debian-patch:13.0`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.0`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.1` | `Debian 13.1` | [`runalsh/debian-patch:13.1`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.1`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.2` | `Debian 13.2` | [`runalsh/debian-patch:13.2`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.2`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.3` | `Debian 13.3` | [`runalsh/debian-patch:13.3`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.3`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.4` | `Debian 13.4` | [`runalsh/debian-patch:13.4`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.4`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.5` | `Debian 13.5` | [`runalsh/debian-patch:13.5`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.5`](https://github.com/users/runalsh/packages/container/package/debian-patch) |
| `13.6` | `Debian 13.6` | [`runalsh/debian-patch:13.6`](https://hub.docker.com/r/runalsh/debian-patch/tags) | [`ghcr.io/runalsh/debian-patch:13.6`](https://github.com/users/runalsh/packages/container/package/debian-patch) |

---


---

## ✂️ What is Stripped from the Rootfs (Size Optimization)

Official Debian GenericCloud / NoCloud root filesystem images are built with bare-metal VM bootloaders, kernels, and packages that are completely unnecessary and non-functional inside Docker containers.

The build script strips non-container bloat, reducing the uncompressed image from **~946 MB** down to **~430 MB** (saving over **510 MB** / **>54%** per image):

| Component / Path | What it is | Why it is safe to remove in Docker | Disk Space Saved |
|---|---|---|---|
| **Linux Kernel & Modules** (`/usr/lib/modules`, `/lib/modules`, `/boot/vmlinuz*`, `/boot/initrd*`) | Linux 6.1 kernel binaries and hardware drivers | Docker containers share the host Linux kernel; internal kernel files are never loaded. | **~394 MB** |
| **GRUB Bootloader** (`/usr/lib/grub`, `/boot/grub`, `/etc/grub.d`) | EFI/BIOS bootloader tools and stages | Containers are started via `runc` without BIOS/EFI bootloaders. | **~50 MB** |
| **APT Index Lists & Cache** (`/var/lib/apt/lists/*`, `/var/cache/apt/*`) | Downloaded package index caches | Refreshed on demand during `apt-get update`. | **~25 MB** |
| **Documentation & Manuals** (`/usr/share/{doc,man,info}`) | Package changelogs and man pages | Not used by headless automated daemons or CI/CD test jobs. | **~35 MB** |
| **Temporary Files & Logs** (`/tmp/*`, `/var/log/*`, `/var/tmp/*`) | Bootstrap install logs and temp sockets | Re-generated on demand during runtime. | **~10 MB** |
| **Total Savings** | | | **~510+ MB (>54% reduction)** |

---
## 🛠 Quick Start

### Docker Hub

```bash
docker run --rm -it runalsh/debian-patch:12.0 cat /etc/os-release
docker run --rm -it runalsh/debian-patch:12.15 cat /etc/os-release
docker run --rm -it runalsh/debian-patch:13.0 cat /etc/os-release
docker run --rm -it runalsh/debian-patch:13.6 cat /etc/os-release
```

### GitHub Container Registry (GHCR)

```bash
docker run --rm -it ghcr.io/runalsh/debian-patch:12.0 cat /etc/os-release
docker run --rm -it ghcr.io/runalsh/debian-patch:12.15 cat /etc/os-release
docker run --rm -it ghcr.io/runalsh/debian-patch:13.0 cat /etc/os-release
docker run --rm -it ghcr.io/runalsh/debian-patch:13.6 cat /etc/os-release
```

### Local Build

The `releases.txt` file contains a list of tags and direct download URLs for rootfs archives.

To import all versions locally:

```bash
chmod +x build.sh
TEST_VERSION=true PUSH_TO_DOCKERHUB=false PUSH_TO_GHCR=false ./build.sh
```

---

## 🔧 Environment Variables

The `build.sh` script supports the following configuration environment variables:

| Variable | Default | Description |
|---|---|---|
| `TEST_VERSION` | `true` | When set to `true`, verifies container functionality and validates `/etc/os-release` after import. |
| `PUSH_TO_DOCKERHUB` | `false` | When set to `true`, automatically pushes built images to Docker Hub (`runalsh/debian-patch:<tag>`). |
| `PUSH_TO_GHCR` | `false` | When set to `true`, automatically pushes built images to GitHub Packages / GHCR (`ghcr.io/runalsh/debian-patch:<tag>`). |
| `CLEANUP_DOCKER_IMAGES` | `false` | When set to `true`, deletes local Docker images (`docker rmi`) after build and push to conserve disk space. |
| `SKIP_EXISTS_CHECK` | `false` | When set to `false`, checks if the image tag already exists and skips download/build if present. Set to `true` to force building all tags regardless of remote registry status. |

---

## 🛡 Security & Trivy Scanning

During build execution, images are scanned using [Trivy](https://github.com/aquasecurity/trivy):
- **SBOM Generation**: Exported in SPDX-JSON format (`trivy-reports/sbom-<tag>.json`) and saved to GitHub Actions Job Artifacts (`debian-sbom-reports`).
- **Vulnerability Logging**: Vulnerabilities (UNKNOWN, LOW, MEDIUM, HIGH, CRITICAL) are logged to build stdout. Scans execute with `--exit-code 0`, ensuring pipeline continuity regardless of identified CVEs.

---

## ⚙️ Repository Structure

```text
.
├── .github/workflows/
│   ├── build-and-push.yml        # Automated CI pipeline for building, testing, scanning, and pushing to Docker Hub & GHCR
│   └── auto-discover-debian.yml  # Weekly cron workflow for discovering new Debian point releases and opening PRs
├── build.sh                       # Script for automatic import, Trivy scanning, and version verification
├── discover_new_releases.py       # Python scanner for checking cloud.debian.org for new point releases
├── releases.txt                   # Registry of URLs with rootfs versions
└── README.md                      # Project documentation
```

---

## 🔐 GitHub Actions Secrets

The CI workflow requires the following secrets in GitHub Secrets:
- `DOCKERHUB_USERNAME`: Your Docker Hub username (`runalsh`)
- `DOCKERHUB_TOKEN`: Docker Hub Personal Access Token
- `${{ secrets.GITHUB_TOKEN }}`: Automatically provided by GitHub for GHCR publishing
