#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
############################################################################
# Function: Print a help message.
usage() {
  echo "Usage: $0 [ -p SA_PROJECT_ID ] [ -s SA_NAME ] [ -d SA_DISPLAY_NAME ]
  
  where:
  -p Project ID of project to create a Service Account
  -s Service Account Name (The service account name is case sensitive and must be in lowercase)
  -d Service Account display name" 1>&2 
}

exit_abnormal() {
  usage
  exit 1
}

#Check the number of arguments. If none are passed, print usage and exit.
NUMARGS=$#
if [ $NUMARGS -eq 0 ]; then
  usage
  exit 1
fi

while getopts "p:s:d:" flag
do
    case "${flag}" in
        # project ID to create a service account
        p) SA_PROJECT_ID=${OPTARG};;
        # service account name
        s) SA_NAME=${OPTARG};;
        # service account display name
        d) SA_DISPLAY_NAME=${OPTARG};;
        # If expected argument omitted:
        :)                          
        echo "Error: -${OPTARG} requires an argument."
        exit_abnormal;;                            # Exit abnormally.
      
        *)                                         # If unknown (any other) option:
        exit_abnormal;;
        esac
done

# mandatory arguments
if [ ! "$SA_PROJECT_ID" ] || [ ! "$SA_NAME" ] || [ ! "$SA_DISPLAY_NAME" ]; then
    echo "arguments -p, -s & -d must be provided"
    exit_abnormal
fi

summary_result()
{
    if [ "$OnboardType" == "ProjectBased" ]; then
        echo -e "$(rm -rf output)"
        echo $SERVICE_ACCOUNT_EMAIL | tee -a output >/dev/null
        echo $SA_KEY | tee -a output >/dev/null
        echo $SA_KEY_PATH | tee -a output >/dev/null
        echo -e "${GREEN}Created Service Account & Key Successfully!!.${NC}"
    else
        echo -e ""
        echo -e "${GREEN}Create Service Account script executed.${NC}"
        echo
        echo -e "${BCyan}Summary:${NC}"
        echo -e "${BCyan}Service Account Project ID:${NC} $SA_PROJECT_ID"
        echo -e "${BCyan}Service Account Email:${NC} $SERVICE_ACCOUNT_EMAIL"
        echo -e "${BCyan}Service Account Key Name:${NC} $SA_KEY"
        echo -e "${BCyan}Service Account Key File Path:${NC} $SA_KEY_PATH"
    fi
}

create_service_account() 
{
    gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
    statusSA=$?
    if [[ "$statusSA" -eq 0 ]]; then
        echo -e "${GREEN}Successfully created service account${NC}"
        sleep 7
        SERVICE_ACCOUNT_EMAIL=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID.iam.gserviceaccount.com)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT_EMAIL --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                SA_KEY=$(ls | grep $SA_NAME.json)
                SA_KEY_PATH=$(pwd)/$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully created service account key${NC}"
                summary_result
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key${NC}"
                exit_abnormal
            fi
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
            exit_abnormal
        fi
    else
        echo -e ""
        echo -e "${RED}Failed to create service account${NC}";
        exit_abnormal
    fi
}

create_service_account