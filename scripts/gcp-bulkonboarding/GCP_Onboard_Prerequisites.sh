#!/bin/bash

: '
#SYNOPSIS
    GCP onboard prerequisites script.
.DESCRIPTION
    This script has been used to create Service Account, Service Account Key, add Service Account in IAM, assign roles to service account and enable all the pre-requisite APIs required to onboard GCP Organization & Project on ZCSPM
.NOTES
    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    Version: 1.0
    ## Coverage

    The prerequisites script covers:

    - Organization Based onbaording
        - Create Service Account
        - Create Service Account Key (Service account will be created in same directory where your are running this script)
        - Promote Service at Organzation Level IAM and attach required roles
            - Organization Role Viewer
            - Folder Viewer
            - Project--> Viewer
            - Cloud Asset Viewer 
        - Enable APIs on all the projects which are going to onboard on ZCSPM
            - Options 
                1. 1-5 projects
                2. All projects
                3. Allowed list of projects (.csv file)
                4. All projects excluding a list of projects (.csv file)


    - Project Based Onboarding
        - Single Project
            - Create Service Account
            - Create Service Account Key (Service account will be created in same directory where your are running this script)
            - Add Service account in IAM & attach required roles
                - Project--> Viewer
                - Cloud Asset Viewer
            - Enable APIs and add Service Acoount in IAM for project which is going to onboard on ZCSPM
        - Multiple Project
            - Create Service Account
            - Create Service Account Key (Service account will be created in same directory where your are running this script)
            - Add Service account in IAM of all the project & assign required roles
                - Project--> Viewer
                - Cloud Asset Viewer
            - Enable APIs and add Service Acoount in IAM for all the projects which are going to onboard on ZCSPM
        - Options
            1. 1-5 projects
            2. Allowed list of projects (.csv file)

    # PREREQUISITE

    - All projects must be linked with Billing Account.

    - Organization Based onbaording
        ### Required APIs

        The following GCP APIs should be enabled on cloud shell project:

        - iam.googleapis.com
        - cloudasset.googleapis.com

        ### Required Permissions

        The following permissions are required to run this script:

        On organization level:

        - Organization Administrator
        - Cloud Asset Viewer
        - Project--> Owner

        ### [optional] CSV file with Allowed or Excluded list of project

        If you are onboarding specific set of project then please create a .csv file with allowed or excluded list of project. by running the below command on cloud shell you can list all the project within organization in .csv file and create allowed or excluded list of project.

        # Open cloud shell and run the below command
        $ gcloud alpha asset list --organization=<ORG_ID> --content-type=resource --asset-types=cloudresourcemanager.googleapis.com/Project --format="csv(resource.data.projectId,resource.data.name)" > projectlist.csv 


    - Project Based onbaording
        ### Required APIs

        The following GCP APIs should be enabled on cloud shell project:

        - iam.googleapis.com

        ### Required Permissions

        The following permissions are required on all the projects to run this script:

        On project level:

        - Project--> Owner

        ### [optional] CSV file with Allowed list of project

        If you are onboarding number of projects then please create a .csv file with allowed list of projects, by running the below command on cloud shell you can list all the project in .csv file and create allowed list of project.

        # Open cloud shell and run the below command
        $ gcloud projects list --format="csv(projectId,name)" > projectlist.csv 

.EXAMPLE

    ## Running the script on Cloud Shell
    ### CLI Example 

    # make sure your are authenticated to GCP
    $ gcloud auth list

    # change the permission of script file to execute
    $ chmod +x GCP_Onboard_Prerequisites.sh

    $ ./GCP_Onboard_Prerequisites.sh
    ...snip...
    GCP Onboard Prerequisites script executed.

    Summary:
    Service Account Email: sa-name@project-org-01-280413.iam.gserviceaccount.com
    Service Account Key Name: sa-name.json
    Service Account Project Passed: 1
    Service Account Project Failed: 0
    Projects Passed: 15
    Projects Failed: 0

    # Service account key is created in the same directory with the service account name (.json).
    $ ls
    # download the key from the path by clicking three dot button at top right corner of cloud shell and select "Download File" option.
    # Please provide full path to key file while downloading ( Example: /path/to/key.json)
    $ pwd


.INPUTS
    None
.OUTPUTS
    None
'

RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
BCyan="\033[1;36m"

title="Please select the onboarding type: "
prompt="Pick an option: "
options=("Organization-based Onboarding" "Project-based Onboarding")
echo "$title"
PS3="$prompt"
select opt in "${options[@]}" "Quit"; do 

    case "$REPLY" in
    1)
    echo "You have selected '$opt'."
    SA_KEY=""
    success=0
    fail=0
    sa_success=0
    sa_fail=0
    ROLES=(roles/iam.organizationRoleViewer roles/viewer roles/resourcemanager.folderViewer roles/cloudasset.viewer)
    ##################
    echo ""
    echo -e "Enter the Organization ID: "
    read ORGANIZATION_ID
    echo ""
    echo -e "Enter the project ID to create a service account: "
    read SA_PROJECT_ID
    echo ""
    echo -e "Enter the service account name: "
    echo -e "(The service account name is case sensitive and must be in lowercase)"
    read SA_NAME
    echo ""
    echo -e "Enter the service account display name: "
    read SA_DISPLAY_NAME
    echo ""
    title="Please select one of the following options to enable APIs for Organization-based Onboarding: "
    prompt="Pick an option: "
    options=("1-5 projects" "All projects" "Allowed list of projects (.csv file)" "All projects excluding a list of projects (.csv file)")
    echo "$title"
    PS3="$prompt"
    select opt in "${options[@]}" "Quit"; do 

        case "$REPLY" in
        1 )
        org_enable_api_few_proj() {
        echo "You have selected '$opt'."
        echo -e ""
        echo -e "Enter the project IDs separated by a space: "
        echo -e "(Example: ProjectId_1 ProjectId_2 ProjectId_3 ... etc) "
        read -a IAM_PROJECT_ID
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
            do
                echo "Role:  $role"
                gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                statusOrgRoleSA=$?
                if [[ "$statusOrgRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Successfully Added role:${NC} $role"
                else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                fi
            done		
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi

        ###############################################
        echo -e ""
        echo -e "${BLUE}*****Enabling API's on Project*****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
        for project in "${IAM_PROJECT_ID[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
                echo "ProjectId: $SA_PROJECT_ID"
                $(gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com bigquery.googleapis.com dns.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
                statusSAProjAPI=$?
                if [[ "$statusSAProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
                    fail=$((fail + 1))
                fi
            else
                echo -e ""
                echo "ProjectId: $project"
                $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
                statusIAMProjAPI=$?
                if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $project"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $project"
                    fail=$((fail + 1))
                fi
            fi
        done
        }

        org_enable_api_few_proj
        break;;
        2 )
        org_enable_api_allProj_func() {
        echo "You have selected '$opt'."
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
            do
                echo "Role:  $role"
                gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                statusRoleSA=$?
                if [[ "$statusRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Successfully Added role:${NC} $role"
                else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                fi
            done			
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi
        echo -e ""
        echo -e "${BLUE}*****Enabling API's on all Project*****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
        for project in  $(gcloud alpha asset list --organization=$ORGANIZATION_ID --content-type=resource --asset-types="cloudresourcemanager.googleapis.com/Project" --format="value(resource.data.projectId)")
        do 
            echo "ProjectId:  $project" 
            $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
            statusAllProjAPI=$?
            if [[ "$statusAllProjAPI" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $project"
            success=$((success + 1))
            else
            echo -e ""
            echo -e "${RED}Failed to Enable APIs on:${NC} $project"
            fail=$((fail + 1))
            fi	
        done
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
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
            do
                echo "Role:  $role"
                gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                statusRoleSA=$?
                if [[ "$statusRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Successfully Added role:${NC} $role"
                else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                fi
            done			
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi
        echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
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
        for project in "${IAM_PROJECT_ID[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
                echo "ProjectId: $SA_PROJECT_ID"
                $(gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com bigquery.googleapis.com dns.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
                statusSAProjAPI=$?
                if [[ "$statusSAProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
                    fail=$((fail + 1))
                fi
            else
                echo -e ""
                echo "ProjectId: $project"
                $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
                statusIAMProjAPI=$?
                if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $project"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $project"
                    fail=$((fail + 1))
                fi 
            fi
        done
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
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Succefully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Succefully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
            do
                echo "Role:  $role"
                gcloud organizations add-iam-policy-binding $ORGANIZATION_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                statusRoleSA=$?
                if [[ "$statusRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Succefully Added role:${NC} $role"
                else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                fi
            done			
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi
        echo -e "${BLUE}****Enabling APIs on Project****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Succefully Enabled API's on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
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
        echo ""
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
        echo ""
        for project in "${IAM_PROJECT_ID[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
                echo "ProjectId: $SA_PROJECT_ID"
                $(gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com bigquery.googleapis.com dns.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
                statusSAProjAPI=$?
                if [[ "$statusSAProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Succefully Enabled API's on:${NC} $SA_PROJECT_ID"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
                    fail=$((fail + 1))
                fi
            else
                echo -e ""
                echo "ProjectId: $project"
                $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
                statusIAMProjAPI=$?
                if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Succefully Enabled API's on:${NC} $project"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $project"
                    fail=$((fail + 1))
                fi
            fi 
        done
        }

        org_enable_api_excludingProj_func
        break;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
        *) echo "Invalid option. Try another one.";continue;;

        esac

    done

    ##################################################################################
    echo -e ""
    echo -e ""
    echo -e "${GREEN}GCP Onboard Prerequisites script executed.${NC}"
    echo
    echo -e "${BCyan}Summary:${NC}"
    echo -e "${BCyan}Service Account Email:${NC} $SERVICE_ACCOUNT"
    echo -e "${BCyan}Service Account Key Name:${NC} $SA_KEY"
    echo -e "${BCyan}Service Account Project Passed:${NC} $sa_success"
    echo -e "${BCyan}Service Account Project Failed:${NC} $sa_fail"
    echo -e "${BCyan}Projects Passed:${NC} $success" 
    echo -e "${BCyan}Projects Failed:${NC} $fail"
    ###################################################################################
    break;;
    2)
    echo "You have selected '$opt'."
    echo -e ""
    SA_KEY=""
    success=0
    fail=0
    sa_success=0
    sa_fail=0
    ROLES=(roles/viewer roles/cloudasset.viewer)
    ##################
    echo -e "Enter the project ID to create a service account: "
    read SA_PROJECT_ID
    echo ""
    echo -e "Enter the service account name: "
    echo -e "(The service account name is case sensitive and must be in lowercase)"
    read SA_NAME
    echo ""
    echo -e "Enter the service account display name: "
    read SA_DISPLAY_NAME
    echo ""
    title="Please select one of the following options to enable APIs and add service account in IAM for Project-based Onboarding: "
    prompt="Pick an option: "
    options=("1-5 projects" "Allowed list of projects (.csv file)")
    echo "$title"
    PS3="$prompt"
    select opt in "${options[@]}" "Quit"; do 

        case "$REPLY" in

        1 )
        enable_api_few_proj() {
        echo "You have selected '$opt'."
        echo -e ""
        echo -e "Enter the project IDs separated by a space: "
        echo -e "(Example: ProjectID_1 ProjectID_2 ProjectID_3 ... etc) "
        read -a IAM_PROJECT_ID
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
                do
                    echo -e ""
                    echo "Role:  $role"
                    gcloud projects add-iam-policy-binding $SA_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                    statusRoleSA=$?
                    if [[ "$statusRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Successfully Added role:${NC} $role"
                    else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                    fi	
                done
            for project in "${IAM_PROJECT_ID[@]}"
            do
                for role in "${ROLES[@]}"
                do
                    if [ $SA_PROJECT_ID == $project ]; then
                        echo -e ""
                    else
                        echo -e ""
                        echo "Role:  $role"
                        gcloud projects add-iam-policy-binding $project --member serviceAccount:$SERVICE_ACCOUNT --role $role
                        statusRoleeq=$?
                        if [[ "$statusRoleeq" -eq 0 ]]; then
                        echo -e ""
                        echo -e "${GREEN}Successfully Added role:${NC} $role"
                        else
                        echo -e ""
                        echo -e "${RED}Failed to add role:${NC} $role"
                        fi
                    fi	
                done
            done		
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi

        ###############################################
        echo -e ""
        echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
        for project in "${IAM_PROJECT_ID[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
                echo "ProjectId: $SA_PROJECT_ID"
                $(gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com bigquery.googleapis.com dns.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
                statusSAProjAPI=$?
                if [[ "$statusSAProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
                    fail=$((fail + 1))
                fi
            else
                echo -e ""
                echo "ProjectId: $project"
                $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
                statusIAMProjAPI=$?
                if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $project"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $project"
                    fail=$((fail + 1))
                fi
            fi
        done
        }

        enable_api_few_proj
        break;;
        2 )
        enable_api_allowed_proj() {
        echo "You have selected '$opt'."
        echo -e ""
        IAM_PROJECT_ID=()
        echo -e ""
        echo -e "Enter the file path to the allowed list of projects: "
        echo -e "(Example: /home/path/to/allowed_list.csv )"
        read  INPUT
        [ ! -f $INPUT ] && { echo "$INPUT file not found"; exit 99; }
        i=1
        while IFS=',' read -r f1 f2
        do
            test $i -eq 1 && ((i=i+1)) && continue
            IAM_PROJECT_ID+=( "$f1" )  
        done < "$INPUT"
        echo ""
        gcloud iam service-accounts create $SA_NAME  --display-name $SA_DISPLAY_NAME --project=$SA_PROJECT_ID
        statusSA=$?
        if [[ "$statusSA" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Successfully Created Service account${NC}"
        else
            echo -e ""
            echo -e "${RED}Failed to create service account${NC}"
        fi
        sleep 5
        SERVICE_ACCOUNT=$(gcloud iam service-accounts list --format="value(email)" --project=$SA_PROJECT_ID | grep $SA_NAME@$SA_PROJECT_ID)
        statusSAlist=$?
        if [[ "$statusSAlist" -eq 0 ]]; then
            echo -e ""
            echo -e "${GREEN}Service account email :${NC} $SERVICE_ACCOUNT"
            echo -e ""
            gcloud iam service-accounts keys create $SA_NAME.json --iam-account=$SERVICE_ACCOUNT --key-file-type="json" --project=$SA_PROJECT_ID
            statusKey=$?
            if [[ "$statusKey" -eq 0 ]]; then
                echo -e ""
                SA_KEY=$(ls | grep $SA_NAME.json)
                echo -e "${GREEN}Successfully Created Service account key ${NC}"
            else
                echo -e ""
                echo -e "${RED}Failed to create service account key ${NC}"
            fi
            echo -e ""
            for role in "${ROLES[@]}"
                do
                    echo -e ""
                    echo "Role:  $role"
                    gcloud projects add-iam-policy-binding $SA_PROJECT_ID --member serviceAccount:$SERVICE_ACCOUNT --role $role
                    statusRoleSA=$?
                    if [[ "$statusRoleSA" -eq 0 ]]; then
                    echo -e ""
                    echo -e "${GREEN}Successfully Added role:${NC} $role"
                    else
                    echo -e ""
                    echo -e "${RED}Failed to add role:${NC} $role"
                    fi	
                done
            for project in "${IAM_PROJECT_ID[@]}"
            do
                for role in "${ROLES[@]}"
                do
                    if [ $SA_PROJECT_ID == $project ]; then
                        echo -e ""
                    else
                        echo -e ""
                        echo "Role:  $role"
                        gcloud projects add-iam-policy-binding $project --member serviceAccount:$SERVICE_ACCOUNT --role $role
                        statusRoleeq=$?
                        if [[ "$statusRoleeq" -eq 0 ]]; then
                        echo -e ""
                        echo -e "${GREEN}Successfully Added role:${NC} $role"
                        else
                        echo -e ""
                        echo -e "${RED}Failed to add role:${NC} $role"
                        fi
                    fi	
                done
            done		
        else
            echo -e ""
            echo -e "${RED}Failed to list service account${NC}"
        fi

        ###############################################
        echo -e ""
        echo -e "${BLUE}*****Enabling APIs on Project*****${NC}"
        echo -e ""
        echo "SA_ProjectId: $SA_PROJECT_ID"
        $(gcloud services enable cloudresourcemanager.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
        statusSAProjAPI1=$?
        if [[ "$statusSAProjAPI1" -eq 0 ]]; then
            echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
            sa_success=$((sa_success + 1))
        else
            echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
            sa_fail=$((sa_fail + 1))
        fi
        for project in "${IAM_PROJECT_ID[@]}"
        do
            if [ $SA_PROJECT_ID == $project ]; then
                echo -e ""
                echo "ProjectId: $SA_PROJECT_ID"
                $(gcloud services enable cloudresourcemanager.googleapis.com compute.googleapis.com bigquery.googleapis.com dns.googleapis.com sqladmin.googleapis.com storage.googleapis.com iam.googleapis.com logging.googleapis.com monitoring.googleapis.com cloudasset.googleapis.com serviceusage.googleapis.com --project $SA_PROJECT_ID)
                statusSAProjAPI=$?
                if [[ "$statusSAProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $SA_PROJECT_ID"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $SA_PROJECT_ID"
                    fail=$((fail + 1))
                fi
            else
                echo -e ""
                echo "ProjectId: $project"
                $(gcloud services enable compute.googleapis.com bigquery.googleapis.com dns.googleapis.com serviceusage.googleapis.com --project $project)
                statusIAMProjAPI=$?
                if [[ "$statusIAMProjAPI" -eq 0 ]]; then
                    echo -e "${GREEN}Successfully Enabled APIs on:${NC} $project"
                    success=$((success + 1))
                else
                    echo -e "${RED}Failed to Enable APIs on:${NC} $project"
                    fail=$((fail + 1))
                fi
            fi
        done
        }

        enable_api_allowed_proj
        break;;
        $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
        *) echo "Invalid option. Try another one.";continue;;

        esac

    done

    ##################################################################################
    echo -e ""
    echo -e ""
    echo -e "${GREEN}GCP Onboard Prerequisites script executed.${NC}"
    echo
    echo -e "${BCyan}Summary:${NC}"
    echo -e "${BCyan}Service Account Email:${NC} $SERVICE_ACCOUNT"
    echo -e "${BCyan}Service Account Key Name:${NC} $SA_KEY"
    echo -e "${BCyan}Service Account Project Passed:${NC} $sa_success"
    echo -e "${BCyan}Service Account Project Failed:${NC} $sa_fail"
    echo -e "${BCyan}Projects Passed:${NC} $success" 
    echo -e "${BCyan}Projects Failed:${NC} $fail"
    ###################################################################################
    break;;
    $(( ${#options[@]}+1 )) ) echo "Goodbye!"; break;;
    *) echo "Invalid option. Try another one.";continue;;

    esac

done
