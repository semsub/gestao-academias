# Sistema de Gestão de Academias de Artes Marciais

SaaS multi-tenant em **Python (Flask + SQLAlchemy)** para gestão de academias.
Banco PostgreSQL no **Neon**, deploy no **Render**.

**Desenvolvido por Júnior Araújo Sistemas** — (91) 98212-2175 — junior.araujo21@yahoo.com.br

---

## 🚀 Funcionalidades

- 🔐 Autenticação com sessão segura (bcrypt + Flask sessions)
- 🏢 Multi-tenant — cada academia tem seus dados isolados
- 👥 Tipos de usuário: Super Admin, Admin de Academia, Professor, Aluno, Aluno Social
- 💳 4 planos: **Isento (10), Plano JA R$85 (20), Plano Prata R$195 (50), Plano Ouro R$255 (∞)**
- 🚫 Bloqueio automático ao atingir limite do plano
- 🥋 Cadastro de alunos, professores, turmas e horários
- 💰 Financeiro com geração de mensalidades em lote, controle de inadimplência
- 🤝 Módulo social: solicitação e aprovação de bolsas
- 📊 Dashboard e relatórios

---

## 🔑 Credenciais Iniciais (Super Admin)

Criadas automaticamente no primeiro start:

- **Usuário:** `junior.araujo21@yahoo.com.br`
- **Senha:** `230808Deus#`

---

## 📦 Estrutura

```
python-app/
├── app.py              # Flask app + todas as rotas
├── models.py           # SQLAlchemy models (11 tabelas)
├── auth.py             # Helpers de autenticação
├── seed.py             # Seed de planos + super admin
├── requirements.txt    # Dependências Python
├── Procfile            # Comando para Render/Heroku
├── runtime.txt         # Versão do Python
├── render.yaml         # Configuração do Render (opcional)
├── .env.example        # Modelo de variáveis de ambiente
├── templates/          # Templates Jinja2 (HTML)
│   ├── base.html
│   ├── login.html
│   └── dashboard/
└── static/             # Logo e ícone (SVG)
```

---

## 💻 Rodar localmente

1. **Clone o repositório**
   ```bash
   git clone https://github.com/semsub/gestao-academias.git
   cd gestao-academias
   ```

2. **Crie um ambiente virtual**
   ```bash
   python -m venv venv
   source venv/bin/activate     # Linux/Mac
   venv\Scripts\activate        # Windows
   ```

3. **Instale as dependências**
   ```bash
   pip install -r requirements.txt
   ```
   > 🐉 **Kali Linux:** use `pip install --break-system-packages -r requirements.txt`

4. **Configure o `.env`**
   ```bash
   cp .env.example .env
   ```
   Edite e coloque sua connection string do Neon (ou use SQLite local).

5. **Rode**
   ```bash
   python app.py
   ```
   Acesse `http://localhost:5000`

## 🐉 Kali Linux — APK Nativo

Se você usa Kali Linux, temos scripts específicos que resolvem os erros de permissão:

```bash
cd python-app

# Setup completo (instala tudo automaticamente)
bash setup-kali.sh

# Gerar APK
bash build-apk.sh
```

Leia o guia completo: [`README-KALI.md`](README-KALI.md)

---

# 📘 PASSO A PASSO COMPLETO — Deploy no Neon + Render

## 🟢 PARTE 1 — NEON (Banco PostgreSQL)

### 1. Criar conta
1. Acesse **https://neon.tech**
2. Clique em **Sign Up** → use sua conta GitHub ou Google.

### 2. Criar projeto
1. Clique em **Create Project**.
2. Preencha:
   - **Project name:** `gestao-academias`
   - **PostgreSQL version:** 16
   - **Region:** **AWS / São Paulo (sa-east-1)** — menor latência para o Brasil
   - **Database name:** `neondb` (ou outro nome)
3. Clique em **Create Project**.

### 3. Copiar a Connection String
1. No painel do projeto, vá em **Connection Details**.
2. Selecione o tipo **Pooled connection** (importante para deploys serverless).
3. Marque **Show password** e copie a string. Ela parece:
   ```
   postgresql://neondb_owner:npg_xxxxxxx@ep-xxx-pooler.sa-east-1.aws.neon.tech/neondb?sslmode=require&channel_binding=require
   ```
4. Guarde essa string — você vai usar no Render.

> **Importante:** o Neon Free Tier hiberna o banco após 5min sem queries. A primeira request depois disso demora ~2s. Para produção real, use o plano pago (US$ 19/mês).

---

## 🟣 PARTE 2 — GITHUB

### 1. Subir o código
```bash
cd python-app
git init
git add .
git commit -m "Sistema de Gestão de Academias - versão Python"
git branch -M main
git remote add origin https://github.com/semsub/gestao-academias.git
git push -f origin main    # -f para sobrescrever os arquivos antigos do Next.js
```

> **Cuidado:** o `-f` (force push) sobrescreve tudo no repositório. Faça backup se precisar do código antigo.

---

## 🔴 PARTE 3 — RENDER (Deploy do app)

### 1. Criar conta
1. Acesse **https://render.com**
2. Clique em **Get Started** → conecte com GitHub.
3. Autorize o Render a acessar seus repositórios.

### 2. Criar Web Service
1. No dashboard, clique em **+ New** → **Web Service**.
2. Selecione o repositório `semsub/gestao-academias` → clique em **Connect**.
3. Preencha o formulário:

   | Campo | Valor |
   |-------|-------|
   | **Name** | `gestao-academias` |
   | **Region** | Oregon (USA) ou Frankfurt |
   | **Branch** | `main` |
   | **Root Directory** | (deixe vazio se Python está na raiz) |
   | **Runtime** | **Python 3** |
   | **Build Command** | `pip install -r requirements.txt` |
   | **Start Command** | `gunicorn app:app --workers 2 --timeout 60 --bind 0.0.0.0:$PORT` |
   | **Instance Type** | **Free** (testes) ou **Starter $7/mês** (produção sem hibernação) |

### 3. Adicionar Variáveis de Ambiente
Clique em **Advanced** → **Add Environment Variable**:

| Key | Value |
|-----|-------|
| `DATABASE_URL` | (cole a connection string do Neon que você copiou) |
| `SECRET_KEY` | (gere uma chave aleatória — instruções abaixo) |
| `PYTHON_VERSION` | `3.12.5` |

**Como gerar `SECRET_KEY`:**
```bash
# No seu terminal:
python -c "import secrets; print(secrets.token_hex(32))"
```
Vai gerar algo como: `a1b2c3d4e5f6...` (64 caracteres). Copie e cole no Render.

### 4. Criar o serviço
1. Clique em **Create Web Service**.
2. O Render vai:
   - Clonar seu repositório do GitHub
   - Rodar `pip install -r requirements.txt`
   - Iniciar o gunicorn
3. Acompanhe os logs. Quando aparecer:
   ```
   [INFO] Booting worker with pid: ...
   [INFO] Started server process
   ```
   Está pronto! ✅

### 5. Acessar
- A URL será algo como: `https://gestao-academias.onrender.com`
- O `seed.py` cria automaticamente o super admin no primeiro acesso.
- Faça login com:
  - **Usuário:** `junior.araujo21@yahoo.com.br`
  - **Senha:** `230808Deus#`

---

## 🔄 Atualizações futuras

Sempre que fizer `git push origin main`, o Render faz **deploy automático**.

```bash
# Faça suas alterações e:
git add .
git commit -m "Nova funcionalidade"
git push origin main
# Render detecta e faz deploy em 2-3 minutos
```

---

## 💡 Dicas e Troubleshooting

### Plano Free do Render
- O serviço hiberna após **15 minutos** sem acesso.
- Primeiro acesso depois disso demora ~30 segundos.
- Para produção, use **Starter ($7/mês)**.

### Plano Free do Neon
- Hiberna após 5 minutos sem queries.
- Storage de 0,5 GB (mais que suficiente para começar).
- Para produção: plano Launch (US$ 19/mês) ou Scale.

### Domínio próprio
No Render: **Settings → Custom Domain** → adicione `seudominio.com.br` e configure os DNS conforme as instruções.

### Erro "could not connect to database"
- Verifique se copiou a connection string com `?sslmode=require` no final.
- Confirme que o IP do Render está liberado no Neon (por padrão, todos IPs são liberados).

### Resetar senha do super admin
Se mudar a senha e esquecer, basta acessar o **Shell** do Render e rodar:
```python
python -c "
from app import create_app
from models import db, User
from auth import hash_password
from sqlalchemy import select
app = create_app()
with app.app_context():
    u = db.session.scalar(select(User).where(User.login == 'junior.araujo21@yahoo.com.br'))
    u.password = hash_password('NovaSenha123!')
    db.session.commit()
    print('Senha resetada')
"
```

### Backup do banco
No painel do Neon: **Branches** → criar branch (snapshot pontual) ou usar `pg_dump`:
```bash
pg_dump "postgresql://...connection-string..." > backup.sql
```

---

## 🛡️ Segurança

- ✅ Senhas com **bcrypt** (12 rounds)
- ✅ Sessões com cookie **HttpOnly + Secure** (em HTTPS)
- ✅ `SECRET_KEY` única em produção (gerada randomicamente)
- ✅ SQL parametrizado pelo SQLAlchemy (sem injection)
- ✅ Multi-tenant com filtro por `academy_id` em todas as queries
- ✅ Decoradores `@login_required` e `@role_required` em todas as rotas

---

## 📞 Suporte

**Júnior Araújo Sistemas**
📱 (91) 98212-2175
📧 junior.araujo21@yahoo.com.br
