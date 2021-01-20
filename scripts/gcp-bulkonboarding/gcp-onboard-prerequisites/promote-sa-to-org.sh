#!/bin/bash

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
  echo "Usage: $0 [ -o Organization ID ] [ -e Service Account Email ]" 1>&2 
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

# flags
while getopts o:e: flag
do
    case "${flag}" in
            # Organization ID
            o) ORGANIZATION_ID=${OPTARG};;
            # Service Account Email
            e) SERVICE_ACCOUNT=${OPTARG};;
            :)                                         # If expected argument omitted:
            echo "Error: -${OPTARG} requires an argument."
            exit_abnormal;;                            # Exit abnormally.
      
            *)                                         # If unknown (any other) option:
            exit_abnormal;;
    esac
done

PERMISSION_FILE="permissions.json"
[ ! -f $PERMISSION_FILE ] && { echo "$PERMISSION_FILE file not found"; exit 99; }

promote_sa_to_org()
{
    ROLES=()
    for role in $(jq -r .ORG_Onboarding[] $PERMISSION_FILE) 
    do
        ROLES+=("$role")  
    done
    echo ""
    for role in "${ROLES[@]}"
    do
        echo "Role: $role"
        gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role --format=json | jq .bindings[].members[] | grep $SERVICE_ACCOUNT | uniq
        statusOrgRoleSA=$?
        if [[ "$statusOrgRoleSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully added role:${NC} $role"
            for success_role in $role
            do
                ADDED_ROLES+=("$success_role")
            done    
        else
            echo -e ""
            echo -e "${RED}Failed to add role:${NC} $role"
            exit_abnormal
        fi
    done
}

promote_sa_to_org

##################################################################################
echo -e ""
echo -e ""
echo -e "${GREEN}Promote Service Account to Organization script executed.${NC}"
echo
echo -e "${BCyan}Summary:${NC}"
RESULT_SUCCESS=$([[ ! -z "$ADDED_ROLES" ]] && echo "NotEmpty" || echo "Empty")
if [[ $RESULT_SUCCESS == "NotEmpty" ]]; then
    echo -e "${BCyan}Successfully Added Roles:${NC}"
    for success_role in "${ADDED_ROLES[@]}"
    do
        echo "------> $success_role"
    done
else
    echo ""
fi
###################################################################################