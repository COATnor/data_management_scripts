#### ------------------------------------------------------------------------------------------------------------ ####
#### DOWNLOAD DATA FROM THE COAT DATA PORTAL
#### ------------------------------------------------------------------------------------------------------------ ####

## this script can be used to download datasets from the COAT data portal
## the data can either be loaded into R or can be saved to a computer

## the function is based on ckan_fetch() from the ckanr package by Chamberlain et al. 2020 and customized for the COAT data portal by Hanna Boehner
## the R-script 'ckanr_helper_functions.R' has to be downloaded from https://github.com/COATnor/data_management_scripts in order to run this script

## ---------------------------------- ##
## SETUP ----
## ---------------------------------- ##

## clear workspace
rm(list = ls())

## load libraries, missing packages will be installed
if (!require('ckanr')) install.packages('ckanr'); library('ckanr')

## set directories
work_dir <- "~/COAT/data_management_scripts"  # path to the folder where 'ckanr_helper_functions.R' is saved
dest_dir <- "~/COAT"  # path to the folder 

## load helper functions
source(paste(work_dir, "ckanr_helper_functions.R", sep = "/"))

## setup the connection to the COAT data portal
COAT_url <- "https://coatdemo.coat.no/"  # write here the url to the COAT data portal
COAT_key <- ""  # write here your API key if you are a registered user, continue without API key if you are not registered

# the API can be found on you page on the COAT data portal (log in and click on your name in the upper right corner of the page)
# The use of an API key allows the user to access also non-public data
# Without an API key only public data can be accessed

## list all datasets available on the COAT data portal
package_list(as = "table", url = COAT_url)

## select the dataset
package_name <- "v_rodents_snaptrapping_individuals_regional_v1"  # write here the name including the version of the dataset you want to download

## specify if the dataset should be imported into R or saved to the disk
store <- "session"  # "session" (imports data into R) or "disk" (saves the file to you computer)

## ---------------------------------- ##
## DOWNLOAD DATASET ----
## ---------------------------------- ##

mylist <- require_dataset(COAT_url = COAT_url, 
                          COAT_key = COAT_key, 
                          dest_dir = dest_dir,
                          package_name = package_name,
                          store = store)

# if store = "session" a list will be returned 
# the first element contains the data (all datafile are combined to one dataframe), the second contains the coordinate file and the third the auxiliary file

# if store = "disk" a folder with the dataset name will be created within the desination directory and all files of the dataset will be saved in this folder





