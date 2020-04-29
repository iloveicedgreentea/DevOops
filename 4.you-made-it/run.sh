#!/bin/bash
set -e

################
# Params
################

cloud=$1
region=$2
environment=$3
component=$4
action=$5

################
# Validation
################

# Various validation tasks left as exercise to the reader (are the dirs present, valid? All params provided?)

################
# Dirs
################

config_dir="$PWD/$cloud/$region/$environment/$component"
module=$(cat "${config_dir}/module" 2>/dev/null)
module_dir="$PWD/modules/${cloud}/${module}"
out_plan="${module_dir}/terraform.tfplan"

################
# Functions
################

function tf_plan() {
  terraform plan \
    -var-file="${config_dir}/terraform.tfvars" \
    -out="${out_plan}" \
    -input=false \
    "${module_dir}"
}

function tf_apply() {
  terraform apply \
        -input=false \
        "${out_plan}"
}

# can implement other functions like import, refresh, destroy, etc

################
# Actions
################

# Init inside the module dir
terraform init \
  -backend-config="${config_dir}/backend.tfvars" \
  -input=false \
  -reconfigure \
  "${module_dir}"

# Plan
if [[ "$action" == "plan" ]]; then
  tf_plan
fi

# Apply
if [[ "$action" == "apply" ]]; then
  tf_plan
  # Can add confirmation dialog here if you want
  tf_apply
fi