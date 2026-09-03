#!/bin/bash

set -o pipefail

# ============================================================
#                    SHINKAI BUILD SCRIPT
# ============================================================
#
# ROM      : Shinkai Project
# Device   : Xiaomi Mi 11 Lite 4G (courbet)
# Branch   : hekkaideka
#
# BUILD=false -> Sync only
# BUILD=true  -> Sync + clone trees + build + upload
#
# Telegram:
export TG_TOKEN="8613137322:AAH3ziSjfOmZqNM-5yh1H5csWFYJv0107KM"
export TG_CHAT_ID="7540957411"
#
# PixelDrain:
export PIXELDRAIN_API_KEY="4f177dc3-e153-4af6-b105-2d25e21740c5"
#
# ============================================================


# ============================================================
# ROM CONFIGURATION
# ============================================================

ROM_NAME="Shinkai"

ROM_URL="https://github.com/Shinkaiprjkt/manifest.git"
ROM_BRANCH="hekkaideka"

DEVICE="courbet"
BUILD_VARIANT="userdebug"

# ------------------------------------------------------------
# Build switch
# ------------------------------------------------------------

BUILD=false

# ============================================================
# ENVIRONMENT
# ============================================================

export TZ="Asia/Jakarta"

export BUILD_USERNAME="Aciss21"
export BUILD_HOSTNAME="crave"

# ============================================================
# TELEGRAM
# ============================================================

TELEGRAM=true

TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"

# ============================================================
# PIXELDRAIN
# ============================================================

PIXELDRAIN=true

PIXELDRAIN_API_KEY="${PIXELDRAIN_API_KEY:-}"

# ============================================================
# COLORS
# ============================================================

RESET='\033[0m'
RED='\033[31m'
GREEN='\033[32m'
YELLOW='\033[33m'
BLUE='\033[34m'
CYAN='\033[36m'
MAGENTA='\033[35m'
BOLD='\033[1m'


# ============================================================
# HELPER FUNCTIONS
# ============================================================

section() {

    echo
    echo -e "${CYAN}${BOLD}"
    echo "╔════════════════════════════════════════════════════════════╗"
    printf "║  %-56s║\n" "$1"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${RESET}"
}


info() {

    echo -e "${BLUE}ℹ${RESET} $1"
}


ok() {

    echo -e "${GREEN}✔${RESET} $1"
}


warn() {

    echo -e "${YELLOW}⚠${RESET} $1"
}


fail() {

    echo -e "${RED}✖${RESET} $1"
}


# ============================================================
# TELEGRAM FUNCTION
# ============================================================

send_telegram() {

    [[ "${TELEGRAM}" != "true" ]] && return 0
    [[ -z "${TG_TOKEN}" ]] && return 0
    [[ -z "${TG_CHAT_ID}" ]] && return 0

    local MESSAGE="$1"

    curl -fsS \
        --max-time 15 \
        -X POST \
        "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d "chat_id=${TG_CHAT_ID}" \
        --data-urlencode "text=${MESSAGE}" \
        >/dev/null 2>&1 || true
}


# ============================================================
# ERROR HANDLER
# ============================================================

error_handler() {

    local EXIT_CODE=$?

    fail "Script exited with status ${EXIT_CODE}"

    send_telegram \
        "❌ ${ROM_NAME} failed

Device: ${DEVICE}
Branch: ${ROM_BRANCH}
Status: Failed
Exit code: ${EXIT_CODE}"

    exit "${EXIT_CODE}"
}


trap error_handler ERR


# ============================================================
# BANNER
# ============================================================

banner() {

    clear 2>/dev/null || true

    echo -e "${CYAN}${BOLD}"

    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║                    S H I N K A I                           ║"
    echo "║                                                            ║"
    echo "║                 Automated Build Script                     ║"
    echo "║                                                            ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║  Device     : Xiaomi Mi 11 Lite 4G / courbet              ║"
    echo "║  Branch     : hekkaideka                                   ║"
    echo "║  Variant    : userdebug                                    ║"
    echo "║  Target     : m shinkai                                    ║"
    echo "║  Server     : Crave                                        ║"
    echo "╚════════════════════════════════════════════════════════════╝"

    echo -e "${RESET}"
}


# ============================================================
# DEPENDENCY CHECK
# ============================================================

check_dependencies() {

    section "Checking Dependencies"

    local MISSING=0

    for COMMAND in git repo curl; do

        if command -v "${COMMAND}" >/dev/null 2>&1; then

            ok "${COMMAND}: $(command -v "${COMMAND}")"

        else

            fail "${COMMAND} is not installed"

            MISSING=1

        fi

    done

    if [[ "${MISSING}" -eq 1 ]]; then

        fail "Missing required dependencies"

        exit 1

    fi

    ok "Dependencies ready"
}


# ============================================================
# CRAVE CHECK
# ============================================================

check_crave() {

    section "Checking Crave Environment"

    if [[ -x "/opt/crave/resync.sh" ]]; then

        ok "Crave resync detected"

    else

        warn "/opt/crave/resync.sh not found"
        warn "Fallback to repo sync will be used"

    fi
}


# ============================================================
# WORKSPACE CHECK
# ============================================================

check_workspace() {

    section "Checking Workspace"

    if [[ ! -w "." ]]; then

        fail "Current directory is not writable"

        exit 1

    fi

    if [[ -d ".repo" ]]; then

        info "Existing repo workspace detected"

    else

        info "Fresh repo workspace"

    fi

    ok "Workspace ready"
}


# ============================================================
# TELEGRAM CHECK
# ============================================================

check_telegram() {

    if [[ "${TELEGRAM}" != "true" ]]; then

        warn "Telegram notifications disabled"

        return 0

    fi

    if [[ -z "${TG_TOKEN}" || -z "${TG_CHAT_ID}" ]]; then

        warn "Telegram credentials are not set"
        warn "Telegram notifications disabled"

        return 0

    fi

    ok "Telegram notifications enabled"
}


# ============================================================
# PIXELDRAIN CHECK
# ============================================================

check_pixeldrain() {

    if [[ "${PIXELDRAIN}" != "true" ]]; then

        warn "PixelDrain upload disabled"

        return 0

    fi

    if [[ -z "${PIXELDRAIN_API_KEY}" ]]; then

        warn "PixelDrain API key is not set"
        warn "PixelDrain upload disabled"

        return 0

    fi

    ok "PixelDrain upload enabled"
}


# ============================================================
# START NOTIFICATION
# ============================================================

notify_start() {

    send_telegram \
        "🚀 ${ROM_NAME} build started

Device: ${DEVICE}
Branch: ${ROM_BRANCH}
Variant: ${BUILD_VARIANT}
Build mode: ${BUILD}"

}


# ============================================================
# REPO INIT
# ============================================================

repo_init() {

    section "Initializing ${ROM_NAME}"

    info "Manifest: ${ROM_URL}"
    info "Branch:   ${ROM_BRANCH}"

    repo init \
        --depth=1 \
        -u "${ROM_URL}" \
        -b "${ROM_BRANCH}" \
        --git-lfs

    ok "${ROM_NAME} repository initialized"
}


# ============================================================
# SOURCE SYNC
# ============================================================

sync_source() {

    section "Syncing ${ROM_NAME} Source"

    local SYNC_START
    local SYNC_END
    local SYNC_SECONDS
    local SYNC_MINUTES

    SYNC_START=$(date +%s)

    if [[ -x "/opt/crave/resync.sh" ]]; then

        info "Using Crave resync"

        if /opt/crave/resync.sh; then

            ok "Crave resync completed"

        else

            warn "Crave resync failed"
            warn "Falling back to repo sync"

            repo sync \
                --force-sync \
                --no-clone-bundle \
                --no-tags

        fi

    else

        warn "Crave resync not found"
        info "Using repo sync"

        repo sync \
            --force-sync \
            --no-clone-bundle \
            --no-tags

    fi

    SYNC_END=$(date +%s)

    SYNC_SECONDS=$((SYNC_END - SYNC_START))
    SYNC_MINUTES=$((SYNC_SECONDS / 60))

    ok "Source sync completed"
    info "Sync time: ${SYNC_MINUTES} minutes"

    send_telegram \
        "📥 ${ROM_NAME} source synced

Device: ${DEVICE}
Branch: ${ROM_BRANCH}
Sync time: ${SYNC_MINUTES} minutes

Source is ready."

}


# ============================================================
# CLONE DEVICE TREES
# ============================================================

clone_trees() {

    section "Cloning Courbet Device Trees"


    # --------------------------------------------------------
    # Device Common
    # --------------------------------------------------------

    info "Cloning device Xiaomi SM6150 common"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/device_xiaomi_sm6150-common.git \
        device/xiaomi/sm6150-common


    # --------------------------------------------------------
    # Vendor Common
    # --------------------------------------------------------

    info "Cloning vendor Xiaomi SM6150 common"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/vendor_xiaomi_sm6150-common.git \
        vendor/xiaomi/sm6150-common


    # --------------------------------------------------------
    # Device
    # --------------------------------------------------------

    info "Cloning Courbet device tree"

    git clone \
        --depth=1 \
        -b shin \
        https://github.com/Aciss21/device_xiaomi_courbet.git \
        device/xiaomi/courbet


    # --------------------------------------------------------
    # Vendor
    # --------------------------------------------------------

    info "Cloning Courbet vendor"

    git clone \
        --depth=1 \
        -b 16.2 \
        https://github.com/Aciss21/vendor_xiaomi_courbet.git \
        vendor/xiaomi/courbet


    # --------------------------------------------------------
    # Kernel
    # --------------------------------------------------------

    info "Cloning SM6150 kernel"

    git clone \
        --depth=1 \
        -b 16 \
        https://github.com/Aciss21/kernel_xiaomi_sm6150.git \
        kernel/xiaomi/sm6150


    # --------------------------------------------------------
    # Xiaomi Hardware
    # --------------------------------------------------------

    info "Cloning Xiaomi hardware"

    git clone \
        --depth=1 \
        -b lineage-23.2 \
        https://github.com/LineageOS/android_hardware_xiaomi.git \
        hardware/xiaomi


    # --------------------------------------------------------
    # MIUI Camera
    # --------------------------------------------------------

    info "Cloning MIUI Camera"

    git clone \
        --depth=1 \
        -b 16 \
        https://github.com/Aciss21/vendor_miuicamera-courbet.git \
        vendor/miuicamera-courbet


    # --------------------------------------------------------
    # Sony Dolby
    # --------------------------------------------------------

    info "Cloning Sony Dolby vendor"

    git clone \
        --depth=1 \
        https://github.com/manipvlator/proprietary_vendor_sony_dolby.git \
        vendor/sony/dolby


    # --------------------------------------------------------
    # Lunaris Dolby
    # --------------------------------------------------------

    info "Cloning Lunaris Dolby"

    git clone \
        --depth=1 \
        https://github.com/manipvlator/android_packages_apps_LunarisDolby.git \
        packages/apps/LunarisDolby


    ok "All device trees cloned"
}


# ============================================================
# TREE CHECK
# ============================================================

check_trees() {

    section "Checking Device Trees"

    local FAILED=0

    local PATHS=(

        "device/xiaomi/sm6150-common"
        "device/xiaomi/courbet"

        "vendor/xiaomi/sm6150-common"
        "vendor/xiaomi/courbet"

        "kernel/xiaomi/sm6150"

        "hardware/xiaomi"

        "vendor/miuicamera-courbet"

        "vendor/sony/dolby"

        "packages/apps/LunarisDolby"

    )


    for TREE in "${PATHS[@]}"; do

        if [[ -d "${TREE}" ]]; then

            ok "${TREE}"

        else

            fail "${TREE}"

            FAILED=1

        fi

    done


    if [[ "${FAILED}" -eq 1 ]]; then

        fail "One or more device trees are missing"

        exit 1

    fi


    ok "All required trees are present"
}


# ============================================================
# BUILD ENVIRONMENT
# ============================================================

setup_build_environment() {

    section "Loading Build Environment"

    if [[ ! -f "build/envsetup.sh" ]]; then

        fail "build/envsetup.sh not found"

        exit 1

    fi

    source build/envsetup.sh

    ok "Build environment loaded"
}


# ============================================================
# BREAKFAST
# ============================================================

breakfast_device() {

    section "Configuring Device"

    info "Running: breakfast ${DEVICE}"

    breakfast "${DEVICE}"

    ok "Device configured"
}


# ============================================================
# BUILD
# ============================================================

build_rom() {

    section "Building ${ROM_NAME}"

    local BUILD_START
    local BUILD_END
    local BUILD_SECONDS
    local BUILD_MINUTES

    BUILD_START=$(date +%s)


    send_telegram \
        "🔨 ${ROM_NAME} compilation started

Device: ${DEVICE}
Target: m shinkai"


    info "Target: m shinkai"


    if m shinkai; then

        BUILD_END=$(date +%s)

        BUILD_SECONDS=$((BUILD_END - BUILD_START))
        BUILD_MINUTES=$((BUILD_SECONDS / 60))


        ok "${ROM_NAME} build successful"

        info "Build time: ${BUILD_MINUTES} minutes"


        send_telegram \
            "✅ ${ROM_NAME} build successful

Device: ${DEVICE}
Target: m shinkai
Build time: ${BUILD_MINUTES} minutes"


    else

        BUILD_END=$(date +%s)

        BUILD_SECONDS=$((BUILD_END - BUILD_START))
        BUILD_MINUTES=$((BUILD_SECONDS / 60))


        fail "${ROM_NAME} build failed"

        info "Build time: ${BUILD_MINUTES} minutes"


        send_telegram \
            "❌ ${ROM_NAME} build failed

Device: ${DEVICE}
Target: m shinkai
Build time: ${BUILD_MINUTES} minutes"


        exit 1

    fi
}


# ============================================================
# FIND ARTIFACT
# ============================================================

find_artifact() {

    section "Searching Build Artifact"

    local PRODUCT_DIR="out/target/product/${DEVICE}"

    if [[ ! -d "${PRODUCT_DIR}" ]]; then

        warn "Product directory not found:"
        warn "${PRODUCT_DIR}"

        return 0

    fi


    local FOUND=0


    while IFS= read -r FILE; do

        FOUND=1

        local NAME
        local SIZE

        NAME=$(basename "${FILE}")
        SIZE=$(du -h "${FILE}" | cut -f1)


        ok "Found: ${NAME}"

        info "Size: ${SIZE}"
        info "Path: ${FILE}"


    done < <(

        find "${PRODUCT_DIR}" \
            -maxdepth 1 \
            -type f \
            -name "*.zip" \
            ! -name "*target_files*" \
            ! -name "*ota*" \
            -print

    )


    if [[ "${FOUND}" -eq 0 ]]; then

        warn "No ROM ZIP found"

    fi
}


# ============================================================
# PIXELDRAIN UPLOAD
# ============================================================

upload_pixeldrain() {

    section "Uploading to PixelDrain"


    if [[ "${PIXELDRAIN}" != "true" ]]; then

        warn "PixelDrain upload disabled"

        return 0

    fi


    if [[ -z "${PIXELDRAIN_API_KEY}" ]]; then

        warn "PixelDrain API key is not configured"

        return 0

    fi


    local PRODUCT_DIR="out/target/product/${DEVICE}"

    if [[ ! -d "${PRODUCT_DIR}" ]]; then

        warn "Product directory does not exist"

        return 0

    fi


    local ROM_ZIP


    ROM_ZIP=$(find "${PRODUCT_DIR}" \
        -maxdepth 1 \
        -type f \
        -name "*.zip" \
        ! -name "*target_files*" \
        ! -name "*ota*" \
        -printf '%T@ %p\n' |
        sort -nr |
        head -n1 |
        cut -d' ' -f2-)


    if [[ -z "${ROM_ZIP}" ]]; then

        warn "No ROM ZIP found for upload"

        send_telegram \
            "⚠️ ${ROM_NAME}

Build completed but no ROM ZIP was found for PixelDrain upload."

        return 0

    fi


    local FILE_NAME
    local FILE_SIZE


    FILE_NAME=$(basename "${ROM_ZIP}")
    FILE_SIZE=$(du -h "${ROM_ZIP}" | cut -f1)


    info "File: ${FILE_NAME}"
    info "Size: ${FILE_SIZE}"
    info "Uploading..."


    send_telegram \
        "⬆️ Uploading ${ROM_NAME}

File: ${FILE_NAME}
Size: ${FILE_SIZE}
Destination: PixelDrain"


    local RESPONSE


    RESPONSE=$(curl \
        --fail-with-body \
        --progress-bar \
        --max-time 0 \
        -X POST \
        -u ":${PIXELDRAIN_API_KEY}" \
        -F "file=@${ROM_ZIP}" \
        "https://pixeldrain.com/api/file/")


    local FILE_ID


    FILE_ID=$(echo "${RESPONSE}" |
        sed -n 's/.*"id":"\([^"]*\)".*/\1/p')


    if [[ -z "${FILE_ID}" ]]; then

        fail "PixelDrain upload failed"

        echo "${RESPONSE}"


        send_telegram \
            "❌ PixelDrain upload failed

File: ${FILE_NAME}
Device: ${DEVICE}"

        return 0

    fi


    local PIXELDRAIN_URL

    PIXELDRAIN_URL="https://pixeldrain.com/u/${FILE_ID}"


    ok "PixelDrain upload successful"

    info "File ID: ${FILE_ID}"
    info "URL: ${PIXELDRAIN_URL}"


    send_telegram \
        "📦 ${ROM_NAME} uploaded successfully

Device: ${DEVICE}
File: ${FILE_NAME}
Size: ${FILE_SIZE}

🔗 ${PIXELDRAIN_URL}"


    export PIXELDRAIN_URL
}


# ============================================================
# FINISH
# ============================================================

finish() {

    local JOB_END
    local JOB_SECONDS
    local JOB_MINUTES


    JOB_END=$(date +%s)

    JOB_SECONDS=$((JOB_END - JOB_START))
    JOB_MINUTES=$((JOB_SECONDS / 60))


    section "Job Complete"


    if [[ "${BUILD}" == "true" ]]; then

        ok "${ROM_NAME} build completed"

    else

        ok "${ROM_NAME} source sync completed"

    fi


    info "Device: ${DEVICE}"
    info "Branch: ${ROM_BRANCH}"
    info "Total time: ${JOB_MINUTES} minutes"


    echo


    if [[ "${BUILD}" == "false" ]]; then

        echo -e "${GREEN}${BOLD}"

        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                                                            ║"
        echo "║              SHINKAI SYNC COMPLETE                         ║"
        echo "║                                                            ║"
        echo "╚════════════════════════════════════════════════════════════╝"

        echo -e "${RESET}"


        echo

        info "Source is ready."
        info "Next: adapt/clone the Courbet device trees."


        send_telegram \
            "📥 ${ROM_NAME} sync complete

Device: ${DEVICE}
Branch: ${ROM_BRANCH}

Source is ready for device tree adaptation."


    else

        echo -e "${GREEN}${BOLD}"

        echo "╔════════════════════════════════════════════════════════════╗"
        echo "║                                                            ║"
        echo "║                 SHINKAI COMPLETE                           ║"
        echo "║                                                            ║"
        echo "╚════════════════════════════════════════════════════════════╝"

        echo -e "${RESET}"

    fi
}


# ============================================================
# MAIN
# ============================================================

banner

check_dependencies
check_crave
check_workspace

check_telegram
check_pixeldrain

JOB_START=$(date +%s)

notify_start

repo_init
sync_source


# ============================================================
# SYNC ONLY MODE
# ============================================================

if [[ "${BUILD}" != "true" ]]; then

    finish

    exit 0

fi


# ============================================================
# BUILD MODE
# ============================================================

clone_trees

check_trees

setup_build_environment

breakfast_device

build_rom

find_artifact

upload_pixeldrain

finish