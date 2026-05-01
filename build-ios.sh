#!/bin/bash
# =============================================================================
# BUILD iOS - REQUER MAC + XCODE
# =============================================================================
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  🍎 BUILD iOS"
echo "  JA Gestão Academias"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute na pasta python-app/"
    exit 1
fi

if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ ERRO: Build iOS requer macOS com Xcode instalado."
    echo "   Este sistema é: $OSTYPE"
    exit 1
fi

echo ""
echo "🧹 Limpando build anterior..."
rm -rf ios

echo ""
echo "🍎 Adicionando iOS..."
npx cap add ios

echo ""
echo "🎨 Gerando ícones..."
python3 generate_icons.py

echo ""
echo "📂 Copiando ícones..."
# iOS usa Assets.xcassets para ícones
if [ -d "android-res-temp" ]; then
    # Copiar o maior ícone para o iOS
    cp android-res-temp/mipmap-xxxhdpi/ic_launcher.png ios/App/App/Assets.xcassets/AppIcon.appiconset/icon-1024.png 2>/dev/null || true
    rm -rf android-res-temp
fi

echo ""
echo "⚙️  Sincronizando..."
npx cap sync ios

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ PROJETO iOS CRIADO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📂 Projeto iOS: ios/App/App.xcworkspace"
echo ""
echo "🔨 Para build manual:"
echo "   1. Abra ios/App/App.xcworkspace no Xcode"
echo "   2. Selecione seu dispositivo/simulador"
echo "   3. Clique em Product → Build"
echo ""
echo "   Ou use: npx cap open ios"
echo ""
