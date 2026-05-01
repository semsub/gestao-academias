#!/bin/bash
# =============================================================================
# BUILD APK ANDROID
# =============================================================================
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  📱 BUILD APK - Android"
echo "  JA Gestão Academias"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute na pasta python-app/"
    exit 1
fi

echo ""
echo "🧹 Limpando build anterior..."
rm -rf android android-res-temp

echo ""
echo "📱 Adicionando Android..."
npx cap add android

echo ""
echo "🎨 Gerando ícones..."
python3 generate_icons.py

echo ""
echo "📂 Copiando ícones..."
if [ -d "android-res-temp" ]; then
    for d in android-res-temp/mipmap-*; do
        name=$(basename "$d")
        if [ -d "$d" ]; then
            mkdir -p "android/app/src/main/res/$name"
            cp "$d"/* "android/app/src/main/res/$name/"
            echo "   ✅ $name"
        fi
    done
    for d in android-res-temp/drawable-*; do
        name=$(basename "$d")
        if [ -d "$d" ]; then
            mkdir -p "android/app/src/main/res/$name"
            cp "$d"/* "android/app/src/main/res/$name/"
            echo "   ✅ $name"
        fi
    done
    rm -rf android-res-temp
fi

echo ""
echo "⚙️  Sincronizando..."
npx cap sync android

echo ""
echo "🔨 Build APK Debug..."
cd android
./gradlew assembleDebug

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ APK GERADO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📂 APK Debug: android/app/build/outputs/apk/debug/app-debug.apk"
echo "📲 Instalar: adb install android/app/build/outputs/apk/debug/app-debug.apk"
echo ""
