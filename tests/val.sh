#!/bin/bash
set -e
ROOT=$PWD
_last_cmd=""
trap '_last_cmd=$BASH_COMMAND' DEBUG


debug=false
while [ "$#" -gt 0 ]; do
    case "$1" in
        -d|--dry-run)
            dry_run=true
            shift
            ;;
        -e|--debug)
            debug=true
            set -x
            shift
            ;;
        -*)
            echo "Error: Unknown option: $1" >&2
            exit 1
            ;;
        *)
            break
            ;;
    esac
done

cleanup() {
    cd $ROOT
    ensure_sops
    echo "Re-encrypting sops secrets"
    # Guarentee decryption - its already bit me
    sops -d -i "tf/environments/prod.tfvars"
    sops -d -i "wg-app/config.yaml"
    sops -d -i "cloudflared/cloudflared.env"
    sops -d -i "terraform.key"      

    sops -e -i "tf/environments/prod.tfvars"
    sops -e -i "wg-app/config.yaml"
    sops -e -i "terraform.key"        
    sops -e -i "cloudflared/cloudflared.env"

    echo "Last cmd: $_last_cmd"

}

trap cleanup EXIT
if [ -d "tests/venv" ]; then
    source tests/venv/bin/activate
else
    python -m venv tests/venv
fi

ensure_sops() {
    if ! command -v sops &> /dev/null; then
        echo "Installing sops to ./bin"
        SOPS_URL=$(curl -s https://api.github.com/repos/getsops/sops/releases/latest \
            jq -r '.assets[] | select(.name | test("sops-.*.linux.amd64$")) | .browser_download_url')
        mkdir -p ./bin
        curl -fsSL -o bin/sops "$SOPS_URL"
        chmod +x sops
        PATH="$PWD/bin:$PATH"
    fi
}

ensure_ansible() {
    if ! command -v ansible-lint &> /dev/null; then
        echo "Installing ansible tools via pip"
        pip3 install -q ansible ansible-dev-tools ansible-lint
    fi
}

if [[ ! -f .github/workflows/deploy.yml ]]; then
    echo Please run from project root.
    exit 1
fi




echo "Decrpyting sops secrets"
ensure_sops
sops -d -i "tf/environments/prod.tfvars"
sops -d -i "wg-app/config.yaml"
sops -d -i "cloudflared/cloudflared.env"
sops -d -i "terraform.key"      

# Terraform
terraform -chdir=tf fmt -check 
terraform -chdir=tf validate

# Cloud init
cloud-init  schema -c wg-init.yaml --annotate

# GH-Actions
action-validator -v .github/workflows/deploy.yml

# Bash scripts
bash -n cloudflared/ssh-tunnel.bash
bash -n scripts/get-con-ip.sh

# Ansible
ensure_ansible
cd ansible
ansible-galaxy collection install -r requirements.yml
ansible-lint
cd ..
