#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"

############################################################################
status_check()
{
    # status check for each file to download
    if [[ "$status" -eq 0 ]]; then
        echo -e "${GREEN}Successfully downloaded file.${NC}"
    else
        echo -e "${RED}Failed to Enable APIs on:${NC} $api"
        exit 1
    fi
}
echo ""
mkdir gcp-bulkonboarding
cd gcp-bulkonboarding
status=$?
if [[ "$statusSA" -eq 0 ]]; then
    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/README.md
    status=$?
else
    echo -e "${RED}Failed to create folder.${NC}"
    exit 1
fi
echo ""
mkdir gcp-onboard-prerequisites
cd gcp-onboard-prerequisites
statusOnboard=$?
if [[ "$statusSA" -eq 0 ]]; then
    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/Projectbased-onboard-prerequisites.sh
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/add-sa-iam.sh
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/apis.json
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/create-sa.sh
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/enable-api.sh
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/permissions.json
    status=$?
    status_check

    wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/promote-sa-to-org.sh
    status=$?
    status_check
else
    echo -e "${RED}Failed to create folder.${NC}"
    exit 1
fi