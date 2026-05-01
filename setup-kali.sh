#!/bin/bash
# =============================================================================
# SETUP COMPLETO PARA KALI LINUX
# =============================================================================
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  🥋 Setup - Sistema de Gestão de Academias"
echo "  Kali Linux Edition"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    exit 1
fi

# === PASSO 1: Python ===
echo ""
echo "📦 Passo 1/5: Instalando dependências Python..."
pip install --break-system-packages -r requirements.txt 2>/dev/null || {
    echo "   ⚠️  psycopg falhou, usando SQLite..."
    pip install --break-system-packages -r requirements-dev.txt
}

# === PASSO 2: Node ===
echo ""
echo "📦 Passo 2/5: Instalando dependências Node.js..."
npm install

# === PASSO 3: Verificar index.html ===
echo ""
echo "🔍 Passo 3/5: Verificando arquivos..."
if [ ! -f "static/index.html" ]; then
    echo "❌ static/index.html não encontrado!"
    echo "   Este arquivo é obrigatório para o Capacitor."
    exit 1
fi
echo "   ✅ static/index.html encontrado"

# === PASSO 4: Gerar ícones ===
echo ""
echo "🎨 Passo 4/5: Gerando ícones..."
python3 generate_icons.py

# === PASSO 5: Capacitor ===
echo ""
echo "🔧 Passo 5/5: Configurando Capacitor Android..."

# Garante capacitor.config.json
if [ ! -f "capacitor.config.json" ]; then
    echo "❌ capacitor.config.json não encontrado!"
    exit 1
fi

# Remove projeto Android antigo completamente
if [ -d "android" ]; then
    echo "   Removendo pasta android/ antiga..."
    rm -rf android
fi
if [ -d "capacitor/android" ]; then
    echo "   Removendo capacitor/android antigo..."
    rm -rf capacitor/android
fi

# Adiciona plataforma Android
echo "   Adicionando Android..."
npx cap add android

# Copia ícones gerados para o projeto Android
if [ -d "android-res-temp" ]; then
    echo "   Copiando ícones..."
    cp -r android-res-temp/* android/app/src/main/res/ 2>/dev/null || true
    rm -rf android-res-temp
fi

# Sync
echo "   Sincronizando..."
npx cap sync android

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ SETUP COMPLETO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📱 Gere o APK com: bash build-apk.sh"
echo "🌐 Teste local: python3 app.py"
echo ""
