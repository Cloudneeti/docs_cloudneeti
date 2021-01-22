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
  echo "Usage: $0 [ -o ORGANIZATION_ID ] [ -p SA_PROJECT_ID  ] 
  [ -l PROJECT_LIST || -a ALL_PROJECT(ALL) || -w ALLOWED_CSV || -x EXCLUDED_CSV ]
  where:
    -o Organization ID
    -p Project ID where Service Account is created

    Provide one of the following options to enable APIs for Organization-based Onboarding:
    -l List of project IDs --> (<=10 Projects)
       (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    -a All projects (value=ALL)
    -w Allowed list of projects (.csv file) --> (>=10 projects)
       (Example: /home/path/to/allowed_list.csv )
    -x All projects excluding a list of projects (.csv file)
       (Example: /home/path/to/excluded_list.csv )
    
    Provide one of the following options to enable APIs for Project-based Onboarding:
    -l List of project IDs --> (<=10 Projects)
       (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    -w Allowed list of projects (.csv file) --> (>=10 projects)
      (Example: /home/path/to/allowed_list.csv )" 1>&2 
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
api_list()
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
api_list

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
                echo -e "${GREEN}Successfully Enabled API:${NC} $api"
            else
                echo -e "${RED}Failed to Enable API:${NC} $api"
                exit_abnormal
            fi
        done
    done
}

while getopts "o:p:l:a:w:x:" options; do

    case "$options" in

    o) ORGANIZATION_ID=${OPTARG};;
    # project ID of project where service account is created
    p) SA_PROJECT_ID=${OPTARG};;

    l) PROJECT_LIST=${OPTARG}
    RESULT_PROJECT_LIST=$([[ ! -z "$PROJECT_LIST" ]] && echo "NotEmpty" || echo "Empty");;

    a) ALL_PROJECT=${OPTARG}
    RESULT_ALL_PROJECT=$([[ ! -z "$ALL_PROJECT" ]] && echo "NotEmpty" || echo "Empty");;

    w) ALLOWED_CSV=${OPTARG}
    RESULT_ALLOWED_CSV=$([[ ! -z "$ALLOWED_CSV" ]] && echo "NotEmpty" || echo "Empty");;

    x) EXCLUDED_CSV=${OPTARG}
    RESULT_EXCLUDED_CSV=$([[ ! -z "$EXCLUDED_CSV" ]] && echo "NotEmpty" || echo "Empty");;

    :)                                         # If expected argument omitted:
    echo "Error: -${OPTARG} requires an argument."
    exit_abnormal;;
            
    *)                                         # If unknown (any other) option:
    exit_abnormal;;
    esac
done
shift "$(( OPTIND - 1 ))"

if [ "$RESULT_PROJECT_LIST" == "NotEmpty" ] && [ "$RESULT_ALL_PROJECT" == "NotEmpty" ]; then
    echo "Please select only one option from: [-l | -a |-w | -x]"
    exit_abnormal
elif [ "$RESULT_ALLOWED_CSV" == "NotEmpty" ] && [ "$RESULT_EXCLUDED_CSV" == "NotEmpty" ]; then
    echo "Please select only one option from: [-l | -a |-w | -x]"
    exit_abnormal
elif [ "$RESULT_ALL_PROJECT" == "NotEmpty" ] && [ "$RESULT_ALLOWED_CSV" == "NotEmpty" ]; then
    echo "Please select only one option from: [-l | -a |-w | -x]"
    exit_abnormal
elif [ "$RESULT_EXCLUDED_CSV" == "NotEmpty" ] && [ "$RESULT_PROJECT_LIST" == "NotEmpty" ]; then
    echo "Please select only one option from: [-l | -a |-w | -x]"
    exit_abnormal
else
    if [ "$RESULT_PROJECT_LIST" == "NotEmpty" ]; then
        enable_api_list_projects()
        {
            # mandatory arguments
            if [ ! "$SA_PROJECT_ID" ]; then
                echo "arguments -p must be provided"
                exit_abnormal
            fi
            IFS="," read -a IAM_PROJECT_ID <<< "$PROJECT_LIST"
            echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
        }
        enable_api_list_projects
    elif [[ $ALL_PROJECT == "ALL" ]]; then
        enable_api_all_projects() 
        {
                # mandatory arguments
                if [ ! "$ORGANIZATION_ID" ] || [ ! "$SA_PROJECT_ID" ]; then
                    echo "arguments -o and -p must be provided"
                    exit_abnormal
                fi
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
        enable_api_all_projects

    elif [ "$RESULT_ALLOWED_CSV" == "NotEmpty" ]; then
        enable_api_allowed_list_projects() 
        {
            # mandatory arguments
            if [ ! "$SA_PROJECT_ID" ]; then
                echo "arguments -p must be provided"
                exit_abnormal
            fi
            IAM_PROJECT_ID=()
            [ ! -f $ALLOWED_CSV ] && { echo "$ALLOWED_CSV file not found"; exit 99; }
            i=1
            while IFS=',' read -r f1 f2
            do
                test $i -eq 1 && ((i=i+1)) && continue
                IAM_PROJECT_ID+=( "$f1" )  
            done < "$ALLOWED_CSV"
            echo -e ""
            echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
            echo -e ""
            enable_api_sa_proj
            enable_api_projlist
            echo ""
            echo -e "${GREEN}Enable APIs script executed.${NC}"
        }
        enable_api_allowed_list_projects

    elif [ "$RESULT_EXCLUDED_CSV" == "NotEmpty" ]; then
        enable_api_excluding_list_projects() 
        {
                # mandatory arguments
                if [ ! "$ORGANIZATION_ID" ] || [ ! "$SA_PROJECT_ID" ]; then
                    echo "arguments -o and -p must be provided"
                    exit_abnormal
                fi
                # Creating array with excluding list of projects
                EX_PROJECT_ID=()
                [ ! -f $EXCLUDED_CSV ] && { echo "$EXCLUDED_CSV file not found"; exit 99; }
                i=1
                while IFS=',' read -r f1 f2
                do
                    test $i -eq 1 && ((i=i+1)) && continue 
                    EX_PROJECT_ID+=( "$f1" )  
                done < "$EXCLUDED_CSV"

                # Creating array for all projects within Organization
                IAM_PROJECT_ID=()
                m=0
                for project in  $(gcloud alpha asset list --organization=$ORGANIZATION_ID --content-type=resource --asset-types="cloudresourcemanager.googleapis.com/Project" --format="value(resource.data.projectId)")
                do
                    IAM_PROJECT_ID[m++]="$project"
                done

                # Array of project to process
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
        enable_api_excluding_list_projects
    else
        exit_abnormal
    fi
fi