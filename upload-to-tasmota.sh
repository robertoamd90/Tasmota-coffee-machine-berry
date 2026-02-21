#!/bin/zsh

# Script to upload .be files to Tasmota device
# Usage: ./upload-to-tasmota.sh [ip] [file1.be] [file2.be] ...
# Or: ./upload-to-tasmota.sh [ip] (uploads all .be files from src/)

# Enable globbing for zsh
setopt NULL_GLOB

# Output colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() { echo "${GREEN}✓ $1${NC}" }
print_error() { echo "${RED}✗ $1${NC}" }
print_info() { echo "${YELLOW}ℹ $1${NC}" }

# Check if IP was provided
if [ -z "$1" ]; then
    print_error "Tasmota device IP not provided"
    echo "Usage: $0 <ip> [file1.be file2.be ...]"
    echo "Examples:"
    echo "  $0 192.168.1.100                    # Upload all .be files from src/"
    echo "  $0 192.168.1.100 src/PowerMgmt.be   # Upload a specific file"
    echo "  $0 192.168.1.100 src/*.be            # Upload all .be files from src/"
    exit 1
fi

TASMOTA_IP=$1
shift

# Array for files to upload
declare -a files_to_upload

# If files were specified, use them
if [ $# -gt 0 ]; then
    files_to_upload=("$@")
else
    # Otherwise upload all .be files from src/
    files_to_upload=(src/*.be)
    if [ ${#files_to_upload[@]} -eq 0 ]; then
        print_error "No .be files found in src/"
        exit 1
    fi
    print_info "No files specified, uploading all .be files from src/"
fi

# URLs
UPLOAD_URL="http://${TASMOTA_IP}/ufsu"
DOWNLOAD_URL="http://${TASMOTA_IP}/ufsd"

# Counters
total=0
success=0
failed=0

# Temp dir for verification downloads
VERIFY_TMP=$(mktemp -d)
trap "rm -rf ${VERIFY_TMP}" EXIT

print_info "Starting upload to ${TASMOTA_IP}..."
echo ""

# Warm up the Tasmota filesystem before uploading (improves upload reliability)
print_info "Warming up filesystem..."
if curl -f -s "${DOWNLOAD_URL}?download=/" > /dev/null 2>&1; then
    print_success "Filesystem ready"
else
    print_error "Could not reach Tasmota at ${TASMOTA_IP}"
    exit 1
fi
echo ""

# Upload each file
for file in "${files_to_upload[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        ((failed++))
        ((total++))
        continue
    fi

    filename=$(basename "$file")
    ((total++))
    print_info "Uploading: $filename"

    # Upload (Tasmota uses only the basename, regardless of local path)
    if ! curl -f -s -F "ufsu=@${file};filename=${filename}" "${UPLOAD_URL}" > /dev/null 2>&1; then
        print_error "Upload failed: $filename"
        ((failed++))
        [ $total -lt ${#files_to_upload[@]} ] && sleep 0.5
        continue
    fi

    # Verify: download back and compare
    VERIFY_FILE="${VERIFY_TMP}/${filename}"
    if curl -f -s "${DOWNLOAD_URL}?download=/${filename}" -o "${VERIFY_FILE}" 2>&1; then
        if cmp -s "${file}" "${VERIFY_FILE}"; then
            print_success "Uploaded and verified: $filename"
            ((success++))
        else
            print_error "Verification failed (content mismatch): $filename"
            ((failed++))
        fi
    else
        print_error "Verification failed (download error): $filename"
        ((failed++))
    fi

    # Small pause between uploads
    [ $total -lt ${#files_to_upload[@]} ] && sleep 0.5
done

# Summary
echo ""
echo "========================================"
print_info "Upload summary:"
echo "  Total:     $total"
print_success "  Verified:  $success"
[ $failed -gt 0 ] && print_error "  Failed:    $failed"
echo "========================================"

# Exit with error code if there were failures
if [ $failed -gt 0 ]; then
    exit 1
fi

# Restart Tasmota only if all files uploaded and verified successfully
echo ""
print_info "All files verified. Restarting Tasmota device..."
if curl -f -s "http://${TASMOTA_IP}/cm?cmnd=Restart%201" > /dev/null 2>&1; then
    print_success "Restart command sent successfully"
    print_info "Device will restart in a few seconds..."
else
    print_error "Failed to send restart command"
    exit 1
fi

exit 0
