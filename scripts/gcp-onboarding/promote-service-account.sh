#!/bin/bash

: '
SYNOPSIS
    Script to create promote GCP service account at organization level and assign required ZCSPM roles
DESCRIPTION
    This script will promote GCP service account at organziation level. It also assign required ZCSPM roles to service account
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    ./promote-service-account.sh -s SERVICE_ACCOUNT_EMAIL -o GCP_ORGANIZATION
INPUTS
    (-s)Service Account Name: Service Account Name
    (-o)GCP Organization Id: GCP organization id
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
ADDED_ROLES=()

# Function: Print a help message.
usage() {
    echo "Script to promote service account to GCP organization"
    echo ""
    echo "Syntax: $0 -s SERVICE_ACCOUNT_EMAIL -o PROJECT_ID"
    echo "Options:"
    echo "  -h    Print this Help"
    echo "  -s    Service Account Email"
    echo "  -o    GCP Organization"
}

exit_abnormal() {
  usage
  exit 1
}

# Check the number of arguments
NUMARGS=$#
if [ $NUMARGS -lt 2 ]; then
  usage
  exit 1
fi

get_service_account_project()
{
    # Get Service Account project id from email
    SERVICEACCOUNTNAME=`echo $SERVICE_ACCOUNT_EMAIL | awk -F'[@/.]' '{ print $2}'`
    echo $SERVICEACCOUNTNAME
}

while getopts s:o:h: options
do
    case "${options}" in
        
        s) # Service Account Email
            SERVICE_ACCOUNT_EMAIL=${OPTARG}
            # Extract service account project id from email
            SA_PROJECT_ID=$(get_service_account_project)
            ;;

        o) # Organization ID
            ORGANIZATION_ID=${OPTARG}
            ;;       
        
        h | *) # Display Help and usage in case of error
            exit_abnormal
            ;;
    esac
done

# mandatory arguments
if [ ! "$ORGANIZATION_ID" ] || [ ! "$SERVICE_ACCOUNT_EMAIL" ]; then
    echo "Arguments -s and -o must be provided"
    exit_abnormal
fi

# Get ZCSPM required GCP roles 
ROLES=()

load_roles()
{    
    ROLE_FILE="zcspm-roles.json"
    # Checking existance of roles file
    [ ! -f $ROLE_FILE ] && { echo "$ROLE_FILE file not found"; exit 99; }

    # Load zcspm roles into array
    ROLES=$(jq -r .orgOnboarding[] $ROLE_FILE)
}

promote_service_account_to_org()
{   
    SUCCESS_COUNT=0
    ROLE_COUNT=0

    #TODO: Instead of one operation per role addition, use YAML based policy updates for multiple roles
    for role in $ROLES
    do
        ((ROLE_COUNT+=1))
        echo "Adding Role $role"
        gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT_EMAIL --role $role --format=json 1> /dev/null
        status=$?
        if [[ "$status" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Added role:${NC} $role"
            ((SUCCESS_COUNT+=1))
        else
            echo -e "${RED}Failed to add role:${NC} $role"
        fi
    done

    # Checking all roles are given to service account or not
    echo ""
    if [[ $SUCCESS_COUNT -eq $ROLE_COUNT ]]
    then
        echo -e "${GREEN}Successfully given all the zcspm gcp roles to service account $SERVICE_ACCOUNT_EMAIL.${NC}"
    else
        echo -e "${RED}Error occurred while performing role assignments.${NC}"
        echo -e "${RED}Please check error messages and try again.${NC}"
    fi
}

# MAIN Execution

# Loading ZCSPM Roles 
echo "Loading ZCSPM roles configuration"
load_roles

# Check Service Account existence
echo "Checking existance of service account $SERVICE_ACCOUNT_EMAIL"
SERVICE_ACCOUNT_EXIST=$(gcloud iam service-accounts list --project $SA_PROJECT_ID --filter $SERVICE_ACCOUNT_EMAIL | awk 'NR>=2 { print $2 }')
if [[ -z "$SERVICE_ACCOUNT_EXIST" ]]; then
    echo -e "${RED}Service account $SERVICE_ACCOUNT_EMAIL is not present${NC}"
    echo -e "${RED}Please check the service account and try again${NC}"
    exit
fi

# Promote Service account to GCP organization
echo "Promoting service account $SERVICE_ACCOUNT_EMAIL to $ORGANIZATION_ID organization"
promote_service_account_to_org

echo -e "${GREEN}Promote Service Account to Organization script executed.${NC}"