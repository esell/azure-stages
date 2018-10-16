# Stage 1

This stage 1 is going to focus on how you can take your existing on-prem resources and
move them into Azure via [ARM templates](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#template-deployment). 
ARM templates are very powerful and give you the ability to automate resource creation vs 
using the portal or the [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/?view=azure-cli-latest). 

One key component is the ability to parameterize the templates which allows you to use
a single template but pass in different parameter values. An example would be using one
set of parameters for your development environment and a different set of parameters for
your production environment.

In this example you can see that we are basically parametrizing everything including the
CIDR ranges for our [VNET](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview) as well as the CIDR ranges for the various subnets.


In addition to ARM templates, we are also going to utilize the [cloud-init](https://cloud-init.io/) standard/functionality
to configure our VMs after they have been created. We will use cloud-init to do things like
install packages, modify config files, etc.


On top of all that we've also done away with the portal! We will be using the Azure CLI from here
on out to interact with Azure. As you become more comfortable with Azure you will likely realize
that while the portal is nice, the Azure CLI is much more efficient.


# Create Resource Group

Azure resources exist in a [resource group](https://docs.microsoft.com/en-us/azure/azure-resource-manager/resource-group-overview#resource-groups). 
This is a "container" that allows you to group
various resources together in one spot. There are no real rules or boundaries related to
resource groups. You could put 10 VMs in 10 different resource groups if you wanted to and
they would all still be able to interact with each other although management would be pretty 
painful.

For this exercise we will create a single resource group that will hold all of our
resources. This pattern is fairly common and usually suggested.

The command below will create the resource group that all of our resources will be 
deployed into for the rest of this exercise:

`az group create --name pastemaster --location westus2`

# Network

Now that we have a resource group to deploy into we will create the VNET and subnets
that will be used later. As mentioned previously, we will be using ARM templates to
do our provisioning. You can take a look at the `templates/network.json` and 
`templates/network-params.json` files to see what we are doing.

The command below will create the VNET and various subnets that the resources will use

`az group deployment create --resource-group pastemaster --template-file network.json --parameters network-params.json`  


# MySQL
This step will create the MySQL server that is used by the app.


We will use the cloud-init standard to configure our VM on creation. In this example
we will set the initial root password for MySQL, install MySQL and start it up. 

Once MySQL is up and running we will then create a user account for the application to
use once we deploy it.

In order for this to work we need to convert the cloud-init config we have into base64
and then insert it into our parameters file. For this example there is a shell script that we'll
use to handle the process. This is just an example on how you might do
this, it is not Azure specific. Additionally, if you don't see your cloud-init data changing
often you could just hard-code the base64 value into the ARM template.

`cd templates/mysql`
    
    
`./create-params.sh`

Now we do the actual deployment:

`az group deployment create --resource-group pastemaster --template-file mysql.json --parameters mysql-params.json`

    
# Application
This step will deploy the application to a VM

For the application we will use cloud-init to install our application from a source code repository, Github in 
this case, create the config file and then start it up.


As with our MySQL VM, we will need to convert the cloud-init file into base64: 


`cd templates/app`
    
    
`./create-params.sh`

Now we do the actual deployment:

`az group deployment create --resource-group pastemaster --template-file app.json --parameters app-params.json`


# Test it out

At this point we should hopefully have a working version of the application. To verify, find the IP of your app VM:


`az vm list-ip-addresses -g pastemaster -n app1`


and then in a browser visit:


`http://YOUR_APP_VM_IP:8080/`


You should see the pastemaster application running and you should be able to create pastes
that you can share with others.
