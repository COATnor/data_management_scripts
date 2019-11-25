#  ********* REQUESTING DATA FROM THE COAT DATA PORTAL    **********

# This script contains examples of how data sets, and information about modules and users can be requested 
# from the COAT data portal API using the package ckanr
# Created by Jane Uhd Jepsen & Matteo De Stefano, Nov 2019

# Please note that the following terminology is used in ckan:
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
COAT_url<-"https://coatdemo.frafra.no/"
# The use of an API key allows the user to access also non-public data
ckanr_setup(url = COAT_url, key = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")
# Without an API key only public data can be reached
ckanr_setup(url = COAT_url)

# list datasets visible to current user (aka packages)
pack<-package_list(as='table') #this will give just a list of datasat names
#pack<-package_list_current(as='table') #this will give a list of datasat names with all details about files within the dataset

# list modules (aka organizations). 
# orgs$title will contain the name of the module and orgs$id will contain the unique ID to access the module data
orgs<-organization_list(as = 'table')

# Search for all datasets within a certain module
mod_web_pkg<-package_search('cross-module-datasets')$results

# identifier of the first dataset on the list
mod_web_pkg[[1]]$id
# number of files in this dataset
mod_web_pkg[[1]]$num_resources
# the names of the files in the dataset
mod_web_pkg[[1]]$resources %>% sapply('[[','name')
# the ids of the files in the dataset
mod_web_pkg[[1]]$resources %>% sapply('[[','id')

#---------download a single text file from a dataset----------
#Give a destination directory for downloaded files
destdir<-"R://Prosjekter/COAT/Data Management/Formatted data/scripts/"
#Give a file name for the single file to be donwloaded
destfile<-"dwnload.txt"
download.file(mod_web_pkg[[1]]$resources[[1]]$url,paste(destdir,destfile,sep=""))

#--------download all files in a dataset-------
# get the dataset name (which includes the version - update to a specific other version if needed)
dataset <- mod_web_pkg[[1]]$name
# Set the remote URL pointing to the .zip package containing all the resources (files) of a dataset
remote_zip <- paste(paste(COAT_url,"dataset/", sep=""), dataset, "/zip", sep = "")
# Set a local destination for data download
destination <- paste(destdir, paste(dataset,".zip",sep=""), sep = "")
# download the zip package
download.file(remote_zip, destination, mode="wb")

#----- Details about modules and users-------------
# see details about a specific organization (=modules in COAT)
organization_show('cross-module-datasets', as = 'table')

# list users
user_list()[1:2]

# show details about a specific user (ask for an existing user)
user_show('jane.jepsen@nina.no', as = 'table')
