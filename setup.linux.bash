#!/bin/bash

### Bootstrap script for ODFI Manager
### Use this script to prepare the local system for manager
loc="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"

# Ensure packages are installed
sudo apt install itcl3
