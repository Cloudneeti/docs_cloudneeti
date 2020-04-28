"""
SYNOPSIS
--------
    Get Count of resources present in AWS account

DESCRIPTION
-----------
    This scripts counts the resources present in AWS account. 
	It will give you the services wise resource count created on all regions of AWS account 

EXAMPLE
-------
    This script can be execute on python compiler (Powershell, Coomand line)
    python ./count_aws_resources.py --accessKey <AWS access key> --secretKey <AWS secret key>
    
NOTES
-----

    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    Prerequisites
        -   Workstation should have installed Python version 3.6.8 and Boto3 modules
        -   User should have Security Audit role on AWS account
"""

from __future__ import print_function
import boto3
import argparse

resource_counts = {}

def autoscale():
    print("Scanning auto scaling resources")
    autoscale_count = 0
    configuration_count = 0

    for region in region_list:
        client = session.client(service_name="autoscaling", region_name=region['RegionName'])

        autoscaling = client.get_paginator('describe_auto_scaling_groups')
        configurations = client.get_paginator('describe_launch_configurations')
        autoscale_iterator = autoscaling.paginate()
        configurations_iterator = configurations.paginate()

        for autoscale in autoscale_iterator:
            autoscale_count += len(autoscale['AutoScalingGroups'])
        for configuration in configurations_iterator:
            configuration_count += len(configuration['LaunchConfigurations'])

    resource_counts['Autoscale Groups'] = autoscale_count
    resource_counts['Launch Configurations'] = configuration_count

def ACM():
    print("Scanning ACM resources")
    certificates_count = 0

    for region in region_list:
        client = session.client(service_name="acm", region_name=region['RegionName'])
        certifcates = client.get_paginator('list_certificates')
        
        acm_iterator = certifcates.paginate()
        for certifcates in acm_iterator:
            certificates_count += len(certifcates['CertificateSummaryList'])

    resource_counts['Certificates'] = certificates_count

def cloudtrail():
    print("Scanning cloudtrail resources")
    trail_count = 0

    for region in region_list:
        cloudtrail = session.client('cloudtrail', region_name=region['RegionName'])
        trails = cloudtrail.describe_trails()
        trail_count += len(trails['trailList'])

    resource_counts['CloudTrail'] = trail_count

def cloudfront():
    print("Scanning cloudfront resources")
    cloudfront_count = 0
    
    client = session.client(service_name="cloudfront")
    paginator = client.get_paginator('list_distributions')
    for distributionlist in paginator.paginate():
        cloudfront_count += distributionlist['DistributionList']['Quantity']

    resource_counts['CloudFront Distribution'] = cloudfront_count


def dynamodb():
    print("Scanning dynamodb resources")
    dynamodb_table_count = 0

    for region in region_list:
        client = session.resource(service_name="dynamodb", region_name=region['RegionName'])
        table_iterator = client.tables.all()
        dynamodb_table_count += len(list(table_iterator))

    resource_counts['DynamoDB Tables'] = dynamodb_table_count


def ec2(account_id):
    print("Scanning ec2 resources")

    ec2_instance_count = 0
    security_group_count = 0
    vpc_count = 0
    ec2_image_count = 0
    ip_count = 0
    
    for region in region_list:
        ec2 = session.resource('ec2', region_name=region['RegionName'])

        instance_iterator = ec2.instances.all()
        security_group_iterator = ec2.security_groups.all()
        image_iterator = ec2.images.filter(Owners=[account_id])
        vpc_iterator = ec2.vpcs.all()
        ip_iterator = ec2.vpc_addresses.all()
    
        ec2_instance_count += len(list(instance_iterator))
        security_group_count += len(list(security_group_iterator))
        ec2_image_count += len(list(image_iterator))
        vpc_count += len(list(vpc_iterator))
        ip_count += len(list(ip_iterator))

    resource_counts['EC2 Instances'] = ec2_instance_count
    resource_counts['Security Groups'] = security_group_count
    resource_counts['VPC'] = vpc_count
    resource_counts['EC2 Images'] = ec2_image_count
    resource_counts['Elastic IPs'] = ip_count

def EMR():
    print("Scanning EMR resources")
    emr_cluster_count = 0

    for region in region_list:
        client = session.client(service_name="emr", region_name=region['RegionName'])
        clusters = client.get_paginator('list_clusters')
        
        for cluster in clusters.paginate():
            emr_cluster_count += len(list(cluster['Clusters']))

    resource_counts['EMR Cluster'] = emr_cluster_count


def IAM():
    print("Scanning IAM resources")
    iam = session.resource('iam', region_name='us-west-2')
    user_iterator = iam.users.all()
    group_iterator = iam.groups.all()
    role_iterator = iam.roles.all()
    policy_iterator = iam.policies.filter(Scope='Local')

    resource_counts['IAM Users'] = len(list(user_iterator))
    resource_counts['IAM Groups'] = len(list(group_iterator))
    resource_counts['IAM Roles'] = len(list(role_iterator))
    resource_counts['IAM Policies'] = len(list(policy_iterator))

def KMS():
    print("Scanning KMS resources")
    key_count = 0

    for region in region_list:
        client = session.client(service_name="kms", region_name=region['RegionName'])
        paginator = client.get_paginator('list_keys')

        for keys in paginator.paginate():
            key_count += len(keys['Keys'])

    resource_counts['KMS Keys'] = key_count


def kinesis():
    print("Scanning Kinesis resources")
    stream_count = 0

    for region in region_list:
        client = session.client(service_name="kinesis", region_name=region['RegionName'])
        streams = client.get_paginator('list_streams')
        
        for stream in streams.paginate():
            stream_count += len(stream['StreamNames'])

    resource_counts['Kinesis Stream'] = stream_count

def loadbalancer():
    print("Scanning load balancer resources")
    elb_count = 0
    elbv2_count = 0

    # Classic ELB
    for region in region_list:
        elb = session.client('elb', region_name=region['RegionName'])

        elb_paginator = elb.get_paginator('describe_load_balancers')
        elb_iterator = elb_paginator.paginate()

        for balancer in elb_iterator:
            elb_count += len(balancer['LoadBalancerDescriptions'])

    # V2 ELB
    for region in region_list:
        elb = session.client('elbv2', region_name=region['RegionName'])

        elb_paginator = elb.get_paginator('describe_load_balancers')
        elb_iterator = elb_paginator.paginate()

        for balancer in elb_iterator:
            elbv2_count += len(balancer['LoadBalancers'])

    resource_counts['Classic Load Balancers'] = elb_count
    resource_counts['Application/Network Load Balancers'] = elbv2_count

def RDS():
    print("Scanning RDS resources")
    rds_cluster_count = 0
    rds_instance_count = 0

    for region in region_list:
        client = session.client(service_name="rds", region_name=region['RegionName'])
        clusters = client.get_paginator('describe_db_clusters')
        
        for cluster in clusters.paginate():
            rds_cluster_count += len(cluster['DBClusters'])

        instances = client.get_paginator('describe_db_instances')
        for instance in instances.paginate():
            rds_instance_count += len(instance['DBInstances'])

    resource_counts['RDS Clusters'] = rds_cluster_count
    resource_counts['RDS Instances'] = rds_instance_count

def redshift():
    print("Scanning Redshift resources")
    redshift_cluster_count = 0

    for region in region_list:
        client = session.client(service_name="redshift", region_name=region['RegionName'])
        clusters = client.get_paginator('describe_clusters')

        for cluster in clusters.paginate():
            redshift_cluster_count += len(cluster['Clusters'])

    resource_counts['Redshift Clusters'] = redshift_cluster_count


def s3bucket():
    print("Scanning S3 bucket resources")
    resource = session.resource(service_name="s3", region_name='us-east-1')
    s3_iterator = resource.buckets.all()
    resource_counts['S3'] = len(list(s3_iterator))


def main(arg):
    access_key = arg.accessKey
    secret_key = arg.secretKey

    global session
    global region_list
    global account_id
    try :
        print("Connecting to AWS account ")
        session = boto3.session.Session(aws_access_key_id=access_key, aws_secret_access_key=secret_key)
    except :
        print("\033[1;31;40m ""Please do Check for Credentials provided or Internet Connection and Try Again\n")
        quit()
    
    iam = session.client('sts')
    account_id = iam.get_caller_identity()["Account"]
    print("Successfully connected to AWS account", account_id)

    print("Collecting list of enabled region")
    available_regions = session.client('ec2',region_name="us-east-1")
    enabled_regions = available_regions.describe_regions()
    region_list = enabled_regions['Regions']

    print("Counting resources across all available regions.")
    print("Wait for few minutes...\n")

    # Count resources as per service type
    ACM()
    autoscale()
    cloudfront()
    cloudtrail()
    dynamodb()
    ec2(account_id)
    EMR()
    IAM()
    KMS()
    kinesis()
    loadbalancer()
    s3bucket()
    RDS()
    redshift()

    print("Completed resource counting.\n")
    print("Resource Summary:")
    
    for key, value in sorted(resource_counts.items()):
        print("\t{} : {}".format(key, value))

    print("\nTotal Resource Count", sum(resource_counts.values()))

if(__name__ == '__main__'):
    arg_parser = argparse.ArgumentParser(prog='count_aws_resources',
                                        usage='%(prog)s [options]',
                                        description='Count AWS resources')

    # Add the arguments
    arg_parser.add_argument('--accessKey',
                        type=str,
                        required=True,
                        help='AWS Access Key')
    arg_parser.add_argument('--secretKey',
                        type=str,
                        required=True,
                        help='AWS Secret Key')

    # Execute the parse_args() method
    args = arg_parser.parse_args()
    main(args)
