#!/bin/bash

export TF_IN_AUTOMATION=1

################
# Params
################

cloud=$1
region=$2
environment=$3
component=$4
action=$5

################
# Dirs
################

config_dir="$PWD/$cloud/$region/$environment/$component"
module=$(cat "${config_dir}/module" 2>/dev/null)
module_dir="$PWD/modules/${cloud}/${module}"
out_plan="${module_dir}/terraform.tfplan"

################
# Validation
################

# You can put whatever validation you want here

# Check if positional arguments are present instead of a condition for each argument
# map an array of commands to the position, return error back to user
arguments=("cloud" "region" "environment" "component" "action")
i=1
while [ $i -lt 6 ]; do
  if [[ -z "${!i}" ]]; then # use variable indirection to construct the actual positional variable
    echo "Argument not provided: \$$i - ${arguments[$i-1]}"
    exit 1
  fi
  i=$((i+1))
done

if [[ ! -f $out_plan ]] && [[ $action == "apply" ]]; then
  echo "terraform.tfplan not found. Please run a plan before applying"
  exit 1
fi

# check if the module file is present
if [[ -z $module ]]; then
  echo "module file is missing from config"
  exit 1
fi

################
# Functions
################

# You can set predefined flags to each command to keep things even more DRY
export TF_CLI_ARGS_init="-backend-config=${config_dir}/backend.tfvars -input=false -reconfigure ${module_dir}"
export TF_CLI_ARGS_plan="-var-file=${config_dir}/terraform.tfvars -out=${out_plan} -input=false ${module_dir}"
export TF_CLI_ARGS_apply="-input=false ${out_plan}"

# can implement other functions like import, refresh, destroy, etc

################
# Actions
################

# Init inside the module dir
terraform init

# Run terraform
terraform "$action"