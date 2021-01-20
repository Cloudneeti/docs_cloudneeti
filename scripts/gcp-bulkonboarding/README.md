# GCP Onboard Prerequisites 

This Project holds the GCP Onboard Prerequisites scripts that has been used to create Service Account, Service Account Key, add Service Account in IAM, assign roles and enable all the pre-requisite APIs required to onboard GCP Organization & Project on ZCSPM.

# Disclaimer
Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Version: 1.0

## Coverage

The pre-onbaording script covers:

- Organization Based onbaording
    - Create Service Account
    - Create Service Account Key (Service account will be created in same directory where your are running this script)
    - Promote Service at Organzation Level IAM & attach required roles
        - Organization Role Viewer
        - Folder Viewer
        - Project--> Viewer
        - Cloud Asset Viewer 
    - Enable APIs on projects which are going to onboard on ZCSPM
        - Options 
            1. List of project IDs --> (<=10 Projects)
            2. All projects
            3. Allowed list of projects (.csv file) --> (>=10 projects)
            4. All projects excluding a list of projects (.csv file)


- Project Based Onboarding
    - Single Project
        - Create Service Account
        - Create Service Account Key (Service account will be created in same directory where your are running this script)
        - Add Service account in IAM & attach required roles
            - Project--> Viewer
            - Cloud Asset Viewer
        - Enable APIs & add Service Acoount in IAM for project which is going to onboard on ZCSPM
    - Multiple Project
        - Create Service Account
        - Create Service Account Key (Service account will be created in same directory where your are running this script)
        - Add Service account in IAM of all the project & assign required roles
            - Project--> Viewer
            - Cloud Asset Viewer
        - Enable APIs and add Service Acoount in IAM for projects which are going to onboard on ZCSPM
    - Options
        1. [-l] List of project IDs separated by a comma --> (<=10 Projects)
        2. [-c] Allowed list of projects (.csv file) --> (>=10 projects)

# PREREQUISITE

- Organization Based onbaording
    ### Required APIs

    The following GCP APIs should be enabled on cloud shell project:

    - cloudasset.googleapis.com

    ### Required Permissions

    The following permissions are required to run the pre-onboarding script:

    On organization level:

    - Project--> Owner/Editor [ Create Service account, Enable APIs]
    - Organization Administrator [ Promote Service account to Organization level ]
    - Cloud Asset Viewer [ Enable APIs]

    ### [optional] CSV file with Allowed or Excluded list of project

    If you are onboarding specific set of project then please create a .csv file with allowed or excluded list of project. by running the below command on cloud shell you can list all the project within organization in .csv file and create allowed or excluded list of project.

    ```
    # Open cloud shell and run the below command
    $ gcloud alpha asset list --organization=<ORG_ID> --content-type=resource --asset-types=cloudresourcemanager.googleapis.com/Project --format="csv(resource.data.projectId,resource.data.name)" > projlist.csv 
    ```


- Project Based onbaording
    ### Required APIs

    The following GCP APIs should be enabled on cloud shell project:

    - cloudresourcemanager.googleapis.com

    ### Required Permissions

    The following permissions are required on all the project to run the pre-onboarding script:

    On project level:

    - Project--> Owner

    ### [optional] CSV file with Allowed list of project

    If you are onboarding number of projects then please create a .csv file with allowed list of projects, by running the below command on cloud shell you can list all the project in .csv file and create allowed list of project.

    ```
    # Open cloud shell and run the below command
    $ gcloud projects list --format="csv(projectId,name)" > projectlist.csv
    ```

## Running the pre-onboarding script on Cloud Shell
### CLI Example

```
# Open cloud shell and set project
$ gcloud config set project <Project_ID>

# Download gcp-prequisites script

# make sure you're authenticated to GCP
$ gcloud auth list
```
#### Organization based onboarding
```
# Change the directory
$ cd gcp-bulkonboarding/gcp-onboard-prerequisites/

# Run the below command create Service Account
$ chmod +x create-sa.sh
$ ./create-sa.sh -p <Project_ID> -s <Service_Account_Name> -d <Service_Account_Display_Name>
# Summary will give you the Service account Email & Key file path, download the key.

# Run the below command to Promote Service account to Organization level
$ chmod +x promote-sa-to-org.sh
$ ./promote-sa-to-org.sh -o <ORGANIZATION_ID> -e <Service_Account_Email>

# Run the below command to Enable APIs
$ chmod +x enable-api.sh
$ ./enable-api.sh -O org-based -o <ORGANIZATION_ID> -p <Service_Account_Project_ID>
# it will prompt for the options please select the appropriate option and proceed.
```
#### Project based onboarding
```
# Change the directory
$ cd gcp-bulkonboarding/gcp-onboard-prerequisites/

# Run the below command
$ chmod +x Projectbased-onboard-prerequisites.sh
$ ./Projectbased-onboard-prerequisites.sh -p <Project_ID> -s <Service_Account_Name> -d <Service_Account_Display_Name> -l "<List_Of_Project_IDs>"
OR
$ ./Projectbased-onboard-prerequisites.sh -p <Project_ID> -s <Service_Account_Name> -d <Service_Account_Display_Name> -c "<CSV_File_Path>"
# Summary will give you the Service account Email & Key file path, download the key.
```