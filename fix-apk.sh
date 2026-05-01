#!/bin/bash
# =============================================================================
# CORREÇÃO DO APK E ÍCONE - KALI LINUX
# Limpa o projeto Android, recria ícones em pastas válidas e faz build
# =============================================================================
set -e

echo "═══════════════════════════════════════════════════════════════"
echo "  📱 CORREÇÃO DO APK E ÍCONE"
echo "═══════════════════════════════════════════════════════════════"

if [ ! -f "app.py" ]; then
    echo "❌ ERRO: Execute este script dentro da pasta python-app/"
    exit 1
fi

# === 1. LIMPAR PROJETO ANDROID ===
echo ""
echo "🧹 Limpando projeto Android..."
rm -rf android
rm -rf android-res-temp
echo "   ✅ Limpo"

# === 2. GARANTIR CONFIG ===
echo ""
echo "🔧 Verificando capacitor.config.json..."
if [ ! -f "capacitor.config.json" ]; then
    cat > capacitor.config.json << 'EOF'
{
  "appId": "br.com.junioraraujo.gestaoacademias",
  "appName": "JA Gestão Academias",
  "webDir": "static"
}
EOF
fi
echo "   ✅ Config OK"

# === 3. GARANTIR INDEX.HTML ===
echo ""
echo "🔍 Verificando static/index.html..."
mkdir -p static
cat > static/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>JA Gestão Academias</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,sans-serif;
background:linear-gradient(135deg,#0D47A1,#1E88E5);min-height:100vh;
display:flex;align-items:center;justify-content:center;color:#fff;text-align:center}
.container{padding:2rem}
.logo{width:140px;height:140px;margin-bottom:1.5rem;background:#fff;border-radius:24px;padding:10px}
h1{font-size:1.7rem;margin-bottom:.5rem}
p{opacity:.9;margin-bottom:1.5rem}
.loading{width:44px;height:44px;border:4px solid rgba(255,255,255,.3);
border-top-color:#fff;border-radius:50%;margin:0 auto 1.5rem;animation:spin 1s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
.btn{display:inline-block;background:#FF7A1A;color:#fff;padding:14px 32px;
border-radius:8px;text-decoration:none;font-weight:600;font-size:1rem}
.footer{margin-top:2rem;font-size:.75rem;opacity:.7}
</style>
</head>
<body>
<div class="container">
<img src="icon.svg" alt="JA Gestão" class="logo" onerror="this.style.display='none'">
<div class="loading"></div>
<h1>JA Gestão Academias</h1>
<p>Carregando sistema...</p>
<a href="https://gestao-academias.onrender.com" class="btn">Acessar Sistema</a>
<div class="footer">Júnior Araújo Sistemas · (91) 98212-2175</div>
</div>
<script>
setTimeout(function(){window.location.replace('https://gestao-academias.onrender.com');},800);
</script>
</body>
</html>
HTMLEOF
echo "   ✅ static/index.html OK"

# === 4. ADICIONAR ANDROID ===
echo ""
echo "📱 Criando projeto Android..."
npx cap add android

# === 5. GERAR ÍCONES EM PASTAS VÁLIDAS ===
echo ""
echo "🎨 Gerando ícones..."
python3 -c "
import os
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.join(BASE, 'assets')
RES = os.path.join(BASE, 'android', 'app', 'src', 'main', 'res')

SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

def draw_icon(size):
    img = Image.new('RGBA', (size, size), (0,0,0,0))
    draw = ImageDraw.Draw(img)
    s = size
    pad = int(s * 0.08)
    sw = s - pad * 2
    sh = int(sw * 1.15)
    cx = s // 2
    blue_dark = (13, 71, 161)
    blue_light = (127, 203, 255)
    orange_mid = (255, 122, 26)
    orange_dark = (212, 78, 0)
    white = (255, 255, 255)

    # shield outline
    sp = [(cx, pad-2), (cx+sw//2+2, pad+int(sw*0.25)),
          (cx+sw//2+2, pad+int(sw*0.55)), (cx, pad+sh+2),
          (cx-sw//2-2, pad+int(sw*0.55)), (cx-sw//2-2, pad+int(sw*0.25))]
    draw.polygon(sp, fill=white)

    # fill
    for y in range(pad, pad+sh):
        ratio = (y-pad)/sh
        r = int(blue_light[0] + (blue_dark[0]-blue_light[0])*ratio)
        g = int(blue_light[1] + (blue_dark[1]-blue_light[1])*ratio)
        b = int(blue_light[2] + (blue_dark[2]-blue_light[2])*ratio)
        if y < pad+int(sw*0.25):
            hw = int((y-pad)/(sw*0.25)*(sw//2))
        elif y < pad+int(sw*0.55):
            hw = sw//2
        else:
            hw = int((1-(y-pad-int(sw*0.55))/(sh-int(sw*0.55)))*(sw//2))
        hw = max(0, hw-2)
        if hw > 0:
            draw.line([(cx-hw, y), (cx+hw, y)], fill=(r,g,b))

    # collar
    ct = pad + int(sh*0.18)
    cb = pad + int(sh*0.38)
    cw = int(sw*0.35)
    lw = max(1, size//40)
    draw.line([(cx-cw, ct), (cx, cb)], fill=white, width=lw)
    draw.line([(cx+cw, ct), (cx, cb)], fill=white, width=lw)

    # fists
    frx = int(sw*0.18)
    fry = int(sw*0.14)
    fy = pad + int(sh*0.62)
    fo = int(frx*0.7)
    draw.ellipse([cx-fo-frx, fy-fry, cx-fo+frx, fy+fry], fill=orange_mid, outline=white, width=max(1,size//60))
    draw.ellipse([cx+fo-frx, fy-fry, cx+fo+frx, fy+fry], fill=orange_mid, outline=white, width=max(1,size//60))
    ll = int(fry*0.6)
    for fx in [cx-fo, cx+fo]:
        for off in [-int(frx*0.5), 0, int(frx*0.5)]:
            x = fx + off
            draw.line([(x, fy-ll//2), (x, fy+ll//2)], fill=orange_dark, width=max(1,size//80))
    return img

source = os.path.join(ASSETS, 'logo-original.png')
has = os.path.exists(source)
if has:
    img = Image.open(source).convert('RGBA')
    print('   Usando logomarca do usuário')
else:
    print('   Criando ícone padrão')
    img = None

for folder, size in SIZES.items():
    out_dir = os.path.join(RES, folder)
    os.makedirs(out_dir, exist_ok=True)
    r = img.resize((size,size), Image.LANCZOS) if img else draw_icon(size)
    r.save(os.path.join(out_dir, 'ic_launcher.png'), 'PNG')
    print(f'  ✅ {folder}/ic_launcher.png ({size}x{size})')
    r.save(os.path.join(out_dir, 'ic_launcher_foreground.png'), 'PNG')
    r.save(os.path.join(out_dir, 'ic_launcher_round.png'), 'PNG')

# Splash screens
splash_sizes = {
    'drawable-mdpi': (320,480), 'drawable-hdpi': (480,800),
    'drawable-xhdpi': (720,1280), 'drawable-xxhdpi': (960,1600),
    'drawable-xxxhdpi': (1280,1920),
}
for folder, (w,h) in splash_sizes.items():
    out_dir = os.path.join(RES, folder)
    os.makedirs(out_dir, exist_ok=True)
    canvas = Image.new('RGB', (w,h), '#0D47A1')
    draw = ImageDraw.Draw(canvas)
    for y in range(h):
        r = int(13 + (30-13)*y/h)
        g = int(71 + (136-71)*y/h)
        b = int(161 + (229-161)*y/h)
        draw.line([(0,y),(w,y)], fill=(r,g,b))
    ls = int(w*0.4)
    logo = img.resize((ls,ls), Image.LANCZOS) if img else draw_icon(ls)
    x = (w-ls)//2
    y = (h-ls)//2
    canvas.paste(logo, (x,y), logo)
    try:
        from PIL import ImageFont
        font = ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf', max(12,h//40))
    except:
        font = ImageFont.load_default()
    text = 'JA Gestão Academias'
    bbox = draw.textbbox((0,0), text, font=font)
    tw = bbox[2]-bbox[0]
    draw.text(((w-tw)//2, y+ls+int(h*0.03)), text, fill='white', font=font)
    canvas.save(os.path.join(out_dir, 'splash.png'), 'PNG')
    print(f'  ✅ {folder}/splash.png ({w}x{h})')

print('\n✅ Ícones gerados!')
"

# === 6. SYNC ===
echo ""
echo "⚙️  Sincronizando Capacitor..."
npx cap sync android

# === 7. BUILD ===
echo ""
echo "🔨 Build do APK Debug..."
cd android
./gradlew assembleDebug

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "  ✅ APK GERADO!"
echo "═══════════════════════════════════════════════════════════════"
echo ""
echo "📂 APK: android/app/build/outputs/apk/debug/app-debug.apk"
echo ""
echo "📲 Instalar no celular:"
echo "   adb install android/app/build/outputs/apk/debug/app-debug.apk"
echo ""
echo "💡 Se o ícone não aparecer, reinicie o celular ou launcher."
echo ""
