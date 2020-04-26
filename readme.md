# DevOops: Bad Terraform

Intentionally bad examples of how to not do Terraform, with one good example.

## Principles of good Terraform

* Remote backend with state locking
  * You should use a remote backend like S3 + DynamoDB which supports state locking

* Credentials separate from code
  * Don't put credentials in your provider config
  * Use built in mechanisms like environment variables, path to credentials file, etc

* Configs separate from code
  * Anything that is a parameter should be a declared variable, not hardcoded in your `.tf` files. Resources with unique name constraints should be scoped to an environment.

* File separation
  * Resources should be grouped in files where it makes sense; don't put everything in a main.tf. Terraform will flatten it for you but having things logically separated will 

* Reuseable Modules
  * Resources for a use case should be self contained in a Terraform Module and they should be reusable. Examples of self contained use cases include an application, a reusable database component, or a Jenkins server deployment.
  * Nesting modules is okay when it can logically separate resources

* Decoupled resources
  * Don't rely on nested modules or remote states as this will introduce strong coupling. Use `data` sources where possible.

* Automation
  * Automation scripts to run Terraform - bash or similar
  * CI/CD - Atlantis, TF Cloud

* .gitignore
  * You want to ignore plans, local `.terraform`, etc

## IAM Considerations for Terraform

Overprivileged accounts are a classic threat vector in cloud security. Terraform user accounts are usually heavily overprivileged and sometimes have full admin access. Here are some recommendations to secure Terraform accounts which may be relevant in different scenarios:

* If multiple users interact with Terraform, have them use dedicated Terraform roles that have tightly scoped permissions commensurate to their business needs i.e crafted policies that restrict actions to what they need to use. Users assume those roles to perform actions. 

* Similarly, restrict access to the state file on an as needed basis. A developer IAM role should not access the production state file. This will prevent both accidental issues and malicious actions.

* If using CI/CD, make sure the role is both scoped and secured with conditions such as mandating an IP range
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::account-id:user/EXAMPLEIAMUSERNAME"
      },
      "Action": "sts:AssumeRole"
    },
    {
      "Effect": "Deny",
      "Principal": {
        "AWS": "arn:aws:iam::account-id:user/EXAMPLEIAMUSERNAME"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "NotIpAddress": {
          "aws:SourceIp": [
            "103.15.250.0/24",
            "12.148.72.0/23"
          ]
        }
      }
    }
  ]
}
```


## Examples

Each of these examples is meant to mimic a full repo. Unfortunately I have seen these exact things  repeatedly when I was doing DevOps consulting. 

### Worst Case Scenario
This is the worst possible example of Terraform. Issues with this repo include not having a backend, having all resources in one file, not using modules, not having config files, and not having any automation. Possibly worst of all, a Readme is missing too. 

Some consequences of this kind of configuration include:

* Single state file
  * State file corruption, loss, or out of band editing is catastrophic
  * Locking will slow down development for different components or business units
  * State file rollbacks will affect all resources

* Spaghetti configs
  * Not having configs/variables means declaring multiple sets of resources for environments
  * Hard to read
  * Less operator friendly (can't pass off the module to less experienced people)

* Not reusable
  * Any new resources will need to be added to this file instead of instantiating a new module with a different state file

* No remote backend
  * Relying on git will cause conflicts
  * No state locking will create inconsistent runs

### Less Bad
This example has configs, a remote backend, and some separation, but is still not reusable. 

Some consequences of this kind of configuration include:

* Single state file
  * State file corruption, loss, or out of band editing is catastrophic
  * Locking will slow down development for different components or business units
  * State file rollbacks will affect all resources

* Not reusable
  * Any new resources will need to be added to this file instead of instantiating a new module with a different state file

### Almost Great
This example has configs, a remote backend, separate files, and reusable modules. It needs some work to automate running it since the configs and modules are in separate directories. It is a PIA to run this each time:

```
terraform init \
  -backend-config="environments/staging/frontend/backend.tfvars" \
  -input=false \
  -reconfigure \
  "modules/frontend"

terraform plan \
  -var-file="environments/staging/frontend/terraform.tfvars" \
  -out=./frontend.plan \
  -input=false \
  "modules/frontend"

terraform apply \
    -input=false \
    ./frontend.plan
```

### You Made It
This example has all of the good principles and also has automation to simplify and speed up running Terraform. You can put this in a CI/CD pipeline or run it locally. 
