# The stages of Azure adoption


One does not simply "go to Azure" with an existing application, it is usually 
done in multiple stages that develop as the users become more familiar with Azure.


In this repo we have created a set of exercises that mimic what you
might see in the real world with regards to the stages. Each stage will build on the
previous one, utilizing more Azure native services, as well as showing how you can
re-factor an existing application to really take advantage of all that the cloud
can offer.


We will be using a toy application called [pastemaster](https://github.com/esell/pastemaster). This is a VERY simple application that acts as a [pastebin](pastebin.com) type page. 
Users can create "pastes" of text and share them with
other users via a unique URL. The pastemaster app consists of a few simple HTML pages (aka
the frontend), a [Go](https://golang.org) application to handle the business logic and a MySQL database for the datastore. Sounds like a typical three-tier app eh?


# [Stage 1](stage1/README.md)


When enterprises begin their journey into the world of Azure, they typically do it
in "phases" or what we are calling stages. Typically the first stage will be
to lift & shift the existing application into Azure as-is. This is just what it sounds like,
picking up the app from wherever it is and then re-creating it one-for-one up in Azure.


Stage 1 will demonstrate how you can improve on the basic lift & shift by taking advantage
of some of the features Azure has to offer. We will try to simulate, at a very basic level,
what that process might look like with our toy pastemaster application.



# [Stage 2](stage2/README.md)

Swap out MySQL for PaaS


# Stage 3

Key Vault for secrets?


# Stage 4

Multi-region active/active
