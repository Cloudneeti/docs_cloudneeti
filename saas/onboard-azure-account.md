

# Onboard an Azure Account

Follow these steps to onboard an Azure account to Cloudneeti. 

**Step-1** : Before you configure the Cloudneeti on to your Azure Subscription, you need an active Azure AD account in the Global Administrator role<br />
1.1  Login into the [`Azure Portal`](https://portal.azure.com/), with User with Global Admin Role

**Step-2** : Create an Active Directory Application

2.1	In the [`Azure Portal`](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal), click Azure Active Directory in the sidebar then select App Registrations<br />
2.2	Click on New application registration button. Enter the Name for example "Cloudneeti" Select the Application Type as "Web App/API" Enter the Sign-on URL as provided . e.g. "http://DNSname.region.cloudapp.azure.com"<br />
2.3	Click Create <br />
2.4	Click on the registered application "Cloudneeti" <br />
2.5	Click Settings <br />
2.6	Click Save <br />
* Note : For Auto Deployment download the script : [`Create AD Application`](https://raw.githubusercontent.com/AvyanConsultingCorp/docs_cloudneeti/master/scripts/Create-ServicePrincipal.ps1). You can find the instructions  [`here`](create-service-principal.html).

**Step-3** : Generate the Application Key
* In App Registration blade, Click on the newly registered application if you had given the name "Cloudneeti" then click on the same
* Click Settings
* Click Keys
* Enter a new description, Select a Expires value from the drop down and Click Save
* The key value is generated, Copy the same for your record along with Application ID

**Step-4** : Configure Azure Active Directory application permissions <br />
4.1 In Settings Preview, click Required permissions <br />

4.2 Click +Add & Select an API : In this step you will modify  <br />
-    Windows Azure Active Directory <br />
-    Microsoft Graph <br />

4.3 Select the **Windows Azure Active Directory** API  <br />

- 4.3.1.	Select the following application permissions <br /> 
    * Manage apps that this app creates or owns  <br />
    * Read all hidden memberships  <br />
    * Read directory data  <br />
 
- 4.3.2.	Select the following delegated permissions <br /> 
    * Access the directory as the signed-in user
    * Read hidden memberships
    * Read Directory data

4.4 Select the **Microsoft Graph** API  <br />

- 4.4.1.	Select the following application permissions <br /> 
    * 	Read all usage reports
    * 	Read all identity risky user information
    * 	Read all hidden memberships
    * 	Read directory data
    * 	Read all groups
    * 	Read all users' full profiles
    * 	Read all identity risk event information
    *   Read your organization’s security events
    

- 4.4.2.	Select the following delegated permissions <br /> 
    * 	Read user devices

**Step-5** : Grant Permissions to enable the configurations
* Click on Grant Permissions to enable the configurations

**Step-6** : Authorize Application ID to access your Azure Subscription resources

* In the Azure Portal.
* Select All services and Subscriptions
* Select the particular subscription to assign the application to.
* Select Access control (IAM).
* Select Add.
* To allow the application to call Azure API, assign the Reader and Backup Reader role. By default, Azure AD applications aren't displayed in the available options. To find your application, search for the name. If you had given the name "Cloudneeti” then search for same and select it.
* Select Save to finish assigning the role.
* Role assignment is automated by [`Assign-RolesToServicePrincipal.ps1`](https://raw.githubusercontent.com/AvyanConsultingCorp/docs_cloudneeti/master/scripts/Assign-RolesToServicePrincipal.ps1) script. You can follow the instructions given in [`link`](assign-roles-to-sp.html).

