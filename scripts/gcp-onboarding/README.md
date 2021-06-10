# GCP Project Onboarding Scripts

This directory contains a set of scripts that can be used for configuring prerequisites required for GCP onboarding to the ZCSPM platform.

## Overview

ZCSPM supports the following onboarding options,

* Organization Based Onboarding
* Project Based Onboarding

In order to onboard the GCP projects on the ZCSPM platform customer needs to perform majorly 3 steps as part of the prerequisites configuration.

1. Creation of Service Account and Key
2. Assigning roles to Service Principal
3. Enabling service APIs on GCP projects

## Prepare workstation

1. Open GCP cloudshell
2. Set GCP Project
   ```bash
   $ gcloud config set project <Project_ID>

   # make sure you're authenticated to GCP
   $ gcloud auth list
   ```
3. Download onboarding prerequisites scripts
   ```bash
   $ wget -O - https://raw.githubusercontent.com/Cloudneeti/docs_cloudneeti/rahul/gcp-onboarding-scripts/scripts/gcp-onboarding/download-gcp-onboarding-scripts.sh | bash
   ```
4. Make scripts executable
   ```bash

   $ chmod +x zcspm-gcp-onboarding/*.sh
   ```
5. Switch working directory
   ```bash

   $ cd zcspm-gcp-onboarding
   ```

## Organization Based Onboarding

### Permissions

Make sure you have below permission on GCP projects while executing the below commands.

| Action  | Required Permission | Billing Account |
| ------------- | ------------- | -------------  |
| Create Service Account & Key  | Project Owner/Editor |  |  |
| Promote Service account and assign role  | Organization Administrator |  |
| Enable Service APIs on GCP project | Project Owner/Editor  | All projects must be linked with Billing Account  |

### Configure organization onboarding prerequisites

**Step 1: Create Service Account**

1. Execute below command to create service account in the GCP project
	```bash
	$ ./create-service-account.sh -p <PROJECT_ID> -s <SERVICE_ACCOUNT_NAME>
	```
2. Find the summary section in the script output for Service account Email & Key file path
3. Copy service account key file path and run below command to download service account key file
	```bash
	$ cloudshell download <SERVICE_ACCOUNT_KEY_FILE_PATH>
	```
4. Store key file at a secure location

**Step 2: Promote Service account to Organization level and assign roles**

Execute the below command to promote the GCP service account at an organization level. It also assigns required ZCSPM roles to the service account

```bash
$ ./promote-service-account.sh -s <SERVICE_ACCOUNT_EMAIL> -o <GCP_ORGANIZATION_ID>
```

**Step 3: Enable Service APIs on GCP project**

Execute the below command to enable ZCSPM required service APIs on all the projects present in the GCP organization

```bash
$ ./enable-gcp-api.sh -s <SERVICE_ACCOUNT_PROJECT_ID> -o <GCP_ORGANIZATION_ID> -a
```

**Note:**
If you have more than 400 projects in the GCP organization then try to increase below API limits of GCP project where service account is created by contacting the GCP support team.
* Service Usage API - Default Request
* Service Usage API - Mutate Request


**[Optional] Multiple projects present in CSV**
1. If you are onboarding a certain number of projects then create a .csv file, by running the below command on the cloud shell you can list all the projects in a .csv file.

	```bash
	$ gcloud alpha asset list --organization=<GCP_ORGANIZATION_ID> --content-type=resource --asset-types=cloudresourcemanager.googleapis.com/Project --format="csv(resource.data.projectId,resource.data.name)" > projlist.csv
	```
	Updates CSV file as per requirement.

2. Execute the below commands to enable service APIs for multiple GCP projects present in CSV file

	```bash
	$ ./enable-gcp-api.sh -s <SERVICE_ACCOUNT_PROJECT_ID> -c <PROJECT_LIST.CSV>
	```

## Project Based Onboarding

### Permissions
Make sure you have below permission on GCP projects while executing the below commands.

| Action | Required Permission | Billing Account |
| - | - | - |
| Create Service Account & Key | Project Owner |   |
| Assign roles to Service Account | Project Owner |   |
| Enable Service APIs on GCP project | Project Owner | All projects must be linked with Billing Account |

### Configure project onboarding prerequisites

**Step 1: Single or multiple project**

Execute the below commands to configure project onboarding prerequisites for single or multiple projects

```bash
$ ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -l <PROJECT_LIST>
```

**[Optional] Multiple projects present in CSV**

1. If you are onboarding a certain number of projects then create a .csv file, by running the below command on the cloud shell you can list all the projects in a .csv file.

	```bash
	$ gcloud projects list --format="csv(projectId,name)" > projectlist.csv
	```
	
2. Execute the below commands to configure project onboarding prerequisites for multiple projects present in a CSV file

	```bash
	$ ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -c <PROJECT_LIST.CSV>
	```
	
**Step 2: Download Service Account Key File**

1. Find the summary section in the script output for Service account Email & Key file path
2. Copy service account key file path and run below command to download service account key file
	```bash
	$ cloudshell download <SERVICE_ACCOUNT_KEY_FILE_PATH> 
	```
3. Store key file at a secure location


# Disclaimer

Copyright (c) Zscaler. All rights reserved.
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software. 
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.