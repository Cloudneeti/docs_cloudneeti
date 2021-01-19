
: '
#SYNOPSIS
    GCP Onboard Prerequisites.
.DESCRIPTION
    These scripts has been used to create Service Account, Service Account Key, add Service Account in IAM, assign roles to service account and enable all the pre-requisite APIs required to onboard GCP Organization & Project on ZCSPM
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
                1. 1-10 projects
                2. All projects
                3. Allowed list of projects (.csv file)
                4. All projects excluding a list of projects (.csv file)
        - List of APIs Enabled on project where service account is created 
            [cloudresourcemanager.googleapis.com, sqladmin.googleapis.com, storage.googleapis.com, iam.googleapis.com, logging.googleapis.com, monitoring.googleapis.com, cloudasset.googleapis.com, serviceusage.googleapis.com]
        - List of APIs Enabled on project where service account is created and selected for onboarding
            [cloudresourcemanager.googleapis.com, compute.googleapis.com, bigquery.googleapis.com, dns.googleapis.com, sqladmin.googleapis.com, storage.googleapis.com, iam.googleapis.com, logging.googleapis.com, monitoring.googleapis.com, cloudasset.googleapis.com, serviceusage.googleapis.com]
        - List of APIs enabled on project selected for onboarding
            [compute.googleapis.com, bigquery.googleapis.com, dns.googleapis.com, serviceusage.googleapis.com]


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
            1. 1-10 projects
            2. Allowed list of projects (.csv file)
        - List of APIs Enabled on project where service account is created 
            [cloudresourcemanager.googleapis.com, sqladmin.googleapis.com, storage.googleapis.com, iam.googleapis.com, logging.googleapis.com, monitoring.googleapis.com, cloudasset.googleapis.com, serviceusage.googleapis.com]
        - List of APIs Enabled on project where service account is created and selected for onboarding
            [cloudresourcemanager.googleapis.com, compute.googleapis.com, bigquery.googleapis.com, dns.googleapis.com, sqladmin.googleapis.com, storage.googleapis.com, iam.googleapis.com, logging.googleapis.com, monitoring.googleapis.com, cloudasset.googleapis.com, serviceusage.googleapis.com]
        - List of APIs enabled on project selected for onboarding
            [compute.googleapis.com, bigquery.googleapis.com, dns.googleapis.com, serviceusage.googleapis.com]

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

    # Open cloud shell and set project
    $ gcloud config set project <Project_ID>

    # Download the script on cloud shell by following the documentation

    # make sure your are authenticated to GCP
    $ gcloud auth list

    # change the directory
    $ cd gcp-bulkonboarding/gcp-onboard-prerequisites/

    # Organization based onboarding
    # chmod +x create-sa.sh
    # 

    $ ./GCP_Onboard_Prerequisites.sh
    ...snip...
    GCP Onboard Prerequisites script executed.

    # Service account key is created in the same directory with the service account name (.json).
    $ ls
    # download the key from the path by clicking three dot button at top right corner of cloud shell and select "Download File" option.
    # Please provide full path to key file while downloading ( Example: /path/to/key.json)


.INPUTS
    None
.OUTPUTS
    None
'

