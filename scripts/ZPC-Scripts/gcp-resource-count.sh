#!/bin/bash

: '
SYNOPSIS
    Script to get the count of all the resources present in GCP Organization and project.
DESCRIPTION
    This script will get the count of all the resource present in GCP Organization and project.
NOTES
    Copyright (c) Zscaler. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    
    Version: 1.0
    # PREREQUISITE
    - Run this script on GCP cloudshell
    - Required Roles & Permission
        Organization level:
            - Organization Viewer
            - Owner/Editor/Cloud Asset Viewer
        Project level:
            - Owner/Editor/Cloud Asset Viewer
EXAMPLE
    1.Get Organization level assets count
    ./gcp-resource-count.sh -o <GCP_ORGANIZATION_ID>
    2.Get Project level assets count
    ./gcp-resource-count.sh -p ROJECT_ID
INPUTS
    (-o)GCP Organization ID
    (-p)Project ID
OUTPUTS
    Workload and total resources present in GCP Organization and Project.
'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;35m'
NC='\033[0m'
BCyan="\033[1;36m"
###############################################################################

# Function: Print a help message.
usage() {
    echo "Script to get the count of all the resources present in GCP Organization and project"
    echo ""
    echo "Syntax: $0 -o GCP_ORGANIZATION_ID | -p ROJECT_ID"
    echo "Options:"
    echo "  -h    Help"
    echo "  -o    GCP Organization ID"
    echo "  -p    Project ID"
}

exit_abnormal() {
  usage
  exit 1
}

#Check the number of arguments. If none are passed, print usage and exit.
NUMARGS=$#

if [ $NUMARGS -ne 2 ]; then
  usage
  exit 1
fi

# Flags
while getopts ":o:p:h" options
do 
    case "$options" in
        o) #Organization ID
            GCP_ORGANIZATION_ID=${OPTARG}
            ;;

        p) # Project ID
            PROJECT_ID=${OPTARG}
            ;;
           
        h | *) # Display Help and usage in case of error
            exit_abnormal
            ;;
    esac
done

validate_parameters()
{
    echo "Validating input parameters"

    # validate if both the options are provided
    if [[ ! -z $GCP_ORGANIZATION_ID && ! -z $PROJECT_ID ]]; then
        echo -e "${YELLOW}Warn:${NC} Please select any one of the option from: [ -o GCP_ORGANIZATION_ID | -p PROJECT_ID ]"
        exit_abnormal
    fi

    # Set Asset load option "--organization || --project"
    if [[ ! -z "$GCP_ORGANIZATION_ID" ]]; then
        ASSET_LOAD_OPTION="--organization"
        ID="$GCP_ORGANIZATION_ID"

        # Validate Organization Id
        echo "Validating Organization ID"
        VALID_ORG_ID=$(gcloud organizations list --filter=$GCP_ORGANIZATION_ID | awk 'NR == 2 {print $2}')
        if [[ $VALID_ORG_ID != $GCP_ORGANIZATION_ID ]]; then
                echo -e "${RED}Incorrect Organization ID $GCP_ORGANIZATION_ID provided${NC}"
                echo -e "${YELLOW}Please provide the valid Organization ID and Continue..${NC}"
                exit
        fi
    else
        ASSET_LOAD_OPTION="--project"
        ID="$PROJECT_ID"
    fi
}

# load ZCSPM workloads
ZCSPM_WORKLOADS=()
load_workloads()
{    
    WorkloadMapping="https://raw.githubusercontent.com/Cloudneeti/docs_cloudneeti/master/scripts/ZPC-Scripts/workloadMapping.json"
    # Load zcspm roles into array
    ZCSPM_WORKLOADS=$( curl -s $WorkloadMapping | jq -r .workloadMapping.GCP[] )
        if [[ -z $ZCSPM_WORKLOADS ]]; then
        echo -e "${RED}Failed to load the workload mapping${NC}"
        echo -e "Check Error message above and try again later"
        exit
    fi
}

# Declare the variable & array
WORKLOAD_COUNT=0
RESOURCE_COUNT=0
WORKLOAD_FUNCTION_COUNT=0 #For gcp functions 
WORKLOAD_FINAL_COUNT=0 #For new workload count for ZPC
Workload_distribution=()
Resource_distribution=()

# get gcp asset count
get_gcp_asset_count()
{
    echo -e "Scanning assets..."
    # Processing all the assets
    for asset in $(gcloud beta asset list $ASSET_LOAD_OPTION $ID --filter="NOT assetType:cloudresourcemanager.googleapis.com*" --format="value(assetType)")
    do
        for workload in ${ZCSPM_WORKLOADS[@]}
        do
            if [[ $workload == "$asset" ]]; then
                # Get the total workload count supported by zcspm
                if [[ $workload = "cloudfunctions.googleapis.com/CloudFunction" ]]; then
                    (( WORKLOAD_FUNCTION_COUNT++ ))
                    Workload_distribution+=("$workload")
                else
                    (( WORKLOAD_COUNT++ ))
                 Workload_distribution+=("$workload")
                fi
            fi
        done
        # Get the total Resource count
        (( RESOURCE_COUNT++ ))
        Resource_distribution+=("$asset")
    done

    if [[ $WORKLOAD_FUNCTION_COUNT = 0 ]]; then
        WORKLOAD_FINAL_COUNT=$(($WORKLOAD_COUNT))
    fi    
    if [[ $WORKLOAD_FUNCTION_COUNT > 0 && $WORKLOAD_FUNCTION_COUNT < 5 ]]; then
        WORKLOAD_FINAL_COUNT=$(($WORKLOAD_COUNT + 1))
    fi
    if [[ $WORKLOAD_FUNCTION_COUNT = 5 || $WORKLOAD_FUNCTION_COUNT > 5 ]]; then
        WORKLOAD_FINAL_COUNT=$(awk -v var1=$WORKLOAD_FUNCTION_COUNT -v var2=$WORKLOAD_COUNT 'BEGIN { printf("%.0f\n", var1/5 + var2); }')
        #WORKLOAD_FINAL_COUNT=$(($WORKLOAD_FUNCTION_COUNT / 5 + $WORKLOAD_COUNT))
    fi

    # get only active Projects & Folders and append to list
    for asset in $(gcloud beta asset list $ASSET_LOAD_OPTION $ID --content-type=resource --asset-types=cloudresourcemanager.googleapis.com.* --filter=resource.data.lifecycleState=ACTIVE --format="value(assetType)")
    do
        # Get Resource count for active Projects & Folder
        (( RESOURCE_COUNT++ ))
        Resource_distribution+=("$asset")
    done
}

# Main Execution

# Validate Parameters
validate_parameters

# load zcspm gcp workloads
echo "Loading GCP workload mapping supported by zcspm"
load_workloads
echo -e "${GREEN}Successfully loaded GCP workload mapping supported by zcspm${NC}"

# Get gcp assets and their count
get_gcp_asset_count

# Get workload Distribution
echo -e "${GREEN}Workload Distribution:${NC}"
for workload in ${Workload_distribution[@]}; do echo "$workload"; done | sort | uniq -c | awk ' FS=" " { print "   " $2 " : " $1 } '
echo -e ""

# Resource Distribution
echo -e "${GREEN}Resource Distribution:${NC}"
for asset in ${Resource_distribution[@]}; do echo "$asset"; done | sort | uniq -c | awk ' FS=" " { print "   " $2 " : " $1 } '
echo -e ""

echo -e "${GREEN}Summary:${NC}"
############################################
echo -e "   ""Zscaler CSPM Supported Total Workloads : $(($WORKLOAD_FINAL_COUNT))"
echo -e "   ""Total Resources : $(($RESOURCE_COUNT))"
