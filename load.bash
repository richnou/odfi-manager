#!/bin/bash

loc="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"

export PATH="$loc/bin:$PATH"