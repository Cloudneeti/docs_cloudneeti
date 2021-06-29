#!/bin/bash

: '
SYNOPSIS
    Script to create service account, assign role to service account and enable APIs on projects.
DESCRIPTION
    This script will Create service account, assign role to service account and enable APIs single or multiple projects.
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    1. Create service account, assign role to service account and enable APIs on single or list of projects.
        ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -l <PROJECT_LIST>
    2. Create service account, assign role to service account and enable APIs on CSV file containing list of projects.
       ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -c <ALLOWED_PROJECT_LIST.CSV>
INPUTS
    (-h)Print this Help
    (-p)Project Id: GCP Project ID where Service Account gets created
    (-s)Service Account Name
    (-l)Single or comma separated list of GCP project ids (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    (-c)CSV file containing allowed list of GCP projects (.csv file) --> (>=10 projects)
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

# Function: Print a help message.
usage() {
    echo "Script to setup onboarding prerequisites on GCP Projects"
    echo ""
    echo "Syntax: $0 -p SERVICE_ACCOUNT_PROJECT_ID -s SERVICE_ACCOUNT_NAME [ -l PROJECT_LIST | -c ALLOWED_PROJECT_LIST.CSV ]"
    echo "Options:"
    echo "  -h    Print this Help"
    echo "  -p    GCP Project ID where Service Account gets created"
    echo "  -s    Service Account Name"
    echo "  -l    Single or comma separated list of GCP project ids (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)"
    echo "  -c    CSV file containing allowed list of GCP projects (>=10 projects)" 
}

exit_abnormal() {
  usage
  exit 1
}

#Check the number of arguments. If none are passed, print usage and exit.
NUMARGS=$#
if [ $NUMARGS -ne 6 ]; then
    exit_abnormal
fi

# flags
while getopts ":p:s:l:c:h:" options
do
    case "$options" in     
           
        p) # project ID to create a service account
           SERVICE_ACCOUNT_PROJECT_ID=${OPTARG}
           ;;

        s) # service account name
           SERVICE_ACCOUNT_NAME=${OPTARG}
           ;;

        l) # List of projects separated by comma
           PROJECT_LIST=${OPTARG}
           ;;

        c) # CSV file containing allowed list of GCP projects
           PROJECT_CSV_FILE=${OPTARG}
           ;;

        h | *) # Display Help and usage in case of error
           exit_abnormal;;
    esac
done

# Pre execution checks
validate_parameters()
{
    # Mandatory arguments
    if [[ ! "$SERVICE_ACCOUNT_PROJECT_ID" || ! "$SERVICE_ACCOUNT_NAME" ]]; then
        echo -e "${YELLOW}Warn:${NC} Argument -p SERVICE_ACCOUNT_PROJECT_ID and -s SERVICE_ACCOUNT_NAME must be provided"
        exit_abnormal
    fi

    # any one option can be selected
    if [[ ! -z "$PROJECT_LIST" && ! -z "$PROJECT_CSV_FILE" ]]; then
        echo -e "${YELLOW}Warn:${NC} Please select any one of the option from: [ -l PROJECT_LIST | -c ALLOWED_PROJECT_LIST.CSV ]"
        exit_abnormal
    fi
    
    # Set Project load option "-p || -c "
    if [[ ! -z "$PROJECT_LIST" ]]; then
        PROJECT_LOAD_OPTION="-p"
        PROJECT_IDS="$PROJECT_LIST"
    else
        PROJECT_LOAD_OPTION="-c"
        PROJECT_IDS="$PROJECT_CSV_FILE"
    fi
}

# get service account email
get_service_account_email()
{
    # Getting service Account Email
    SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --filter $SERVICE_ACCOUNT_NAME@$SERVICE_ACCOUNT_PROJECT_ID.iam.gserviceaccount.com --project $SERVICE_ACCOUNT_PROJECT_ID | awk 'NR>=2 { print $2 }')
    if [[ ! -z "$SERVICE_ACCOUNT_EMAIL" ]]; then
        echo -e "${GREEN}Successfully got service account email${NC}"
    else
        echo -e "${RED}Service account $SERVICE_ACCOUNT_NAME is not present in $SERVICE_ACCOUNT_PROJECT_ID.${NC}"
    fi
}


# Main execution

# Validate parameters
validate_parameters

# Run script to create Service account 
./create-service-account.sh -p $SERVICE_ACCOUNT_PROJECT_ID -s $SERVICE_ACCOUNT_NAME
status=$?
if [[ "$status" -ne 0 ]]; then
    echo -e "${RED}Error occurred while creating service account:${NC}"
    echo -e "${RED}Error Details:${NC} $0 "
    echo -e "Check Error message above and try again later"
    exit 1
fi

# get service account email
get_service_account_email

# Run script to assign role to service account and add in IAM
./assign-roles-to-service-account.sh -s $SERVICE_ACCOUNT_EMAIL $PROJECT_LOAD_OPTION $PROJECT_IDS
status=$?
if [[ "$status" -ne 0 ]]; then
    echo -e "${RED}Error occurred while assigning service account roles:${NC}"
    echo -e "${RED}Error Details:${NC} $0 "
    echo -e "Check Error message above and try again later"
    exit 1
fi

# Run script to enable APIs on single project or list of projects
./enable-gcp-api.sh -s $SERVICE_ACCOUNT_PROJECT_ID $PROJECT_LOAD_OPTION $PROJECT_IDS
status=$?
if [[ "$status" -ne 0 ]]; then
    echo -e "${RED}Error occurred while enabling APIs on GCP projects:${NC} $0 "
    echo -e "${RED}Error Details:${NC} $0 "
    echo -e "Check Error message above and try again later"
    exit 1
fi

echo -e "${GREEN}Project based onboard script executed${NC}"
