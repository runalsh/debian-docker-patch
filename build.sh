#!/bin/bash
set -euo pipefail

# Ensure required dependencies are installed (for Ubuntu / Debian host)
if command -v apt-get &>/dev/null; then
    MISSING_PKGS=()
    command -v curl &>/dev/null || MISSING_PKGS+=("curl")
    command -v docker &>/dev/null || MISSING_PKGS+=("docker.io")
    command -v tar &>/dev/null || MISSING_PKGS+=("tar")
    command -v xz &>/dev/null || MISSING_PKGS+=("xz-utils")

    if [ ${#MISSING_PKGS[@]} -gt 0 ]; then
        echo "Installing missing dependencies: ${MISSING_PKGS[*]}..."
        SUDO_CMD=""
        if [ "$(id -u)" -ne 0 ] && command -v sudo &>/dev/null; then
            SUDO_CMD="sudo"
        fi
        $SUDO_CMD apt-get update -qq && $SUDO_CMD apt-get install -y -qq "${MISSING_PKGS[@]}"
    fi
fi

IMAGE_NAME="runalsh/debian-patch"
RELEASES_FILE="releases.txt"
MISMATCHED_TAGS=()

if [ ! -f "$RELEASES_FILE" ]; then
    echo "Error: $RELEASES_FILE not found!"
    exit 1
fi

# Pre-cleanup temporary files from previous runs
rm -f temp_rootfs_*.tar.xz /tmp/temp_rootfs_*.tar.xz
mkdir -p trivy-reports

echo "Starting process for image repository: ${IMAGE_NAME}"

OVERALL_LATEST=$(sort -V "$RELEASES_FILE" | tail -n 1 | awk '{print $1}')

while read -r tag url || [ -n "$tag" ]; do
    [[ -z "$tag" || "$tag" =~ ^# ]] && continue

    echo "=========================================="
    echo "Processing tag: ${tag}"
    echo "URL: ${url}"
    echo "=========================================="

    FULL_IMAGE_TAG="${IMAGE_NAME}:${tag}"
    GHCR_IMAGE_NAME="ghcr.io/$(echo "${IMAGE_NAME}" | tr '[:upper:]' '[:lower:]')"
    FULL_GHCR_TAG="${GHCR_IMAGE_NAME}:${tag}"

    MAJOR_VER=$(echo "${tag}" | cut -d'.' -f1)
    LATEST_IN_TRACK=$(grep -E "^${MAJOR_VER}\." "$RELEASES_FILE" | sort -V | tail -n 1 | awk '{print $1}')
    
    IS_LATEST_MAJOR=false
    if [ "$tag" = "$LATEST_IN_TRACK" ]; then
        IS_LATEST_MAJOR=true
        echo "Tag ${tag} is latest for Debian ${MAJOR_VER} track. Will automatically tag as major ${MAJOR_VER} & codename alias!"
    fi

    IS_OVERALL_LATEST=false
    if [ "$tag" = "$OVERALL_LATEST" ]; then
        IS_OVERALL_LATEST=true
        echo "Tag ${tag} is overall latest. Will tag as latest!"
    fi

    TARGET_ARG="${1:-all}"
    if [ "$TARGET_ARG" != "all" ] && [ "$TARGET_ARG" != "$tag" ]; then
        continue
    fi

    NEEDS_DOCKERHUB_PUSH=false
    NEEDS_GHCR_PUSH=false

    if [ "${SKIP_EXISTS_CHECK:-false}" = "true" ] || [ "${CHECK_REMOTE_TAGS:-true}" = "false" ]; then
        echo "SKIP_EXISTS_CHECK is true (or CHECK_REMOTE_TAGS is false). Forcing build and push for ${tag}..."
        [ "${PUSH_TO_DOCKERHUB:-false}" = "true" ] && NEEDS_DOCKERHUB_PUSH=true
        [ "${PUSH_TO_GHCR:-false}" = "true" ] && NEEDS_GHCR_PUSH=true
    else
        if [ "${PUSH_TO_DOCKERHUB:-false}" = "true" ]; then
            if ! docker manifest inspect "${FULL_IMAGE_TAG}" &>/dev/null && ! curl -sfSL "https://hub.docker.com/v2/repositories/${IMAGE_NAME}/tags/${tag}/" &>/dev/null; then
                echo "Tag ${FULL_IMAGE_TAG} missing on Docker Hub."
                NEEDS_DOCKERHUB_PUSH=true
            else
                echo "Tag ${FULL_IMAGE_TAG} exists on Docker Hub."
            fi
        fi

        if [ "${PUSH_TO_GHCR:-false}" = "true" ]; then
            if ! docker manifest inspect "${FULL_GHCR_TAG}" &>/dev/null; then
                echo "Tag ${FULL_GHCR_TAG} missing on GHCR."
                NEEDS_GHCR_PUSH=true
            else
                echo "Tag ${FULL_GHCR_TAG} exists on GHCR."
            fi
        fi

        if [ "${NEEDS_DOCKERHUB_PUSH}" = "false" ] && [ "${NEEDS_GHCR_PUSH}" = "false" ]; then
            if [ "${PUSH_TO_DOCKERHUB:-false}" = "true" ] || [ "${PUSH_TO_GHCR:-false}" = "true" ]; then
                echo "Tag ${tag} already exists on all enabled remote registries. Skipping download and build!"
                echo
                continue
            fi
        fi
    fi

    TAR_FILE="/tmp/temp_rootfs_${tag}.tar.xz"
    CREATED_TAGS=("${FULL_IMAGE_TAG}")

    cleanup_iteration() {
        rm -f "${TAR_FILE:-}"
        if [ "${CLEANUP_DOCKER_IMAGES:-true}" = "true" ] && [ ${#CREATED_TAGS[@]} -gt 0 ]; then
            for img_tag in "${CREATED_TAGS[@]}"; do
                docker rmi -f "${img_tag}" 2>/dev/null || true
            done
        fi
    }
    trap cleanup_iteration EXIT INT TERM HUP

    echo "1. Downloading image archive..."
    curl -fSL -sS --show-error -o "${TAR_FILE}" "${url}"

    echo "2. Extracting and optimizing rootfs (excluding kernel, modules, grub, caches, docs)..."
    ABS_TAR_PATH="${TAR_FILE}"
    docker run --rm --privileged -v "${ABS_TAR_PATH}:/work/rootfs.tar.xz:ro" alpine sh -c '
        apk add --no-cache tar xz 7zip >/dev/null 2>&1
        mkdir -p /tmp/parts /tmp/mount_rootfs
        tar -xf /work/rootfs.tar.xz -C /tmp/parts
        7z x /tmp/parts/disk.raw -o/tmp/parts 0.img -y >/dev/null 2>&1 || true
        if [ -f /tmp/parts/0.img ]; then
            mount -o loop,ro /tmp/parts/0.img /tmp/mount_rootfs
        else
            mount -o loop,ro /tmp/parts/disk.raw /tmp/mount_rootfs
        fi
        tar -C /tmp/mount_rootfs             --exclude="./usr/lib/modules"             --exclude="./lib/modules"             --exclude="./boot/vmlinuz*"             --exclude="./boot/initrd*"             --exclude="./boot/System.map*"             --exclude="./boot/config*"             --exclude="./usr/lib/grub"             --exclude="./boot/grub"             --exclude="./etc/grub.d"             --exclude="./var/cache/apt/*"             --exclude="./var/lib/apt/lists/*"             --exclude="./usr/share/doc/*"             --exclude="./usr/share/man/*"             --exclude="./usr/share/info/*"             --exclude="./tmp/*"             --exclude="./var/log/*"             --exclude="./var/tmp/*"             -c .
        umount /tmp/mount_rootfs
    ' | docker import       -c 'ENV LANG=C.UTF-8'       -c 'CMD ["/bin/bash"]'       - "${FULL_IMAGE_TAG}"

    rm -f "${TAR_FILE}"

    if [ "${TEST_VERSION:-true}" = "true" ]; then
        echo "3. Verifying container functionality and version in /etc/debian_version & /etc/os-release..."
        DEBIAN_VER=$(docker run --rm "${FULL_IMAGE_TAG}" cat /etc/debian_version 2>/dev/null || echo "")
        OS_RELEASE=$(docker run --rm "${FULL_IMAGE_TAG}" cat /etc/os-release 2>/dev/null || echo "")
        echo "/etc/debian_version: ${DEBIAN_VER}"
        echo "/etc/os-release:"
        echo "$OS_RELEASE"

        IS_MISMATCH=false
        if [ "$DEBIAN_VER" = "$tag" ]; then
            echo "SUCCESS: Exact version match '${DEBIAN_VER}' in /etc/debian_version!"
        else
            echo "ERROR: Version mismatch! Container /etc/debian_version is '${DEBIAN_VER}', expected '${tag}'!"
            MISMATCHED_TAGS+=("${tag} (found ${DEBIAN_VER:-unknown})")
            IS_MISMATCH=true
        fi

        if [ "$IS_MISMATCH" = "true" ]; then
            echo "Skipping push for mismatched tag ${tag}."
            rm -f "${TAR_FILE}"
            echo
            continue
        fi
    else
        echo "3. Skipping version verification (TEST_VERSION is false)."
    fi

    if command -v trivy &>/dev/null || [ "${ENABLE_TRIVY_SCAN:-false}" = "true" ]; then
        echo "4. Generating Trivy SBOM and vulnerability files..."
        trivy image --format spdx-json --output "trivy-reports/sbom-${tag}.json" "${FULL_IMAGE_TAG}" 2>/dev/null || true
        trivy image --format json --output "trivy-reports/vulnerabilities-${tag}.json" "${FULL_IMAGE_TAG}" 2>/dev/null || true
    fi

    if [ "${NEEDS_DOCKERHUB_PUSH}" = "true" ] || [ "${PUSH_TO_DOCKERHUB:-false}" = "true" ]; then
        echo "5. Pushing image to Docker Hub (${FULL_IMAGE_TAG})..."
        docker push "${FULL_IMAGE_TAG}" || true
        
        if [ "$IS_LATEST_MAJOR" = "true" ]; then
            MAJOR_TAG="${IMAGE_NAME}:${MAJOR_VER}"
            echo "Pushing major alias tag to Docker Hub (${MAJOR_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${MAJOR_TAG}"
            CREATED_TAGS+=("${MAJOR_TAG}")
            docker push "${MAJOR_TAG}" || true

            CODENAME=$(docker run --rm "${FULL_IMAGE_TAG}" sh -c '. /etc/os-release 2>/dev/null && echo "$VERSION_CODENAME"' 2>/dev/null || echo "")
            if [ -n "$CODENAME" ]; then
                CODENAME_TAG="${IMAGE_NAME}:${CODENAME}"
                echo "Pushing codename alias tag to Docker Hub (${CODENAME_TAG})..."
                docker tag "${FULL_IMAGE_TAG}" "${CODENAME_TAG}"
                CREATED_TAGS+=("${CODENAME_TAG}")
                docker push "${CODENAME_TAG}" || true
            fi
        fi

        if [ "$IS_OVERALL_LATEST" = "true" ]; then
            LATEST_TAG="${IMAGE_NAME}:latest"
            echo "Pushing latest tag to Docker Hub (${LATEST_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${LATEST_TAG}"
            CREATED_TAGS+=("${LATEST_TAG}")
            docker push "${LATEST_TAG}" || true
        fi
    else
        echo "5. Skipping Docker Hub push."
    fi

    if [ "${NEEDS_GHCR_PUSH}" = "true" ] || [ "${PUSH_TO_GHCR:-false}" = "true" ]; then
        echo "6. Pushing image to GitHub Packages / GHCR (${FULL_GHCR_TAG})..."
        docker tag "${FULL_IMAGE_TAG}" "${FULL_GHCR_TAG}"
        CREATED_TAGS+=("${FULL_GHCR_TAG}")
        docker push "${FULL_GHCR_TAG}" || true

        if [ "$IS_LATEST_MAJOR" = "true" ]; then
            GHCR_MAJOR_TAG="${GHCR_IMAGE_NAME}:${MAJOR_VER}"
            echo "Pushing major alias tag to GHCR (${GHCR_MAJOR_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${GHCR_MAJOR_TAG}"
            CREATED_TAGS+=("${GHCR_MAJOR_TAG}")
            docker push "${GHCR_MAJOR_TAG}" || true

            if [ -n "$CODENAME" ]; then
                GHCR_CODENAME_TAG="${GHCR_IMAGE_NAME}:${CODENAME}"
                echo "Pushing codename alias tag to GHCR (${GHCR_CODENAME_TAG})..."
                docker tag "${FULL_IMAGE_TAG}" "${GHCR_CODENAME_TAG}"
                CREATED_TAGS+=("${GHCR_CODENAME_TAG}")
                docker push "${GHCR_CODENAME_TAG}" || true
            fi
        fi

        if [ "$IS_OVERALL_LATEST" = "true" ]; then
            GHCR_LATEST_TAG="${GHCR_IMAGE_NAME}:latest"
            echo "Pushing latest tag to GHCR (${GHCR_LATEST_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${GHCR_LATEST_TAG}"
            CREATED_TAGS+=("${GHCR_LATEST_TAG}")
            docker push "${GHCR_LATEST_TAG}" || true
        fi

        if [ "${CLEANUP_DOCKER_IMAGES:-true}" = "true" ]; then
            docker rmi -f "${FULL_GHCR_TAG}" 2>/dev/null || true
        fi
    else
        echo "6. Skipping GHCR push."
    fi

    echo "7. Cleaning up iteration artifacts and pruning all local Docker tags..."
    cleanup_iteration
    CREATED_TAGS=()

    echo "Successfully completed processing for tag ${tag}!"
    echo
done < "$RELEASES_FILE"

if [ ${#MISMATCHED_TAGS[@]} -gt 0 ]; then
    echo "=========================================="
    echo "SUMMARY: Version mismatches detected!"
    echo "The following tags failed verification:"
    for m in "${MISMATCHED_TAGS[@]}"; do
        echo "  - ${m}"
    done
    echo "=========================================="
    exit 1
else
    echo "All images processed and verified successfully!"
fi
