# 📱 PWA, APK Android e iOS

O sistema funciona em 3 formatos:

| Formato | Como funciona | Requisitos |
|---------|--------------|------------|
| **🌐 Site** | Acesso via navegador | Apenas internet |
| **📲 PWA** | Instalado na tela inicial do celular | Navegador moderno (Chrome, Safari) |
| **🤖 APK Android** | App nativo Android | Android 8+ |
| **🍎 iOS** | App nativo iOS | macOS + Xcode |

---

## 🌐 1. Site (já funciona)

Acesse: **https://gestao-academias-ghna.onrender.com**

---

## 📲 2. PWA (Instalar no celular sem APK)

### Android (Chrome):
1. Abra o site no Chrome
2. Toque no menu (⋮) → **"Adicionar à tela inicial"**
3. O app aparece com o ícone da logomarca

### iOS (Safari):
1. Abra o site no Safari
2. Toque em **Compartilhar** (□⬆️)
3. Role e toque em **"Adicionar à Tela de Início"**

---

## 🤖 3. APK Android

### Pré-requisitos:
- Node.js 18+
- Android Studio (com SDK 34)
- Java 17

### Build:
```bash
cd ~/gestao-academias/python-app
bash build-android.sh
```

### Instalar no celular:
```bash
adb install android/app/build/outputs/apk/debug/app-debug.apk
```

Ou envie o arquivo pelo WhatsApp/Telegram e toque para instalar.

---

## 🍎 4. iOS (requer Mac)

### Pré-requisitos:
- macOS
- Xcode (App Store)
- Node.js 18+

### Build:
```bash
cd ~/gestao-academias/python-app
bash build-ios.sh
```

### Abrir no Xcode:
```bash
npx cap open ios
```

No Xcode:
1. Conecte seu iPhone
2. Selecione o dispositivo no topo
3. Clique no ▶️ (Run)

---

## 🔄 Atualizar app (nova versão do site)

Sempre que atualizar o site no Render, reconstrua:

```bash
cd ~/gestao-academias/python-app

# Android
rm -rf android
bash build-android.sh

# iOS (Mac)
rm -rf ios
bash build-ios.sh
```

---

## 🛠️ Solução de Problemas

### APK abre mas fica em branco
- Verifique se a URL no `capacitor.config.json` está correta
- O site do Render precisa estar no ar

### Ícone não aparece no celular
- Reinicie o celular
- Ou use um launcher diferente (Nova Launcher)

### "App not installed"
- Desinstale a versão anterior primeiro
- Ou use `adb install -r` (reinstall)

---

**Desenvolvido por Júnior Araújo Sistemas**
📱 (91) 98212-2175 | 📧 junior.araujo21@yahoo.com.br
