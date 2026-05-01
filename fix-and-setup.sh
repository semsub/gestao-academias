#!/bin/bash
# =============================================================================
# SCRIPT ÚNICO DE CORREÇÃO + SETUP
# Limpa tudo, recria config, gera ícones em pasta temporária, cria Android
# =============================================================================
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  🔧 CORREÇÃO + SETUP"
echo "  Sistema de Gestão de Academias"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    exit 1
fi

# === 1. LIMPEZA TOTAL ===
echo ""
echo "🧹 Limpando tudo..."
rm -rf android
rm -rf capacitor/android
rm -rf android-res-temp
rm -f capacitor.config.json
echo "   ✅ Limpo"

# === 2. PYTHON ===
echo ""
echo "📦 Instalando Python..."
pip install --break-system-packages -r requirements.txt 2>/dev/null || {
    echo "   ⚠️  psycopg falhou, usando SQLite..."
    pip install --break-system-packages -r requirements-dev.txt
}

# === 3. NODE ===
echo ""
echo "📦 Instalando Node.js..."
npm install

# === 4. CAPACITOR CONFIG ===
echo ""
echo "🔧 Criando capacitor.config.json..."
cat > capacitor.config.json << 'EOF'
{
  "appId": "br.com.junioraraujo.gestaoacademias",
  "appName": "JA Gestão Academias",
  "webDir": "static",
  "bundledWebRuntime": false,
  "server": {
    "url": "https://gestao-academias.onrender.com",
    "cleartext": false
  },
  "plugins": {
    "SplashScreen": {
      "launchShowDuration": 3000,
      "launchAutoHide": true,
      "backgroundColor": "#0D47A1",
      "androidSplashResourceName": "splash",
      "androidScaleType": "CENTER_CROP"
    }
  }
}
EOF
echo "   ✅ capacitor.config.json"

# === 5. STATIC/INDEX.HTML ===
echo ""
echo "🔍 Verificando static/index.html..."
if [ ! -f "static/index.html" ]; then
    mkdir -p static
    cat > static/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>JA Gestão Academias</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
           background: linear-gradient(135deg, #0D47A1, #1E88E5);
           min-height: 100vh; display: flex; align-items: center; justify-content: center;
           color: white; }
    .container { text-align: center; padding: 2rem; }
    .logo { width: 150px; height: 150px; margin-bottom: 1.5rem; }
    h1 { font-size: 1.8rem; margin-bottom: 0.5rem; }
    p { opacity: 0.9; margin-bottom: 2rem; }
    .loading { width: 48px; height: 48px; border: 4px solid rgba(255,255,255,0.3);
               border-top-color: #fff; border-radius: 50%; margin: 0 auto 1.5rem;
               animation: spin 1s linear infinite; }
    @keyframes spin { to { transform: rotate(360deg); } }
    .btn { display: inline-block; background: #FF7A1A; color: white;
           padding: 12px 32px; border-radius: 8px; text-decoration: none;
           font-weight: 600; margin-top: 1rem; }
  </style>
</head>
<body>
  <div class="container">
    <img src="icon.svg" alt="JA Gestão" class="logo">
    <div class="loading"></div>
    <h1>JA Gestão Academias</h1>
    <p>Carregando sistema...</p>
    <a href="https://gestao-academias.onrender.com" class="btn">Acessar Sistema</a>
  </div>
  <script>
    setTimeout(function() { window.location.replace('https://gestao-academias.onrender.com'); }, 500);
  </script>
</body>
</html>
HTMLEOF
    echo "   ✅ static/index.html criado"
else
    echo "   ✅ static/index.html já existe"
fi

# === 6. SOBRESCREVER GENERATE_ICONS.PY ===
echo ""
echo "🎨 Atualizando generate_icons.py..."
cat > generate_icons.py << 'PYEOF'
#!/usr/bin/env python3
import os
from PIL import Image, ImageDraw

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
ANDROID_RES_DIR = os.path.join(BASE_DIR, "android-res-temp")
STATIC_ICONS_DIR = os.path.join(BASE_DIR, "static", "icons")

ANDROID_SIZES = {
    "mipmap-mdpi": 48, "mipmap-hdpi": 72, "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144, "mipmap-xxxhdpi": 192,
}
PWA_SIZES = [72, 96, 128, 144, 152, 192, 384, 512]

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def draw_shield_icon(size):
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    s = size
    pad = int(s * 0.08)
    shield_w = s - pad * 2
    shield_h = int(shield_w * 1.15)
    blue_dark = (13, 71, 161)
    blue_light = (127, 203, 255)
    orange_mid = (255, 122, 26)
    orange_dark = (212, 78, 0)
    white = (255, 255, 255)
    cx = s // 2

    shield_points = [
        (cx, pad - 2), (cx + shield_w // 2 + 2, pad + int(shield_w * 0.25)),
        (cx + shield_w // 2 + 2, pad + int(shield_w * 0.55)),
        (cx, pad + shield_h + 2), (cx - shield_w // 2 - 2, pad + int(shield_w * 0.55)),
        (cx - shield_w // 2 - 2, pad + int(shield_w * 0.25)),
    ]
    draw.polygon(shield_points, fill=white)

    for y in range(pad, pad + shield_h):
        ratio = (y - pad) / shield_h
        r = int(blue_light[0] + (blue_dark[0] - blue_light[0]) * ratio)
        g = int(blue_light[1] + (blue_dark[1] - blue_light[1]) * ratio)
        b = int(blue_light[2] + (blue_dark[2] - blue_light[2]) * ratio)
        if y < pad + int(shield_w * 0.25):
            half_w = int((y - pad) / (shield_w * 0.25) * (shield_w // 2))
        elif y < pad + int(shield_w * 0.55):
            half_w = shield_w // 2
        else:
            half_w = int((1 - (y - pad - int(shield_w * 0.55)) / (shield_h - int(shield_w * 0.55))) * (shield_w // 2))
        half_w = max(0, half_w - 2)
        if half_w > 0:
            draw.line([(cx - half_w, y), (cx + half_w, y)], fill=(r, g, b))

    collar_top = pad + int(shield_h * 0.18)
    collar_bottom = pad + int(shield_h * 0.38)
    collar_w = int(shield_w * 0.35)
    line_w = max(1, size // 40)
    draw.line([(cx - collar_w, collar_top), (cx, collar_bottom)], fill=white, width=line_w)
    draw.line([(cx + collar_w, collar_top), (cx, collar_bottom)], fill=white, width=line_w)

    fist_rx = int(shield_w * 0.18)
    fist_ry = int(shield_w * 0.14)
    fist_y = pad + int(shield_h * 0.62)
    fist_offset = int(fist_rx * 0.7)
    draw.ellipse([cx - fist_offset - fist_rx, fist_y - fist_ry, cx - fist_offset + fist_rx, fist_y + fist_ry], fill=orange_mid, outline=white, width=max(1, size // 60))
    draw.ellipse([cx + fist_offset - fist_rx, fist_y - fist_ry, cx + fist_offset + fist_rx, fist_y + fist_ry], fill=orange_mid, outline=white, width=max(1, size // 60))
    line_len = int(fist_ry * 0.6)
    for fx in [cx - fist_offset, cx + fist_offset]:
        for offset in [-int(fist_rx*0.5), 0, int(fist_rx*0.5)]:
            x = fx + offset
            draw.line([(x, fist_y - line_len//2), (x, fist_y + line_len//2)], fill=orange_dark, width=max(1, size // 80))
    return img

def generate_android_icons(source_path=None):
    if source_path and os.path.exists(source_path):
        img = Image.open(source_path).convert("RGBA")
        print("   Usando logomarca do usuário")
    else:
        print("   Criando ícone programaticamente")
        img = None
    for folder, size in ANDROID_SIZES.items():
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        ensure_dir(out_dir)
        resized = img.resize((size, size), Image.LANCZOS) if img else draw_shield_icon(size)
        resized.save(os.path.join(out_dir, "ic_launcher.png"), "PNG")
        print(f"  ✅ {folder}/ic_launcher.png ({size}x{size})")
        out_dir_round = os.path.join(ANDROID_RES_DIR, folder + "-round")
        ensure_dir(out_dir_round)
        mask = Image.new("L", (size, size), 0)
        draw_mask = ImageDraw.Draw(mask)
        draw_mask.ellipse((0, 0, size, size), fill=255)
        rounded = Image.new("RGBA", (size, size), (0, 0, 0, 0))
        rounded.paste(resized, (0, 0))
        rounded.putalpha(mask)
        rounded.save(os.path.join(out_dir_round, "ic_launcher_round.png"), "PNG")
        print(f"  ✅ {folder}-round/ic_launcher_round.png ({size}x{size})")

def generate_pwa_icons(source_path=None):
    if source_path and os.path.exists(source_path):
        img = Image.open(source_path).convert("RGBA")
    else:
        img = None
    ensure_dir(STATIC_ICONS_DIR)
    for size in PWA_SIZES:
        resized = img.resize((size, size), Image.LANCZOS) if img else draw_shield_icon(size)
        resized.save(os.path.join(STATIC_ICONS_DIR, f"icon-{size}x{size}.png"), "PNG")
        print(f"  ✅ static/icons/icon-{size}x{size}.png")
    favicon = img.resize((32, 32), Image.LANCZOS) if img else draw_shield_icon(32)
    favicon.save(os.path.join(STATIC_ICONS_DIR, "favicon.ico"), format="ICO")
    print(f"  ✅ static/icons/favicon.ico")

def generate_splash_screen(source_path=None):
    splash_sizes = {
        "drawable-mdpi": (320, 480), "drawable-hdpi": (480, 800),
        "drawable-xhdpi": (720, 1280), "drawable-xxhdpi": (960, 1600),
        "drawable-xxxhdpi": (1280, 1920),
    }
    for folder, (w, h) in splash_sizes.items():
        out_dir = os.path.join(ANDROID_RES_DIR, folder)
        ensure_dir(out_dir)
        canvas = Image.new("RGB", (w, h), "#0D47A1")
        draw = ImageDraw.Draw(canvas)
        for y in range(h):
            r = int(13 + (30 - 13) * y / h)
            g = int(71 + (136 - 71) * y / h)
            b = int(161 + (229 - 161) * y / h)
            draw.line([(0, y), (w, y)], fill=(r, g, b))
        logo_size = int(w * 0.4)
        if source_path and os.path.exists(source_path):
            logo = Image.open(source_path).convert("RGBA")
            logo = logo.resize((logo_size, logo_size), Image.LANCZOS)
        else:
            logo = draw_shield_icon(logo_size)
        x = (w - logo_size) // 2
        y = (h - logo_size) // 2
        canvas.paste(logo, (x, y), logo)
        try:
            from PIL import ImageFont
            font_size = max(12, h // 40)
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", font_size)
        except Exception:
            font = ImageFont.load_default()
        text = "JA Gestão Academias"
        bbox = draw.textbbox((0, 0), text, font=font)
        text_w = bbox[2] - bbox[0]
        text_x = (w - text_w) // 2
        text_y = y + logo_size + int(h * 0.03)
        draw.text((text_x, text_y), text, fill="white", font=font)
        canvas.save(os.path.join(out_dir, "splash.png"), "PNG")
        print(f"  ✅ {folder}/splash.png ({w}x{h})")

def main():
    source = os.path.join(ASSETS_DIR, "logo-original.png")
    has_source = os.path.exists(source)
    if not has_source:
        print("⚠️  assets/logo-original.png não encontrado. Usando ícone padrão.")
    print("🎨 Gerando ícones...\n")
    print("📱 Ícones Android:")
    generate_android_icons(source if has_source else None)
    print("\n🌐 Ícones PWA:")
    generate_pwa_icons(source if has_source else None)
    print("\n🖼️ Splash Screens:")
    generate_splash_screen(source if has_source else None)
    print("\n✅ Todos os ícones gerados!")
    print(f"\n📂 Android resources: {ANDROID_RES_DIR}")
    print(f"📂 PWA icons: {STATIC_ICONS_DIR}")

if __name__ == "__main__":
    main()
PYEOF

chmod +x generate_icons.py
python3 generate_icons.py

# === 7. CAPACITOR ADD ANDROID ===
echo ""
echo "📱 Adicionando plataforma Android..."
npx cap add android

# === 8. COPIAR ÍCONES ===
echo ""
echo "🎨 Copiando ícones..."
if [ -d "android-res-temp" ]; then
    cp -r android-res-temp/* android/app/src/main/res/ 2>/dev/null || true
    rm -rf android-res-temp
    echo "   ✅ Ícones copiados"
fi

# === 9. SYNC ===
echo ""
echo "⚙️  Sincronizando..."
npx cap sync android

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ TUDO PRONTO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📱 Gere o APK: cd android && ./gradlew assembleDebug"
echo "📲 Instalar: adb install android/app/build/outputs/apk/debug/app-debug.apk"
echo ""
