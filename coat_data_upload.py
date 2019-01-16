#!/usr/bin/fades
"""Uploading default data on CKAN. python>=3.6 required."""

import yaml  #fades
import requests #fades
import zenipy #fades

from helpers.requests import raise_for_status_verbose

import argparse
import os


@raise_for_status_verbose
def organization_create(server, headers):
    """Create organizations based on configuration settings."""
    for organization in defaults['organizations']:

        return requests.post(f"{server}/api/action/organization_create",
                             headers=headers, data=organization)


@raise_for_status_verbose
def package_create(server, headers, dataset):
    """Send dataset creation request to CKAN API."""
    return requests.post(f"{server}/api/action/package_create",
                         headers=headers, data=dataset)


def multi_packages_create(server, headers):
    """Create datasets based on configuration settings."""
    print("creating a dataset")
    for dataset in defaults['datasets']:
        package_create(server, headers, dataset)


@raise_for_status_verbose
def resource_create(server, headers, package_id, path, resource_name, extension):
    """Create a single resources in a datasets."""
    print("creating a resource")
    req = requests.post(f"{server}/api/action/resource_create",
                        data={'package_id': package_id,
                              'name': resource_name,
                              'format': extension,
                              'url': 'upload',  # Needed to pass validation
                              },
                        headers=headers,
                        files=[('upload', open(path, 'rb'))])

    return req


def get_package_id(server, headers, dataset):
    """Get metadata abut the requested dataset from CKAN, to obtain the package id (required to upload resources to a specific dataset)."""
    info = requests.post(f"{server}/api/action/package_show",
                         data={'id': dataset
                               },
                         headers=headers, )
    package_id = info.json()['result']['id']
    return package_id


def create_resources_from_folder(server, headers, folder, dataset):
    """Given a folder path and a package name, create resources for every file contained."""
    package_id = get_package_id(server, headers, dataset)

    # TODO: check for resource name uniqueness

    for filename in os.listdir(folder):
        path = os.path.join(folder, filename)
        extension = os.path.splitext(filename)[1][1:].upper()
        resource_name = os.path.splitext(filename)[0][0:].lower()

        try:
            resource_create(server, headers, package_id, path, resource_name, extension)
        except:
            pass


def multi_resources_create(server, headers):
    """Creates resources for all datasets and folders listed."""
    for dataset in defaults['folders']:

        create_resources_from_folder(server, headers, dataset['path'], dataset['name'])


def create_all(server, headers):
    """Create organizations, datasets and resources in sequence."""
    try:
        organization_create(server, headers)
    except:
        pass

    try:
        multi_packages_create(server, headers)
    except:
        pass

    try:
        multi_resources_create(server, headers)
    except:
        pass


def single_dataset_resources_create(server, headers):
    """Create a single dataset with a folder selection widget."""
    if args.dataset == "None":
        zenipy.zenipy.warning(text='Please add a target dataset with the --dataset option flag to the command')
    else:
        zenipy.zenipy.message(text='Please select a folder containing the data to be added to the chosen dataset')
        folder = zenipy.zenipy.file_selection(directory=True, title="please select a folder containing the data to be added to the dataset")

    create_resources_from_folder(server, headers, folder, args.dataset)


# Parser
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--operation', default='resource')
parser.add_argument('--server', default='http://localhost:5000',
                    help='CKAN server')
parser.add_argument('--initial', default='populate.yaml',
                    help='Defaults data file')
parser.add_argument('--dataset', default='None',
                    help='Dataset target for new resources')
args = parser.parse_args()

operation = args.operation
print(operation)

defaults = yaml.load(open(args.initial).read())

try:
    headers = {'Authorization': os.environ['CKAN_API_KEY']}
except EnvironmentError:
    print("Please set up the CKAN_API_KEY environmental variable")

server = args.server

operation_dict = {
    "organization": organization_create,
    "dataset": multi_packages_create,
    "resource": single_dataset_resources_create,
    "all": create_all,
    "multiresources": multi_resources_create
}


def execute_operation(operation, server, headers):
    """Execute the upload operation specified in the command."""
    return operation_dict[operation](server, headers)


execute_operation(operation, server, headers)

