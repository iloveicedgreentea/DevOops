#!/bin/bash
set -e
# PWD + module name + environment

module_name=$1
environment=$2
action=$3


config_dir="$PWD/environments/$environment/$module_name"
module_dir="$PWD/modules/$module_name"
out_plan="${module_dir}/terraform.tfplan"

terraform init \
  -backend-config="${config_dir}/backend.tfvars" \
  -input=false \
  -reconfigure \
  "${module_dir}"


if [[ "$action" == "plan" ]]; then
  terraform plan \
    -var-file="${config_dir}/terraform.tfvars" \
    -out="${out_plan}" \
    -input=false \
    "${module_dir}"
fi

if [[ "$action" == "apply" ]]; then
  terraform apply \
      -input=false \
      "${out_plan}"
fi