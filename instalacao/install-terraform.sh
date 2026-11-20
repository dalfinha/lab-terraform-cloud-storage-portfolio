#!/usr/bin/env bash
set -Eeuo pipefail

VERSION="${1:-latest}"
INSTALL_DIR="$HOME/.local/bin"
TEMP_DIR="$(mktemp -d)"
PROFILE="$HOME/.bashrc"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

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

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

handle_error() {
  error "A instalação falhou na linha $1."
  error "Verifique sua conexão e tente novamente."
}
trap 'handle_error $LINENO' ERR

echo ""
echo "======================================"
echo "       TERRAFORM INSTALLER"
echo "======================================"
echo ""

if command -v terraform >/dev/null 2>&1; then
  CURRENT_VERSION="$(terraform version -json | grep -o '"terraform_version":"[^"]*"' | cut -d '"' -f 4 || true)"

  if [[ -n "$CURRENT_VERSION" ]]; then
    warning "Terraform já está instalado!"
    log "Versão encontrada: $CURRENT_VERSION"
    log "Localização: $(command -v terraform)"

    read -r -p "Deseja continuar e atualizar/reinstalar? (y/N): " ANSWER

    if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
      success "Instalação cancelada. Nada foi alterado."
      exit 0
    fi
  fi
fi

log "Detectando arquitetura do sistema..."

case "$(uname -m)" in
  x86_64)
    ARCH="amd64"
    ;;
  aarch64|arm64)
    ARCH="arm64"
    ;;
  *)
    error "Arquitetura não suportada: $(uname -m)"
    exit 1
    ;;
esac

log "Arquitetura identificada: windows_$ARCH"

if [[ "$VERSION" == "latest" ]]; then
  log "Consultando última versão disponível..."

  VERSION=$(curl -fsSL \
    https://checkpoint-api.hashicorp.com/v1/check/terraform \
    | grep -o '"current_version":"[^"]*"' \
    | cut -d '"' -f 4)

  [[ -n "$VERSION" ]] || {
    error "Não foi possível identificar a versão."
    exit 1
  }
fi

log "Versão selecionada: $VERSION"

log "Preparando diretório de instalação..."
mkdir -p "$INSTALL_DIR"

URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_windows_${ARCH}.zip"

log "Iniciando download do Terraform..."
log "Origem: $URL"

curl -fL --progress-bar "$URL" -o "$TEMP_DIR/terraform.zip"

success "Download concluído."

log "Extraindo pacote..."
unzip -oq "$TEMP_DIR/terraform.zip" -d "$TEMP_DIR"

if [[ ! -f "$TEMP_DIR/terraform.exe" ]]; then
  error "Executável terraform.exe não encontrado."
  exit 1
fi

success "Extração concluída."

log "Instalando Terraform em: $INSTALL_DIR"

mv -f "$TEMP_DIR/terraform.exe" "$INSTALL_DIR/terraform.exe"

success "Executável instalado."

log "Configurando PATH do Git Bash..."

touch "$PROFILE"

if ! grep -Fqx "$PATH_LINE" "$PROFILE"; then
  echo "$PATH_LINE" >> "$PROFILE"
  success "PATH adicionado ao ~/.bashrc."
else
  warning "PATH já estava configurado."
fi

export PATH="$INSTALL_DIR:$PATH"

log "Validando instalação..."

if ! command -v terraform >/dev/null 2>&1; then
  error "Terraform não foi encontrado no PATH."
  exit 1
fi

echo ""
terraform version
echo ""

success "Terraform instalado com sucesso!"
log "Executável: $(command -v terraform)"
log "Diretório: $INSTALL_DIR"

echo ""
echo "Para utilizar em um novo terminal, abra outro Git Bash."
echo "======================================"
