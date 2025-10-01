#!/bin/bash

set -xe
if [[ ! -f .github/workflows/deploy.yml ]]; then
    echo Please run from project root.
    exit 1
fi

act --secret-file .secrets 