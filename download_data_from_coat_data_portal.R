##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## DOWNLOAD DATA FROM THE COAT DATA PORTAL
## last update 05.08.2025
## script made by Hanna Boehner
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

## DESCRIPTION
## This function can be used to download data files from the COAT Data Portal
## The data can either be imported to the current R session or saved on your computer

## For downloading private datasets, you need the specify an API key. 
## After login in to data.coat.no, the API key can be found by clicking on your name in the top right corner

## The development version of the ckanr package has to be installed (remotes::install_github("ropensci/ckanr")), 
## this will be done by the function if the package is not installed yet.

## For downloading parquet files, this development version hast to be installed (remotes::install_github("hannaboe/ckanr")).
## This has to be done manually before running the functions! This version works also for downloading txt-files


## ARGUMENTS OF THE FUNCTION
## COAT_key:  API key for the COAT Data portal (the API key can be found by clicking on your name in the top right corner on data.coat.no)
##            NULL for downloading public dataset without an API key (default)
## name:      name of the dataset, has to start with a lower case letter (!) and end with the version that should be downloaded (e.g. v1)
## version:   version that should be downloaded (same version as specified in name
## filenames: names of the data files that should be downloaded, either a single name or a vecotr
## store:     "session" for importing the data in the current R session, "disk" for saving the data on your computer
## out.dir:   if store = "disk", you have to specify the path to a folder where the data should be stored


## EXAMPLE

## get function for downloading data from the COAT Data Portal from GitHub
#source("https://github.com/COATnor/data_management_scripts/blob/master/download_data_from_coat_data_portal.R?raw=TRUE")

## download data
#coat_dat <- download_coat_data(COAT_key = NULL, # write here your API key for downloading private datasets or datasets under embargo
#                              name = "v_snowdepth_intensive_v1", 
#                               version = 1,
#                               filenames = paste0("V_snowdepth_intensive_", 2018:2020, ".txt"),
#                               store = "session",
#                               out.dir = NA)



##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## FUNCTION
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


download_coat_data <- function(COAT_key = COAT_key, 
                               name = name, 
                               version = version,
                               filenames = filenames,
                               store = "session",
                               out.dir = out.dir) {
  
  if (!require("ckanr")) remotes::install_github("ropensci/ckanr"); library("ckanr")
  
  
  ## setup the connection to the data portal
  ckanr_setup(url =  "https://data.coat.no", key = COAT_key)
  
  ## search for the dataset
  pkg <- package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE)$results[[1]]
  urls <- pkg$resources %>% sapply("[[", "url") # get the urls to the files included in the dataset
  filenames_dataset <- pkg$resources %>% sapply("[[", "name") # get the filenames
  
  ## check if all files are available
  if (!all(filenames %in% filenames_dataset)){
    print("Error: files not found")
    break
  }
  
  ## order filenames chronologically
  chrono <- order(filenames_dataset)
  filenames_dataset <- filenames_dataset[chrono]
  urls <- urls[chrono]
  
  ## urls of filenames that should be downloaded
  urls2 <- urls[which(filenames_dataset %in% filenames)]
  
  ## check if out.dir exists
  if (store == "disk") {
    if(!dir.exists(out.dir)) {
      print("Error: directory does not exist")
      break
    }
  }
  
  ## download all files 
  mylist <- c() # empty object for the files
  
  for (i in 1:length(filenames)) {
    mylist[[i]] <- ckan_fetch(urls2[i],
                              store = store,
                              path = paste(out.dir, filenames[i], sep = "/"),
                              sep = ";",
                              header = TRUE,
                              #format = "txt"
    )
  }
  
  
  return(mylist)
}


