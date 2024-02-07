# Creating a CloudFront Distribution with SSL 

## S3
1. Create S3 Bucket 
2. Click on S3 Bucket 
3. Upload Files 
4. go to 'Permissions' 
5. scroll to Bucket Policies and click Edit 
6. Go to different tab and open CloudFront 

## CloudFront
1. Create Distribution 
2. 'Origin Domain' - choose created bucket 
3. 'Origin Access Controls - create control settings - create 
4. WAF - do not enable security protections 
5. Custome SSL certificate 
6. Settings - use only N America and Europe 
7. Default root object - type: index.html 
8. Create Distribution 
9. Copy Policy 
10. Go to S3 bucket tab - Paste Policy - save changes 
11. Click Distribution - wait for Deployment 
12. Click on Distribution ID - copy Distribution Domain Name

## Route53
1. Create Record
2. Alias - true
3. Route traffic to - Alias to CloudFront distribution
4. Select your disribution

#### Pre-Requisites
## Route 53 
1. Register domain

## Certificate Manager (us-east-1)
1. Request
2. Domain names - Fully qualified domain name - example.com, *.example.com
3. Create records in Route 53

## Cool terraform commands 
- $ terraform state list 
- $ terraform state rm 'aws_route53_zone.my_zone' 
- $ terraform show -json 
- $ terraform console