#!/bin/bash
# Copyright 2023 The MathWorks, Inc.

set -euo pipefail

if [[ -v MATLAB_REQUIRED_PRODUCTS ]];
then
    # Get mpm
    echo $(date) - Getting mpm
    wget -q https://www.mathworks.com/mpm/glnxa64/mpm
    chmod +x ./mpm
    echo $(date) - Installing required products $MATLAB_REQUIRED_PRODUCTS
    # Install MATLAB_REQUIRED_PRODUCTS
    ./mpm install --no-gpu --release=$MATLAB_RELEASE --destination=$MATLAB_DESTINATION --products $MATLAB_REQUIRED_PRODUCTS
fi

echo $(date) - Calling matlab-batch
# Call matlab-batch
matlab-batch $*
echo $(date) - Done
