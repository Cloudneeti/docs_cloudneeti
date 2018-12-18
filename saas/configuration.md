
# SaaS Configuration and User Guide 

**Introduction** : **Cloudneeti**  offers continuous infrastructure security and compliance monitoring. It provides a clear evidence about actual implementation of controls and the information required for compliance audits.


1. Dashboard of the cybersecurity and compliance posture against industry standards such as PCI DSS 3.2, HIPAA, Cyber Security Foundations, Security Benchmark, NIST CSF, GDPR 
2. Compliance evidence for key industry benchmarks 
3. Continuous Monitoring to detect deviations from standards 
4. Remediation guidance for discovered vulnerabilities 
5. Azure usage visibility across the entire organization


## Onboard an Azure subscription

Follow these steps to onboard an Azure account to Cloudneeti. 

**Step-1** : Before you configure the Cloudneeti on to your Azure Subscription, you need an active Azure AD account in the Global Administrator role<br />
1.1  Login into the [Azure Portal](https://portal.azure.com/), with User with Global Admin Role

**Step-2** : Create an Active Directory Application

2.1	In the [Azure Portal](https://docs.microsoft.com/en-us/azure/active-directory/develop/howto-create-service-principal-portal), click Azure Active Directory in the sidebar then select App Registrations<br />
2.2	Click on New application registration button. Enter the Name for example "Cloudneeti" Select the Application Type as "Web App/API" Enter the Sign-on URL as provided . e.g. "http://DNSname.region.cloudapp.azure.com"<br />
2.3	Click Create <br />
2.4	Click on the registered application "Cloudneeti" <br />
2.5	Click Settings <br />
2.6	Click Reply URL <br />
2.7	Enter Reply URL with DNS name created above. e.g. "http://DNSname.region.cloudapp.azure.com/Account/SignIn" <br />
2.8	Click Save <br />
* Note : For Auto Deployment download the script : [`Create AD Application`](https://github.com/AvyanConsultingCorp/docs_cloudneeti/blob/master/scripts/Create-ServicePrincipal.ps1). You can find the instructions  [`here`](create-service-principal.html).

**Step-3** : Configure Azure Active Directory application permissions <br />
3.1 In Settings Preview, click Required permissions <br />
3.2 Click +Add & Select an API : In this step you will modify  <br />
    * Windows Azure Active Directory <br />
    * Microsoft Graph <br />
3.3 Select the **Windows Azure Active Directory** API  <br />

- 3.3.1.	Select the following application permissions <br /> 
    * Manage apps that this app creates or owns  <br />
    * Read all hidden memberships  <br />
    * Read directory data  <br />
 
- 3.3.2.	Select the following delegated permissions <br /> 
    * Access the directory as the signed-in user
    * Read hidden memberships
    * Read Directory data

3.4 Select the **Microsoft Graph** API  <br />

- 3.4.1.	Select the following application permissions <br /> 
    * 	Read all usage reports
    * 	Read all identity risky user information
    * 	Read all hidden memberships
    * 	Read directory data
    * 	Read all groups
    * 	Read all users' full profiles
    * 	Read all identity risk event information
    * 	Read directory data
    

- 3.4.2.	Select the following delegated permissions <br /> 
    * 	Read user devices

**Step-4** : Grant Permissions to enable the configurations
* Click on Grant Permissions to enable the configurations


**Step-5** : Generate the Application Key
* In App Registration blade, Click on the newly registered application if you had given the name "Cloudneeti" then click on the same
* Click Settings
* Click Keys
* Enter a new description, Select a Expires value from the drop down and Click Save
* The key value is generated, Copy the same for your record along with Application ID

**Step-6** : Authorize Application ID to access your Azure Subscription resources

* In the Azure Portal.
* Select All services and Subscriptions
* Select the particular subscription to assign the application to.
* Select Access control (IAM).
* Select Add.
* To allow the application to call Azure API, select the Reader role. By default, Azure AD applications aren't displayed in the available options. To find your application, search for the name. If you had given the name "Cloudneeti” then search for same and select it.
* Select Save to finish assigning the role.
* Role assignment is automated by [`Assign-RolesToServicePrincipal.ps1`](https://github.com/AvyanConsultingCorp/docs_cloudneeti/blob/master/scripts/Assign-RolesToServicePrincipal.ps1) script. You can follow the instructions given in [`link`](assign-roles-to-sp.html).

