#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

PROFILE="$HOME/.bashrc"

log() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

handle_error() {
    error "Falha na linha $1."
    error "Verifique a autenticação e tente novamente."
}
trap 'handle_error $LINENO' ERR

echo ""
echo "======================================"
echo "      GOOGLE CLOUD AUTHENTICATION"
echo "======================================"
echo ""

log "Procurando Google Cloud CLI..."

GCLOUD_BIN=""

for DIR in \
    "$HOME/google-cloud-sdk/bin" \
    "$HOME/google-cloud-sdk/google-cloud-sdk/bin"
do
    if [[ -f "$DIR/gcloud.cmd" ]]; then
        GCLOUD_BIN="$DIR"
        break
    fi
done

if [[ -z "$GCLOUD_BIN" ]]; then
    error "gcloud.cmd não encontrado nas pastas esperadas."
    error "Verifique a instalação do Google Cloud SDK."
    exit 1
fi

export PATH="$GCLOUD_BIN:$PATH"
hash -r

success "Google Cloud CLI encontrado."
log "Localização: $GCLOUD_BIN"

# Função para executar o CLI
gcloud() {
    "$GCLOUD_BIN/gcloud.cmd" "$@"
}

gcloud version

echo ""
log "Verificando contas autenticadas..."

gcloud auth list

read -r -p "Deseja realizar um novo login? (y/N): " LOGIN

if [[ "$LOGIN" =~ ^[Yy]$ ]]; then
    log "Iniciando autenticação Google..."
    gcloud auth login
    success "Autenticação concluída."
else
    warning "Login existente será mantido."
fi

echo ""
log "Configurando projeto GCP..."

CURRENT_PROJECT="$(gcloud config get-value project 2>/dev/null || true)"

if [[ -n "$CURRENT_PROJECT" && "$CURRENT_PROJECT" != "(unset)" ]]; then
    log "Projeto atual: $CURRENT_PROJECT"

    read -r -p "Deseja manter esse projeto? (Y/n): " KEEP_PROJECT

    if [[ "$KEEP_PROJECT" =~ ^[Nn]$ ]]; then
        read -r -p "Informe o Project ID: " PROJECT_ID
    else
        PROJECT_ID="$CURRENT_PROJECT"
    fi
else
    read -r -p "Informe o Project ID: " PROJECT_ID
fi

if [[ -z "$PROJECT_ID" ]]; then
    error "Project ID não informado."
    exit 1
fi

gcloud config set project "$PROJECT_ID"
success "Projeto configurado: $PROJECT_ID"

echo ""
log "Configurando Application Default Credentials..."

gcloud auth application-default login

success "Credenciais ADC configuradas."

echo ""
log "Configurando projeto de quota..."

gcloud auth application-default set-quota-project "$PROJECT_ID"

success "Projeto de quota configurado."

echo ""
log "Validando autenticação..."

gcloud auth list
gcloud config list

log "Validando token ADC..."

gcloud auth application-default print-access-token >/dev/null

success "Token ADC válido."

echo ""
log "Configurando PATH permanente..."

PATH_LINE="export PATH=\"$GCLOUD_BIN:\$PATH\""

touch "$PROFILE"

if ! grep -Fqx "$PATH_LINE" "$PROFILE"; then
    echo "$PATH_LINE" >> "$PROFILE"
    success "PATH adicionado ao ~/.bashrc."
else
    warning "PATH já estava configurado."
fi

echo ""
echo "======================================"
success "AUTENTICAÇÃO CONCLUÍDA!"
echo "======================================"

echo ""
echo "Próximos passos:"
echo "1. terraform init"
echo "2. terraform plan"
echo ""
