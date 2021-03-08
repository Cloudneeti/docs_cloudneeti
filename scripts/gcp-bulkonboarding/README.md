# GCP Onboard Prerequisites 

This Project holds the GCP Onboard Prerequisites scripts that has been used to create Service Account, Service Account Key, add Service Account in IAM, assign roles and enable all the pre-requisite APIs required to onboard GCP Organization & Project on ZCSPM.

# Disclaimer
Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
Version: 1.0

## Coverage

The gcp onboard prerequisites scripts covers:

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
            1. (-l) List of project IDs --> (<=10 Projects)
            2. (-a) All projects
            3. (-w) Allowed list of projects (.csv file) --> (>=10 projects)
            4. (-x) All projects excluding a list of projects (.csv file)


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
        1. (-l) List of project IDs --> (<=10 Projects)
        2. (-w) Allowed list of projects (.csv file) --> (>=10 projects)

# PREREQUISITE

- Organization Based onbaording

    | Action  | Required Permission | Required APIs  | Billing Account | Options  |
    | ------------- | ------------- | ------------- |-------------  | ------------- |
    | Create Service Account & Key  | Owner/Editor |  |  |  |
    | Promote Service account to Organization level & Attach Roles  | Organization Administrator |  |  |    |
    | Enable APIs | Owner/Editor<br />Cloud Asset Viewer | Cloud Asset API  | All projects must be linked with Billing Account  | (-l) List of project IDs --> (<=10 Projects)<br />(-a) All projects<br />(-w) Allowed list of projects (.csv file) --> (>=10 projects)<br />(-x) All projects excluding a list of projects (.csv file) |


    ### [optional] CSV file with Allowed or Excluded list of project

    If you are onboarding specific set of project then please create a .csv file with allowed or excluded list of project. by running the below command on cloud shell you can list all the project within organization in .csv file and create allowed or excluded list of project.

    ```
    # Open cloud shell and run the below command
    $ gcloud alpha asset list --organization=<ORG_ID> --content-type=resource --asset-types=cloudresourcemanager.googleapis.com/Project --format="csv(resource.data.projectId,resource.data.name)" > projlist.csv 
    ```


- Project Based onbaording

    | Action  | Required Permission | Billing Account |  Options |
    | ------------- | ------------- |-------------  | ------------- |
    | Create Service Account & Key  | Owner |  |  |
    | Add Service Account in IAM & Attach Roles  | Owner |   | (-l) List of project IDs --> (<=10 Projects)<br />(-w) Allowed list of projects (.csv file) --> (>=10 projects) |
    | Enable APIs | Owner | All projects must be linked with Billing Account | (-l) List of project IDs --> (<=10 Projects)<br />(-w) Allowed list of projects (.csv file) --> (>=10 projects) |


    ### [optional] CSV file with Allowed list of project

    If you are onboarding number of projects then please create a .csv file with allowed list of projects, by running the below command on cloud shell you can list all the project in .csv file and create allowed list of project.

    ```
    # Open cloud shell and run the below command
    $ gcloud projects list --format="csv(projectId,name)" > projectlist.csv
    ```

## Running the GCP Onboard Prerequisites scripts on Cloud Shell
### CLI Example

#### Setup: Set project & download script
```
# Open cloud shell and set project
$ gcloud config set project <Project_ID>

# make sure you're authenticated to GCP
$ gcloud auth list

# Run the below commnad to download script
$ wget https://raw.githubusercontent.com/lomaingali/docs_cloudneeti/amol/gcp-preOnboard-script/scripts/gcp-bulkonboarding/gcp-bulkonboarding.sh

# Change the permission & run the script
$ chmod +x gcp-bulkonboarding.sh
$ ./gcp-bulkonboarding.sh
# it will download all the script required to setup gcp onboard prerequisites

```

#### Organization based onboarding
```
# Once completed the setup follow steps:

# Change the directory
$ cd gcp-bulkonboarding/gcp-onboard-prerequisites/

# Create Service Account
# Change the permission of file
$ chmod +x create-sa.sh

# Run the below command:
$ ./create-sa.sh -p <SA_PROJECT_ID> -s <SA_NAME> -d <SA_DISPLAY_NAME>
# Summary will give you the Service account Email & Key file path, copy the path of the key & and click three dot icon at top right corner of cloud shell, select Download File option and download the key.
$ cloudshell download <KEY_PATH>

# Promote Service account to Organization level
# Change the permission of file
$ chmod +x promote-sa-to-org.sh

# Run the below command:
$ ./promote-sa-to-org.sh -o <ORGANIZATION_ID> -e <SERVICE_ACCOUNT_EMAIL>

# Enable APIs
# Change the permission of file
$ chmod +x enable-api.sh

# Run the below command:
$ ./enable-api.sh -o <ORGANIZATION_ID> -p <SA_PROJECT_ID>

    Provide one of the following options to enable APIs for Organization-based Onboarding:
    -l List of project IDs --> (<=10 Projects)
       (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    -a All projects (value=ALL)
    -w Allowed list of projects (.csv file) --> (>=10 projects)
       (Example: /home/path/to/allowed_list.csv )
    -x All projects excluding a list of projects (.csv file)
       (Example: /home/path/to/excluded_list.csv )
```

#### Project based onboarding
```
# Once completed the setup follow steps:

# Change the directory
$ cd gcp-bulkonboarding/gcp-onboard-prerequisites/

# Change the permission of file
$ chmod +x Projectbased-onboard-prerequisites.sh

# Run the below command to setup gcp onboard prerequisites
$ ./Projectbased-onboard-prerequisites.sh -p <SA_PROJECT_ID> -s <SA_NAME> -d <SA_DISPLAY_NAME>

    Provide one of the following options to enable APIs and add service account in IAM for Project-based Onboarding:
    -l List of project IDs --> (<=10 Projects)
      (Example: "ProjectID_1,ProjectID_2,ProjectID_3,..." etc)
    -w Allowed list of projects (.csv file) --> (>=10 projects)
      (Example: /home/path/to/allowed_list.csv )

# Summary will give you the Service account Email & Key file path, copy the path of the key & and click three dot icon at top right corner of cloud shell, select Download File option and download the key.
```