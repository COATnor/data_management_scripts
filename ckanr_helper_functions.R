require_dataset <- function (COAT_url, COAT_key = NULL, dest_dir, package_name, store = "session") {
  
  ## load libraries, missing packages will be installed
  if (!require('remotes')) install.packages('remotes')
  if (!require('ckanr')) remotes::install_github("ropensci/ckanr"); library('ckanr')
  if (!require('purrr')) install.packages('purrr'); library('purrr')
  
  if (!is.null(COAT_key)) {
    if ( COAT_key == "") {
      COAT_key <- NULL
    }
  }
 
  ## setup the connection to the data portal
  if (is.null(COAT_key)) {
    ckanr::ckanr_setup(url = COAT_url)
  } else {
    ckanr::ckanr_setup(url = COAT_url, key = COAT_key)
  }
  
  ## serach for the dataset
  pkg<-ckanr::package_search(q = list(paste("name:", name, sep = "")), fq = list(paste("version:", version, sep = "")), include_private = TRUE)$results[[1]] # search for the dataset and save the results
  urls <- pkg$resources %>% sapply('[[','url')  # get the urls to the files included in the dataset
  filenames <-  pkg$resources %>% sapply('[[','name')
  
  ## create a folder with the dataset name if files should be saved to computer-> all data files will be saved here
  if (store == "disk") {
    dir.create(paste(dest_dir, name, sep = "/"), showWarnings = FALSE)
  }
  
  ## download all files of the dataset
  mylist <- c()  # empty object for the files
  
  for (i in 1:length(urls)) {
    mylist[[i]] <- ckanr::ckan_fetch(urls[i],
                              store = store,
                              path = paste(dest_dir, name, filenames[i], sep = "/"),
                              sep = ";",
                              header = TRUE
    )
  }
  
  
  ## this part splits the list that contains all files into coordinate file, aux file and data file
  if (store == "session") {
    
    dat <- purrr::keep(mylist, !grepl("coordinates|aux|readme", urls)) %>% do.call(rbind, .)  # this does not work if the data files have different structures (e.g. temperature datasets)
    
    if (any(grepl("coordinates", urls))) {
      coordinates <- mylist[[grep("coordinates", urls)]]
    }
    
    if (any(grepl("aux", urls))) {
      aux <- mylist[[grep("aux", urls)]]
    }
    
    if (any(grepl("coordinates", urls)) & (any(grepl("aux", urls)))) {
      output <- list(dat = dat, coordinates = coordinates, aux = aux)
    } else if (any(grepl("coordinates", urls))) {
      output <- list(dat = dat, coordinates = coordinates, aux = NULL)
    } else if (any(grepl("aux", urls))) {
      output <- list(dat = dat, coordinates = NULL, aux = aux)
    } else {
      output <- list(dat = dat, coordinates = NULL, aux = NULL)
    }
    
    return(output)
  }
}





