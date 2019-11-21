# install ckanr package
install.packages("ckanr")

# import ckanr library
library("ckanr")

# setup the connection to the data portal (use your API key)
ckanr_setup(url = "https://coatdemo.somewhere.no/", key = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx")

# list public packages
package_list(as = "table")

# list modules (aka organizations)
organizations_list(as = 'table')[1:3]

# see details about a specific organization
organization_show('cross-module-datasets', as = 'table')

# list users
user_list()[1:2]

# show details about a specific user (ask for an existing user)
user_show('ola.nordmann@inst.no', as = 'table')