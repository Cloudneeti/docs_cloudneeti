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
  echo "Usage: $0 [ -p Project ID where Service Account is created ] [ -e Service Account Email ] [ -l List of project IDs separated by a comma --> (<=10 Projects) | -c Allowed list of projects (.csv file) --> (>=10 projects) ]" 1>&2 
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

# list of roles for project based onboarding
ROLES=()
PERMISSION_FILE="permissions.json"
[ ! -f $PERMISSION_FILE ] && { echo "$PERMISSION_FILE file not found"; exit 99; }
project_level_roles()
{
    for role in $(jq -r .Project_Onboarding[] $PERMISSION_FILE) 
    do
        ROLES+=("$role")  
    done
}
project_level_roles

# Adding Service account in IAM for project where service account is created and assigning roles
add_sa_in_iam_saproj()
{
    for role in "${ROLES[@]}"
    do
        echo -e ""
        echo "Role: $role"
        gcloud projects add-iam-policy-binding $SA_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role --format=json | jq -r .bindings[].members[] | grep $SERVICE_ACCOUNT | uniq
        statusRoleSA=$?
        if [[ "$statusRoleSA" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Added role:${NC} $role"
        else
            echo -e "${RED}Failed to add role:${NC} $role"
            exit_abnormal
        fi	
    done
}

# Adding Service account in IAM for allowed list of projects and assigning roles
add_sa_in_iam_projlist()
{
   for project in "${IAM_PROJECT_ID[@]}"
    do
        for role in "${ROLES[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
            else
                echo -e ""
                echo "Role: $role"
                gcloud projects add-iam-policy-binding $project --member serviceAccount:$SERVICE_ACCOUNT --role $role --format=json | jq -r .bindings[].members[] | grep $SERVICE_ACCOUNT | uniq
                statusRoleeq=$?
                if [[ "$statusRoleeq" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully added role:${NC} $role"
                else
                    echo -e "${RED}Failed to add role:${NC} $role"
                    exit_abnormal
                fi
            fi	
        done
    done
}

while getopts ":p:e:l:c:" options
do 

        case "$options" in

        p) SA_PROJECT_ID=${OPTARG};;
            # Service Account Email
        e) SERVICE_ACCOUNT=${OPTARG};;

        l)
        process_list_proj() {
            IFS="," read -a IAM_PROJECT_ID <<< "$OPTARG"
            add_sa_in_iam_saproj
            add_sa_in_iam_projlist
            echo ""
            echo -e "${GREEN}Added Service Account in IAM & assigned roles.${NC}"
        }

        process_list_proj
        break;;
        c) 
        process_csvlist_proj() {
            INPUT=${OPTARG}
            IAM_PROJECT_ID=()
            [ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
            i=1
            while IFS=',' read -r f1 f2
            do
                test $i -eq 1 && ((i=i+1)) && continue
                IAM_PROJECT_ID+=( "$f1" )  
            done < "$INPUT"
            echo ""
            add_sa_in_iam_saproj
            add_sa_in_iam_projlist
            echo ""
            echo -e "${GREEN}Added Service Account in IAM & assigned roles.${NC}"
        }

        process_csvlist_proj
        break;;
        :)                                         # If expected argument omitted:
        echo "Error: -${OPTARG} requires an argument."
        exit_abnormal;;                            # Exit abnormally.
        *)                                         # If unknown (any other) option:
        exit_abnormal;;

    esac
done	