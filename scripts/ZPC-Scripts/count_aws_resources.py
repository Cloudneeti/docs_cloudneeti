"""
SYNOPSIS
--------
    Get the count of resources present across regions in the AWS account.

DESCRIPTION
-----------
    This script provides a detailed overview of the number of resources present in the AWS account. 
	It provides a service-wise count of resources created in all the regions of the AWS account. 

PREREQUISITES
-------------
  - Python [ preferably version 3 and above ] [ https://www.python.org/downloads/ ]
  - boto3 [ AWS Python based SDK ]
    - Install using: pip install boto3

EXAMPLE
-------
    This script can be executed on a python compiler (Powershell, any command line tool with python installed)
    python ./count_aws_resources.py --accessKey <AWS Access Key Id> --secretKey <AWS Secret Access Key>
    
NOTES
-----
    Copyright (c) Cloudneeti. All rights reserved.
    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is  furnished to do so, subject to the following conditions:
    The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    Prerequisites
        -   Workstation with Python version 3 and above, with multiprocessing and Boto3 modules installed.
        -   User credentials (Access Key Id and Secret Accces Key) of a user having atleast the Security Audit permission and above on the AWS account
"""

import json
import boto3
import argparse
import multiprocessing

from urllib.request import urlopen

def acm(function, credentials, resource_count, region_list):
    print('Scanning ACM resources')
    certificate_count = 0

    for region in region_list:
        try:
            acm_client = boto3.client(service_name='acm', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            acm_paginator = acm_client.get_paginator('list_certificates')
            for certifcates in acm_paginator.paginate():
                certificate_count += len(certifcates['CertificateSummaryList'])
        except:
            pass
    
    resource_count[function] = certificate_count

def apigateway(function, credentials, resource_count, region_list):
    print('Scanning for Rest APIs')
    api_count = 0

    for region in region_list:
        try:
            api_client = boto3.client(service_name='apigateway', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            api_paginator = api_client.get_paginator('get_rest_apis')
            for rest_apis in api_paginator.paginate():
                api_count += len(rest_apis['items'])
        except:
            pass

    resource_count[function] = api_count

def apigatewayv2(function, credentials, resource_count, region_list):
    print('Scanning for APIs')
    apiv2_count = 0

    for region in region_list:
        try:
            api_client = boto3.client(service_name='apigatewayv2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            api_paginator = api_client.get_paginator('get_apis')
            for apis in api_paginator.paginate():
                apiv2_count += len(apis['Items'])
        except:
            pass

    resource_count[function] = apiv2_count

def asg(function, credentials, resource_count, region_list):
    print('Scanning auto scaling resources')
    autoscale_count = 0

    for region in region_list:
        try:
            asg_client = boto3.client(service_name='autoscaling', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            asg_paginator = asg_client.get_paginator('describe_auto_scaling_groups')
            for autoscale in asg_paginator.paginate():
                autoscale_count += len(autoscale['AutoScalingGroups'])
        except:
            pass

    resource_count[function] = autoscale_count

def launch_config(function, credentials, resource_count, region_list):
    print('Scanning Launch configurations')
    launchconfig_count = 0

    for region in region_list:
        try:
            asg_client = boto3.client(service_name='autoscaling', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            asg_paginator = asg_client.get_paginator('describe_launch_configurations')
            for autoscale in asg_paginator.paginate():
                launchconfig_count += len(autoscale['LaunchConfigurations'])
        except:
            pass

    resource_count[function] = launchconfig_count

def asg_plan(function, credentials, resource_count, region_list):
    print('Scanning ASG plans')
    asgplan_count = 0

    for region in region_list:
        try:
            asg_client = boto3.client(service_name='autoscaling-plans', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            asg_paginator = asg_client.get_paginator('describe_scaling_plans')
            for plan in asg_paginator.paginate():
                asgplan_count += len(plan['ScalingPlans'])
        except:
            pass

    resource_count[function] = asgplan_count

def backup(function, credentials, resource_count, region_list):
    print('Scanning for backups')
    backup_count = 0

    for region in region_list:
        try:
            backup_client = boto3.client(service_name='backup', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            backup_count = len(backup_client.list_backup_plans()['BackupPlansList'])
        except:
            pass
    resource_count[function] = backup_count

def cloudformation(function, credentials, resource_count, region_list):
    print('Scanning for cloudformation stacks')
    stack_count = 0

    for region in region_list:
        try:
            cf_resource = boto3.resource('cloudformation', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            stack_count += len(list(cf_resource.stacks.all()))
        except:
            pass
    resource_count[function] = stack_count

def cloudfront(function, credentials, resource_count, region_list):
    print('Scanning cloudfront resources')
    cloudfront_count = 0
    
    try:
        cloudfront_client = boto3.client(service_name='cloudfront')
        cloudfront_paginator = cloudfront_client.get_paginator('list_distributions')
        for distributionlist in cloudfront_paginator.paginate():
            cloudfront_count += distributionlist['DistributionList']['Quantity']
    except:
        pass

    resource_count[function] = cloudfront_count

def cloudtrail(function, credentials, resource_count, region_list):
    print('Scanning cloudtrail resources')
    trail_count = 0

    for region in region_list:
        try:
            ct_client = boto3.client('cloudtrail', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            trails = ct_client.describe_trails()
            trail_count += len(trails['trailList'])
        except:
            pass

    resource_count[function] = trail_count

def docdb_cluster(function, credentials, resource_count, region_list):
    print('Scanning documendb resources')
    docdb_cluster_count= 0

    for region in region_list:
        paginated_data = []
        try:
            docdb_client = boto3.client(service_name='docdb', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            cluster_paginator = docdb_client.get_paginator('describe_db_clusters')
            for clusters in cluster_paginator.paginate():
                paginated_data.extend(clusters['DBClusters'])

            for cluster_detail in paginated_data:
                if cluster_detail['Engine'] == 'docdb':                    
                    docdb_cluster_count += 1
        except:
            pass

    resource_count[function] = docdb_cluster_count

def docdb_instance(function, credentials, resource_count, region_list):
    print('Scanning documendb resources')
    docdb_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            docdb_client = boto3.client(service_name='docdb', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instance_paginator = docdb_client.get_paginator('describe_db_instances')
            for instances in instance_paginator.paginate():
                paginated_data.extend(instances['DBInstances'])

            for instance_detail in paginated_data:
                if instance_detail['Engine'] == 'docdb':
                    docdb_instance_count += 1
        except:
            pass

    resource_count[function] = docdb_instance_count

def dynamodb(function, credentials, resource_count, region_list):
    print('Scanning dynamodb resources')
    dynamodb_table_count = 0

    for region in region_list:
        try:
            dynamodb_client = boto3.resource(service_name='dynamodb', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            table_iterator = dynamodb_client.tables.all()
            dynamodb_table_count += len(list(table_iterator))
        except:
            pass

    resource_count[function] = dynamodb_table_count

def dax(function, credentials, resource_count, region_list):
    print('Scanning dax resources')
    dax_count = 0

    for region in region_list:
        try:
            dax_client = boto3.client(service_name='dax', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            cluster_paginator = dax_client.get_paginator('describe_clusters')
            for clusters in cluster_paginator.paginate():
                dax_count += len(clusters['Clusters'])
        except:
            pass

    resource_count[function] = dax_count

def ec2_ami(function, credentials, resource_count, region_list):
    print('Scanning ec2 AMIs')
    ec2_image_count = 0

    for region in region_list:
        try:
            ec2 = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ec2_image_count += len(list(ec2.images.filter(Owners=[credentials['account_id']])))
        except:
            pass

    resource_count[function] = ec2_image_count

def ec2_instances(function, credentials, resource_count, region_list):
    print('Scanning ec2 instances')
    ec2_instance_count = 0

    for region in region_list:
        try:
            ec2 = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)    
            ec2_instance_count += len(list(ec2.instances.all()))
        except:
            pass

    resource_count[function] = ec2_instance_count

def ec2_sg(function, credentials, resource_count, region_list):
    print('Scanning ec2 security groups')
    security_group_count = 0

    for region in region_list:
        try:
            ec2 = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            security_group_count += len(list(ec2.security_groups.all()))
        except:
            pass

    resource_count[function] = security_group_count

def vpc(function, credentials, resource_count, region_list):
    print('Scanning VPCs')
    vpc_count = 0

    for region in region_list:
        try:
            vpc_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            vpc_count += len(list(vpc_client.vpcs.all()))
        except:
            pass

    resource_count[function] = vpc_count

def subnet(function, credentials, resource_count, region_list):
    print('Scanning Subnets')
    subnet_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            subnet_count += len(list(ec2_client.subnets.all()))
        except:
            pass

    resource_count[function] = subnet_count

def route_table(function, credentials, resource_count, region_list):
    print('Scanning Route Tables')
    routetable_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            routetable_count += len(list(ec2_client.route_tables.all()))
        except:
            pass

    resource_count[function] = routetable_count

def igw(function, credentials, resource_count, region_list):
    print('Scanning IGWs')
    igw_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            igw_count += len(list(ec2_client.internet_gateways.all()))
        except:
            pass

    resource_count[function] = igw_count

def nacl(function, credentials, resource_count, region_list):
    print('Scanning NACLs')
    nacl_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            nacl_count += len(list(ec2_client.network_acls.all()))
        except:
            pass

    resource_count[function] = nacl_count

def placement_group(function, credentials, resource_count, region_list):
    print('Scanning Placement Groups')
    pg_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            pg_count += len(list(ec2_client.placement_groups.all()))
        except:
            pass

    resource_count[function] = pg_count

def network_interface(function, credentials, resource_count, region_list):
    print('Scanning NICs')
    nic_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            nic_count += len(list(ec2_client.network_interfaces.all()))
        except:
            pass

    resource_count[function] = nic_count

def ebs(function, credentials, resource_count, region_list):
    print('Scanning EBS Volumes')
    ebs_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ebs_count += len(list(ec2_client.volumes.all()))
        except:
            pass

    resource_count[function] = ebs_count

def ebs_snapshots(function, credentials, resource_count, region_list):
    print('Scanning EBS Snapshots')
    snapshot_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.resource('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            snapshot_count += len(list(ec2_client.snapshots.filter(OwnerIds=[credentials['account_id']])))
        except:
            pass

    resource_count[function] = snapshot_count

def reserved_instances(function, credentials, resource_count, region_list):
    print('Scanning EC2 reserved instances')
    ri_count = 0

    for region in region_list:
        try:
            ec2_client = boto3.client('ec2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ri_count += len(ec2_client.describe_reserved_instances()['ReservedInstances'])
        except:
            pass

    resource_count[function] = ri_count

def ecr(function, credentials, resource_count, region_list):
    print('Scanning ECR resources')
    ecr_count = 0

    for region in region_list:
        try:
            ecr_client = boto3.client(service_name='ecr', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ecr_paginator = ecr_client.get_paginator('describe_repositories')            
            for ecr in ecr_paginator.paginate():
                ecr_count += len(list(ecr['repositories']))
        except:
            pass
    
    resource_count[function] = ecr_count

def ecs(function, credentials, resource_count, region_list):
    print('Scanning ECS resources')
    ecs_count = 0

    for region in region_list:
        try:
            ecs_client = boto3.client(service_name='ecs', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ecs_paginator = ecs_client.get_paginator('list_clusters')            
            for ecs in ecs_paginator.paginate():
                ecs_count += len(list(ecs['clusterArns']))
        except:
            pass
    
    resource_count[function] = ecs_count

def efs(function, credentials, resource_count, region_list):
    print('Scanning EFS resources')
    efs_count = 0

    for region in region_list:
        try:
            efs_client = boto3.client(service_name='efs', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            efs_paginator = efs_client.get_paginator('describe_file_systems')            
            for efs in efs_paginator.paginate():
                efs_count += len(list(efs['FileSystems']))
        except:
            pass
    
    resource_count[function] = efs_count

def eks(function, credentials, resource_count, region_list):
    print('Scanning EKS resources')
    eks_count = 0

    for region in region_list:
        try:
            eks_client = boto3.client(service_name='eks', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            eks_paginator = eks_client.get_paginator('list_clusters')            
            for eks in eks_paginator.paginate():
                eks_count += len(list(eks['clusters']))
        except:
            pass
    
    resource_count[function] = eks_count

def elasticache(function, credentials, resource_count, region_list):
    print('Scanning ElastiCache resources')
    memcache_count = 0

    for region in region_list:
        try:
            ec_client = boto3.client(service_name='elasticache', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)            
            mem_paginator = ec_client.get_paginator('describe_cache_clusters')            
            for mem_cache in mem_paginator.paginate():
                memcache_count += len(list(mem_cache['CacheClusters']))
        except:
            pass
    
    resource_count[function] = memcache_count

def replication_group(function, credentials, resource_count, region_list):
    print('Scanning ElastiRedisCache resources')
    rg_count = 0

    for region in region_list:
        try:
            ec_client = boto3.client(service_name='elasticache', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)            
            redis_paginator = ec_client.get_paginator('describe_replication_groups')            
            for redis_cache in redis_paginator.paginate():
                rg_count += len(list(redis_cache['ReplicationGroups']))
        except:
            pass
    
    resource_count[function] = rg_count

def elasticsearch(function, credentials, resource_count, region_list):
    print('Scanning ElasticSearch resources')
    esdomain_count = 0

    for region in region_list:
        try:
            es_client = boto3.client(service_name='es', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            es_list = es_client.list_domain_names()            
            esdomain_count += len(es_list['DomainNames'])
        except:
            pass
    
    resource_count[function] = esdomain_count

def elb(function, credentials, resource_count, region_list):
    print('Scanning load balancer resources')
    elb_count = 0

    for region in region_list:
        try:
            elb = boto3.client('elb', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            elb_paginator = elb.get_paginator('describe_load_balancers')
            for balancer in elb_paginator.paginate():
                elb_count += len(balancer['LoadBalancerDescriptions'])
        except:
            pass

    resource_count[function] = elb_count

def elbv2(function, credentials, resource_count, region_list):
    print('Scanning load balancer v2 resources')
    elbv2_count = 0

    for region in region_list:
        try:
            elb = boto3.client('elbv2', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            elb_paginator = elb.get_paginator('describe_load_balancers')
            for balancer in elb_paginator.paginate():
                elbv2_count += len(balancer['LoadBalancers'])
        except:
            pass

    resource_count[function] = elbv2_count

def fsx(function, credentials, resource_count, region_list):
    print('Scanning FSx resources')
    fsx_count = 0

    for region in region_list:
        try:
            fsx_client = boto3.client(service_name='fsx', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            fsx_paginator = fsx_client.get_paginator('describe_file_systems')            
            for fsx in fsx_paginator.paginate():
                fsx_count += len(list(fsx['FileSystems']))
        except:
            pass

    resource_count[function] = fsx_count

def emr(function, credentials, resource_count, region_list):
    print('Scanning EMR resources')
    emr_cluster_count = 0

    for region in region_list:
        try:
            emr_client = boto3.client(service_name='emr', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            clusters = emr_client.get_paginator('list_clusters')            
            for cluster in clusters.paginate():
                emr_cluster_count += len(list(cluster['Clusters']))
        except:
            pass

    resource_count[function] = emr_cluster_count

def iam_user(function, credentials, resource_count, region_list):
    print('Scanning IAM Users')
    iam_user_count = 0
    
    try:
        iam = boto3.resource('iam')
        iam_user_count = len(list(iam.users.all()))
    except:
        pass

    resource_count[function] = iam_user_count

def iam_group(function, credentials, resource_count, region_list):
    print('Scanning IAM Groups')
    iam_group_count = 0
    
    try:
        iam = boto3.resource('iam')
        iam_group_count = len(list(iam.groups.all()))
    except:
        pass

    resource_count[function] = iam_group_count

def iam_roles(function, credentials, resource_count, region_list):
    print('Scanning IAM roles')
    iam_role_count = 0
    
    try:
        iam = boto3.resource('iam')
        iam_role_count = len(list(iam.roles.all()))
    except:
        pass

    resource_count[function] = iam_role_count

def iam_policy(function, credentials, resource_count, region_list):
    print('Scanning IAM policies')
    iam_policy_count = 0
    
    try:
        iam = boto3.resource('iam')
        iam_policy_count = len(list(iam.policies.filter(Scope='Local')))
    except:
        pass

    resource_count[function] = iam_policy_count

def iam_certificate(function, credentials, resource_count, region_list):
    print('Scanning IAM certificates')
    iam_certificate_count = 0
    
    try:
        iam = boto3.resource('iam')
        iam_certificate_count = len(list(iam.server_certificates.all()))
    except:
        pass

    resource_count[function] = iam_certificate_count

def kms(function, credentials, resource_count, region_list):
    print('Scanning KMS resources')
    key_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            kms_client = boto3.client(service_name='kms', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            kms_paginator = kms_client.get_paginator('list_aliases')
            for keys in kms_paginator.paginate():
                paginated_data.extend(keys['Aliases'])
        
            for KMS_Detail in paginated_data:
                if 'alias/aws/' not in KMS_Detail['AliasName']:
                    key_count += 1
        except:
            pass

    resource_count[function] = key_count

def kinesis(function, credentials, resource_count, region_list):
    print('Scanning Kinesis resources')
    stream_count = 0

    for region in region_list:
        try:
            kinesis_client = boto3.client(service_name='kinesis', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            streams = kinesis_client.get_paginator('list_streams')            
            for stream in streams.paginate():
                stream_count += len(stream['StreamNames'])
        except:
            pass

    resource_count[function] = stream_count

def firehose(function, credentials, resource_count, region_list):
    print('Scanning Kinesis resources')
    firehose_count = 0

    for region in region_list:
        try:
            firehose_client = boto3.client(service_name='firehose', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            firehose_count += len(firehose_client.list_delivery_streams(Limit=100)['DeliveryStreamNames'])
        except:
            pass

    resource_count[function] = firehose_count

def lambdas(function, credentials, resource_count, region_list):
    print('Scanning Lambda resources')
    lambda_count = 0

    for region in region_list:
        try:
            lambda_client = boto3.client(service_name='lambda', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            lambda_paginator = lambda_client.get_paginator('list_functions')            
            for func in lambda_paginator.paginate():
                lambda_count += len(list(func['Functions']))
        except:
            pass

    resource_count[function] = lambda_count

def neptune_cluster(function, credentials, resource_count, region_list):
    print('Scanning Neptune resources')
    neptune_cluster_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            neptune_client = boto3.client(service_name='neptune', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            clusters = neptune_client.get_paginator('describe_db_clusters')            
            for cluster in clusters.paginate():
                paginated_data.extend(cluster['DBClusters'])

            for NeptuneDetail in paginated_data:
                if 'neptune' in NeptuneDetail['Engine']:
                    neptune_cluster_count+=1
        except:
            pass

    resource_count[function] = neptune_cluster_count

def neptune_instance(function, credentials, resource_count, region_list):
    print('Scanning Neptune resources')
    neptune_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            neptune_client = boto3.client(service_name='neptune', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = neptune_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
            
            for NeptuneDetail in paginated_data:
                if 'neptune' in NeptuneDetail['Engine']:
                    neptune_instance_count+=1
        except:
            pass

    resource_count[function] = neptune_instance_count

def rds_aurora_cluster(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    cluster_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)            
            clusters = rds_client.get_paginator('describe_db_clusters')            
            for cluster in clusters.paginate():
                paginated_data.extend(cluster['DBClusters'])

            for RDS_Detail in paginated_data:
                if (RDS_Detail['Engine'] == 'aurora-postgresql' or RDS_Detail['Engine'] == 'aurora') and (RDS_Detail['EngineMode'] == 'provisioned' or RDS_Detail['EngineMode'] == 'parallelquery' or RDS_Detail['EngineMode'] == 'multimaster'):
                    cluster_count += 1
        except:
            pass

    resource_count[function] = cluster_count

def rds_auroramysql_cluster(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    cluster_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)            
            clusters = rds_client.get_paginator('describe_db_clusters')            
            for cluster in clusters.paginate():
                paginated_data.extend(cluster['DBClusters'])

            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'aurora' and RDS_Detail['EngineMode'] == 'serverless':
                    cluster_count += 1
        except:
            pass

    resource_count[function] = cluster_count

def rds_aurorapostgres_cluster(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    cluster_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)            
            clusters = rds_client.get_paginator('describe_db_clusters')            
            for cluster in clusters.paginate():
                paginated_data.extend(cluster['DBClusters'])

            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'aurora-postgresql' and RDS_Detail['EngineMode'] == 'serverless':
                    cluster_count += 1
        except:
            pass

    resource_count[function] = cluster_count

def rds_aurora_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'aurora-postgresql' or RDS_Detail['Engine'] == 'aurora':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_mariadb_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'mariadb':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_mysql_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'mysql':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_oracle_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'oracle-se' or RDS_Detail['Engine'] == 'oracle-ee' or RDS_Detail['Engine'] == 'oracle-se1' or RDS_Detail['Engine'] == 'oracle-se2':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_postgres_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'postgres':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_sqlserver_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        paginated_data=[]
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_db_instances')
            for instance in instances.paginate():
                paginated_data.extend(instance['DBInstances'])
                
            for RDS_Detail in paginated_data:
                if RDS_Detail['Engine'] == 'sqlserver-ex' or RDS_Detail['Engine'] == 'sqlserver-se' or RDS_Detail['Engine'] == 'sqlserver-web' or RDS_Detail['Engine'] == 'sqlserver-ee':
                    rds_instance_count += 1
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_reserved_instance(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_instance_count = 0

    for region in region_list:
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            instances = rds_client.get_paginator('describe_reserved_db_instances')
            for instance in instances.paginate():
                rds_instance_count += len(instance['ReservedDBInstances'])
        except:
            pass

    resource_count[function] = rds_instance_count

def rds_snapshot(function, credentials, resource_count, region_list):
    print('Scanning RDS resources')
    rds_snapshot_count = 0

    for region in region_list:
        try:
            rds_client = boto3.client(service_name='rds', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            rds_paginator = rds_client.get_paginator('describe_db_snapshots')
            filters = { 'SnapshotType': 'manual'}
            for snapshots in rds_paginator.paginate(**filters):
                rds_snapshot_count += len(snapshots['DBSnapshots'])
        except:
            pass

    resource_count[function] = rds_snapshot_count

def redshift(function, credentials, resource_count, region_list):
    print('Scanning Redshift resources')
    redshift_cluster_count = 0

    for region in region_list:
        try:
            redshift_client = boto3.client(service_name='redshift', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            clusters = redshift_client.get_paginator('describe_clusters')
            for cluster in clusters.paginate():
                redshift_cluster_count += len(cluster['Clusters'])
        except:
            pass

    resource_count[function] = redshift_cluster_count

def redshift_reserved(function, credentials, resource_count, region_list):
    print('Scanning Redshift reserved resources')
    reserved_redshift_count = 0

    for region in region_list:
        try:
            redshift_client = boto3.client(service_name='redshift', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            redshift_paginator = redshift_client.get_paginator('describe_reserved_nodes')
            for node in redshift_paginator.paginate():
                reserved_redshift_count += len(node['ReservedNodes'])
        except:
            pass

    resource_count[function] = reserved_redshift_count

def route53(function, credentials, resource_count, region_list):
    print('Scanning Route53 resources')
    zone_count = 0

    try:
        route53_client = boto3.client(service_name='route53')
        zone_paginator = route53_client.get_paginator('list_hosted_zones')        
        for zones in zone_paginator.paginate():
            zone_count += len(zones['HostedZones'])
    except:
        pass

    resource_count[function] = zone_count

def route53domain(function, credentials, resource_count, region_list):
    print('Scanning Route53 resources')
    domain_count = 0

    try:
        domain_client = boto3.client(service_name='route53domains')
        domain_paginator = domain_client.get_paginator('list_domains')
        for domains in domain_paginator.paginate():
            domain_count += len(domains['Domains'])
    except:
        pass

    resource_count[function] = domain_count

def s3bucket(function, credentials, resource_count, region_list):
    print('Scanning S3 bucket resources')
    s3_count = 0
    try:
        resource = boto3.resource(service_name='s3')
        s3_count = len(list(resource.buckets.all()))
    except:
        pass
    
    resource_count[function] = s3_count

def ses(function, credentials, resource_count, region_list):
    print('Scanning SES resources')
    ses_count = 0

    for region in region_list:
        try:
            ses_client = boto3.client(service_name='ses', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ses_paginator = ses_client.get_paginator('list_identities')            
            for ses in ses_paginator.paginate():
                ses_count += len(ses['Identities'])
        except:
            pass

    resource_count[function] = ses_count

def simpledb(function, credentials, resource_count, region_list):
    print('Scanning SimpleDb resources')
    sdb_count = 0

    for region in region_list:
        try:
            sdb_client = boto3.client(service_name='sdb', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            sdb_paginator = sdb_client.get_paginator('list_domains')            
            for sdb in sdb_paginator.paginate():
                sdb_count += len(sdb['DomainNames'])
        except:
            pass

    resource_count[function] = sdb_count

def sns(function, credentials, resource_count, region_list):
    print('Scanning SNS resources')
    sns_count = 0

    for region in region_list:
        try:
            sns_resource = boto3.resource('sns', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            sns_count += len(list(sns_resource.topics.all()))
        except:
            pass

    resource_count[function] = sns_count

def sqs(function, credentials, resource_count, region_list):
    print('Scanning SQS resources')
    sqs_count = 0

    for region in region_list:
        try:
            sqs_resource = boto3.resource('sqs', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            sqs_count += len(list(sqs_resource.queues.all()))
        except:
            pass

    resource_count[function] = sqs_count

def log_group(function, credentials, resource_count, region_list):
    print('Scanning Cloudwatch log groups')
    logs_count = 0

    for region in region_list:
        try:
            cw_client = boto3.client(service_name='logs', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            log_paginator = cw_client.get_paginator('describe_log_groups')            
            for log in log_paginator.paginate():
                logs_count += len(log['logGroups'])
        except:
            pass

    resource_count[function] = logs_count

def alarms(function, credentials, resource_count, region_list):
    print('Scanning Cloudwatch alarms')
    alarm_count = 0

    for region in region_list:
        try:
            cw_client = boto3.resource(service_name='cloudwatch', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            alarm_count += len(list(cw_client.alarms.all()))
        except:
            pass

    resource_count[function] = alarm_count

def organization(function, credentials, resource_count, region_list):
    print('Scanning Organization')
    org_count = 0

    try:
        org_client = boto3.client(service_name='organizations')
        org_client.describe_organization()['Organization']
        org_count = 1
    except:
        pass

    resource_count[function] = org_count

def elastic_beanstalk(function, credentials, resource_count, region_list):
    print('Scanning Beanstalk applications')
    eb_count = 0

    for region in region_list:
        try:
            eb_client = boto3.client(service_name='elasticbeanstalk', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            eb_count += len(eb_client.describe_applications()['Applications'])
        except:
            pass

    resource_count[function] = eb_count

def lightsail_instance(function, credentials, resource_count, region_list):
    print('Scanning Lightsail instances')
    instance_count = 0

    for region in region_list:
        try:
            lightsail_client = boto3.client(service_name='lightsail', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ls_paginator = lightsail_client.get_paginator('get_instances')            
            for instance in ls_paginator.paginate():
                instance_count += len(instance['instances'])
        except:
            pass

    resource_count[function] = instance_count

def lightsail_lb(function, credentials, resource_count, region_list):
    print('Scanning Lightsail load balancers')
    lb_count = 0

    for region in region_list:
        try:
            lightsail_client = boto3.client(service_name='lightsail', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ls_paginator = lightsail_client.get_paginator('get_load_balancers')            
            for load_balancer in ls_paginator.paginate():
                lb_count += len(load_balancer['loadBalancers'])
        except:
            pass

    resource_count[function] = lb_count

def lightsail_rds(function, credentials, resource_count, region_list):
    print('Scanning Lightsail RDS')
    rds_count = 0

    for region in region_list:
        try:
            lightsail_client = boto3.client(service_name='lightsail', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            ls_paginator = lightsail_client.get_paginator('get_relational_databases')            
            for rds in ls_paginator.paginate():
                rds_count += len(rds['relationalDatabases'])
        except:
            pass

    resource_count[function] = rds_count

def codecommit(function, credentials, resource_count, region_list):
    print('Scanning CodeCommit repositories')
    repo_count = 0

    for region in region_list:
        try:
            codecommit_client = boto3.client(service_name='codecommit', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            cc_paginator = codecommit_client.get_paginator('list_repositories')            
            for repository in cc_paginator.paginate():
                repo_count += len(repository['repositories'])
        except:
            pass

    resource_count[function] = repo_count

def codedeploy(function, credentials, resource_count, region_list):
    print('Scanning codedeploy applications')
    app_count = 0

    for region in region_list:
        try:
            codedeploy_client = boto3.client(service_name='codedeploy', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            cd_paginator = codedeploy_client.get_paginator('list_applications')            
            for application in cd_paginator.paginate():
                app_count += len(application['applications'])
        except:
            pass

    resource_count[function] = app_count

def codepipeline(function, credentials, resource_count, region_list):
    print('Scanning codepipeline pipelines')
    pipeline_count = 0

    for region in region_list:
        try:
            codepipeline_client = boto3.client(service_name='codepipeline', aws_access_key_id=credentials['access_key'], aws_secret_access_key=credentials['secret_key'], region_name=region)
            cp_paginator = codepipeline_client.get_paginator('list_pipelines')            
            for pipeline in cp_paginator.paginate():
                pipeline_count += len(pipeline['pipelines'])
        except:
            pass

    resource_count[function] = pipeline_count

def main(arg):
    access_key = arg.accessKey
    secret_key = arg.secretKey 

    resource_count_details = {}
    region_list = []

    try :
        print("Connecting to AWS account ")
        session = boto3.session.Session(aws_access_key_id=access_key, aws_secret_access_key=secret_key)
    except :
        print("\033[1;31;40m ""Please do Check for Credentials provided or Internet Connection and Try Again\n")
        quit()

    iam = session.client('sts')
    account_id = iam.get_caller_identity()["Account"]
    print("Successfully connected to AWS account", account_id)

    print("Counting resources across all available regions.")
    print("Wait for few minutes...\n")

    function_list= [ lambdas, acm, apigateway, apigatewayv2, asg, launch_config, asg_plan, backup, cloudformation, cloudfront, cloudtrail, docdb_cluster,
                    docdb_instance, dynamodb, dax, ec2_ami, ec2_instances, ec2_sg, vpc, subnet, route_table, igw, nacl, placement_group, network_interface,
                    ebs, ebs_snapshots, reserved_instances, ecr, ecs, efs, eks, elasticache, replication_group, elasticsearch, elb, elbv2, fsx,
                    iam_user, iam_group, iam_roles, iam_policy, iam_certificate, emr, kms, kinesis, firehose, neptune_cluster, neptune_instance,
                    rds_aurora_cluster, rds_auroramysql_cluster, rds_aurorapostgres_cluster, rds_aurora_instance, rds_mariadb_instance, rds_mysql_instance,
                    rds_oracle_instance, rds_postgres_instance, rds_sqlserver_instance, rds_reserved_instance, rds_snapshot, route53, route53domain,
                    redshift, redshift_reserved, s3bucket, ses, simpledb, sns, sqs, log_group, alarms, organization, elastic_beanstalk, lightsail_instance,
                    lightsail_lb, lightsail_rds, codecommit, codedeploy, codepipeline ]

    print("Collecting list of enabled region")
    available_regions = session.client('ec2',region_name="us-east-1")
    enabled_regions = available_regions.describe_regions()['Regions']
    for region in enabled_regions:
        region_list.append(region['RegionName'])
    
    manager = multiprocessing.Manager()
    resource_count = manager.dict()
    credentials = manager.dict()
    credentials['access_key'] = access_key
    credentials['secret_key'] = secret_key
    credentials['account_id'] = account_id
    jobs = []

    for function in function_list:
        try:
            p = multiprocessing.Process(target=function, args=(function, credentials, resource_count, region_list))
            jobs.append(p)
            p.start()
        except:
            print("Excepyion occurred while creating process. Please try again later!")
            quit()
    
    if jobs:
        for process in jobs:
            try:
                process.join()
            except:
                print("Excepyion occurred while creating process. Please try again later!")
                quit()

    print("Completed resource counting")

    # Updating Resource Count Object
    resource_count_details.update({ 'AWS::Lambda::Function': resource_count[lambdas],
                                    'AWS::CertificateManager::Certificate': resource_count[acm],
                                    'AWS::ApiGateway::RestApi': resource_count[apigateway],
                                    'AWS::ApiGatewayV2::Api': resource_count[apigatewayv2],
                                    'AWS::AutoScaling::AutoScalingGroup': resource_count[asg],
                                    'AWS::AutoScaling::LaunchConfiguration': resource_count[launch_config],
                                    'AWS::AutoScalingPlans::ScalingPlan': resource_count[asg_plan],
                                    'AWS::Backup::BackupPlan': resource_count[backup],
                                    'AWS::CloudFormation::Stack': resource_count[cloudformation],
                                    'AWS::CloudFront::Distribution': resource_count[cloudfront],
                                    'AWS::CloudTrail::Trail': resource_count[cloudtrail],
                                    'AWS::DocDB::DBCluster': resource_count[docdb_cluster],
                                    'AWS::DocDB::DBInstance': resource_count[docdb_instance],
                                    'AWS::DynamoDB::Table': resource_count[dynamodb],
                                    'AWS::DAX::Cluster': resource_count[dax],
                                    'AWS::EC2::AMI': resource_count[ec2_ami],
                                    'AWS::EC2::Instance': resource_count[ec2_instances],
                                    'AWS::EC2::SecurityGroup': resource_count[ec2_sg],
                                    'AWS::EC2::VPC': resource_count[vpc],
                                    'AWS::EC2::Subnet': resource_count[subnet],
                                    'AWS::EC2::RouteTable': resource_count[route_table],
                                    'AWS::EC2::InternetGateway': resource_count[igw],
                                    'AWS::EC2::NetworkAcl': resource_count[nacl],
                                    'AWS::EC2::PlacementGroup': resource_count[placement_group],
                                    'AWS::EC2::NetworkInterface': resource_count[network_interface],
                                    'AWS::EC2::Volume': resource_count[ebs],
                                    'AWS::EC2::EBSSnapshot': resource_count[ebs_snapshots],
                                    'AWS::EC2::CapacityReservation': resource_count[reserved_instances],
                                    'AWS::ECR::Repository': resource_count[ecr],
                                    'AWS::ECS::Cluster': resource_count[ecs],
                                    'AWS::EFS::FileSystem': resource_count[efs],
                                    'AWS::EKS::Cluster': resource_count[eks],
                                    'AWS::ElastiCache::CacheCluster': resource_count[elasticache],
                                    'AWS::ElastiCache::ReplicationGroup': resource_count[replication_group],
                                    'AWS::Elasticsearch::Domain': resource_count[elasticsearch],
                                    'AWS::ElasticLoadBalancing::LoadBalancer': resource_count[elb],
                                    'AWS::ElasticLoadBalancingV2::LoadBalancer': resource_count[elbv2],
                                    'AWS::FSx::FileSystem': resource_count[fsx],
                                    'AWS::IAM::User': resource_count[iam_user],
                                    'AWS::IAM::Group': resource_count[iam_group],
                                    'AWS::IAM::Role': resource_count[iam_roles],
                                    'AWS::IAM::Policy': resource_count[iam_policy],
                                    'AWS::IAM::ServerCertificate': resource_count[iam_certificate],
                                    'AWS::EMR::Cluster': resource_count[emr],
                                    'AWS::KMS::Key': resource_count[kms],
                                    'AWS::Kinesis::Stream': resource_count[kinesis],
                                    'AWS::KinesisFirehose::DeliveryStream': resource_count[firehose],
                                    'AWS::Neptune::DBCluster': resource_count[neptune_cluster],
                                    'AWS::Neptune::DBInstance': resource_count[neptune_instance],
                                    'AWS::RDS::DBCluster::Aurora': resource_count[rds_aurora_cluster],
                                    'AWS::RDS::DBCluster::AuroraMySql': resource_count[rds_auroramysql_cluster],
                                    'AWS::RDS::DBCluster::AuroraPostgres': resource_count[rds_aurorapostgres_cluster],
                                    'AWS::RDS::DBInstance::Aurora': resource_count[rds_aurora_instance],
                                    'AWS::RDS::DBInstance::MariaDB': resource_count[rds_mariadb_instance],
                                    'AWS::RDS::DBInstance::MySql': resource_count[rds_mysql_instance],
                                    'AWS::RDS::DBInstance::Oracle': resource_count[rds_oracle_instance],
                                    'AWS::RDS::DBInstance::Postgres': resource_count[rds_postgres_instance],
                                    'AWS::RDS::DBInstance::SQLServer': resource_count[rds_sqlserver_instance],
                                    'AWS::RDS::ReservedInstance': resource_count[rds_reserved_instance],
                                    'AWS::RDS::Snapshot': resource_count[rds_snapshot],
                                    'AWS::Redshift::Cluster': resource_count[redshift],
                                    'AWS::Redshift::ReservedNode': resource_count[redshift_reserved],
                                    'AWS::Route53::HostedZone': resource_count[route53],
                                    'AWS::Route53::Domain': resource_count[route53domain],
                                    'AWS::S3::Bucket': resource_count[s3bucket],
                                    'AWS::SES': resource_count[ses],
                                    'AWS::SDB::Domain': resource_count[simpledb],
                                    'AWS::SNS::Topic': resource_count[sns],
                                    'AWS::SQS::Queue': resource_count[sqs],
                                    'AWS::Logs::LogGroup': resource_count[log_group],
                                    'AWS::CloudWatch::Alarm': resource_count[alarms],
                                    'AWS::Organization': resource_count[organization],
                                    'AWS::ElasticBeanstalk::Application': resource_count[elastic_beanstalk],
                                    'AWS::Lightsail::Instance': resource_count[lightsail_instance],
                                    'AWS::Lightsail::LoadBalancer': resource_count[lightsail_lb],
                                    'AWS::Lightsail::RDS': resource_count[lightsail_rds],
                                    'AWS::CodeCommit::Repository': resource_count[codecommit],
                                    'AWS::CodeDeploy::Application': resource_count[codedeploy],
                                    'AWS::CodePipeline::Pipeline': resource_count[codepipeline]
                                    })

    # Processing Workloads
    workload_count = 0
    try:
        print("Fetching workload mapping")
        workload_mapping_url = "https://raw.githubusercontent.com/Avantika-Gupta30/docs_cloudneeti/Avantika/resource-count-script-modification/scripts/ZPC-Scripts/workloadMapping.json" 

        with urlopen(workload_mapping_url) as url:
            workload_mapping = json.loads(url.read())

        print("Successfully fetched workload mapping")

        print("\nWorkload Distribution:")
        for workload in workload_mapping['workloadMapping']['AWS']:
            service_type = workload_mapping['workloadMapping']['AWS'][workload]
            if resource_count_details[service_type] != 0:
                if service_type != 'AWS::Lambda':
                    workload_count += resource_count_details[service_type]
                else:
                    workload_count += [int](resource_count_details[service_type]/5)
                print("\t{} : {}".format(service_type, resource_count_details[service_type]))
            
    except:
        print("Error occurred while processing workloads, Please contact cspm support")

    # Showing Resource Distribution
    print("\nResource Distribution:")
    resource_count = 0
    for key, value in sorted(resource_count_details.items(), key=lambda x: x[1], reverse=True):
        if value != 0:
            print("\t{} : {}".format(key, value))
            resource_count+=value

    print("\n\nSummary:")
    print("\tZscaler CSPM Supported Total Workloads:", workload_count)
    print("\tTotal Resources:", resource_count)


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
