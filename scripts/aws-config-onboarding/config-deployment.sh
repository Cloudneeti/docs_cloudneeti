#!/bin/bash

: '
#SYNOPSIS
    Deployment of config and related resources for config based data collection.
.DESCRIPTION
    This script will deploy all the services required for the config based data collection.
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
    Command to execute : bash config-deployment.sh [-a <12-digit-account-id>] [-c <cloudformation-stack-name>] [-e <environment-prefix>] [-n <config-aggregator-name] [-p <primary-aggregator-region>] [-s <list of regions(secondary) where config is to enabled>]

.INPUTS
    (-a)Account Id: 12-digit AWS account Id of the account where you want the remediation framework to be deployed
    (-c)Cloudformation Stack name: Name of the deployment stack that will be created
    (-e)Environment prefix: Enter any suitable prefix for your deployment
    (-n)Config Aggregator Name: Suitable name for the config aggregator
    (-p)Config Aggregator region(primary): Programmatic name of the region where the the primary config with an aggregator is to be created(eg:us-east-1)
    (-s)Region list(secondary): Comma seperated list(with nos spaces) of the regions where the config(secondary) is to be enabled(eg: us-east-1,us-east-2)
        **Pass "all" if you want to enable config in all other available regions
        **Pass "na" if you do not want to enable config in any other region

.OUTPUTS
    None
'

usage() { echo "Usage: $0 [-a <12-digit-account-id>] [-c <cloudformation-stack-name>] [-e <environment-prefix>] [-n <config-aggregator-name] [-p <primary-aggregator-region>] [-s <list of regions(secondary) where config is to enabled>]" 1>&2; exit 1; }
env="dev"
version="1.0"
regionlist=('na')
while getopts "a:c:e:n:p:s:" o; do
    case "${o}" in
        a)
            awsaccountid=${OPTARG}
            ;;
        c)
            stack=${OPTARG}
            ;;
        e)
            env=${OPTARG}
            ;;
        n)
            aggregatorname=${OPTARG}
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

if [[ "$awsaccountid" == "" ]] || ! [[ "$awsaccountid" =~ ^[0-9]+$ ]] || [[ ${#awsaccountid} != 12 ]] || [[ "$aggregatorname" == "" ]]; then
    usage
fi

env="$(echo "$env" | tr "[:upper:]" "[:lower:]")"
stack="$(echo "$stack" | tr "[:upper:]" "[:lower:]")"

aws_regions=( "na" "us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-2" "ap-southeast-1" "ap-southeast-2" "ap-northeast-1" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1" "sa-east-1" "ap-east-1" )

if [[ " ${aws_regions[*]} " != *" $aggregatorregion "* ]]; then
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

aws cloudformation deploy --template-file deploy-config.yml --stack-name $env-$stack --region $aggregatorregion --parameter-overrides Stack=$env-$stack awsaccountid=$awsaccountid aggregatorname=$aggregatorname --capabilities CAPABILITY_NAMED_IAM --no-fail-on-empty-changeset
aggregator_status=$?

if [[ "$aggregator_status" -eq 0 ]] && [[ "${input_regions[0]}" != "na" ]]; then
    for region in "${input_regions[@]}"; do
        if [[ "$region" != "$aggregatorregion" ]]; then
            aws cloudformation deploy --template-file multi-regionconfig.yml --stack-name $env-$stack --region $region --parameter-overrides Stack=$env-$stack awsaccountid=$awsaccountid aggregatorregion=$aggregatorregion --capabilities CAPABILITY_NAMED_IAM --no-fail-on-empty-changeset
        fi
    done
else
    echo "Something went wrong! Please contact Cloudneeti support for more details"
fi