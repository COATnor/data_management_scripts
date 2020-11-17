#### ------------------------------------------------------------------------------------------------------------ ####
#### DOWNLOAD DATA FROM THE COAT DATA PORTAL
#### ------------------------------------------------------------------------------------------------------------ ####

## this script can be used to download datasets from the COAT data portal
## the data can either be loaded into R or can be saved to a computer

## the function is based on ckan_fetch() from the ckanr package by Chamberlain et al. 2020 and customized for the COAT data portal by Hanna Boehner
## the R-script 'ckanr_helper_functions.R' has to be downloaded from https://github.com/COATnor/data_management_scripts in order to run this script

## ---------------------------------- ##
## SETUP
## ---------------------------------- ##

## load libraries, missing packages will be installed
if (!require('ckanr')) install.packages('ckanr'); library('ckanr')
if (!require('purrr')) install.packages('purrr'); library('purrr')

## set working directory
work_dir <- "~/COAT/data_management_scripts"  # write here the path to the folder 'data_management_scripts' downloaded from github

## load helper functions
source(paste(work_dir, "ckanr_helper_functions.R", sep = "/"))

## setup the connection to the data portal
COAT_url <- "https://coatdemo.coat.no/"  # write here the url to the COAT data portal
COAT_key <- ""  # write here your API key if you are a registered user, continue without API key if you are not registered
# the API can be found on you page on the COAT data portal (log in and click on your name in the upper right corner of the page)
# The use of an API key allows the user to access also non-public data

ckanr_setup(url = COAT_url, key = COAT_key)  # set up the ckanr-API


## ---------------------------------- ##
## DOWNLOAD DATA
## ---------------------------------- ##

## list all datasets available on the COAT data portal
package_list()

## serach for your dataset
package_name <- "v_rodents_snaptrapping_trapstatus_intensive_v3"  # write here the name including the version of the dataset you want to download
pkg<-package_search(q = list(paste("name:", package_name, sep = "")), include_private = TRUE)$results[[1]]  # search for the dataset and save the results
urls <- pkg$resources %>% sapply('[[','url')  # get the urls to the files included in the dataset
filenames <-  pkg$resources %>% sapply('[[','name')

## specify if the downloaded files should be saved to your computer or imported into R
store <- "disk"  # "session" (imports data into R) or "disk" (saves the file to you computer)

## specify the desination directory for downloaded dataset 
dest_dir <- "~/COAT"  # write here the path to the directory, a folder with the dataset name will be created in the specified directory and all files of the dataset will be saved in this folder
# specifying a destination directory is only necessary if you want to save the files on you computer (store = "disk")
# if you want to import the data into R, specifying a destination directory is not necessary (store = "session")


## download all files of the dataset
mylist <- c()  # empty object for the files

for (i in 1:length(urls)) {
  mylist[[i]] <- ckan_fetch_coat(urls[i],
                                 store = store,
                                 path = paste(dest_dir, package_name, filenames[i], sep = "/"),
                                 sep = ";",
                                 package_name = package_name,
                                 dest_dir = dest_dir
  )
}

## ---------------------------------- ##
## ORGANIZE THE DATA - if imported into R
## ---------------------------------- ##

## this part splits the list that contains all files into coordinate file, aux file and data file

coordinates <- mylist[[grep("coordinates", urls)]]
aux <- mylist[[grep("aux", urls)]]
dat <- keep(mylist, !grepl("coordinates|aux|readme", urls)) %>% do.call(rbind, .)  # this does not work if the data files have different structures (e.g. temperature datasets)






