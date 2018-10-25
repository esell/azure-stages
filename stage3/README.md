# Stage 3

We are well on our way to an awesome, cloud-native application now that we are using a PaaS service :).

We'll deviate a bit here in stage 3 though. We are going to add [Azure Key Vault](https://docs.microsoft.com/en-us/azure/key-vault/)
into the mix to hopefully make it easier to go "cloud scale" later on. If you are not familiar with Azure Key Vault,
it is a PaaS service that acts as a secrets vault. If you want to see all of the cool things it can do I suggest
you read the documentation linked above. For our app we will use Azure Key Vault to hold our database connection
information. We do this for two reasons:

* It allows us to have a central spot to pull AND update the data from, no need to update configs all over
* It allows us to put walls up between the various environments and teams. Keep those crazy devs from accessing the prod database ;)


Now to prepare you, this is not going to be quite as easy as stages 1 and 2, we are going to do a bit of re-factoring that 
will allow us to take advantage of Azure Key Vault. This is not a huge deal (you'll see in a bit), but it will be a bit of work.
We'll roll things out in a way though that the existing resources won't be impacted.


Another cool thing we are going to use to make this a bit easier is an offering called [managed identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/).
Using a managed identity that we assign to our VM will allow the VM to query our Azure Key Vault directly and pull down the data we want.
We don't have to deal with application accounts or adding any code to our application. Later on that might be a better solution, but since
we are focusing on easing into Azure with as little disruption as possible we'll skip that for now.


# Create a Key Vault

Our first step will be to create an Azure Key Vault resource that our application can use later on to pull secrets from.
In order to help automate the process of pulling the secrets we will also need a managed identity.

Just an FYI, there are two different types of managed identities, [system-assigned and user-assigned](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview#how-does-the-feature-worka-namehow-does-it-worka), that can be created in Azure. 
Since we want a managed identity that is "floating", as in we can assign it to a specific resource when we want, 
we are going to create a user-assigned managed identity. Think of this as creating a static IP but not assigning it to a NIC/VM.


The template we will be using will actually create our managed identity PLUS our key vault. On top of that, it will pre-populate
the key vault with our super secret database password and assign access to our managed identity. As you have read many times before,
this is not model security as you typically would not want to hardcode your database passwords in your templates :).

Once you have deployed the template you will get back the key vault name. Save this as you'll need it later when we configure
our app deployment (again).

`cd templates/keyvault`


`az group deployment create --resource-group pastemaster --template-file keyvault.json --parameters keyvault-params.json --query "properties.outputs.vaulthostname.value"`


# Re-deploy Our App


As we've previously done, we are going to re-deploy a new VM with our app on it that takes advantage of our new Azure Key Vault. 
If you were to look at the `templates/app/app.json` template you would see that we added a section to assign the managed identity
we created earlier to the VM. What this will allow us to do is actually query a special IP and get auth tokens for the
various Azure services, in our case it is Azure Key Vault.


If you'd like to see exactly how this is being done, you can look at the `templates/app/app-cloud-init.yml` file and see the horror
that is our hacked up script :). Basically we will first get an auth token for Azure Key Vault service, and then use that token to get our 
secret (database password) from the vault we created previously. All of this is done using `curl` and stored as environment variables on
the system. The app then reads these environment variables and uses them when it creates a connection to the database.


So just like in stage 2, you will need to open up the `app-cloud-init.yml` file and populate a few values. Sticking with the same
naming convention from stage 2, find `YOUR_HOST_NAME_FROM_ABOVE` and replace it with your MySQL PaaS hostname from stage 2. Once you have
completed that, find `YOUR_VAULT_NAME_FROM_ABOVE` and replace that with your vault name from earlier. Now we deploy just as we have previously:


`cd templates/app`

`./create-params.sh`

`az group deployment create --resource-group pastemaster --template-file app.json --parameters app-params.json`



# Test

At this point we should hopefully have a working version of the application. To verify, find the IP of your *new* app VM:

`az vm list-ip-addresses -g pastemaster -n app3 -o table`


and then in a browser visit:


`http://YOUR_APP_VM_IP:8080/`


You should see the pastemaster application running and you should be able to create pastes
that you can share with others.


# Cleanup

In our current state we have a bunch of resources sitting out in Azure that we no longer need so let's clean those up.
Currently, there is no way to delete all resources associated with a VM so we will use a slightly modified version 
of a script that [@riedwaab](https://github.com/riedwaab) previously created and shared with the world (thanks!):


`./delete-vm.sh app2 pastemaster`


