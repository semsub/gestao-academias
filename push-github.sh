#!/bin/bash
# =============================================================================
# PUSH PARA O GITHUB - SUBSTITUI TUDO NO REPOSITÓRIO REMOTO
# =============================================================================

echo "═══════════════════════════════════════════════════════════════"
echo "  🚀 Subindo para o GitHub"
echo "  https://github.com/semsub/gestao-academias"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    exit 1
fi

if [ ! -d ".git" ]; then
    echo ""
    echo "🔧 Inicializando repositório Git..."
    git init
fi

echo ""
echo "🔗 Configurando remote origin..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/semsub/gestao-academias.git

echo ""
echo "📦 Adicionando arquivos..."
git add .

echo ""
echo "💾 Criando commit..."
git commit -m "Sistema de Gestão de Academias - Python + APK Android v1.0"

echo ""
echo "🌿 Configurando branch main..."
git branch -M main

echo ""
echo "🚀 Enviando para o GitHub (substituindo tudo)..."
git push -u -f origin main

echo ""
if [ $? -eq 0 ]; then
    echo "═══════════════════════════════════════════════════════════════"
    echo "  ✅ ENVIADO COM SUCESSO!"
    echo "═══════════════════════════════════════════════════════════════"
    echo ""
    echo "📂 Repositório: https://github.com/semsub/gestao-academias"
    echo ""
    echo "📋 Próximo passo - Deploy no Render:"
    echo "   1. Acesse https://render.com"
    echo "   2. New + → Web Service"
    echo "   3. Conecte o repositório semsub/gestao-academias"
    echo "   4. Configure:"
    echo "      Runtime: Python 3"
    echo "      Build Command: pip install -r requirements.txt"
    echo "      Start Command: gunicorn app:app --workers 2 --timeout 60 --bind 0.0.0.0:\$PORT"
    echo "   5. Adicione as Environment Variables:"
    echo "      DATABASE_URL=postgresql://neondb_owner:..."
    echo "      SECRET_KEY=(gere uma chave aleatória)"
    echo ""
    echo "📱 Para gerar o APK depois do deploy:"
    echo "   cd ~/gestao-academias/python-app"
    echo "   bash fix-and-setup.sh"
    echo "   cd android && ./gradlew assembleDebug"
    echo ""
else
    echo "❌ ERRO AO ENVIAR"
    echo ""
    echo "Verifique se você tem acesso ao repositório."
    echo "Se for privado, configure suas credenciais do GitHub."
    echo "Use token de acesso pessoal: https://github.com/settings/tokens"
fi
