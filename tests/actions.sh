#!/bin/bash

set -xe
if [[ ! -f .github/workflows/deploy.yaml ]]; then
    echo Please run from project root.
    exit 1
fi

act --secret-file .secrets 