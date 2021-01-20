#!/bin/bash

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
########################################################################
SA_Project_APIs=()
Onboard_Project_APIs=()
API_FILE="apis.json"

# Function: Print a help message.
usage() {
  echo "Usage: $0 [ -O Organization-based onboarding | -P Project-based Onboarding ] [ -o Organization ID ] [ -p Project ID where Service Account is created  ]" 1>&2 
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

[ ! -f $API_FILE ] && { echo "$API_FILE file not found"; exit 99; }
api_list_func()
{
    # APIs needs to enable on project where Service account is created
    for api in $(jq -r .SA_Project_APIs[] $API_FILE) 
    do
        SA_Project_APIs+=("$api")  
    done
    # APIs needs to enable on project which are going to onboard
    for api in $(jq -r .Onboard_Project_APIs[] $API_FILE) 
    do
        Onboard_Project_APIs+=("$api")  
    done
}
api_list_func

enable_api_sa_proj()
{
    echo "SA_ProjectId: $SA_PROJECT_ID"
    for api in "${SA_Project_APIs[@]}"
    do
        $(gcloud services enable $api --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled API:${NC} $api"
            else
                echo -e "${RED}Failed to Enable API:${NC} $api"
                exit_abnormal
            fi
    done
}

enable_api_projlist()
{
    for project in "${IAM_PROJECT_ID[@]}"
    do
        echo -e ""
        echo "ProjectId: $project"
        for api in "${Onboard_Project_APIs[@]}"
        do
            $(gcloud services enable $api --project $project)
            statusIAMProjAPI=$?
            if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                echo -e "${GREEN}Successfully Enabled APIs on:${NC} $api"
            else
                echo -e "${RED}Failed to Enable APIs on:${NC} $api"
            fi
        done
    done
}

while getopts "O:P:" options; do

    case "$options" in
    O) Org_based_Onboarding=${OPTARG}
    if [ "$Org_based_Onboarding" == "org-based" ]; then
        while getopts o:p: flag
        do
            case "${flag}" in
                # project ID to create a service account
                o) ORGANIZATION_ID=${OPTARG};;
                p) SA_PROJECT_ID=${OPTARG};;
                :)                                         # If expected argument omitted:
                echo "Error: -${OPTARG} requires an argument."
                exit_abnormal;;                            # Exit abnormally.
        
                *)                                         # If unknown (any other) option:
                exit_abnormal;;
            esac
        done
        #echo "You have selected '$opt'."
        echo ""
        title="Please select one of the following options to enable APIs for Organization-based Onboarding: "
        prompt="Pick an option: "
        options=("List of project IDs --> (<=10 Projects)" "All projects" "Allowed list of projects (.csv file) --> (>=10 projects)" "All projects excluding a list of projects (.csv file)")
        echo "$title"
        PS3="$prompt"
        select opt in "${options[@]}" "Quit"; do 

            case "$REPLY" in
            1 )
            org_enable_api_few_proj() {
            echo "You have selected '$opt'."
            echo -e ""
            echo -e "Enter the project IDs separated by a comma: "
            echo -e "(Example: ProjectID_1,ProjectID_2,ProjectID_3,... etc) "
            IFS="," read -a IAM_PROJECT_ID

            ###############################################
            echo -e ""
            echo -e "${BLUE}*****Enabling API's on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }

            org_enable_api_few_proj
            break;;
            2 )
            org_enable_api_allProj_func() {
            echo "You have selected '$opt'."
            echo -e ""
            IAM_PROJECT_ID=()
            m=0
            for project in  $(gcloud alpha asset list --organization=$ORGANIZATION_ID --content-type=resource --asset-types="cloudresourcemanager.googleapis.com/Project" --format="value(resource.data.projectId)")
            do
                IAM_PROJECT_ID[m++]="$project"
            done
            echo -e "${BLUE}*****Enabling API's on all Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }

            org_enable_api_allProj_func
            break;;
            3 )
            org_enable_api_allowedProj_func() {
            echo "You have selected '$opt'."
            echo -e ""
            echo -e "Enter the file path to the allowed list of projects: "
            echo -e "(Example: /home/path/to/allowed_list.csv )"
            read  INPUT
            echo -e ""
            IAM_PROJECT_ID=()
            [ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
            i=1
            while IFS=',' read -r f1 f2
            do
                test $i -eq 1 && ((i=i+1)) && continue
                IAM_PROJECT_ID+=( "$f1" )  
            done < "$INPUT"
            echo -e ""
            echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }

            org_enable_api_allowedProj_func
            break;;
            4 )
            org_enable_api_excludingProj_func() {
            echo "You have selected '$opt'."
            echo -e ""
            echo -e "Enter the file path to the list of projects to be excluded: "
            echo -e "(Example: /home/path/to/excluded_list.csv )"
            read INPUT
            # creating array with excluding list of projects
            EX_PROJECT_ID=()
            [ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
            i=1
            while IFS=',' read -r f1 f2
            do
                test $i -eq 1 && ((i=i+1)) && continue 
                EX_PROJECT_ID+=( "$f1" )  
            done < "$INPUT"

            # Creating array for all projects within Organization
            IAM_PROJECT_ID=()
            m=0
            for project in  $(gcloud alpha asset list --organization=$ORGANIZATION_ID --content-type=resource --asset-types="cloudresourcemanager.googleapis.com/Project" --format="value(resource.data.projectId)")
            do
                IAM_PROJECT_ID[m++]="$project"
            done

            # IAM_PROJECT_ID
            for target in "${EX_PROJECT_ID[@]}"; do
            for l in "${!IAM_PROJECT_ID[@]}"; do
                if [[ ${IAM_PROJECT_ID[l]} = $target ]]; then
                unset 'IAM_PROJECT_ID[l]'
                fi
            done
            done
            echo -e "${BLUE}****Enabling APIs on Project****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }

            org_enable_api_excludingProj_func
            break;;
            $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
            *) echo "Invalid option. Try another one.";continue;;

            esac
        done
    fi
    break;;
    P) Project_based_Onboarding=${OPTARG}
    if [ "$Project_based_Onboarding" == "project-based" ]; then

        # Function: Print a help message.
        usage_proj_based() {
        echo "Usage: $0 [ -p Project ID where Service Account is created  ] [ -l List of project IDs separated by a comma --> (<=10 Projects) | -c Allowed list of projects (.csv file) --> (>=10 projects) ]" 1>&2 
        }

        exit_abnormal_sub() {
        usage_proj_based
        exit 1
        }

        #Check the number of arguments. If none are passed, print usage and exit.
        NUMARGS=$#
        if [ $NUMARGS -eq 0 ]; then
        usage_proj_based
        exit 1
        fi

        while getopts ":p:l:c:" options
        do

            case "$options" in
            p) SA_PROJECT_ID=${OPTARG};;

            l)
            enable_api_few_proj() {
            IFS="," read -a IAM_PROJECT_ID <<< "$OPTARG"
            echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }

            enable_api_few_proj
            break;;
            c)
            enable_api_allowed_proj() {
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

            ###############################################
            echo -e ""
            echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
            }
            enable_api_allowed_proj
            break;;
            :)                                         # If expected argument omitted:
            echo "Error: -${OPTARG} requires an argument."
            exit_abnormal_sub;;
            
            *)                                         # If unknown (any other) option:
            exit_abnormal_sub;;
            esac
        done
    fi
    break;;
    :)                                         # If expected argument omitted:
    echo "Error: -${OPTARG} requires an argument."
    exit_abnormal;;
      
    *)                                         # If unknown (any other) option:
    exit_abnormal;;
    esac
done