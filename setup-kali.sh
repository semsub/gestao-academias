#!/bin/bash
# =============================================================================
# SETUP COMPLETO PARA KALI LINUX
# Resolve: externally-managed-environment (pip) e EACCES (npm)
# =============================================================================

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  🥋 Setup - Sistema de Gestão de Academias"
echo "  Kali Linux Edition"
echo "═══════════════════════════════════════════════════════════════"

# Detectar se estamos na pasta correta
if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    echo "   cd python-app"
    echo "   bash setup-kali.sh"
    exit 1
fi

echo ""
echo "📦 Passo 1/5: Instalando dependências Python..."
echo "   (usando --break-system-packages para Kali)"

pip install --break-system-packages -r requirements.txt

echo ""
echo "📦 Passo 2/5: Instalando dependências Node.js (Capacitor)..."
echo "   (instalação local, sem sudo necessário)"

npm install

echo ""
echo "🎨 Passo 3/5: Gerando ícones..."
python3 generate_icons.py

echo ""
echo "🔧 Passo 4/5: Inicializando Capacitor Android..."

# Se já existe android, remove para recriar limpo
if [ -d "capacitor/android" ]; then
    echo "   Removendo build anterior..."
    rm -rf capacitor/android
fi

npx cap add android

echo ""
echo "⚙️  Passo 5/5: Sincronizando..."
npx cap sync android

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ SETUP COMPLETO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📱 Agora gere o APK com:"
echo "   bash build-apk.sh"
echo ""
