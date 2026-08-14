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

if [ ! -f "$RELEASES_FILE" ]; then
    echo "Error: $RELEASES_FILE not found!"
    exit 1
fi

mkdir -p trivy-reports

echo "Starting process for image repository: ${IMAGE_NAME}"

# Determine latest tags for track 12 and track 13
LATEST_12=$(grep -E "^12\." "$RELEASES_FILE" | sort -V | tail -n 1 | awk '{print $1}')
LATEST_13=$(grep -E "^13\." "$RELEASES_FILE" | sort -V | tail -n 1 | awk '{print $1}')
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
    
    IS_LATEST_MAJOR=false
    if [ "$MAJOR_VER" = "12" ] && [ "$tag" = "$LATEST_12" ]; then
        IS_LATEST_MAJOR=true
        echo "Tag ${tag} is latest for Debian 12. Will tag as 12 & bookworm!"
    elif [ "$MAJOR_VER" = "13" ] && [ "$tag" = "$LATEST_13" ]; then
        IS_LATEST_MAJOR=true
        echo "Tag ${tag} is latest for Debian 13. Will tag as 13 & trixie!"
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

    NEEDS_DOCKERHUB_PUSH=true
    NEEDS_GHCR_PUSH=true

    if [ "${CHECK_REMOTE_TAGS:-true}" = "true" ]; then
        if docker manifest inspect "${FULL_IMAGE_TAG}" &>/dev/null; then
            echo "Tag ${FULL_IMAGE_TAG} exists on Docker Hub."
            NEEDS_DOCKERHUB_PUSH=false
        else
            echo "Tag ${FULL_IMAGE_TAG} missing on Docker Hub."
        fi

        if docker manifest inspect "${FULL_GHCR_TAG}" &>/dev/null; then
            echo "Tag ${FULL_GHCR_TAG} exists on GHCR."
            NEEDS_GHCR_PUSH=false
        else
            echo "Tag ${FULL_GHCR_TAG} missing on GHCR."
        fi

        if [ "${NEEDS_DOCKERHUB_PUSH}" = "false" ] && [ "${NEEDS_GHCR_PUSH}" = "false" ]; then
            if [ "${PUSH_TO_DOCKERHUB:-false}" = "true" ] || [ "${PUSH_TO_GHCR:-false}" = "true" ]; then
                echo "Tag ${tag} already exists on all enabled remote registries. Skipping download and build!"
                echo
                continue
            fi
        fi
    fi

    TAR_FILE="temp_rootfs_${tag}.tar.xz"

    echo "1. Downloading image archive..."
    curl -fSL -o "${TAR_FILE}" "${url}"

    echo "2. Extracting rootfs and importing into Docker as ${FULL_IMAGE_TAG}..."
    ABS_TAR_PATH="$(pwd)/${TAR_FILE}"
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
        tar -C /tmp/mount_rootfs -c .
        umount /tmp/mount_rootfs
    ' | docker import - "${FULL_IMAGE_TAG}"

    rm -f "${TAR_FILE}"

    if [ "${TEST_VERSION:-true}" = "true" ]; then
        echo "3. Verifying container functionality and /etc/os-release version..."
        OS_RELEASE=$(docker run --rm "${FULL_IMAGE_TAG}" cat /etc/os-release)
        echo "$OS_RELEASE"

        if echo "$OS_RELEASE" | grep -q "${MAJOR_VER}"; then
            echo "SUCCESS: Version match found for Debian ${MAJOR_VER} in /etc/os-release!"
        else
            echo "ERROR: Version mismatch! Expected Debian ${MAJOR_VER} in /etc/os-release"
            exit 1
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
            docker push "${MAJOR_TAG}" || true

            CODENAME="bookworm"
            [ "$MAJOR_VER" = "13" ] && CODENAME="trixie"
            CODENAME_TAG="${IMAGE_NAME}:${CODENAME}"
            echo "Pushing codename alias tag to Docker Hub (${CODENAME_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${CODENAME_TAG}"
            docker push "${CODENAME_TAG}" || true
        fi

        if [ "$IS_OVERALL_LATEST" = "true" ]; then
            LATEST_TAG="${IMAGE_NAME}:latest"
            echo "Pushing latest tag to Docker Hub (${LATEST_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${LATEST_TAG}"
            docker push "${LATEST_TAG}" || true
        fi
    else
        echo "5. Skipping Docker Hub push."
    fi

    if [ "${NEEDS_GHCR_PUSH}" = "true" ] || [ "${PUSH_TO_GHCR:-false}" = "true" ]; then
        echo "6. Pushing image to GitHub Packages / GHCR (${FULL_GHCR_TAG})..."
        docker tag "${FULL_IMAGE_TAG}" "${FULL_GHCR_TAG}"
        docker push "${FULL_GHCR_TAG}" || true

        if [ "$IS_LATEST_MAJOR" = "true" ]; then
            GHCR_MAJOR_TAG="${GHCR_IMAGE_NAME}:${MAJOR_VER}"
            echo "Pushing major alias tag to GHCR (${GHCR_MAJOR_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${GHCR_MAJOR_TAG}"
            docker push "${GHCR_MAJOR_TAG}" || true

            CODENAME="bookworm"
            [ "$MAJOR_VER" = "13" ] && CODENAME="trixie"
            GHCR_CODENAME_TAG="${GHCR_IMAGE_NAME}:${CODENAME}"
            echo "Pushing codename alias tag to GHCR (${GHCR_CODENAME_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${GHCR_CODENAME_TAG}"
            docker push "${GHCR_CODENAME_TAG}" || true
        fi

        if [ "$IS_OVERALL_LATEST" = "true" ]; then
            GHCR_LATEST_TAG="${GHCR_IMAGE_NAME}:latest"
            echo "Pushing latest tag to GHCR (${GHCR_LATEST_TAG})..."
            docker tag "${FULL_IMAGE_TAG}" "${GHCR_LATEST_TAG}"
            docker push "${GHCR_LATEST_TAG}" || true
        fi

        if [ "${CLEANUP_DOCKER_IMAGES:-false}" = "true" ]; then
            docker rmi -f "${FULL_GHCR_TAG}" 2>/dev/null || true
        fi
    else
        echo "6. Skipping GHCR push."
    fi

    echo "7. Cleaning up local tarball..."
    rm -f "${TAR_FILE}"

    if [ "${CLEANUP_DOCKER_IMAGES:-false}" = "true" ]; then
        echo "Removing local Docker image ${FULL_IMAGE_TAG} to save disk space..."
        docker rmi -f "${FULL_IMAGE_TAG}" 2>/dev/null || true
    fi

    echo "Successfully completed processing for tag ${tag}!"
    echo
done < "$RELEASES_FILE"

echo "All images processed successfully!"
