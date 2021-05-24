#!/bin/bash

: '
SYNOPSIS
    Script to download ZCSPM gcp onboarding scripts
DESCRIPTION
    This script will download the scripts used for setting up the prerequisites for ZCSPM gcp project or organization onboarding
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    ./download-gcp-onboarding-scripts.sh
INPUTS
    None
OUTPUTS
    None
'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
############################################################################

FILES=(
        "create-service-account.sh"
        "assign-roles-to-service-account.sh"
        "gcp-apis.json"
        "zcspm-roles.json"
        "promote-service-account.sh"
    )

SCRIPT_REPO_URL="https://raw.githubusercontent.com/Cloudneeti/docs_cloudneeti/rahul/gcp-onboarding-scripts/scripts/gcp-onboarding/"

download_scripts()
{
    FILE_COUNT=0
    for file in "${FILES[@]}"
    do
        echo "Downloading $file" 
        http_status=$(wget $SCRIPT_REPO_URL/$file)
        exit_status=$?
        # status check for each file to download
        if [[ "$exit_status" -eq 0 ]]; then
            echo -e "${GREEN}Successfully downloaded file $file${NC}"
            ((FILE_COUNT+=1))
        else
            echo -e "${RED}Error occurred while downloading file $file${NC}"
        fi
    done

    # Checking all files are downloaded or not
    echo ""
    if [[ FILE_COUNT -eq ${#FILES[@]} ]]
    then
        echo -e "${GREEN}Successfully downloaded all the zcspm gcp onboarding scripts.${NC}"
    else
        echo -e "${RED}Error occurred while downloading zcspm gcp onboarding scripts.${NC}"
        echo -e "${RED}Please check error message and try again.${NC}"
    fi
}

# MAIN Execution
SCRIPT_DIR="zcspm-gcp-onboarding" 

# Create directory if not exists
echo "Creating $SCRIPT_DIR directory"
[ -d $SCRIPT_DIR ] || mkdir $SCRIPT_DIR 
cd $SCRIPT_DIR

# Download scripts
echo "Downloading ZCSPM gcp onboarding scripts"
download_scripts
