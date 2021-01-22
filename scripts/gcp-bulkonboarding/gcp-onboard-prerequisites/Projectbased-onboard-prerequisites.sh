#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
############################################################################

OnboardType="ProjectBased"
output=()

# Function: Print a help message.
usage() {
  echo "Usage: $0 [ -p SA_PROJECT_ID ] [ -s SA_NAME ] [ -d SA_DISPLAY_NAME ] 
  [ -l PROJECT_LIST || -w ALLOWED_CSV ]
  
  where:
    -p Project ID of project to create a Service Account
    -s Service Account Name (The service account name is case sensitive and must be in lowercase)
    -d Service Account display name

    Provide one of the following options to enable APIs and add service account in IAM for Project-based Onboarding:
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

# flags
while getopts ":p:s:d:l:w:" flag
do
    case "${flag}" in
        # project ID to create a service account
        p) SA_PROJECT_ID=${OPTARG};;

        # service account name
        s) SA_NAME=${OPTARG};;

        # service account display name
        d) SA_DISPLAY_NAME=${OPTARG};;

        l) PROJECT_LIST=${OPTARG}
        RESULT_PROJECT_LIST=$([[ ! -z "$PROJECT_LIST" ]] && echo "NotEmpty" || echo "Empty");;

        w) ALLOWED_CSV=${OPTARG}
        RESULT_ALLOWED_CSV=$([[ ! -z "$ALLOWED_CSV" ]] && echo "NotEmpty" || echo "Empty");;

        # If expected argument omitted:
        :)                                        
        echo "Error: -${OPTARG} requires an argument."
        exit_abnormal;;                            # Exit abnormally.
      
        *)                                         # If unknown (any other) option:
        exit_abnormal;;
    esac
done

summary()
{
    [ ! -f output ] && { echo "output not found"; exit 99; }
    i=0
    while IFS=',' read -r f1
    do
        test $i -eq 1 && ((i=i+1)) && continue
        output+=( "$f1" )  
    done < "output"
}

project_based_prerequisites()
{
    if [ "$RESULT_PROJECT_LIST" == "NotEmpty" ] && [ "$RESULT_ALLOWED_CSV" == "NotEmpty" ]; then
        echo "Please select only one option from: [-l |-w ]"
        exit_abnormal
    fi
    # mandatory arguments
    if [ ! "$SA_PROJECT_ID" ] || [ ! "$SA_NAME" ] || [ ! "$SA_DISPLAY_NAME" ]; then
        echo "arguments -p, -s & -d must be provided"
        exit_abnormal
    fi
    chmod +x create-sa.sh
    source ./create-sa.sh -p $SA_PROJECT_ID -s $SA_NAME -d $SA_DISPLAY_NAME
    status=$?
    if [[ "$status" -eq 0 ]]; then
        summary
        chmod +x add-sa-in-iam.sh
        if [ "$RESULT_PROJECT_LIST" == "NotEmpty" ]; then
            ./add-sa-in-iam.sh -p $SA_PROJECT_ID -e ${output[0]} -l $PROJECT_LIST
            status_add_sa=$?
        else
            ./add-sa-in-iam.sh -p $SA_PROJECT_ID -e ${output[0]} -w $ALLOWED_CSV
            status_add_sa=$?
        fi
        if [[ "$status_add_sa" -eq 0 ]]; then
            echo ""
            chmod +x enable-api.sh
            if [ "$RESULT_PROJECT_LIST" == "NotEmpty" ]; then
                ./enable-api.sh -p $SA_PROJECT_ID -l $PROJECT_LIST
                status_enable_api=$?
            else
                ./enable-api.sh -p $SA_PROJECT_ID -w $ALLOWED_CSV
                status_enable_api=$?
            fi
            if [[ "$status_enable_api" -eq 0 ]]; then
                echo ""
                echo ""
                echo -e "${BCyan}Summary:${NC}"
                echo -e "${BCyan}Service Account Project ID:${NC} $SA_PROJECT_ID"
                echo -e "${BCyan}Service Account Email:${NC} ${output[0]}"
                echo -e "${BCyan}Service Account Key Name:${NC} ${output[1]}"
                echo -e "${BCyan}Service Account Key File Path:${NC} ${output[2]}"
                echo -e "$(rm -rf output)"
            else
                echo -e "${RED}Failed to run script${NC} "
                exit 1
            fi
        else
            echo -e "${RED}Failed to run script${NC} "
            exit 1
        fi
    else
        echo -e "${RED}Failed to run script${NC} "
        exit 1
    fi
}
project_based_prerequisites