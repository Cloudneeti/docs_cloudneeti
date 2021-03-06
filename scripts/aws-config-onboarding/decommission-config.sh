#!/bin/bash

: '
#SYNOPSIS
    Deletion of config and related resources that were deployed for config based data collection.
.DESCRIPTION
    This script will delete all the resources that were deployed for config based data collection.

.NOTES

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Version: 1.0

    # PREREQUISITE
      - Install aws cli
        Link : https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html
      - Install json parser jq
        Installation command: sudo apt-get install jq
      - Configure your aws account using the below command:
        aws configure
        Enter the required inputs:
            AWS Access Key ID: Access key of any admin user of the account in consideration.
            AWS Secret Access Key: Secret Access Key of any admin user of the account in consideration
            Default region name: Programmatic region name where you want to deploy the framework (eg: us-east-1)
            Default output format: json  
      - Run this script in any bash shell (linux command prompt)

.EXAMPLE
    Command to execute : bash decommission-config.sh [-a <12-digit-account-id>] [-e <environment-prefix>] [-p <primary-aggregator-region>]

.INPUTS
    (-a)Account Id: 12-digit AWS account Id of the account from where you want to delete the AWS Config setup
    (-e)Environment prefix: Enter any suitable prefix for your deployment
    (-p)Config Aggregator region(primary): Programmatic name of the region where the the primary config with an aggregator was deployed(eg:us-east-1)

.OUTPUTS
    None
'

usage() { echo "Usage: $0 [-a <12-digit-account-id>] [-e <environment-prefix>] [-p <primary-aggregator-region>]" 1>&2; exit 1; }
aggregion_validation() { echo "Enter correct value for the aggregator region parameter. Following are the acceptable values: ${aggregator_regions[@]}" 1>&2; exit 1; }

env="dev"

while getopts "a:e:p:" o; do
    case "${o}" in
        a)
            awsaccountid=${OPTARG}
            ;;
        e)
            env=${OPTARG}
            ;;
        p)
            aggregatorregion=${OPTARG}
            ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ "$awsaccountid" == "" ]] || ! [[ "$awsaccountid" =~ ^[0-9]+$ ]] || [[ ${#awsaccountid} != 12 ]]; then
    usage
fi

echo "Validating input parameters..."

region_detail="$(aws ec2 describe-regions | jq '.Regions')"
region_count="$(echo $region_detail | jq length)"

aws_regions=()
for ((i = 0 ; i < region_count ; i++ )); do
    aws_regions+=("$(echo $region_detail | jq -r --arg i "$i" '.[$i | tonumber]' | jq '.RegionName')")
done

enabled_regions=()
for index in ${!aws_regions[@]}; do
    enabled_regions+=("$(echo ${aws_regions[index]//\"/})")
done

aggregator_regions=( "us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1" "sa-east-1")

configure_account="$(aws sts get-caller-identity)"

if [[ "$configure_account" != *"$awsaccountid"* ]];then
    echo "AWS CLI configuration AWS account Id and entered AWS account Id does not match. Please try again with correct AWS Account Id."
    exit 1
fi

env="$(echo "$env" | tr "[:upper:]" "[:lower:]")"
aggregatorregion="$(echo "$aggregatorregion" | tr "[:upper:]" "[:lower:]")"

if [[ " ${aggregator_regions[*]} " != *" $aggregatorregion "* ]] || [[ " ${aggregatorregion} " != *" $aggregatorregion "* ]]; then
    aggregion_validation
fi

stack_detail="$(aws cloudformation describe-stacks --stack-name "cn-data-collector-"$env --region $aggregatorregion 2>/dev/null)"
stack_status=$?

echo "Validating environment prefix..."
sleep 5

if [[ $stack_status -ne 0 ]]; then
    echo "Invaild environment prefix/ Stack name. No relevant stack found. Please enter current environment prefix/stack name or verify the region parameters and try to re-run the script again."
    exit 1
fi

echo "Checking if the config bucket has been deleted or not...."

s3_detail="$(aws s3api get-bucket-versioning --bucket config-bucket-$env-$awsaccountid 2>/dev/null)"
s3_status=$?

sleep 5

if [[ $s3_status -eq 0 ]]; then
    echo "Config bucket is still not deleted. Please delete config-bucket-$env-$awsaccountid and try to re-run the script again."
    exit 1
fi

echo "Deleting primary config deployment stack in $aggregatorregion region..."
sleep 3
aws cloudformation delete-stack --stack-name "cn-data-collector-"$env --region $aggregatorregion 2>/dev/null

sleep 6
echo "Deleting config(secondary) deployment stack(s)..."
for region in "${enabled_regions[@]}"; do
    if [[ "$region" != "$aggregatorregion" ]]; then
        aws cloudformation delete-stack --stack-name "cn-data-collector-"$env --region $region 2>/dev/null
    fi
done

echo "Successfully deleted the config(secondary) setup from all the concerned region(s)"