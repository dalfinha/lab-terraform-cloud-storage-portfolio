#!/usr/bin/env bash
set -Eeuo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

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

trap 'error "Falha na linha $LINENO."' ERR

echo ""
echo "======================================"
echo "       GOOGLE CLOUD LOGOUT"
echo "======================================"
echo ""

log "Localizando Google Cloud CLI..."

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
    error "Google Cloud CLI não encontrado."
    exit 1
fi

gcloud() {
    "$GCLOUD_BIN/gcloud.cmd" "$@"
}

success "Google Cloud CLI encontrado."

echo ""
warning "Esta operação removerá as credenciais locais do GCP."
read -r -p "Deseja continuar? (y/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
    warning "Logout cancelado."
    exit 0
fi

echo ""
log "Revogando contas autenticadas..."

if gcloud auth list --format="value(account)" | grep -q .; then
    while IFS= read -r ACCOUNT; do
        [[ -z "$ACCOUNT" ]] && continue

        log "Revogando conta: $ACCOUNT"
        gcloud auth revoke "$ACCOUNT" --quiet
        success "Conta revogada: $ACCOUNT"
    done < <(gcloud auth list --format="value(account)")
else
    warning "Nenhuma conta autenticada encontrada."
fi

echo ""
log "Removendo Application Default Credentials..."

ADC_PATH="$(gcloud info --format='value(config.paths.global_config_dir)' 2>/dev/null || true)"

if [[ -n "$ADC_PATH" && -f "$ADC_PATH/application_default_credentials.json" ]]; then
    gcloud auth application-default revoke --quiet
    success "Credenciais ADC removidas."
else
    warning "Arquivo ADC não encontrado."
fi

echo ""
read -r -p "Deseja remover o projeto ativo da configuração? (y/N): " CLEAR_PROJECT

if [[ "$CLEAR_PROJECT" =~ ^[Yy]$ ]]; then
    gcloud config unset project
    success "Projeto ativo removido."
else
    warning "Configuração do projeto mantida."
fi

echo ""
log "Limpando variáveis de ambiente da sessão..."

unset GOOGLE_APPLICATION_CREDENTIALS 2>/dev/null || true
unset CLOUDSDK_AUTH_CREDENTIAL_FILE_OVERRIDE 2>/dev/null || true

success "Variáveis de ambiente removidas da sessão atual."

echo ""
log "Validando logout..."

gcloud auth list

echo ""
success "LOGOUT CONCLUÍDO!"
echo ""
echo "As credenciais locais foram revogadas."
echo "Para autenticar novamente:"
echo "gcloud auth login"
echo "gcloud auth application-default login"
echo ""
echo "======================================"
