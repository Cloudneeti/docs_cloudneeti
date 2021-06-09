# GCP Project Onboarding Scripts

This directory contains set of scripts that can be used for configuring prerequisites required for GCP onboarding to the ZCSPM platform.

## Overview

ZCSPM supports following onboarding options,

* Organization Based Onboarding
* Project Based Onboarding

In order to onboard the GCP projects on ZCSPM platform customer needs to perform majorly 3 steps as part of prerequisites configuration.

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
5. Swich working directory
   ```bash

   $ cd zcspm-gcp-onboarding
   ```

## Organization Based Onboarding

### Configure organization onboarding prerequisites

**Step 1: Create Service Account**

**Step 2: Assign Roles to Service Account**

**Step 3: Enable Service APIs on GCP project**

## Project Based Onboarding

### Permissions
Make sure you have below permission on GCP projects while executing the below commands.

| Action | Required Permission | Billing Account |
| - | - | - |
| Create Service Account & Key | Project Owner |   |
| Assign roles to Service Account | Project Owner |   |
| Enable APIs | Project Owner | All projects must be linked with Billing Account |

### Configure project onboarding prerequisites

**Step 1: Single or multiple project**

Execute below commands to configure project onboarding prerequisites for single or multiple projects

```bash
$ ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -l <PROJECT_LIST>
```

**[Optional] Multiple projects present in CSV**

1. If you are onboarding number of projects then please create a .csv file with allowed list of projects, by running the below command on cloud shell you can list all the project in .csv file and create allowed list of project.

	```bash
	# Open cloud shell and run the below command
	$ gcloud projects list --format="csv(projectId,name)" > projectlist.csv
	```
	
2. Execute below commands to configure project onboarding prerequisites for multiple projects present in CSV file

	```bash
	$ ./configure-project-onboarding-prerequisites.sh -p <SERVICE_ACCOUNT_PROJECT_ID> -s <SERVICE_ACCOUNT_NAME> -c <ALLOWED_PROJECT_LIST.CSV>
	```
	
**Step 2: Download Service Account Key File**

1. Find summary section in the script output for Service account Email & Key file path
2. Copy service account key file path and run below command to download service account key file
	```bash
	$ cloudshell download <SERVICE_ACCOUNT_KEY_FILE_PATH> 
	```
3. Store key file at secure location