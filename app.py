"""
Sistema de Gestão de Academias de Artes Marciais
SaaS multi-tenant — Flask + SQLAlchemy + PostgreSQL (Neon)

Desenvolvido por Júnior Araújo Sistemas
(91) 98212-2175 | junior.araujo21@yahoo.com.br
"""
import os
from datetime import datetime, timedelta, date
from decimal import Decimal

from dotenv import load_dotenv
from flask import (
    Flask, render_template, request, redirect, url_for,
    flash, session, abort, jsonify,
)
from sqlalchemy import select, func, and_

from models import (
    db, Plan, Academy, User, Student, SocialProfile,
    Instructor, Class, Payment, PLANS, get_plan,
)
from auth import (
    hash_password, verify_password, login_user, logout_user,
    current_user, login_required, role_required,
)
from seed import run_seed

load_dotenv()


def create_app() -> Flask:
    app = Flask(__name__)

    # Database URL — Neon usa postgresql://, SQLAlchemy aceita direto
    db_url = os.environ.get("DATABASE_URL", "sqlite:///app.db")
    # Compatibilidade: alguns providers retornam postgres:// (legado)
    if db_url.startswith("postgres://"):
        db_url = db_url.replace("postgres://", "postgresql://", 1)
    app.config["SQLALCHEMY_DATABASE_URI"] = db_url
    app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False
    app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
        "pool_pre_ping": True,
        "pool_recycle": 300,
    }
    app.config["SECRET_KEY"] = os.environ.get(
        "SECRET_KEY", "troque-isso-em-producao-por-uma-chave-aleatoria-grande"
    )
    app.permanent_session_lifetime = timedelta(days=7)

    db.init_app(app)

    with app.app_context():
        db.create_all()
        run_seed()

    register_routes(app)
    return app


# =====================================================================
# ROTAS
# =====================================================================
def register_routes(app: Flask):

    # Health check
    @app.get("/api/health")
    def health():
        try:
            db.session.execute(db.text("SELECT 1"))
            return jsonify(ok=True)
        except Exception as e:
            return jsonify(ok=False, error=str(e)), 500

    # ---- Index ----
    @app.get("/")
    def index():
        if session.get("uid"):
            return redirect(url_for("dashboard"))
        return redirect(url_for("login_view"))

    # =================================================================
    # AUTENTICAÇÃO
    # =================================================================
    @app.get("/login")
    def login_view():
        if session.get("uid"):
            return redirect(url_for("dashboard"))
        return render_template("login.html", error=request.args.get("error"))

    @app.post("/login")
    def login_submit():
        login_input = (request.form.get("login") or "").strip()
        password = request.form.get("password") or ""
        if not login_input or not password:
            return redirect(url_for("login_view", error="Informe usuário e senha."))

        user = db.session.scalar(select(User).where(User.login == login_input))
        if not user or not verify_password(password, user.password):
            return redirect(
                url_for("login_view", error="Usuário ou senha inválidos.")
            )

        login_user(user)
        return redirect(url_for("dashboard"))

    @app.post("/logout")
    def logout():
        logout_user()
        return redirect(url_for("login_view"))

    # =================================================================
    # DASHBOARD
    # =================================================================
    @app.get("/dashboard")
    @login_required
    def dashboard():
        is_super = session.get("role") == "super_admin"
        academy_id = session.get("academy_id")

        if is_super:
            metrics = {
                "academies": db.session.scalar(select(func.count(Academy.id))) or 0,
                "students": db.session.scalar(select(func.count(Student.id))) or 0,
                "instructors": db.session.scalar(select(func.count(Instructor.id))) or 0,
                "classes": db.session.scalar(select(func.count(Class.id))) or 0,
            }
        else:
            metrics = {
                "students": db.session.scalar(
                    select(func.count(Student.id)).where(Student.academy_id == academy_id)
                ) or 0,
                "instructors": db.session.scalar(
                    select(func.count(Instructor.id)).where(Instructor.academy_id == academy_id)
                ) or 0,
                "classes": db.session.scalar(
                    select(func.count(Class.id)).where(Class.academy_id == academy_id)
                ) or 0,
                "pending": db.session.scalar(
                    select(func.count(Payment.id))
                    .join(Student, Student.id == Payment.student_id)
                    .where(and_(Student.academy_id == academy_id, Payment.status == "pendente"))
                ) or 0,
                "received": float(db.session.scalar(
                    select(func.coalesce(func.sum(Payment.amount), 0))
                    .join(Student, Student.id == Payment.student_id)
                    .where(and_(Student.academy_id == academy_id, Payment.status == "pago"))
                ) or 0),
            }

        return render_template("dashboard/home.html", is_super=is_super, metrics=metrics)

    # =================================================================
    # ACADEMIAS (super admin)
    # =================================================================
    @app.get("/academies")
    @role_required("super_admin")
    def academies_list():
        academies = db.session.scalars(select(Academy).order_by(Academy.id)).all()

        # Contagens por academia
        rows = db.session.execute(
            select(Student.academy_id, func.count(Student.id))
            .group_by(Student.academy_id)
        ).all()
        count_map = {a_id: c for a_id, c in rows}

        # Admins por academia
        admin_users = db.session.scalars(
            select(User).where(User.role == "admin")
        ).all()
        admin_map = {}
        for u in admin_users:
            admin_map.setdefault(u.academy_id, []).append(u)

        return render_template(
            "dashboard/academies.html",
            academies=academies,
            count_map=count_map,
            admin_map=admin_map,
            plans=PLANS,
        )

    @app.post("/academies")
    @role_required("super_admin")
    def academies_create():
        name = (request.form.get("name") or "").strip()
        if not name:
            flash("Nome obrigatório.", "error")
            return redirect(url_for("academies_list"))

        plan_name = request.form.get("plan_type") or "Plano JA"
        plan = get_plan(plan_name)
        if not plan:
            flash("Plano inválido.", "error")
            return redirect(url_for("academies_list"))

        ac = Academy(
            name=name,
            cnpj=request.form.get("cnpj") or None,
            phone=request.form.get("phone") or None,
            email=request.form.get("email") or None,
            plan_type=plan["name"],
            member_limit=plan["member_limit"],
        )
        db.session.add(ac)
        db.session.flush()

        # Admin opcional
        admin_login = (request.form.get("admin_login") or "").strip()
        admin_password = request.form.get("admin_password") or ""
        admin_name = (request.form.get("admin_name") or "").strip()
        if admin_login and admin_password and admin_name:
            exists = db.session.scalar(select(User).where(User.login == admin_login))
            if exists:
                db.session.rollback()
                flash("Login do admin já está em uso.", "error")
                return redirect(url_for("academies_list"))
            db.session.add(User(
                name=admin_name, login=admin_login, password=hash_password(admin_password),
                role="admin", academy_id=ac.id,
            ))

        db.session.commit()
        flash(f"Academia '{ac.name}' criada com sucesso.", "success")
        return redirect(url_for("academies_list"))

    @app.post("/academies/<int:academy_id>/delete")
    @role_required("super_admin")
    def academies_delete(academy_id):
        ac = db.session.get(Academy, academy_id)
        if ac:
            db.session.delete(ac)
            db.session.commit()
            flash("Academia excluída.", "success")
        return redirect(url_for("academies_list"))

    # =================================================================
    # ALUNOS
    # =================================================================
    @app.get("/students")
    @role_required("super_admin", "admin", "instructor")
    def students_list():
        is_super = session.get("role") == "super_admin"
        academy_id = session.get("academy_id")

        if is_super:
            students = db.session.scalars(select(Student).order_by(Student.id)).all()
            academies = db.session.scalars(select(Academy).order_by(Academy.name)).all()
            current_academy, used, limit, plan_name = None, 0, None, ""
        else:
            students = db.session.scalars(
                select(Student).where(Student.academy_id == academy_id).order_by(Student.id)
            ).all()
            current_academy = db.session.get(Academy, academy_id) if academy_id else None
            academies = []
            used = db.session.scalar(
                select(func.count(Student.id)).where(Student.academy_id == academy_id)
            ) or 0
            plan_name = current_academy.plan_type if current_academy else ""
            plan = get_plan(plan_name)
            limit = plan["member_limit"] if plan else (current_academy.member_limit if current_academy else None)

        academy_map = {a.id: a for a in db.session.scalars(select(Academy)).all()}
        is_full = limit is not None and used >= (limit or 0)

        return render_template(
            "dashboard/students.html",
            students=students, academies=academies, is_super=is_super,
            current_academy=current_academy, used=used, limit=limit,
            plan_name=plan_name, is_full=is_full, academy_map=academy_map,
        )

    @app.post("/students")
    @role_required("super_admin", "admin")
    def students_create():
        name = (request.form.get("name") or "").strip()
        if not name:
            flash("Nome obrigatório.", "error")
            return redirect(url_for("students_list"))

        is_super = session.get("role") == "super_admin"
        if is_super:
            academy_id = int(request.form.get("academy_id") or 0)
        else:
            academy_id = session.get("academy_id")

        if not academy_id:
            flash("Academia obrigatória.", "error")
            return redirect(url_for("students_list"))

        academy = db.session.get(Academy, academy_id)
        if not academy:
            flash("Academia não encontrada.", "error")
            return redirect(url_for("students_list"))

        # Verificação de limite
        plan = get_plan(academy.plan_type)
        limit = plan["member_limit"] if plan else academy.member_limit
        if limit is not None:
            count = db.session.scalar(
                select(func.count(Student.id)).where(Student.academy_id == academy_id)
            ) or 0
            if count >= limit:
                flash("Limite do plano atingido. Faça upgrade para cadastrar mais alunos.", "error")
                return redirect(url_for("students_list"))

        is_social = bool(request.form.get("is_social"))
        birth_date_str = request.form.get("birth_date")
        birth_date = None
        if birth_date_str:
            try:
                birth_date = datetime.strptime(birth_date_str, "%Y-%m-%d").date()
            except ValueError:
                pass

        s = Student(
            name=name,
            cpf=request.form.get("cpf") or None,
            birth_date=birth_date,
            phone=request.form.get("phone") or None,
            email=request.form.get("email") or None,
            academy_id=academy_id,
            is_social=is_social,
        )
        db.session.add(s)
        db.session.flush()

        if is_social:
            db.session.add(SocialProfile(student_id=s.id, approved=False))

        db.session.commit()
        flash(f"Aluno '{s.name}' cadastrado.", "success")
        return redirect(url_for("students_list"))

    @app.post("/students/<int:sid>/delete")
    @role_required("super_admin", "admin")
    def students_delete(sid):
        s = db.session.get(Student, sid)
        if s:
            if session.get("role") != "super_admin" and s.academy_id != session.get("academy_id"):
                abort(403)
            db.session.delete(s)
            db.session.commit()
            flash("Aluno excluído.", "success")
        return redirect(url_for("students_list"))

    # =================================================================
    # PROFESSORES
    # =================================================================
    @app.get("/instructors")
    @role_required("super_admin", "admin")
    def instructors_list():
        is_super = session.get("role") == "super_admin"
        if is_super:
            items = db.session.scalars(select(Instructor).order_by(Instructor.id)).all()
            academies = db.session.scalars(select(Academy).order_by(Academy.name)).all()
        else:
            items = db.session.scalars(
                select(Instructor).where(Instructor.academy_id == session.get("academy_id"))
                .order_by(Instructor.id)
            ).all()
            academies = []
        academy_map = {a.id: a for a in db.session.scalars(select(Academy)).all()}
        return render_template(
            "dashboard/instructors.html",
            instructors=items, academies=academies, is_super=is_super,
            academy_map=academy_map,
        )

    @app.post("/instructors")
    @role_required("super_admin", "admin")
    def instructors_create():
        name = (request.form.get("name") or "").strip()
        if not name:
            flash("Nome obrigatório.", "error")
            return redirect(url_for("instructors_list"))
        is_super = session.get("role") == "super_admin"
        academy_id = int(request.form.get("academy_id") or 0) if is_super else session.get("academy_id")
        if not academy_id:
            flash("Academia obrigatória.", "error")
            return redirect(url_for("instructors_list"))
        db.session.add(Instructor(
            name=name,
            specialty=request.form.get("specialty") or None,
            phone=request.form.get("phone") or None,
            academy_id=academy_id,
        ))
        db.session.commit()
        flash("Professor cadastrado.", "success")
        return redirect(url_for("instructors_list"))

    @app.post("/instructors/<int:iid>/delete")
    @role_required("super_admin", "admin")
    def instructors_delete(iid):
        i = db.session.get(Instructor, iid)
        if i:
            if session.get("role") != "super_admin" and i.academy_id != session.get("academy_id"):
                abort(403)
            db.session.delete(i)
            db.session.commit()
            flash("Professor excluído.", "success")
        return redirect(url_for("instructors_list"))

    # =================================================================
    # TURMAS
    # =================================================================
    @app.get("/classes")
    @role_required("super_admin", "admin", "instructor")
    def classes_list():
        is_super = session.get("role") == "super_admin"
        if is_super:
            items = db.session.scalars(select(Class).order_by(Class.id)).all()
            academies = db.session.scalars(select(Academy).order_by(Academy.name)).all()
            instructors = db.session.scalars(select(Instructor)).all()
        else:
            items = db.session.scalars(
                select(Class).where(Class.academy_id == session.get("academy_id"))
                .order_by(Class.id)
            ).all()
            academies = []
            instructors = db.session.scalars(
                select(Instructor).where(Instructor.academy_id == session.get("academy_id"))
            ).all()
        academy_map = {a.id: a for a in db.session.scalars(select(Academy)).all()}
        instructor_map = {i.id: i for i in db.session.scalars(select(Instructor)).all()}
        return render_template(
            "dashboard/classes.html",
            classes=items, academies=academies, instructors=instructors,
            is_super=is_super, academy_map=academy_map, instructor_map=instructor_map,
        )

    @app.post("/classes")
    @role_required("super_admin", "admin")
    def classes_create():
        name = (request.form.get("name") or "").strip()
        if not name:
            flash("Nome obrigatório.", "error")
            return redirect(url_for("classes_list"))
        is_super = session.get("role") == "super_admin"
        academy_id = int(request.form.get("academy_id") or 0) if is_super else session.get("academy_id")
        if not academy_id:
            flash("Academia obrigatória.", "error")
            return redirect(url_for("classes_list"))
        instructor_id_raw = request.form.get("instructor_id")
        instructor_id = int(instructor_id_raw) if instructor_id_raw else None
        db.session.add(Class(
            name=name,
            modality=request.form.get("modality") or None,
            schedule=request.form.get("schedule") or None,
            instructor_id=instructor_id,
            academy_id=academy_id,
        ))
        db.session.commit()
        flash("Turma cadastrada.", "success")
        return redirect(url_for("classes_list"))

    @app.post("/classes/<int:cid>/delete")
    @role_required("super_admin", "admin")
    def classes_delete(cid):
        c = db.session.get(Class, cid)
        if c:
            if session.get("role") != "super_admin" and c.academy_id != session.get("academy_id"):
                abort(403)
            db.session.delete(c)
            db.session.commit()
            flash("Turma excluída.", "success")
        return redirect(url_for("classes_list"))

    # =================================================================
    # FINANCEIRO
    # =================================================================
    @app.get("/financial")
    @role_required("super_admin", "admin")
    def financial_list():
        is_super = session.get("role") == "super_admin"

        q = (
            select(
                Payment.id, Payment.amount, Payment.status,
                Payment.due_date, Payment.payment_date,
                Student.id.label("student_id"), Student.name.label("student_name"),
                Student.is_social,
            )
            .join(Student, Student.id == Payment.student_id)
            .order_by(Payment.due_date.desc())
        )
        if not is_super:
            q = q.where(Student.academy_id == session.get("academy_id"))
        rows = db.session.execute(q).all()

        today = date.today()
        totals = {"paid": 0.0, "pending": 0.0, "overdue": 0.0}
        items = []
        for r in rows:
            amount = float(r.amount or 0)
            if r.status == "pago":
                totals["paid"] += amount
                disp_status = "pago"
            elif r.due_date and r.due_date < today:
                totals["overdue"] += amount
                disp_status = "atrasado"
            else:
                totals["pending"] += amount
                disp_status = "pendente"
            items.append({
                "id": r.id, "amount": amount, "status": r.status,
                "due_date": r.due_date, "payment_date": r.payment_date,
                "student_name": r.student_name, "is_social": r.is_social,
                "disp_status": disp_status,
            })

        # Alunos ativos (pagantes) para selecionar
        if is_super:
            students = db.session.scalars(
                select(Student).where(Student.is_social == False).order_by(Student.name)
            ).all()
        else:
            students = db.session.scalars(
                select(Student).where(and_(
                    Student.academy_id == session.get("academy_id"),
                    Student.is_social == False,
                )).order_by(Student.name)
            ).all()

        return render_template(
            "dashboard/financial.html",
            items=items, totals=totals, students=students, today=today.isoformat(),
        )

    @app.post("/financial")
    @role_required("super_admin", "admin")
    def financial_create():
        due_date_str = request.form.get("due_date")
        if not due_date_str:
            flash("Vencimento obrigatório.", "error")
            return redirect(url_for("financial_list"))
        try:
            due_date = datetime.strptime(due_date_str, "%Y-%m-%d").date()
        except ValueError:
            flash("Data inválida.", "error")
            return redirect(url_for("financial_list"))

        generate_all = bool(request.form.get("generate_all"))
        if generate_all:
            try:
                amount = Decimal(request.form.get("month_amount") or "0")
            except Exception:
                amount = Decimal("0")
            if amount <= 0:
                flash("Valor inválido.", "error")
                return redirect(url_for("financial_list"))
            q = select(Student).where(Student.is_social == False)
            if session.get("role") != "super_admin":
                q = q.where(Student.academy_id == session.get("academy_id"))
            students = db.session.scalars(q).all()
            if not students:
                flash("Sem alunos pagantes.", "error")
                return redirect(url_for("financial_list"))
            for s in students:
                db.session.add(Payment(student_id=s.id, amount=amount, status="pendente", due_date=due_date))
            db.session.commit()
            flash(f"{len(students)} mensalidades geradas.", "success")
            return redirect(url_for("financial_list"))

        try:
            student_id = int(request.form.get("student_id") or 0)
            amount = Decimal(request.form.get("amount") or "0")
        except Exception:
            student_id, amount = 0, Decimal("0")
        if not student_id or amount <= 0:
            flash("Aluno e valor obrigatórios.", "error")
            return redirect(url_for("financial_list"))

        s = db.session.get(Student, student_id)
        if not s:
            flash("Aluno não encontrado.", "error")
            return redirect(url_for("financial_list"))
        if session.get("role") != "super_admin" and s.academy_id != session.get("academy_id"):
            abort(403)

        db.session.add(Payment(student_id=student_id, amount=amount, status="pendente", due_date=due_date))
        db.session.commit()
        flash("Mensalidade gerada.", "success")
        return redirect(url_for("financial_list"))

    @app.post("/financial/<int:pid>/pay")
    @role_required("super_admin", "admin")
    def financial_pay(pid):
        p = db.session.get(Payment, pid)
        if not p:
            return redirect(url_for("financial_list"))
        if session.get("role") != "super_admin":
            s = db.session.get(Student, p.student_id)
            if not s or s.academy_id != session.get("academy_id"):
                abort(403)
        p.status = "pago"
        p.payment_date = date.today()
        db.session.commit()
        flash("Pagamento registrado.", "success")
        return redirect(url_for("financial_list"))

    # =================================================================
    # SOCIAL (bolsistas)
    # =================================================================
    @app.get("/social")
    @role_required("super_admin", "admin")
    def social_list():
        is_super = session.get("role") == "super_admin"
        q = (
            select(SocialProfile, Student)
            .join(Student, Student.id == SocialProfile.student_id)
        )
        if not is_super:
            q = q.where(Student.academy_id == session.get("academy_id"))
        rows = db.session.execute(q).all()
        items = [
            {
                "id": sp.id, "student_name": st.name,
                "family_income": float(sp.family_income) if sp.family_income else None,
                "dependents": sp.dependents, "approved": sp.approved,
                "notes": sp.notes,
            }
            for sp, st in rows
        ]
        return render_template("dashboard/social.html", items=items)

    @app.post("/social/<int:sid>")
    @role_required("super_admin", "admin")
    def social_update(sid):
        sp = db.session.get(SocialProfile, sid)
        if not sp:
            return redirect(url_for("social_list"))
        if session.get("role") != "super_admin":
            s = db.session.get(Student, sp.student_id)
            if not s or s.academy_id != session.get("academy_id"):
                abort(403)
        action = request.form.get("action")
        income = request.form.get("family_income")
        dep = request.form.get("dependents")
        notes = request.form.get("notes")
        if income:
            try: sp.family_income = Decimal(income)
            except Exception: pass
        if dep:
            try: sp.dependents = int(dep)
            except Exception: pass
        if notes is not None:
            sp.notes = notes or None
        if action == "approve":
            sp.approved = True
            flash("Bolsa aprovada.", "success")
        elif action == "reject":
            sp.approved = False
            flash("Bolsa revogada.", "success")
        else:
            flash("Dados atualizados.", "success")
        db.session.commit()
        return redirect(url_for("social_list"))

    # =================================================================
    # RELATÓRIOS
    # =================================================================
    @app.get("/reports")
    @role_required("super_admin", "admin")
    def reports_view():
        is_super = session.get("role") == "super_admin"
        academy_id = session.get("academy_id")

        def scoped(q, model_academy_attr):
            if is_super:
                return q
            return q.where(model_academy_attr == academy_id)

        student_total = db.session.scalar(scoped(select(func.count(Student.id)), Student.academy_id)) or 0
        social_total = db.session.scalar(scoped(
            select(func.count(Student.id)).where(Student.is_social == True),
            Student.academy_id,
        )) or 0
        class_total = db.session.scalar(scoped(select(func.count(Class.id)), Class.academy_id)) or 0
        instructor_total = db.session.scalar(scoped(select(func.count(Instructor.id)), Instructor.academy_id)) or 0

        # Pagamentos
        if is_super:
            pq = select(Payment.status, func.coalesce(func.sum(Payment.amount), 0)).group_by(Payment.status)
        else:
            pq = (
                select(Payment.status, func.coalesce(func.sum(Payment.amount), 0))
                .join(Student, Student.id == Payment.student_id)
                .where(Student.academy_id == academy_id)
                .group_by(Payment.status)
            )
        prows = db.session.execute(pq).all()
        total_paid = total_pending = 0.0
        for status, total in prows:
            if status == "pago":
                total_paid += float(total)
            else:
                total_pending += float(total)

        per_academy = []
        if is_super:
            ac_list = db.session.scalars(select(Academy).order_by(Academy.name)).all()
            counts = dict(db.session.execute(
                select(Student.academy_id, func.count(Student.id)).group_by(Student.academy_id)
            ).all())
            for a in ac_list:
                p = get_plan(a.plan_type)
                per_academy.append({
                    "name": a.name, "plan": a.plan_type,
                    "students": counts.get(a.id, 0),
                    "limit": p["member_limit"] if p else a.member_limit,
                })

        return render_template(
            "dashboard/reports.html",
            is_super=is_super,
            student_total=student_total, social_total=social_total,
            class_total=class_total, instructor_total=instructor_total,
            total_paid=total_paid, total_pending=total_pending,
            per_academy=per_academy,
        )


app = create_app()


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
