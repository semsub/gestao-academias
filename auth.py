"""Helpers de autenticação e autorização."""
from functools import wraps

import bcrypt
from flask import session, redirect, url_for, request, flash, abort

from models import User, db


def hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode("utf-8"), bcrypt.gensalt()).decode("utf-8")


def verify_password(password: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(password.encode("utf-8"), hashed.encode("utf-8"))
    except Exception:
        return False


def login_user(user: User) -> None:
    session.clear()
    session["uid"] = user.id
    session["role"] = user.role
    session["name"] = user.name
    session["login"] = user.login
    session["academy_id"] = user.academy_id
    session.permanent = True


def logout_user() -> None:
    session.clear()


def current_user():
    uid = session.get("uid")
    if not uid:
        return None
    return db.session.get(User, uid)


def login_required(view_func):
    @wraps(view_func)
    def wrapper(*args, **kwargs):
        if not session.get("uid"):
            return redirect(url_for("login_view", next=request.path))
        return view_func(*args, **kwargs)

    return wrapper


def role_required(*roles):
    def decorator(view_func):
        @wraps(view_func)
        def wrapper(*args, **kwargs):
            if not session.get("uid"):
                return redirect(url_for("login_view", next=request.path))
            if session.get("role") not in roles:
                flash("Você não tem permissão para acessar essa página.", "error")
                return redirect(url_for("dashboard"))
            return view_func(*args, **kwargs)

        return wrapper

    return decorator
