# Data Management Scripts - COAT DATA PORTAL
#### code snippets and scripts for data and metadata management

the COAT DATA PORTAL is based on CKAN (https://ckan.org/)

## Uploading DATA and METADATA


You can upload new datasets by:
 - using the CKAN graphic interface (manually, mouse click on the Data Portal)
 - using the CKAN API (scripts sending API requests)
 
### The CKAN API
Please find details at: https://docs.ckan.org/en/2.8/api/

### Using python:

https://github.com/ckan/ckanapi

### Using R

https://github.com/ropensci/ckanr

It is recommended to install the development version of ckanr:
```
install.packages("remotes")
remotes::install_github("ropensci/ckanr")
```