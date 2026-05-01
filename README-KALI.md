# 🐉 Kali Linux — Setup e Build do APK

Este guia é específico para **Kali Linux** e resolve os erros comuns de permissão.

---

## 🚨 Erros que vamos resolver

| Erro | Causa | Solução |
|------|-------|---------|
| `externally-managed-environment` | Kali bloqueia pip system-wide | `--break-system-packages` |
| `EACCES: permission denied` | npm -g precisa de root | Instalar localmente com `npm install` (sem -g) |

---

## 📋 Passo a Passo

### 1. Entrar na pasta do projeto

```bash
cd ~/gestao-academias/python-app
```

### 2. Colocar a sua logomarca (OPCIONAL)

Pegue a imagem que você anexou e salve como:
```
python-app/assets/logo-original.png
```

> Se não colocar, o script cria um ícone programaticamente com o shield azul + punhos laranja.

### 3. Rodar o setup completo (uma vez só)

```bash
bash setup-kali.sh
```

Este script faz TUDO automaticamente:
- ✅ Instala dependências Python (`pip install --break-system-packages`)
- ✅ Instala Capacitor localmente (`npm install` sem sudo)
- ✅ Gera ícones Android + PWA + Splash screens
- ✅ Cria projeto Android

**Saída esperada:**
```
═══════════════════════════════════════════════════════════════
  ✅ SETUP COMPLETO!
═══════════════════════════════════════════════════════════════

📱 Agora gere o APK com:
   bash build-apk.sh
```

### 4. Gerar o APK

```bash
bash build-apk.sh
```

**Saída esperada:**
```
═══════════════════════════════════════════════════════════════
  ✅ APK GERADO COM SUCESSO!
═══════════════════════════════════════════════════════════════

📂 Local do APK (Debug):
   capacitor/android/app/build/outputs/apk/debug/app-debug.apk
```

### 5. Instalar no celular

```bash
cd capacitor/android
adb install app/build/outputs/apk/debug/app-debug.apk
```

Ou envie o arquivo pelo WhatsApp/Telegram e toque para instalar.

---

## 🔧 Pré-requisitos (instale uma vez no Kali)

### Node.js
```bash
# Verificar se tem Node.js
node --version

# Se não tiver, instale:
sudo apt update
sudo apt install -y nodejs npm

# Ou use nvm (recomendado):
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
```

### Android Studio
```bash
# Baixe em: https://developer.android.com/studio
# Extraia em ~/android-studio
# Rode: ~/android-studio/bin/studio.sh

# Configure o SDK:
# Tools → SDK Manager → instale Android SDK Platform 33
```

### Variáveis de ambiente
Adicione no final do `~/.bashrc`:
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

Depois recarregue:
```bash
source ~/.bashrc
```

---

## 🔄 Atualizar o app (nova versão do site)

```bash
cd ~/gestao-academias/python-app
npx cap sync android
cd capacitor/android
./gradlew assembleDebug
```

---

## 🏪 APK de Release (para Play Store)

```bash
cd ~/gestao-academias/python-app/capacitor/android

# Criar keystore (uma vez só)
keytool -genkey -v -keystore release.keystore -alias gestaoacademias \
  -keyalg RSA -keysize 2048 -validity 10000
# Senha: 230808Deus#

# Build release
./gradlew assembleRelease
```

APK assinado:
```
app/build/outputs/apk/release/app-release.apk
```

---

## ❓ Troubleshooting

### "adb: command not found"
```bash
export PATH=$PATH:$ANDROID_HOME/platform-tools
```

### "SDK location not found"
```bash
echo "sdk.dir=$ANDROID_HOME" > capacitor/android/local.properties
```

### "JAVA_HOME not set"
```bash
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
```

### "Could not find gradle wrapper"
```bash
cd capacitor/android
gradle wrapper
```

---

**Desenvolvido por Júnior Araújo Sistemas**
📱 (91) 98212-2175 | 📧 junior.araujo21@yahoo.com.br
