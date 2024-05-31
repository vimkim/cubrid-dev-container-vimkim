#!/bin/bash

# Enable devtoolset-8
source scl_source enable devtoolset-8

# Set the number of parallel jobs for make
export MAKEFLAGS="-j $(nproc)"

# Automatically set JAVA_HOME
JAVA_PATH=$(command -v java)
if [ -n "$JAVA_PATH" ]; then
    JAVA_PATH=$(readlink -f "$JAVA_PATH")
    JAVA_HOME=$(dirname "$(dirname "$(dirname "$JAVA_PATH")")")
    export JAVA_HOME
    export PATH="$JAVA_HOME/bin:$PATH"
    echo "JAVA_HOME is set to $JAVA_HOME"
else
    echo "Java not found in PATH. Please install Java or ensure it is in your PATH."
fi

# Set CUBRID environment variables
export CUBRID="$HOME/CUBRID"
export CUBRID_DATABASES="$CUBRID/databases"
export LD_LIBRARY_PATH="$CUBRID/lib:$CUBRID/cci/lib:$LD_LIBRARY_PATH"

export PATH="$CUBRID/bin:$PATH"

# Confirm the settings
echo "CUBRID environment set up successfully."
echo "CUBRID=$CUBRID"
echo "CUBRID_DATABASES=$CUBRID_DATABASES"
echo "LD_LIBRARY_PATH=$LD_LIBRARY_PATH"
