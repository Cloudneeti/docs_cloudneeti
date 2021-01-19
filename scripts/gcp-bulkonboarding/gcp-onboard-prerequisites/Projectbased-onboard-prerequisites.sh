#!/bin/bash
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"
############################################################################

OnboardType="ProjectBased"

# Function: Print a help message.
usage() {
  echo "Usage: $0 [ -p Project ID to create a Service Account ] [ -s Service Account Name ] [ -d Service Account display name ] [ -l ] [ -c ]" 1>&2 
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
while getopts ":p:s:d:l:c:" flag
do
    case "${flag}" in
        # project ID to create a service account
        p) SA_PROJECT_ID=${OPTARG};;
        # service account name
        s) SA_NAME=${OPTARG};;
        # service account display name
        d) SA_DISPLAY_NAME=${OPTARG};;

        l) list=${OPTARG}
        echo "$list";;

        c) INPUT=${OPTARG};;

        :)                                         # If expected argument omitted:
        echo "Error: -${OPTARG} requires an argument."
        exit_abnormal;;                            # Exit abnormally.
      
        *)                                         # If unknown (any other) option:
        exit_abnormal;;
    esac
done

summary_result()
{
    output=()
    [ ! -f output ] && { echo "output not found"; exit 99; }
    i=0
    while IFS=',' read -r f1
    do
        test $i -eq 1 && ((i=i+1)) && continue
        output+=( "$f1" )  
    done < "output"
}

chmod +x create-sa.sh
source ./create-sa.sh -p $SA_PROJECT_ID -s $SA_NAME -d $SA_DISPLAY_NAME
status=$?
if [[ "$status" -eq 0 ]]; then
    summary_result
    chmod +x add-sa-iam.sh
    if [ $([[ ! -z "$list" ]] && echo "NotEmpty" || echo "Empty") == "NotEmpty" ]; then
        ./add-sa-iam.sh -p $SA_PROJECT_ID -e ${output[0]} -l $list
        status_add_sa=$?
    else
        ./add-sa-iam.sh -p $SA_PROJECT_ID -e ${output[0]} -c $INPUT
        status_add_sa=$?
    fi
    if [[ "$status_add_sa" -eq 0 ]]; then
        echo ""
        chmod +x enable-api.sh
        if [ $([[ ! -z "$list" ]] && echo "NotEmpty" || echo "Empty") == "NotEmpty" ]; then
            ./add-sa-iam.sh -p $SA_PROJECT_ID -e ${output[0]} -l $list
            status_add_sa=$?
        else
            ./enable-api.sh -P project-based -p $SA_PROJECT_ID -c $INPUT
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
        else
            echo -e "${RED}Failed to run script${NC} "
            $(rm -rf output)
            exit_abnormal
        fi
    else
        echo -e "${RED}Failed to run script${NC} "
        $(rm -rf output)
        exit_abnormal
    fi
else
    echo -e "${RED}Failed to run script${NC} "
    $(rm -rf output)
    exit 1
fi