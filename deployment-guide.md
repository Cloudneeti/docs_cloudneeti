---
layout: default
title: Installation & Deployment Guide
author: Ajay C
modified by: Julian A
---

# Getting Started with CloudNeeti VM for Azure Marketplace

This article describes how to Automate Governance, Compliance, Reliability and Risk Monitoring for an enterprise using Azure

To deploy CloudNeeti VM from the Azure Marketplace:

**Note**: User logging into Azure Portal must have Global admin role to make the necessary configuration changes.

## Purchase CloudNeeti from Azure Marketplace
1. Log in to the  [Microsoft Azure portal](https://portal.azure.com/). 
2. Click Marketplace or click Browse &gt; in the left side navigation, and select Marketplace from the list.
3. In Click the Security + Identity blade and search for `CloudNeeti Enterprise`.
4. Click CloudNeeti Enterprise
5. In the CloudNeeti Enterprise blade, in Select a deployment model, select `Resource Manager`.
6. Click Create. The Create virtual machine and Basics blades appear.
7. On the Basics blade, complete the following fields:

    * `Name`: Type a descriptive name for your virtual machine.
    * `VM disk type`: Select disk type SSD or HDD
    * `User name`: Type a user name for logging in to your virtual machine
    * `Password`: Enter password for logging in to your virtual machine
    * `Confirm password`: Enter the same password for confirmation
    * `Subscription`: Select the subscription under which to create your virtual machine
    * `Resource group`: Specify the resource group to contain all your CloudNeeti VM resources. You can create a new resource group or select an existing resource group
    * `Location`: Select an Azure region from the Location list
    * Click OK


8. On the Choose a size blade, select a size and pricing tier for your virtual machine, and click Select.
9. On the Settings blade, review the preconfigured values for each field, and click OK. Most fields have additional settings that are not displayed on the Settings  To see all settings, expand each field. after validation, review the Summary information, and then click OK.
10. On the Purchase blade, review the offer details, Terms of use, privacy policy, and Azure Marketplace Terms and then click Purchase. The deployment is submitted
11. Depending on the disk types and VM instance type, It might take approximately 8-20 minutes before your new virtual machine is running
12. Update Network Security Group rules you must create rules that allow inbound for communication for the CloudNeeti application refer [Opening ports to a VM](https://docs.microsoft.com/en-us/azure/virtual-machines/windows/nsg-quickstart-portal)
13. When installation is complete, we need to configure certain parameters to open the application, follow below mentioned steps
    * Go to left pane of [Microsoft Azure portal](https://portal.azure.com/) click on Resource Group and find for resource group which is created above under your subscription
    * Then select the resource name against the the resource type "Public IP address" and go to the configuration settings of Public IP address resource type. Update the  DNS name label in the configuration blade. Note the DNS Name you specified it would be \*&lt;DNSname&gt;.&lt;region&gt;.cloudapp.azure.com.  
     \*it will be the Azure region / location which you have selected for creating VM
    * In order to get an access to the CloudNeeti application you must set up an Azure Active Directory (AD) application and assign the required permissions to it Refer [Azure Active Directory application](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal)
    
     
### Configuring Authentication and Authorization using  Active Directory Application



CloudNeeti uses AD Application for requesting consent accessing your Azure Subscription resources. To create an Active Directory Application. Refer to documentation [Integrating applications with Azure Active Directory](https://docs.microsoft.com/en-us/azure/active-directory/develop/active-directory-integrating-applications)  


#### Create an Active Directory Application
1.  In the [Azure Portal](https://portal.azure.com/), select **App
    Registrations**.
2.  Click on New application registration button.
    Enter the Name for example "Cloudneeti"
    Select the Application Type as "Web App/API"
    Enter the Sign-on URL as "&lt;DNSname&gt;.&lt;region&gt;.cloudapp.azure.com."
3. Click **Create**.
4. Click on the registered application "Cloudneeti"
5. Click **Settings**
6. Click **Reply URL**
7. Enter **Reply URL** with DNS name created above                           &lt;DNSname&gt;.&lt;region&gt;.cloudapp.azure.com/Account/Signon
8. Click **Save**

#### Authorize Application ID to access your Subscription resources
 
1. In the [Azure Portal](https://portal.azure.com/), select **App
    Registrations**.
2.  In App Registration blade, Click on the newly registered application if you had given the name "Cloudneeti" then click on the same.
3.  Click **Settings**
4.  Click **Keys**
5.  Enter a new description, Select a Expires value from the drop down and Click **Save**
6.  The key value is generated, Copy the same for your record.
7.  To access resources in your subscription, you must assign the application to a role refer **[Assign application to role](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-create-service-principal-portal#assign-application-to-role)**

You can do both the steps i.e. Create an Active Directory Application using automated script and Authorize Application ID to access your Subscription resources using automated scripts shared at **[Automation Script for Application Registration and Authorize Access to Subscription ](https://github.com/AvyanConsultingCorp/Cloudneeti-Public-Repository/blob/master/PowershellScripts/Create-ServicePrincipal.ps1)**

#### Azure Active Directory application permissions must be configured manually

 The following sections will help you configure each **App Registration** permission sets.
1.  In the [Azure Portal](https://portal.azure.com/), select **App
    Registrations**.
2.  In App Registration blade, Click on the newly registered application if you had given the name "Cloudneeti" then click on the same.
3.  Click **Settings**
4.  Click **Required Permissions**
5.  Click **+Add**.
6.  Click **Select an API**.
7.  In this step you will modify **Windows Azure Active Directory**, **Microsoft Graph**, **Windows Azure Service Management API**


 >**NOTE** the order of your API’s maybe different than listed in this documentation.

1.  Select the **Windows Azure Active Directory** API

    1.  Select the following 2 application permissions

        -   **Read and write directory data**

        -   **Read directory data**

    2.  Select the following 3 delegated permissions

        -   **Read all groups**

        -   **Read directory data**

        -   **Access the directory as the signed-in user**

2.  Click Select

3.  Select Done

4.  Click **+Add**.

5.  Select the **Microsoft Graph** API

    1.  Select the following 6 application permissions

        -   **Read files in all site collections**

        -   **Read all groups**

        -   **Read directory data**

        -   **Read and write directory data**

        -   **Read all users’ full profiles**

        -   **Read all identity risk event information**

    2.  Select the following 7 delegated permissions

        -   **Sign in and read user profiles**

        -   **Read all users’ basic profiles**

        -   **Read all users’ full profiles**

        -   **Read all groups**

        -   **Read directory data**

        -   **Read and write directory data**

        -   **Access the directory as the signed in user**

6.  Click Select

7.  Select Done

12. Click **+Add**

13. Select the **Windows Azure Service Management API**

    1.  Select no application permissions

    2.  Select the following 1 delegated permission

        -   **Access Azure Service Management as organization user**

14. Click Select

15. Select Done

>   If the configurations are successful, you will see a table of permissions
>   similar to the following:

| **API**                             | **Application permissions** | **Delegated permissions** |
|-------------------------------------|-----------------------------|---------------------------|
| Windows Azure Active Directory      | 2                           | 3                         |
| Microsoft Graph                     | 6                           | 7                         |
| Windows Azure Service Management    | 0                           | 1                         |
 

  




## Configure CloudNeeti Application 

1. After you finish these steps, you are ready with CloudNeeti Application, open a browser and go to **:** &lt;DNSname&gt;.&lt;region&gt;.cloudapp.azure.com







