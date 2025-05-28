##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
## FUNCTIONS FOR DOWNLOADING PARQUET FILES FROM THE COAT DATA PORTAL
## last update 27.01.2023
## script made by Hanna Boehner
## all helper functions are available from https://github.com/ropensci/ckanr/tree/master
##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

## DESCRIPTION
## The function can be used to download parquet files from the COAT data portal
## The downloaded data will be either returned as a list or saved to a specified folder
## the ckanr package has to be installed with remotes::install_github("ropensci/ckanr") before downloading data

## PARAMETERS OF THE FUNCTION
## COAT_key:  API key for the COAT data portal (can be found by clicking on your name in the top right corner on data.coat.no)
## name:      name and version of the dataset, use only lowercase letters and include the version at the end of the name with v1
## version:   version of the dataset
## filenames: name(s) of the file(s) that should be downloaded
## store:     session (if the data should be imported to R) or disk (if the data should be saved)
## out.dir:   path to the folder where the data should be saved (if store = disk)

## EXAMPLE

## source() # load the function and all helper functions from github

## name <- 

## finish example when parquet files are uploaded



####------------------------------------------####
#### DOWNLOAD FUNCTION
####------------------------------------------####

download_coat_parquet <- function(COAT_key = COAT_key, 
                               name = name, 
                               version = version,
                               filenames = filenames,
                               store = "session",
                               out.dir = out.dir) {
  
  check4X("ckanr")
  library(ckanr)
  
  
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
  
  ## urls of filenames that should be downloaded
  chrono <- order(filenames_dataset)
  filenames_dataset <- filenames_dataset[chrono]
  urls <- urls[chrono]
  
  urls2 <- urls[which(filenames_dataset %in% filenames)]
  
  
  ## download all files 
  mylist <- c() # empty object for the files
  
  for (i in 1:length(filenames)) {
    mylist[[i]] <- ckan_fetch_2(urls2[i],
                                store = store,
                                path = paste(out.dir, filenames[i], sep = "/"),
                                sep = ";",
                                header = TRUE,
                                format = "txt"
    )
  }
  
  #myfile <- do.call(rbind, mylist)
  
  return(mylist)
}



####------------------------------------------####
#### HELPER FUNCTIONS
####------------------------------------------####

# crul helpers -----------------------
ckan_POST <- function(url, method, body = NULL, key = NULL,
                      headers = list(), opts = list(), ...) {
  ckan_VERB("post", url, method, body, key, list(), headers, opts, ...)
}

ckan_PATCH <- function(url, method, body = NULL, key = NULL,
                       headers = list(), opts = list(), ...) {
  ckan_VERB("patch", url, method, body, key, list(), headers, opts, ...)
}

ckan_GET <- function(url, method, query = NULL, key = NULL,
                     headers = list(), opts = list(), ...) {
  ckan_VERB("get", url, method, body = NULL, key, query,
            headers, opts, ...)
}

ckan_DELETE <- function(url, method, body = NULL, key = NULL,
                        headers = list(), opts = list(), ...) {
  ckan_VERB("delete", url, method, body, key, list(), headers, opts, ...)
}

ckan_VERB <- function(verb, url, method, body, key, query = list(),
                      headers = list(), opts = list(), ...) {
  
  url <- notrail(url)
  
  # check if proxy set
  proxy <- get("ckanr_proxy", ckanr_settings_env)
  if (!is.null(proxy)) {
    if (!inherits(proxy, "proxy")) {
      stop("proxy must be of class 'proxy', see ?ckanr_setup")
    }
  } else {
    proxy <- NULL
  }
  
  con <- crul::HttpClient$new(url = file.path(url, ck(), method),
                              opts = opts, headers = headers)
  
  if (is.null(key)) {
    # no authentication
    if (is.null(body) || length(body) == 0) {
      con$headers <- c(con$headers, ctj())
      if (!is.null(proxy)) con$proxies <- proxy
      res <- con$verb(verb, query = query)
    } else {
      if (!is.null(proxy)) con$proxies <- proxy
      res <- con$verb(verb, body = body, query = query)
    }
  } else {
    # authentication
    con$headers <- c(con$headers, list("X-CKAN-API-Key" = key))
    if (is.null(body) || length(body) == 0) {
      con$headers <- c(con$headers, ctj())
      if (!is.null(proxy)) con$proxies <- proxy
      res <- con$verb(verb, query = query)
    } else {
      if (!is.null(proxy)) con$proxies <- proxy
      res <- con$verb(verb, body = body, query = query)
    }
  }
  err_handler(res)
  res$parse("UTF-8")
}

# GET fxn for fetch()
fetch_GET_2 <- function(x, store, path, args = NULL, format = NULL, key = NULL, ...) {
  # check if proxy set
  proxy <- get("ckanr_proxy", ckanr_settings_env)
  if (!is.null(proxy)) {
    if (!inherits(proxy, "proxy")) {
      stop("proxy must be of class 'proxy', see ?ckanr_setup")
    }
  }
  # set file format
  derived_file_fmt <- file_fmt(x)
  fmt <- ifelse(is.na(derived_file_fmt), format, derived_file_fmt)
  fmt <- tolower(fmt)
  
  # set API key header
  if (!is.null(key)) {
    api_key_header <- list("X-CKAN-API-Key" = key)
  }
  
  # initialize client, and set headers and proxy
  con <- crul::HttpClient$new(url = x, opts = list(...))
  if (!is.null(key)) con$headers <- list("X-CKAN-API-Key" = key)
  if (!is.null(proxy)) con$proxies <- proxy
  
  if (store == "session") {
    if (fmt %in% c("xls", "xlsx", "geojson", "txt", "parquet")) {
      dat <- NULL
      path <- tempfile(fileext = paste0(".", fmt))
      res <- con$get(query = args, disk = path)
      path <- res$content
      temp_files <- path
    } else if (fmt %in% c("shp", "zip")) {
      dat <- NULL
      path <- tempfile(fileext = ".zip")
      res <- con$get(query = args, disk = path)
      dir <- tempdir()
      zip_files <- unzip(path, list = TRUE)
      zip_files <- paste0(dir, "/", zip_files[["Name"]])
      unzip(path, exdir = dir)
      temp_files <- c(path, zip_files)
      path <- list.files(dir, pattern = ".shp$", full.names = TRUE)
      if (identical(path, character(0))) {
        fmt <- "zip"
        path <- zip_files
      } else {
        fmt <- "shp"
      }
    } else {
      path <- NULL
      temp_files <- NULL
      res <- con$get(query = args)
      err_handler(res)
      dat <- res$parse("UTF-8")
    }
    list(store = store, fmt = fmt, data = dat, path = path,
         temp_files = temp_files)
  } else {
    res <- con$get(query = args, disk = path, ...)
    list(store = store, fmt = fmt, data = NULL, path = res$content)
  }
}

file_fmt <- function(x) {
  fmt <- gsub("\\.", "", strextract(x, "\\.[A-Za-z0-9]+$"))
  if (length(fmt) == 0) {
    NA
  } else {
    fmt
  }
}

strextract <- function(str, pattern) regmatches(str, regexpr(pattern, str))

#------------------------------------------------------------------------------#
# Helpers
cc <- function(l) Filter(Negate(is.null), l)
ck <- function() 'api/3/action'
as_log <- function(x){ stopifnot(is.logical(x)); if (x) 'true' else 'false' }
jsl <- function(x) jsonlite::fromJSON(x, FALSE)$result
jsd <- function(x) jsonlite::fromJSON(x)$result
ctj <- function() list(`Content-Type` = "application/json")

# fxn to attach classes
as_ck <- function(x, class) {
  structure(x, class = class)
}

err_handler <- function(x) {
  if (x$status_code > 201) {
    obj <- try({
      err <- jsonlite::fromJSON(x$parse("UTF-8"))$error
      tmp <- err[names(err) != "__type"]
      errmsg <- paste(names(tmp), unlist(tmp[[1]]))
      list(err = err, errmsg = errmsg)
    }, silent = TRUE)
    if (!inherits(obj, "try-error")) {
      stop(sprintf("%s - %s\n  %s",
                   x$status_code,
                   obj$err$`__type`,
                   obj$errmsg),
           #obj$err$message),
           call. = FALSE)
    } else {
      obj <- {
        err <- x$status_http()$message
        errmsg <- x$parse("UTF-8")
        list(err = err, errmsg = errmsg)
      }
      stop(sprintf("%s - %s\n  %s",
                   x$status_code,
                   obj$err,
                   obj$errmsg),
           call. = FALSE)
    }
  }
}

pluck <- function(x, name, type) {
  if (missing(type)) {
    lapply(x, "[[", name)
  } else {
    vapply(x, "[[", name, FUN.VALUE = type)
  }
}

asl <- function(z) {
  if (is.logical(z) || tolower(z) == "true" || tolower(z) == "false") {
    if (z) {
      return('true')
    } else {
      return('false')
    }
  } else {
    return(z)
  }
}

tojun <- function(x, unbox = TRUE) {
  jsonlite::toJSON(x, auto_unbox = unbox)
}

check4X <- function(x) {
  if (!requireNamespace(x, quietly = TRUE)) {
    stop("Please install ", x, call. = FALSE)
  }
}

notrail <- function(x) {
  gsub("/+$", "", x)
}

assert <- function(x, y) {
  if (!is.null(x)) {
    if (!inherits(x, y)) {
      stop(deparse(substitute(x)), " must be of class ",
           paste0(y, collapse = ", "), call. = FALSE)
    }
  }
}

check_http_method <- function(http_method, methods) {
  if (!http_method %in% methods) {
    stop("'http_method' must be one of: ", paste0(methods, collapse = ", "),
         call. = FALSE)
  }
}

haz_names <- function(x) {
  stopifnot(is.list(x))
  if (length(x) == 0) return(TRUE)
  length(Filter(nzchar, names(x))) == length(x)
}

handle_many <- function(x) {
  x <- unlist(x)
  if (!is.character(x))
    stop("query/q must be vector or list of strings", call.=FALSE)
  unlist(lapply(x, function(z) list(query = z)), FALSE)
}

#ckan_fetch -----------------------
ckan_fetch_2 <- function(x, store = "session", path = "file", format = NULL,
                         key = get_default_key(), ...) {
  
  if (length(x) != 1) {
    stop("`x` must be length 1.", call. = FALSE)
  }
  
  store <- match.arg(store, c("session", "disk"))
  derived_file_fmt <- file_fmt(x)
  if (is.na(derived_file_fmt) && is.null(format)) {
    stop("File format is not available from URL; please specify via `format` argument.", call. = FALSE)
  }
  fmt <- ifelse(is.na(derived_file_fmt), format, derived_file_fmt)
  fmt <- tolower(fmt)
  res <- fetch_GET_2(x, store, path, format = fmt, key = key)
  if (store == "session") {
    if (res$fmt == "zip") {
      temp_res <- vector(mode = "list", length = length(res$path))
      for (i in seq_along(res$path)) {
        temp_res[[i]] <- read_session_2(
          file_fmt(res$path[[i]]), res$data, res$path[[i]])
      }
      temp_names <- res$path
      temp_names <- basename(temp_names)
      names(temp_res) <- temp_names
    } else {
      temp_res <- read_session_2(res$fmt, res$data, res$path)
    }
    unlink(res$temp_files)
    temp_res
  } else {
    res
  }
}

read_session_2 <- function(fmt, dat, path, ...) {
  switch(fmt,
         csv = {
           if (!is.null(dat)) {
             read.csv(text = dat, stringsAsFactors = FALSE,
                      fileEncoding = "latin1", ...)
           } else {
             read.csv(path, stringsAsFactors = FALSE,
                      fileEncoding = "latin1", ...)
           }
         },
         xls = {
           check4X("readxl")
           read_all_excel_sheets(path)
         },
         xlsx = {
           check4X("readxl")
           read_all_excel_sheets(path)
         },
         xml = {
           check4X("xml2")
           xml2::read_xml(dat, ...)
         },
         html = {
           check4X("xml2")
           xml2::read_html(dat, ...)
         },
         json = jsonlite::fromJSON(dat, ...),
         shp = {
           check4X("sf")
           sf::st_read(path, ...)
         },
         geojson = {
           check4X("sf")
           sf::st_read(path, ...)
         },
         txt = {
           txt_res <- try(utils::read.table(path, ...), silent = TRUE)
           
           if (inherits(txt_res, "try-error")) {
             stop("File cannot be read via `read.table()`. Please download and import into R manually.", call. = FALSE)
           } else {
             txt_res
           }
         },
         parquet = {
           check4X("arrow")
           arrow::read_parquet(path, ...)
         }
  )
}

read_all_excel_sheets <- function(x, ...) {
  sheets <- readxl::excel_sheets(x)
  if (length(sheets) > 1) {
    res <- lapply(sheets, readxl::read_excel, path = x, ...)
    names(res) <- sheets
    res
  } else {
    readxl::read_excel(x, ...)
  }
}

## set up ckanr environment
ckanr_settings_env <- new.env()
assign("ckanr_proxy", NULL, envir = ckanr_settings_env)
