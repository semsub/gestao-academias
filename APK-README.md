# 📱 Gerar APK Nativo Android

Guia completo para transformar o sistema web em um **APK nativo Android** com a sua logomarca e ícone.

---

## 🎨 Sobre a Logomarca

Você precisa colocar a **imagem da logomarca que anexou no início da conversa** no projeto. Ela será usada para:
- Ícone do app no celular
- Ícone na Play Store
- Splash screen (tela de abertura)
- Ícones PWA (instalação via navegador)

---

## 📋 Passo a Passo

### 1. Preparar a imagem da logomarca

Pegue a imagem que você enviou no início (a logo com fundo preto, escudo azul, punhos laranja e texto).

Salve ela como:
```
python-app/assets/logo-original.png
```

> 💡 A imagem pode ser **PNG, JPG, JPEG, WEBP, BMP, TIFF** ou qualquer formato comum.

---

### 2. Gerar todos os ícones automaticamente

Rode o script Python que gera ícones em TODOS os tamanhos necessários:

```bash
cd python-app
python3 generate_icons.py
```

Isso vai criar:
- 📱 Ícones Android em 5 densidades (mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)
- 🌐 Ícones PWA em 8 tamanhos (72px até 512px)
- 🖼️ Splash screens em 5 resoluções

Saída esperada:
```
🎨 Gerando ícones a partir da logomarca...

📱 Ícones Android:
  ✅ mipmap-mdpi/ic_launcher.png (48x48)
  ✅ mipmap-hdpi/ic_launcher.png (72x72)
  ...

🌐 Ícones PWA:
  ✅ static/icons/icon-72x72.png
  ...

🖼️ Splash Screens:
  ✅ drawable-mdpi/splash.png (320x480)
  ...

✅ Todos os ícones gerados com sucesso!
```

---

### 3. Instalar pré-requisitos para build do APK

Você precisa ter instalado:

| Ferramenta | Download | Versão |
|------------|----------|--------|
| **Node.js** | https://nodejs.org/ | 18+ LTS |
| **Android Studio** | https://developer.android.com/studio | Mais recente |
| **Python** | já tem | 3.10+ |

**Configurar Android Studio:**
1. Abra o Android Studio
2. Vá em **More Actions → SDK Manager**
3. Instale:
   - **Android SDK Platform 33** (ou 34)
   - **Android SDK Build-Tools 33.0.0**
   - **Android SDK Command-line Tools**
4. Configure as variáveis de ambiente:

```bash
# Linux/Mac — adicione no ~/.bashrc ou ~/.zshrc:
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Windows — adicione nas variáveis de ambiente do sistema:
# ANDROID_HOME = C:\Users\SEU_USUARIO\AppData\Local\Android\Sdk
# PATH += %ANDROID_HOME%\tools;%ANDROID_HOME%\platform-tools
```

---

### 4. Gerar o APK (comando único)

```bash
cd python-app
bash build-apk.sh
```

O script vai:
1. ✅ Verificar se a logomarca existe
2. ✅ Instalar Capacitor globalmente
3. ✅ Gerar ícones (se ainda não gerou)
4. ✅ Criar projeto Android
5. ✅ Copiar ícones
6. ✅ Build do APK

---

### 5. Instalar no celular

**Opção A — USB (mais rápido):**
```bash
cd python-app/capacitor/android
adb install app/build/outputs/apk/debug/app-debug.apk
```

**Opção B — Transferir arquivo:**
1. Copie o arquivo:
   ```
   python-app/capacitor/android/app/build/outputs/apk/debug/app-debug.apk
   ```
2. Envie para o celular (WhatsApp, Telegram, USB, Google Drive)
3. No celular, toque no arquivo → **Instalar**
4. Se pedir "Fonte desconhecida", permita nas configurações

---

### 6. APK de Release (para publicar na Play Store)

Para gerar um APK assinado (necessário para publicar):

```bash
cd python-app/capacitor/android

# Criar keystore (faça UMA vez só)
keytool -genkey -v -keystore release.keystore -alias gestaoacademias \
  -keyalg RSA -keysize 2048 -validity 10000
# Senha sugerida: 230808Deus#

# Build release
./gradlew assembleRelease
```

O APK assinado ficará em:
```
app/build/outputs/apk/release/app-release.apk
```

---

## 🔄 Atualizar o app (nova versão)

Sempre que atualizar o site no Render:

```bash
cd python-app/capacitor
npx cap sync android
cd android
./gradlew assembleDebug
```

O APK será atualizado com a versão mais recente do site.

---

## 🛠️ Solução de Problemas

### "Command not found: adb"
```bash
# Linux/Mac
export PATH=$PATH:$ANDROID_HOME/platform-tools

# Windows
# Adicione %ANDROID_HOME%\platform-tools no PATH
```

### "Could not find gradle wrapper"
```bash
cd python-app/capacitor/android
gradle wrapper
```

### "SDK location not found"
Crie o arquivo `python-app/capacitor/android/local.properties`:
```properties
sdk.dir=/home/seu-usuario/Android/Sdk   # Linux
# sdk.dir=C:\\Users\\SEU_USUARIO\\AppData\\Local\\Android\\Sdk   # Windows
# sdk.dir=/Users/seu-usuario/Library/Android/sdk   # Mac
```

### "JAVA_HOME not set"
```bash
# Linux (OpenJDK 17)
export JAVA_HOME=/usr/lib/jvm/java-17-openjdk

# Mac (com Homebrew)
export JAVA_HOME=/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home

# Windows
# JAVA_HOME = C:\Program Files\Java\jdk-17
```

---

## 📱 Como o app funciona

O APK gerado é um **WebView nativo** que carrega o seu site do Render:
- Funciona **online** (requer internet)
- Tem ícone nativo no celular
- Tem splash screen personalizada
- Pode ser instalado como app normal
- Pode ser publicado na **Google Play Store**

Para funcionar **offline**, seria necessário implementar cache avançado no service worker (não incluso nesta versão).

---

## 📞 Suporte

**Júnior Araújo Sistemas**
📱 (91) 98212-2175
📧 junior.araujo21@yahoo.com.br
