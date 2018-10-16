# Stage 2

In [stage 1](https://github.com/esell/azure-stages/stage1) we pretended to build out
the pastemaster infrastructure in Azure to mimic what was running in our
imaginary datacenter. At this point we haven't really taken advantage of
what Azure can offer outside of automation, let's change that :).


Data is hard, it's just something we have to live with. Architecting solutions
to deal with this can also be hard so we're going to try and take a shortcut
here and see what happens. That shortcut is [Azure Database for MySQL](https://docs.microsoft.com/en-us/azure/mysql/). 
Azure offers a PaaS service for MySQL (and [Postgres](https://docs.microsoft.com/en-us/azure/postgresql/)) 
which is aimed at trying to make it easier for you and your teams to run MySQL in Azure.


What this service does is create a MySQL "server" for you that you don't have to manage. You use
it just like any other MySQL server, you just don't have to worry about the care and feeding. Changes
like this are fairly painless because we are just replacing something that already exists with a 
service that maps 100% back to MySQL. No code changes, no having to learn something new, just
simplifying your architecture and freeing your teams up to do more important stuff.


With all of that being said, moving to the MySQL PaaS service is not just a simple one line
command, we will need to modify some of our existing resources in order to support this new
architecture but don't worry, it isn't that painful. Let's get started!



# Virtual Network Service Endpoints

Azure PaaS services typically come with a public endpoint that you can't disable. If you plan on using
one of these PaaS services internally or you are looking to make sure that anyone external
cannot access your PaaS service you'll want to use [VNET service endpoints](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-network-service-endpoints-overview).
By doing this you will restrict access to your PaaS services to only the VNETs that you configure.
This functionality is not enabled by default on the VNET we created earlier so let's enable it:

`az network vnet subnet update -g pastemaster --vnet-name pm-vnet -n pm-app-subnet --service-endpoints Microsoft.SQl`

Just to clarify what is happening here, we are enabling the MySQL endpoint for our subnet
that is hosting our application. We will be getting rid of the db subnet later so there
is no need to enable it there.

# MySQL PaaS

Now it is time to create the MySQL PaaS resource. This process is fairly straightforward and
is something that _could_ be done with the Azure CLI, but we are knee deep in templates
already so let's keep going with those. As with stage 1, we'll change into the MySQL
directory and deploy our template:

`cd templates/mysql`


`az group deployment create --resource-group pastemaster --template-file mysql.json --parameters mysql-params.json`


You should have a shiny new `mysql1-paas` resource in your resource group now.


We're not quite done yet though, we need to tell our new MySQL PaaS resource to only accept
traffic from the `pm-app-subnet` subnet that we configured previously:

`az mysql server vnet-rule create -n app-subnet-rule -g pastemaster -s mysql1-paas --vnet-name pm-vnet --subnet pm-app-subnet`


# Re-deploy Our App

We've got a fancy MySQL PaaS service up and running now so let's re-deploy our app server
to take advantage of it. If you look at `templates/app/app-cloud-init.yml` you will
see that most everything is the same except for the database connection information.
We have updated the connection string info as well as added a flag to our app
that forces us to use TLS when we connect to the MySQL PaaS resource. While 
security is an afterthought in most of this document, we might as well do this
since Azure MySQL supports TLS right out of the box.


`cd templates/app`


`./create-params.sh`


Now we do the actual deployment:


`az group deployment create --resource-group pastemaster --template-file app.json --parameters app-params.json`


# Test

At this point we should hopefully have a working version of the application. To verify, find the IP of your *new* app VM:

`az vm list-ip-addresses -g pastemaster -n app2`


and then in a browser visit:


`http://YOUR_APP_VM_IP:8080/`


You should see the pastemaster application running and you should be able to create pastes
that you can share with others.


# Cleanup

In our current state we have a bunch of resources sitting out in Azure that we no longer need so let's clean those up.
Currently, there is no way to delete all resources associated with a VM so we will use a slightly modified version 
of a script that [@riedwaab](https://github.com/riedwaab) previously created and shared with the world (thanks!):


`./delete-vm.sh app1 pastemaster`


`./delete-vm.sh mysql1 pastemaster`


We should now have a clean resource group and can move on to the next stage.


