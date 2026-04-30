"""Seed inicial — cria planos e o super admin."""
from sqlalchemy import select

from auth import hash_password
from models import db, Plan, User, PLANS

SUPER_LOGIN = "junior.araujo21@yahoo.com.br"
SUPER_PASSWORD = "230808Deus#"


def run_seed():
    # Planos
    for p in PLANS:
        existing = db.session.scalar(select(Plan).where(Plan.name == p["name"]))
        if not existing:
            db.session.add(
                Plan(name=p["name"], price=p["price"], member_limit=p["member_limit"])
            )

    # Remove login antigo (caso exista)
    old = db.session.scalar(select(User).where(User.login == "junior.araujo21"))
    if old:
        db.session.delete(old)

    # Super admin
    existing = db.session.scalar(select(User).where(User.login == SUPER_LOGIN))
    if not existing:
        db.session.add(
            User(
                name="Júnior Araújo",
                login=SUPER_LOGIN,
                email=SUPER_LOGIN,
                password=hash_password(SUPER_PASSWORD),
                role="super_admin",
                academy_id=None,
            )
        )
    else:
        # Sincroniza senha sempre (garante acesso)
        existing.password = hash_password(SUPER_PASSWORD)
        existing.role = "super_admin"
        existing.email = SUPER_LOGIN
        existing.academy_id = None

    db.session.commit()
