#!/bin/bash

set -Eeuo pipefail

# ============================================================
# Shinkai Project - Crave Build Script
# Device : Xiaomi Mi 11 Lite 4G (courbet)
# Branch : hekkaideka
# Build  : userdebug
# ============================================================

ROM_NAME="Shinkai"
ROM_URL="https://github.com/Shinkaiprjkt/manifest.git"
ROM_BRANCH="hekkaideka"

DEVICE="courbet"
BUILD_VARIANT="userdebug"

# ============================================================
# Environment
# ============================================================

export TZ="Asia/Jakarta"
export BUILD_USERNAME="Aciss21"
export BUILD_HOSTNAME="crave"

# ============================================================
# Telegram
# ============================================================

TELEGRAM="${TELEGRAM:-true}"
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

# ============================================================
# PixelDrain
# ============================================================

PIXELDRAIN="${PIXELDRAIN:-true}"
PIXELDRAIN_API_KEY="${PIXELDRAIN_API_KEY:-}"

# ============================================================
# Colors
# ============================================================

cyan='\033[0;36m'
green='\033[0;32m'
yellow='\033[1;33m'
red='\033[0;31m'
reset='\033[0m'

info() {
    echo -e "${cyan}ℹ ${1}${reset}"
}

ok() {
    echo -e "${green}✔ ${1}${reset}"
}

warn() {
    echo -e "${yellow}⚠ ${1}${reset}"
}

error() {
    echo -e "${red}✖ ${1}${reset}"
}

section() {
    echo
    echo "============================================================"
    echo " ${1}"
    echo "============================================================"
    echo
}

# ============================================================
# Error Handler
# ============================================================

BUILD_START=$(date +%s)

on_error() {
    local exit_code=$?
    local line_no=$1

    error "Build failed"
    error "Exit code : ${exit_code}"
    error "Line      : ${line_no}"

    telegram_message \
        "❌ *Shinkai build failed*

Device: \`${DEVICE}\`
Branch: \`${ROM_BRANCH}\`
Variant: \`${BUILD_VARIANT}\`
Exit code: \`${exit_code}\`
Line: \`${line_no}\`"

    exit "${exit_code}"
}

trap 'on_error ${LINENO}' ERR

# ============================================================
# Telegram
# ============================================================

telegram_message() {
    [[ "${TELEGRAM}" == "true" ]] || return 0
    [[ -n "${TG_TOKEN}" ]] || return 0
    [[ -n "${TG_CHAT_ID}" ]] || return 0

    curl -fsS \
        --max-time 20 \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        --data-urlencode "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "parse_mode=Markdown" \
        --data-urlencode "text=${1}" \
        >/dev/null 2>&1 || true
}

# ============================================================
# Dependencies
# ============================================================

check_dependencies() {
    section "Checking Dependencies"

    local deps=(
        git
        repo
        curl
    )

    for cmd in "${deps[@]}"; do
        if command -v "${cmd}" >/dev/null 2>&1; then
            ok "${cmd}"
        else
            error "Missing dependency: ${cmd}"
            exit 1
        fi
    done
}

# ============================================================
# Crave Environment
# ============================================================

check_crave() {
    section "Checking Crave Environment"

    if [[ ! -x "/opt/crave/resync.sh" ]]; then
        error "/opt/crave/resync.sh not found"
        error "This script must run inside a Crave build job."
        error "Do NOT run repo sync directly inside Devspace."
        exit 1
    fi

    ok "Crave resync detected"
}

# ============================================================
# Workspace
# ============================================================

check_workspace() {
    section "Checking Workspace"

    if [[ ! -d ".repo" ]]; then
        info "Fresh repo workspace"
    else
        info "Existing repo workspace detected"
    fi

    ok "Workspace ready"

    if [[ "${TELEGRAM}" == "true" ]]; then
        ok "Telegram notifications enabled"
    else
        info "Telegram notifications disabled"
    fi

    if [[ "${PIXELDRAIN}" == "true" ]]; then
        ok "PixelDrain upload enabled"
    else
        info "PixelDrain upload disabled"
    fi
}

# ============================================================
# Repo Init
# ============================================================

repo_init() {
    section "Initializing ${ROM_NAME}"

    info "Manifest: ${ROM_URL}"
    info "Branch: ${ROM_BRANCH}"

    repo init \
        --depth=1 \
        -u "${ROM_URL}" \
        -b "${ROM_BRANCH}" \
        --git-lfs

    ok "${ROM_NAME} repository initialized"
}

# ============================================================
# Source Sync
# ============================================================

sync_source() {
    section "Syncing ${ROM_NAME} Source"

    info "Using Crave resync"

    /opt/crave/resync.sh

    ok "Shinkai source synced"
}

# ============================================================
# Device Trees
# ============================================================

clone_trees() {
    section "Cloning Courbet Device Trees"

    # --------------------------------------------------------
    # Device common
    # --------------------------------------------------------

    info "Cloning Xiaomi SM6150 common device tree"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/device_xiaomi_sm6150-common.git \
        device/xiaomi/sm6150-common

    ok "device/xiaomi/sm6150-common"

    # --------------------------------------------------------
    # Vendor common
    # --------------------------------------------------------

    info "Cloning Xiaomi SM6150 common vendor tree"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/vendor_xiaomi_sm6150-common.git \
        vendor/xiaomi/sm6150-common

    ok "vendor/xiaomi/sm6150-common"

    # --------------------------------------------------------
    # Device courbet
    # --------------------------------------------------------

    info "Cloning Xiaomi courbet device tree"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/device_xiaomi_courbet.git \
        device/xiaomi/courbet

    ok "device/xiaomi/courbet"

    # --------------------------------------------------------
    # Vendor courbet
    # --------------------------------------------------------

    info "Cloning Xiaomi courbet vendor tree"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/vendor_xiaomi_courbet.git \
        vendor/xiaomi/courbet

    ok "vendor/xiaomi/courbet"

    # --------------------------------------------------------
    # Kernel
    # --------------------------------------------------------

    info "Cloning Xiaomi SM6150 kernel"

    git clone \
        --depth=1 \
        -b 16 \
        https://github.com/Aciss21/kernel_xiaomi_sm6150.git \
        kernel/xiaomi/sm6150

    ok "kernel/xiaomi/sm6150"

    # --------------------------------------------------------
    # Hardware Xiaomi
    # --------------------------------------------------------

    info "Cloning Xiaomi hardware"

    git clone \
        --depth=1 \
        -b lineage-23.2 \
        https://github.com/LineageOS/android_hardware_xiaomi.git \
        hardware/xiaomi

    ok "hardware/xiaomi"

    # --------------------------------------------------------
    # MIUI Camera
    # --------------------------------------------------------

    info "Cloning MIUI Camera"

    git clone \
        --depth=1 \
        -b 16 \
        https://github.com/Aciss21/vendor_miuicamera-courbet.git \
        vendor/miuicamera-courbet

    ok "vendor/miuicamera-courbet"

    # --------------------------------------------------------
    # Sony Dolby blobs
    # --------------------------------------------------------

    info "Cloning Sony Dolby vendor"

    git clone \
        --depth=1 \
        https://github.com/manipvlator/proprietary_vendor_sony_dolby.git \
        vendor/sony/dolby

    ok "vendor/sony/dolby"

    # --------------------------------------------------------
    # Lunaris Dolby
    # --------------------------------------------------------

    info "Cloning Lunaris Dolby"

    git clone \
        --depth=1 \
        https://github.com/manipvlator/android_packages_apps_LunarisDolby.git \
        packages/apps/LunarisDolby

    ok "packages/apps/LunarisDolby"

    ok "All Courbet device trees cloned"
}

# ============================================================
# Build
# ============================================================

build_rom() {
    section "Building ${ROM_NAME}"

    info "Device  : ${DEVICE}"
    info "Variant : ${BUILD_VARIANT}"
    info "Target  : m shinkai"

    source build/envsetup.sh

    ok "Build environment initialized"

    breakfast "${DEVICE}"

    ok "Breakfast completed"

    telegram_message \
        "🚀 *Shinkai build started*

Device: \`${DEVICE}\`
Branch: \`${ROM_BRANCH}\`
Variant: \`${BUILD_VARIANT}\`
Target: \`m shinkai\`"

    m shinkai
}

# ============================================================
# Find Build Output
# ============================================================

find_build_output() {
    section "Searching Build Output"

    local product_dir="out/target/product/${DEVICE}"

    if [[ ! -d "${product_dir}" ]]; then
        error "Product directory not found: ${product_dir}"
        return 1
    fi

    BUILD_ZIP=$(find "${product_dir}" \
        -maxdepth 1 \
        -type f \
        \( \
            -iname "*.zip" \
            -o \
            -iname "*.img" \
        \) \
        -printf '%T@ %p\n' \
        | sort -nr \
        | head -1 \
        | cut -d' ' -f2- || true)

    if [[ -z "${BUILD_ZIP}" ]]; then
        error "No build artifact found"
        return 1
    fi

    ok "Build artifact:"
    echo "${BUILD_ZIP}"
}

# ============================================================
# PixelDrain Upload
# ============================================================

upload_pixeldrain() {
    [[ "${PIXELDRAIN}" == "true" ]] || return 0

    section "Uploading To PixelDrain"

    if [[ -z "${PIXELDRAIN_API_KEY}" ]]; then
        warn "PixelDrain API key is not set"
        warn "Skipping upload"
        return 0
    fi

    if [[ -z "${BUILD_ZIP:-}" || ! -f "${BUILD_ZIP}" ]]; then
        warn "No valid build artifact"
        return 0
    fi

    info "Uploading: $(basename "${BUILD_ZIP}")"

    local response

    response=$(
        curl -fsS \
            --max-time 3600 \
            -T "${BUILD_ZIP}" \
            -u ":${PIXELDRAIN_API_KEY}" \
            "https://pixeldrain.com/api/file"
    )

    local file_id

    file_id=$(echo "${response}" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')

    if [[ -n "${file_id}" ]]; then
        local url="https://pixeldrain.com/u/${file_id}"

        ok "PixelDrain upload completed"
        info "${url}"

        telegram_message \
            "📦 *Shinkai build completed*

Device: \`${DEVICE}\`
Branch: \`${ROM_BRANCH}\`

Artifact:
\`$(basename "${BUILD_ZIP}")\`

PixelDrain:
${url}"

    else
        warn "PixelDrain upload finished but file ID could not be detected"
        telegram_message \
            "📦 *Shinkai build completed*

Device: \`${DEVICE}\`
Branch: \`${ROM_BRANCH}\`

Artifact:
\`$(basename "${BUILD_ZIP}")\`

PixelDrain upload response received."
    fi
}

# ============================================================
# Finish
# ============================================================

finish() {
    local build_end
    build_end=$(date +%s)

    local duration=$((build_end - BUILD_START))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))

    section "Build Complete"

    ok "Shinkai build completed"
    info "Device : ${DEVICE}"
    info "Branch : ${ROM_BRANCH}"
    info "Time   : ${minutes}m ${seconds}s"

    if [[ -n "${BUILD_ZIP:-}" ]]; then
        info "Output : ${BUILD_ZIP}"
    fi
}

# ============================================================
# Main
# ============================================================

main() {
    section "SHINKAI PROJECT"

    echo "Device : Xiaomi Mi 11 Lite 4G / ${DEVICE}"
    echo "Branch : ${ROM_BRANCH}"
    echo "Variant: ${BUILD_VARIANT}"
    echo "Target : m shinkai"
    echo "Server : Crave"

    check_dependencies
    check_crave
    check_workspace

    telegram_message \
        "📥 *Shinkai build job started*

Device: \`${DEVICE}\`
Branch: \`${ROM_BRANCH}\`
Variant: \`${BUILD_VARIANT}\`"

    repo_init
    sync_source
    clone_trees
    build_rom
    find_build_output
    upload_pixeldrain
    finish
}

main "$@"