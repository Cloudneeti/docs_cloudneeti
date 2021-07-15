'''
SYNOPSIS
    Script to grant KMS Key metadata reader access to CSPM Data Collector IAM Role.

.DESCRIPTION
    - This script will update the Key Access Policy [ all Keys in the AWS Account ] to grant Key metadata Reader access to the CSPM Data Collector IAM Role
    - This script does not provide any write permissions on the Key

.NOTES

  Copyright (c) Cloudneeti. All rights reserved.
  Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

.Version: 1.0

.EXAMPLE
    - Login to the AWS Management Console and navigate to AWS Cloudshell
    - Upload this script on Cloudsheel using the Actions menu.

    Command to execute : python3 updateKmsKeyAccessPolicy.py --cspmRoleArn <CSPM Onboarding IAM Role ARN>

.INPUTS
    cspmRoleARM : ARN of the IAM Role that was created during Account onboarding on CSPM.

.OUTPUTS
    None
'''

import boto3
import json
import argparse

def getAllRegions(servicename):
    regions=[]
    enabled_regions = []

    try:
        session = boto3.session.Session()
    except:
        print("Unable to create boto3 session. Try again later with appropriate permissions!")
        return

    regions = session.get_available_regions(servicename)
    
    for region in regions:
        sts_client = session.client('sts', region_name=region)
        try:
            sts_client.get_caller_identity()
            enabled_regions.append(region)
        except:
            pass
            
    return enabled_regions

def main(arg):
    cspmRoleArn = arg.cspmRoleArn

    print("Initiating Key Policy update for all KMS Keys in the AWS Account\n")
    cspmPolicyJson = {"Sid": "Allow Read Access to Key","Effect": "Allow","Principal": {"AWS": str(cspmRoleArn)},"Action": ["kms:DescribeKey", "kms:ListResourceTags","kms:ListKeyPolicies","kms:GetKeyPolicy","kms:GetKeyRotationStatus"],"Resource": "*"}
    regions = getAllRegions('kms')
    print("Listing all keys in the following regions: "+str(regions)+"\n")
    
    for region in regions:
        try:
            kms_client = boto3.client('kms',region_name = region)
        except:
            print("Unable to create kms_client for region: " + region + ". Executing for next region..")
            continue
        
        try:
            paginated_data=[]
            kms_paginator = kms_client.get_paginator('list_aliases')
            for keys in kms_paginator.paginate():
                paginated_data.extend(keys['Aliases'])
        except:
            pass

        for kmsDetail in paginated_data:
            if 'alias/aws/' not in kmsDetail['AliasName']:
                print("Updating key policy for KMS Key: " + kmsDetail['AliasName'] + " in region: "+ region)
                kmsPolicy = []
                try:
                    kmsPolicy = kms_client.list_key_policies(KeyId=kmsDetail['TargetKeyId'])['PolicyNames']
                except:
                    pass

                if kmsPolicy:
                    kmsPolicyJson = ''                    
                    kmsPolicyStatement = []
                    try:
                        kmsPolicyJson = json.loads(kms_client.get_key_policy(KeyId=kmsDetail['TargetKeyId'],PolicyName=kmsPolicy[0])['Policy'])
                        kmsPolicyStatement.extend(kmsPolicyJson['Statement'])
                    except:
                        print("Error while fetching Key Policy for Key: " + kmsDetail['AliasName'] + ". Continuing execution for subsequent keys.\n")
                        continue

                if kmsPolicyStatement:
                    if cspmRoleArn in str(kmsPolicyStatement):
                        print("Key Policy is already updated for Key : "+kmsDetail['AliasName']+"\n")                   

                    else:                     
                        kmsPolicyStatement.append(cspmPolicyJson)
                        kmsPolicyJson['Statement'] = kmsPolicyStatement
                        try:
                            kms_client.put_key_policy(KeyId=kmsDetail['TargetKeyId'],PolicyName=kmsPolicy[0], Policy=json.dumps(kmsPolicyJson))
                            print("Successfully updated key policy for KMS Key: "+ kmsDetail['AliasName']+"\n")
                        except:
                            print("Unable to update policy for Key: "+ kmsDetail['AliasName'] + ". Continuing execution for subsequent keys.\n")
                            continue

if(__name__ == '__main__'):
    arg_parser = argparse.ArgumentParser(prog='update_key_policy',
                                        usage='%(prog)s [options]',
                                        description='Update KMS Key Policy')

    arg_parser.add_argument('--cspmRoleArn',
                            type=str,
                            required=True,
                            help='CSPM Data Collector Role ARN')

    args = arg_parser.parse_args()
    main(args)