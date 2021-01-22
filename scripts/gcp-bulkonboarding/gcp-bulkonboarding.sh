#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"

############################################################################
FILES=(Projectbased-onboard-prerequisites.sh add-sa-in-iam.sh apis.json create-sa.sh enable-api.sh permissions.json promote-sa-to-org.sh)
status_check()
{
    # status check for each file to download
    if [[ "$status" -eq 0 ]]; then
        echo -e "${GREEN}Successfully downloaded file.${NC}"
    else
        echo -e "${RED}Failed to download file:${NC} $api"
        exit 1
    fi
}

download_scripts()
{
echo ""
mkdir gcp-bulkonboarding
cd gcp-bulkonboarding
status=$?
if [[ "$statusSA" -eq 0 ]]; then
    $(wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/README.md)
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
    for file in "${FILES[@]}"
    do
        $(wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-onboard-prerequisites/$file)
        status=$?
        status_check
    done
else
    echo -e "${RED}Failed to create folder.${NC}"
    exit 1
fi
}
download_scripts