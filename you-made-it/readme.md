# You Made It

## Environments

* `admin`
* `staging` 
* `prod`

## modules

* `aws`
  * `route53` - route53 zones and records
  * `frontend` - s3 and cloudfront distributions, plus IAM

## Usage
`./run.sh (cloud) (region) (environment) (component name) (plan|apply)`

## Structure

```text
├── $CLOUD
│   └── $REGION       
│       └── $ENVIRONMENT
│           └── $COMPONENT
├── modules
│   └── $CLOUD
│       └── $MODULE
├── readme.md
└── run.sh
```
