##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## DOWNLOAD DATA FROM THE COAT DATA PORTAL
## last update 05.08.2025
## script made by Hanna Boehner
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

## DESCRIPTION

## This script includes functions and an example for downloading data files from the COAT Data Portal
## The data can either be imported to the current R session or saved on your computer

## For downloading private datasets, you need the specify an API key. 
## After loging in to data.coat.no, the API key can be found by clicking on your name in the top right corner

## The development version of the ckanr package has to be installed (remotes::install_github("ropensci/ckanr")), 
## For downloading parquet files, this development version hast to be installed: remotes::install_github("hannaboe/ckanr").

## You can first list all COAT modules and then list all datasets of the selected module
## From this list you can select the datasets you want to download, list all files belonging to the dataset and select the files you want to download
## then you can download the selected files
# if you already know the names of the dataset and the files you want to download, you can skip the first steps and only run download_coat_data()


## EXAMPLE

if (FALSE) {
  
  ## load libraries
  if (!require("ckanr")) remotes::install_github("ropensci/ckanr"); library("ckanr")  # (remotes::install_github("hannaboe/ckanr")) for downloading parquet files
  if (!require("tidyverse")) install.packages("tidyverse"); library("tidyverse")
  
  ## get function for downloading data from the COAT Data Portal from GitHub
  source("https://github.com/COATnor/data_management_scripts/blob/master/download_data_from_coat_data_portal.R?raw=TRUE")
  
  ## set up the connection to the COAT Data Portal
  ckanr_setup(url =  "https://data.coat.no", 
              key = NULL)  # API key for downloading private datasets or datasets under embargo (the API key can be found by clicking on your name in the top right corner on data.coat.no)
  
  ## list all modules (optional)
  organization_list(as = "table")$name
  
  ## list all datasets of a module (optional)
  list_datasets(module = "climate-module")
  
  ## list the names of all data files of the selected dataset (optional)
  filenames <- list_data_files("v_snowdepth_intensive_v1")  # name of the dataset (choose from the list above)
  
  ## download data
  coat_dat <- download_coat_data(name = "v_snowdepth_intensive_v1", # name of the dataset (choose from the list above)
                                 filenames = filenames[!grepl("readme|aux|coordinates", filenames)], # names of the files that should be downloaded, e.g. all data files
                                 store = "session", #"session" for importing the data in the current R session, "disk" for saving the data on your computer
                                 out.dir = NA) #if store = "disk", you have to specify the path to a folder where the data should be stored
}


##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## FUNCTIONS
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##


download_coat_data <- function(name = name, 
                               version = version,
                               filenames = filenames,
                               store = "session",
                               out.dir = out.dir) {
  
  ## extract the version from the dataset name
  version <- substr(name, nchar(name), nchar(name))
  
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

list_datasets <- function(module = module) {
  
  ## search for all datasets of a module
  all_pkg <- package_search(q = paste0("organization:", module), rows = 1000, include_private = TRUE, as = "table")$results %>% 
    mutate(status = ifelse(private, "private", "public")) %>% 
    select(name, version, type, status, temporal_start, temporal_end) %>% 
    arrange(name)
  
  print(all_pkg)
    
}

list_data_files <- function(name) {
  
  ## extract the version from the dataset name
  version <- substr(name, nchar(name), nchar(name))
  
  ## list the names of all data files
  pkg <- package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE, as = "table")$results$resources[[1]]
  filenames_dataset <- pkg$name
  
  print(filenames_dataset)
  return(filenames_dataset)
}


