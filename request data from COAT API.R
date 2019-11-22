#  ********* REQUESTING DATA FROM THE COAT DATA PORTAL    **********

# This script contains examples of how data sets, and information about modules and users can be requested 
# from the COAT data portal API using the package ckanr
# Created by Jane Uhd Jepsen & Matteo De Stefano, Nov 2019

#Please note that the following terminology is used in ckan: 
# "organization" = a module in the COAT data portal
# "package" = a data set in the COAT data portal
# "resource" = a file within a dataset in the COAT data portal
# "User" = individual persons registred as users in the COAT data portal

#------------------------------------------------------------------------------------------------------

# install ckanr package
install.packages("ckanr")
# import ckanr library
library("ckanr")

# setup the connection to the data portal
# The use of an API key allows the user to access also non-public data  !!!! MATTEO: is this true? User control is the purpose of the API key?
ckanr_setup(url = "https://coatdemo.frafra.no/", key = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
#Without an API key only public data can be reached
ckanr_setup(url = "https://coatdemo.frafra.no/")

# list public datasets (aka packages)
pack<-package_list_current()

# list modules (aka organizations). 
#orgs$title will contain the name of the module and orgs$id will contain the unique ID to access the module data
orgs<-organization_list(as = 'table')

#Search for all datasets within a certain module
mod_web_pkg<-package_search('cross-module-datasets')$results

#identifier of the first dataset on the list 
mod_web_pkg[[1]]$id
#number of files in this dataset
mod_web_pkg[[1]]$num_resources
#the names of the files in the dataset
files<-mod_web_pkg[[1]]$resources %>% sapply('[[','name')
#the ids of the files in the dataset
filesid<-mod_web_pkg[[1]]$resources %>% sapply('[[','id')

#download a single text file from a dataset
destdir<-"R://Prosjekter/COAT/Data Management/Formatted data/scripts/"
destfile<-"dwnload.txt"
dnlfile<-download.file(mod_web_pkg[[1]]$resources[[1]]$url,paste(destdir,destfile,sep=""))

#download all files in a dataset
#TODO: where do I get the package URL to download all resources in a package at once?
#TODO: how can I control which version of the data I download (external users should of course only be 
# able to download the current published version, but we might want to access older versions of the dataset)


#----- Details about modules and users-------------
# see details about a specific organization (=modules in COAT)
organization_show('cross-module-datasets', as = 'table')

# list users
user_list()[1:2]

# show details about a specific user (ask for an existing user)
user_show('jane.jepsen@nina.no', as = 'table')
