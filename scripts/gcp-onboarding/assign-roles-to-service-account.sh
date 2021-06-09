#!/bin/bash

: '
SYNOPSIS
    Script to assign ZCSPM roles to GCP service account
DESCRIPTION
    This script will assign a required roles to service account at project level
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    1. Assign roles to single project
        ./assign-roles-to-service-account.sh -s SERVICE_ACCOUNT_EMAIL -p PROJECT_ID
    2. Assign roles to multiple projects
        ./assign-roles-to-service-account.sh -s SERVICE_ACCOUNT_EMAIL -p PROJECT_ID1,PROJECT_ID2,PROJECT_ID3
    3. Assign roles to multiple projects using projects present in CSV file
        ./assign-roles-to-service-account.sh -s SERVICE_ACCOUNT_EMAIL -c PROJECT_LIST.csv
INPUTS
    (-s)Service Account Email: Service Account Email
    (-p)Project Id: Single or comma separated list of GCP project ids
    (-c)CSV File: CSV file containing list of project ids
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
    echo "Script to assign ZCSPM roles to GCP service account"
    echo ""
    echo "Syntax: $0 -s SERVICE_ACCOUNT_EMAIL  [ -p PROJECT_ID | -c PROJECT_LIST.CSV ]"
    echo "Options:"
    echo "  -h    Print this Help"
    echo "  -s    Service Account Email"
    echo "  -p    Single or list of comma separated GCP project ids"
    echo "  -c    CSV file containing list of GCP projects) (>=10 projects)" 
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

# Get ZCSPM required GCP roles 
ROLES=()

load_roles()
{    
    ROLE_FILE="zcspm-roles.json"
    # Checking existance of roles file
    [ ! -f $ROLE_FILE ] && { echo "$ROLE_FILE file not found"; exit 99; }

    # Load zcspm roles into array
    ROLES=$(jq -r .projectOnboarding[] $ROLE_FILE) 
}

# Adding Service account in IAM for project where service account is created and assigning roles
add_iam_policy_binding()
{
    project=$1

    #TODO: Instead of one operation per role addition, use YAML based policy updates for multiple roles
    for role in $ROLES
    do
        echo "Adding Role $role"
        gcloud projects add-iam-policy-binding $project --member serviceAccount:$SERVICE_ACCOUNT_EMAIL --role $role --format=json 1> /dev/null
        status=$?
        if [[ "$status" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Added role:${NC} $role"
        else
            echo -e "${RED}Failed to add role:${NC} $role"
        fi
    done
}

# Adding Service account in IAM for allowed list of projects and assigning roles
assign_roles_to_service_account()
{
    # TODO: Assign roles to service account in parallel using multi-threading
    for project in $PROJECT_LIST
    do  
        echo -e "${YELLOW}Adding service account $SERVICE_ACCOUNT_EMAIL to project $project IAM${NC}"
        add_iam_policy_binding $project
    done
}

load_project_from_csv() 
{
    PROJECT_CSV=$1
 
    # Test existance of csv file
    [ ! -f $PROJECT_CSV ] && { echo "$PROJECT_CSV file not found"; exit 99; }
    
    # Iterate CSV
    while IFS=',' read -r project_id project_name
    do
        PROJECT_ID+=( "$project_id" )  
    done < <( tail -n +2 $PROJECT_CSV )

    echo "${PROJECT_ID[@]}"
}

get_service_account_project()
{
    # Get Service Account project id from email
    SERVICEACCOUNTNAME=`echo $SERVICE_ACCOUNT_EMAIL | awk -F'[@/.]' '{ print $2}'`
    echo $SERVICEACCOUNTNAME
}

while getopts ":s:p:c:h:" options
do 
    case "$options" in
        s) # Service Account Email
            SERVICE_ACCOUNT_EMAIL=${OPTARG}
            # Extract service account project id from email
            SA_PROJECT_ID=$(get_service_account_project)
            ;;

        p) # Single or multiple project ids in which service account is added
            PROJECT_ID=${OPTARG}
            IFS="," read -a IAM_PROJECT_ID <<< "$PROJECT_ID"
            PROJECT_LIST=${IAM_PROJECT_ID[@]}
            ;;

        c) # Load projects from CSV file
            PROJECT_CSV_FILE=${OPTARG}
            PROJECT_LIST=$(load_project_from_csv $PROJECT_CSV_FILE)
            ;;

        h | *) # Display Help and usage in case of error
            exit_abnormal;;
            esac
done

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

echo "Assigning zcspm roles to service account $SERVICE_ACCOUNT_EMAIL"
assign_roles_to_service_account $PROJECT_LIST
