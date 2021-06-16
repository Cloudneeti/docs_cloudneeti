#!/bin/bash

: '
SYNOPSIS
    Script to enable service APIs on GCP projects.
DESCRIPTION
    This script will enable ZCSPM required service APIs on GCP projects.
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
      - Run this script in any bash shell (linux command prompt)
EXAMPLE
    1. Enable APIs on list of project
        ./enable-gcp-api.sh -s <SERVICE_ACCOUNT_PROJECT_ID> -p <PROJECT_LIST>
    2. Enable APIs on allowed list of projects (.csv file)
        ./enable-gcp-api.sh -s <SERVICE_ACCOUNT_PROJECT_ID> -c <PROJECT_LIST.CSV>
    3. Enable APIs on all projects within Organization
        ./enable-gcp-api.sh -s <SERVICE_ACCOUNT_PROJECT_ID> -o <ORGANIZATION_ID> -a
INPUTS
    (-s)Service Account Project ID
    (-p)List of projects separated by comma (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    (-o)Organization ID
    (-c)CSV file containing allowed list of GCP projects (.csv file) --> (>=10 projects)
    (-a)All projects
OUTPUTS
    None
'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
########################################################################

# Function: Print a help message.
usage() {
    echo "Script to enable APIs on GCP Projects"
    echo ""
    echo "Syntax: $0 -s SERVICE_ACCOUNT_PROJECT_ID [ -o ORGANIZATION_ID | -p PROJECT_LIST | -a | -c ALLOWED_PROJECT_LIST.CSV ]"
    echo "Options:"
    echo "  -h    Print this Help"
    echo "  -o    Organization ID"
    echo "  -s    Service Account Project ID"
    echo "  -p    Single or comma separated list of GCP project ids (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)"
    echo "  -a    All projects within Organization"
    echo "  -c    CSV file containing list of GCP projects (>=10 projects)"
}

exit_abnormal() {
    usage
    exit 1
}

#Check the number of arguments. If none are passed, print usage and exit.
NUMARGS=$#
if [[ $NUMARGS -lt 4 ]]; then
    exit_abnormal
fi

# Load APIs form json file
SERVICE_ACCOUNT_PROJECT_API=()
ONBOARDING_PROJECT_API=()

load_apis()
{
    PROJECT_TYPE=$1
    # APIs needs to enable on project where Service account is created
    APIS=$(jq -r .$PROJECT_TYPE[] $API_FILE)
    echo "$APIS"
}

load_project_from_csv() 
{
    PROJECT_CSV=$1
 
    # Iterate CSV
    while IFS=',' read -r project_id project_name
    do
        PROJECT_ID+=( "$project_id" )  
    done < <( tail -n +2 $PROJECT_CSV )

    echo "${PROJECT_ID[@]}"
}

# Enable APIs on GCP Projects
enable_apis()
{
    PROJECT_IDS=$1
    PROJECT_APIS=$2
    NUM_THREADS=$3
    
    for project in $PROJECT_IDS
    do
        {   
            echo "Enabling GCP APIs on $project project"
            gcloud services enable $PROJECT_APIS --project $project
            status=$?
            if [[ "$status" -eq 0 ]]; then
                echo -e "${GREEN}Successfully Enabled APIs on $project project${NC}" #$PROJECT_APIS"
            else
                echo -e "${RED}Failed to Enable APIs on $project project${NC}"
            fi
        } &
        ((i=i%NUM_THREADS)); ((i++==0)) && wait
    done
    wait
}

# Load all projects within Organization
PROJECT_LIST=()
load_all_org_projects() 
{
    ORGANIZATION_ID=$1
    # validate org id
    echo "Validating Organization ID"
    VALID_ORG_ID=$(gcloud organizations list --filter=$ORGANIZATION_ID | awk 'NR > 1 {print $2}')
    if [[ $VALID_ORG_ID == $ORGANIZATION_ID ]]; then
        # Load all the GCP projects
        PROJECT_LIST="$(gcloud alpha asset list --organization=$ORGANIZATION_ID --content-type=resource --asset-types="cloudresourcemanager.googleapis.com/Project" --filter=resource.data.lifecycleState=ACTIVE --format="value(resource.data.projectId)")"
    else
        echo -e "${RED}Incorrect Organization ID $ORGANIZATION_ID provided${NC}"
        echo -e "${YELLOW}Please provide the valid Organization ID and Continue..${NC}"
        exit 1
    fi
}

# Verify the condition before execution
validate_parameters()
{
    echo "Validating input parameters"
    # Mandatory arguments
    if [[ ! "$SERVICE_ACCOUNT_PROJECT_ID" ]]; then
        echo -e "${YELLOW}Warn:${NC} Argument -s SERVICE_ACCOUNT_PROJECT_ID must be provided"
        exit_abnormal
    fi

    # Validate project list or CSV load conditions
    if [[ ! -z "$PROJECT_ID" && ! -z "$PROJECT_CSV_FILE" && ! -z $ORGANIZATION_ID ]] ||
       [[ ! -z "$PROJECT_ID" && ! -z "$PROJECT_CSV_FILE" ]] ||
       [[ ! -z "$PROJECT_ID" && ! -z "$ORGANIZATION_ID" ]] ||
       [[ ! -z "$PROJECT_CSV_FILE" && ! -z "$ORGANIZATION_ID" ]]; then
        echo -e "${YELLOW}Warn:${NC} Please select any one of the option from: [ -p PROJECT_LIST | -c ALLOWED_PROJECT_LIST | -o ORGANIZATION_ID ]"
        exit_abnormal
    fi

    # Mandatory arguments to load Organization projects
    if  [[ -z $ORGANIZATION_ID  &&  ! -z $ALL_PROJECT ]] || [[ ! -z $ORGANIZATION_ID  &&  -z $ALL_PROJECT ]] ; then
        echo -e "${YELLOW}Warn:${NC} Argument -o ORGANIZATION_ID and -a must be provided"
        exit_abnormal
    fi

}

while getopts ":s:p:o:c:ah" options
do 
    case "$options" in

        s) # project ID of project where service account is created
           SERVICE_ACCOUNT_PROJECT_ID=${OPTARG}
           ;;
           
        p) # Single or multiple project ids in which service account is added
            PROJECT_ID=${OPTARG}
            IFS="," read -a IAM_PROJECT_ID <<< "$PROJECT_ID"
            PROJECT_LIST=${IAM_PROJECT_ID[@]}
            ;;

        o) # Organization id
            ORGANIZATION_ID=${OPTARG}
            ;;

        c) # Load projects from CSV file
            PROJECT_CSV_FILE=${OPTARG}
            # Test existance of csv file
            [ ! -f $PROJECT_CSV_FILE ] && { echo "$PROJECT_CSV_FILE file not found"; exit 1; }
            PROJECT_LIST=$(load_project_from_csv $PROJECT_CSV_FILE)
            ;;

        a) # List of all projects within Organization
            ALL_PROJECT=1
            load_all_org_projects $ORGANIZATION_ID        
            ;;

        :)  # If expected argument omitted:
            echo -e "${RED}Error:${NC} -${OPTARG} requires an argument."
            exit_abnormal;;
           
        h | *) # Display Help and usage in case of error
            exit_abnormal
            ;;
    esac
done
shift "$(( OPTIND - 1 ))"

# MAIN Execution

# Validating user inputs
validate_parameters

# Checking existance of api file
API_FILE="gcp-apis.json"
[ ! -f $API_FILE ] && { echo "$API_FILE file not found"; exit 99; }

# Load API lists
echo "Loading Service API required for ZCSPM to enable on projects"
SERVICE_ACCOUNT_PROJECT_API=$(load_apis "ServiceAccountProjectAPIs")
ONBOARDING_PROJECT_API=$(load_apis "OnboardProjectAPIs")
echo -e "${GREEN}Successfully loaded Service API required for ZCSPM to enable on projects${NC}"
echo ""

# Enable GCP API on service account project
enable_apis $SERVICE_ACCOUNT_PROJECT_ID "${SERVICE_ACCOUNT_PROJECT_API[@]}" 1

# Enable GCP API on onboarding projects
enable_apis "${PROJECT_LIST[@]}" "${ONBOARDING_PROJECT_API[@]}" 10

#TODO: Display API enablement operation summary and dump details in CSV
echo -e ""
echo -e "${GREEN}Enable APIs script executed.${NC}"
