#!/bin/bash

: '
#SYNOPSIS
    Deployment of config and related resources that were deployed for config based data collection.
.DESCRIPTION
    This script will delete all the resources that were deployed for config based data collection.
.NOTES
    Version: 1.0

    # PREREQUISITE
      - Install aws cli
        Link : https://docs.aws.amazon.com/cli/latest/userguide/install-linux-al2017.html
      - Configure your aws account using the below command:
        aws configure
        Enter the required inputs:
            AWS Access Key ID: Access key of any admin user of the account in consideration.
            AWS Secret Access Key: Secret Access Key of any admin user of the account in consideration
            Default region name: Programmatic region name where you want to deploy the framework (eg: us-east-1)
            Default output format: json  
      - Run this script in any bash shell (linux command prompt)

.EXAMPLE
    Command to execute : bash decommission-config.sh [-a <12-digit-account-id>] [-e <environment-prefix>] [-p <primary-aggregator-region>] [-s <list of regions(secondary) where config is to enabled>]

.INPUTS
    (-a)Account Id: 12-digit AWS account Id of the account where you want the remediation framework to be deployed
    (-e)Environment prefix: Enter any suitable prefix for your deployment
    (-p)Config Aggregator region(primary): Programmatic name of the region where the the primary config with an aggregator is to be created(eg:us-east-1)
    (-s)Region list(secondary): Comma seperated list(with nos spaces) of the regions where the config(secondary) is to be enabled(eg: us-east-1,us-east-2)

.OUTPUTS
    None
'

usage() { echo "Usage: $0 [-a <12-digit-account-id>] [-e <environment-prefix>] [-p <primary-aggregator-region>] [-s <list of regions(secondary) where config is to enabled>]"
          echo "Enter correct values for region parameters. Following are the acceptable values: ${aws_regions[@]}" 1>&2; exit 1; }
env="dev"
version="1.0"
regionlist=('na')
while getopts "a:e:p:s:" o; do
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
		s)  
            regionlist=${OPTARG}
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

env="$(echo "$env" | tr "[:upper:]" "[:lower:]")"
aggregatorregion="$(echo "$aggregatorregion" | tr "[:upper:]" "[:lower:]")"
regionlist="$(echo "$regionlist" | tr "[:upper:]" "[:lower:]")"

aws_regions=( "na" "us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1" "sa-east-1")

if [[ " ${aws_regions[*]} " != *" $aggregatorregion "* ]] || [[ " ${aggregatorregion} " != *" $aggregatorregion "* ]]; then
    usage
fi

if [[ $regionlist == "all" ]]; then
    input_regions = aws_regions
fi

IFS=, read -a input_regions <<<"${regionlist}"
printf -v ips ',"%s"' "${input_regions[@]}"
ips="${ips:1}"

input_regions=($(echo "${input_regions[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

validated_regions=()
for i in "${aws_regions[@]}"; do
    for j in "${input_regions[@]}"; do
        if [[ $i == $j ]]; then
            validated_regions+=("$i")
        fi
    done
done

if [[ ${#validated_regions[@]} != ${#input_regions[@]} ]]; then
    usage
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

echo "Deleting primary config deployment stack..."
sleep 3
aws cloudformation delete-stack --stack-name "cn-data-collector-"$env --region $aggregatorregion 2>/dev/null

echo "Deleting config(secondary) deployment stack in the mentioned regions..."
sleep 6
for region in "${input_regions[@]}"; do
    if [[ "$region" != "$aggregatorregion" ]]; then
        aws cloudformation delete-stack --stack-name "cn-data-collector-"$env --region $region 2>/dev/null
    fi
done

echo "Successfully deleted config setup in all the mentioned regions"