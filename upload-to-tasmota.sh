#!/bin/zsh

# Script to upload .be files to Tasmota device
# Usage: ./upload-to-tasmota.sh [ip] [file1.be] [file2.be] ...
# Or: ./upload-to-tasmota.sh [ip] (uploads all .be files in the folder)

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
    echo "  $0 192.168.1.100                    # Upload all .be files"
    echo "  $0 192.168.1.100 PowerMgmt.be       # Upload a specific file"
    echo "  $0 192.168.1.100 *.be               # Upload all .be files"
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
    # Otherwise upload all .be files in current directory
    files_to_upload=(*.be)
    if [ ${#files_to_upload[@]} -eq 0 ]; then
        print_error "No .be files found in current directory"
        exit 1
    fi
    print_info "No files specified, uploading all .be files found"
fi

# Upload URL
UPLOAD_URL="http://${TASMOTA_IP}/ufsu"

# Counters
total=0
success=0
failed=0

print_info "Starting upload to ${TASMOTA_IP}..."
echo ""

# Upload each file
for file in "${files_to_upload[@]}"; do
    if [ ! -f "$file" ]; then
        print_error "File not found: $file"
        ((failed++))
        ((total++))
        continue
    fi
    
    ((total++))
    print_info "Uploading: $file"
    
    # Execute curl and capture exit code
    if curl -f -s -F "ufsu=@${file}" "${UPLOAD_URL}" > /dev/null 2>&1; then
        print_success "Uploaded: $file"
        ((success++))
    else
        print_error "Upload error: $file"
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
print_success "  Success:   $success"
[ $failed -gt 0 ] && print_error "  Failed:    $failed"
echo "========================================"

# Exit with error code if there were failures
if [ $failed -gt 0 ]; then
    exit 1
fi

# Restart Tasmota if all uploads were successful
echo ""
print_info "Restarting Tasmota device..."
if curl -f -s "http://${TASMOTA_IP}/cm?cmnd=Restart%201" > /dev/null 2>&1; then
    print_success "Restart command sent successfully"
    print_info "Device will restart in a few seconds..."
else
    print_error "Failed to send restart command"
    exit 1
fi

exit 0
