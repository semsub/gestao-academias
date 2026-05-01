#!/bin/bash
# =============================================================================
# BUILD DO APK NATIVO ANDROID - KALI LINUX
# =============================================================================
# NÃO precisa de sudo. Tudo é instalado localmente na pasta do projeto.
#
# PRÉ-REQUISITOS:
#   - Node.js 18+ instalado
#   - Android Studio instalado
#   - SDK Android 33+ instalado
#   - JAVA_HOME configurado
#
# USO:
#   1. Coloque sua logomarca em: assets/logo-original.png (opcional)
#   2. Rode: bash setup-kali.sh      (primeira vez)
#   3. Rode: bash build-apk.sh       (gerar APK)
# =============================================================================

set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  🥋 BUILD APK - Sistema de Gestão de Academias"
echo "  Júnior Araújo Sistemas"
echo "═══════════════════════════════════════════════════════════════"

# Detectar se estamos na pasta correta
if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    exit 1
fi

# Verificar se a logomarca existe (opcional - script cria ícone padrão se não houver)
if [ ! -f "assets/logo-original.png" ]; then
    echo "⚠️  Aviso: assets/logo-original.png não encontrado."
    echo "   Será usado o ícone padrão gerado pelo script Python."
    echo "   Para usar SUA logomarca, salve-a como:"
    echo "   python-app/assets/logo-original.png"
    echo ""
fi

echo "🎨 Gerando ícones..."
python3 generate_icons.py

echo ""
echo "📱 Verificando Capacitor..."
if [ ! -d "capacitor/android" ]; then
    echo "   Capacitor Android não encontrado. Rodando setup..."
    bash setup-kali.sh
fi

echo ""
echo "⚙️  Sincronizando código web..."
npx cap sync android

echo ""
echo "🔨 Build do APK Debug..."
cd capacitor/android
./gradlew assembleDebug

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ APK GERADO COM SUCESSO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📂 Local do APK (Debug):"
echo "   capacitor/android/app/build/outputs/apk/debug/app-debug.apk"
echo ""
echo "📲 Para instalar no celular conectado via USB:"
echo "   adb install app/build/outputs/apk/debug/app-debug.apk"
echo ""
echo "💡 Para gerar APK de release assinado:"
echo "   cd capacitor/android"
echo "   ./gradlew assembleRelease"
echo ""
