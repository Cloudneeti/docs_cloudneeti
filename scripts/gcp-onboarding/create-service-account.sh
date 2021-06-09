#!/bin/bash

: '
SYNOPSIS
    Script to create GCP service account with keys
DESCRIPTION
    This script will create service account inside the GCP project and generate the service account keys
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    ./create-service-account.sh -p PROJECT_ID -s SERVICE_ACCOUNT_NAME
INPUTS
    (-p)Project Id: GCP Project ID where Service Account gets created
    (-s)Service Account Name: Service Account Name
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
    echo "Script to create GCP service account"
    echo ""
    echo "Syntax: $0 -p PROJECT_ID -s SERVICE_ACCOUNT_NAME"
   
    echo "Options:"
    echo "  -h     Print this Help"
    echo "  -p     Project ID of project to create a Service Account"
    echo "  -s     Service Account Name (The service account name is case sensitive and must be in lowercase)"
}

exit_abnormal() {
  usage
  exit 1
}

# Check the for two arguments
NUMARGS=$#
if [ $NUMARGS -le 2 ]; then
  usage
  exit 1
fi

while getopts "p:s:d:" flag
do
    case "${flag}" in
        p) # project ID to create a service account
            PROJECT_ID=${OPTARG};;
        s) # service account name
            SERVICE_ACCOUNT_NAME=${OPTARG};;
        h | *) # Display Help and usage in case of error
            exit_abnormal;;
            esac
done

create_service_account() 
{
    # Check service account existance
    echo "Checking existance of service account $SERVICE_ACCOUNT_NAME in $PROJECT_ID"
    SERVICE_ACCOUNT_EXIST=$(gcloud iam service-accounts list --project $PROJECT_ID --filter $SERVICE_ACCOUNT_NAME | awk 'NR>=2 { print $2 }')
    if [[ ! -z "$SERVICE_ACCOUNT_EXIST" ]]; then
        echo -e "${YELLOW}Service account $SERVICE_ACCOUNT_NAME is already present in project $PROJECT_ID.${NC}"
        echo "Use the already generated keys or create service account with new name"
        exit
    fi

    # Create a service account
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME  --display-name $SERVICE_ACCOUNT_NAME --project=$PROJECT_ID
    if [[ "$?" -eq 0 ]]; then
        echo -e "${GREEN}Successfully created service account $SERVICE_ACCOUNT_NAME in GCP project $PROJECT_ID. ${NC}"
    else
        echo -e ""
        echo -e "${RED}Failed to create service account, Please try again later...${NC}";
        exit
    fi
}

get_service_account_email()
{
    # Getting service Account Email
    sleep 5
    SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --filter $SERVICE_ACCOUNT_NAME --project $PROJECT_ID | awk 'NR>=2 { print $2 }')
    if [[ ! -z "$SERVICE_ACCOUNT_EMAIL" ]]; then
        echo -e "${GREEN}Successfully got service account email${NC}"
    else
        echo -e "${RED}Service account $SERVICE_ACCOUNT_NAME is not present in $PROJECT_ID.${NC}"
    fi
}

create_service_account_keys()
{
    KEY_FILE_NAME="$SERVICE_ACCOUNT_NAME.json"
    KEY_FILE_PATH=$(pwd)/$(ls | grep $KEY_FILE_NAME)

    gcloud iam service-accounts keys create $KEY_FILE_NAME --iam-account=$SERVICE_ACCOUNT_EMAIL --key-file-type="json" --project=$PROJECT_ID
    statusKey=$?
    if [[ "$statusKey" -eq 0 ]]; then
        echo -e "${GREEN}Successfully created service account $SERVICE_ACCOUNT_NAME key${NC}"
    else
        echo -e ""
        echo -e "${RED}Failed to create service account key, Please check error message and try again.${NC}"
        exit
    fi
}

# MAIN Execution

# Create a Service Account
echo "Creating Service Account $SERVICE_ACCOUNT_NAME in GCP Project $PROJECT_ID"
create_service_account

# Get Service Account Email
echo "Getting Service Account $SERVICE_ACCOUNT_NAME email id"
get_service_account_email

# Generate Service Account Keys
echo "Generating Service Account $SERVICE_ACCOUNT_NAME keys"
create_service_account_keys

# Service Account Details
echo -e "${BCyan}Summary:${NC}"
echo
echo -e "${BCyan}Service Account Project ID:${NC} $PROJECT_ID"
echo -e "${BCyan}Service Account Email:${NC} $SERVICE_ACCOUNT_EMAIL"
echo -e "${BCyan}Service Account Key Name:${NC} $KEY_FILE_NAME"
echo -e "${BCyan}Service Account Key File Path:${NC} $KEY_FILE_PATH"
echo
echo -e "${BCyan}*Note: Store service account key file in secure location${NC} $KEY_FILE_PATH"