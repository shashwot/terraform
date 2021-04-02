## Commands used

### initialize

    terraform init

### preview terraform actions

    terraform plan

### apply configuration with variables

    terraform apply -var-file terraform-dev.tfvars

### destroy a single resource

    terraform destroy -target aws_vpc.development-vpc

### destroy everything from tf files

    terraform destroy

### show resources and components from current state

    terraform state list

### show current state of a specific resource/data

    terraform state show aws_vpc.development-vpc  
