
#!/usr/bin/env bash
set -Eeuo pipefail

INSTALL_DIR="$HOME/google-cloud-sdk"
PROFILE="$HOME/.bashrc"
INSTALLER_URL="https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe"
TEMP_DIR="$(mktemp -d)"

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
    error "Falha na linha $1."
    error "Verifique os logs e tente novamente."
}
trap 'handle_error $LINENO' ERR

echo ""
echo "======================================"
echo "      GOOGLE CLOUD CLI INSTALLER"
echo "======================================"
echo ""

log "Verificando sistema operacional..."

case "$(uname -s)" in
    MINGW*|MSYS*)
        success "Windows + Git Bash identificado."
        ;;
    *)
        error "Este script foi desenvolvido para Windows + Git Bash."
        exit 1
        ;;
esac

GCLOUD_PATH=""

for DIR in \
    "$INSTALL_DIR/bin" \
    "$INSTALL_DIR/google-cloud-sdk/bin"
do
    if [[ -f "$DIR/gcloud.cmd" ]]; then
        GCLOUD_PATH="$DIR/gcloud.cmd"
        GCLOUD_BIN="$DIR"
        break
    fi
done

if [[ -n "$GCLOUD_PATH" ]]; then
    warning "Google Cloud CLI já está instalado!"
    log "Localização: $GCLOUD_PATH"

    "$GCLOUD_PATH" version

    read -r -p "Deseja reinstalar/atualizar? (y/N): " ANSWER

    if [[ ! "$ANSWER" =~ ^[Yy]$ ]]; then
        success "Instalação mantida."
        exit 0
    fi
fi

INSTALLER="$TEMP_DIR/GoogleCloudSDKInstaller.exe"

log "Baixando instalador oficial..."
log "Origem: $INSTALLER_URL"

curl -fL --progress-bar "$INSTALLER_URL" -o "$INSTALLER"

if [[ ! -s "$INSTALLER" ]]; then
    error "O instalador foi baixado vazio."
    exit 1
fi

success "Download concluído."

log "Validando assinatura digital..."

export GCLOUD_INSTALLER="$(cygpath -w "$INSTALLER")"

powershell.exe -NoProfile -Command '
    $signature = Get-AuthenticodeSignature $env:GCLOUD_INSTALLER
    if ($signature.Status -ne "Valid") {
        Write-Error "Assinatura digital inválida."
        exit 1
    }
    Write-Host "Assinatura digital válida."
'

success "Assinatura validada."

log "Executando instalador oficial..."

export GCLOUD_INSTALL_DIR="$(cygpath -w "$INSTALL_DIR")"

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command '
    $installerArgs = @(
        "/S",
        "/singleuser",
        "/noreporting",
        ("/D=" + $env:GCLOUD_INSTALL_DIR)
    )

    $process = Start-Process `
        -FilePath $env:GCLOUD_INSTALLER `
        -ArgumentList $installerArgs `
        -Wait `
        -PassThru

    exit $process.ExitCode
'

success "Instalador finalizado."

log "Procurando executável gcloud.cmd..."

GCLOUD_BIN=""

for DIR in \
    "$INSTALL_DIR/bin" \
    "$INSTALL_DIR/google-cloud-sdk/bin"
do
    if [[ -f "$DIR/gcloud.cmd" ]]; then
        GCLOUD_BIN="$DIR"
        break
    fi
done

if [[ -z "$GCLOUD_BIN" ]]; then
    error "gcloud.cmd não encontrado."
    error "Diretório pesquisado: $INSTALL_DIR"
    exit 1
fi

success "Executável encontrado: $GCLOUD_BIN/gcloud.cmd"

log "Configurando PATH do Git Bash..."

PATH_LINE="export PATH=\"$GCLOUD_BIN:\$PATH\""

touch "$PROFILE"

sed -i '\|google-cloud-sdk/bin|d' "$PROFILE"

echo "$PATH_LINE" >> "$PROFILE"

export PATH="$GCLOUD_BIN:$PATH"
hash -r

success "PATH configurado."

log "Validando Google Cloud CLI..."

gcloud.cmd version

echo ""
success "Google Cloud CLI instalado com sucesso!"

log "Diretório: $INSTALL_DIR"
log "Executável: $GCLOUD_BIN/gcloud.cmd"

echo ""
echo "Próximos passos:"
echo "1. Abra um novo Git Bash."
echo "2. Execute: gcloud init"
echo "3. Autentique: gcloud auth application-default login"
echo ""
echo "======================================"