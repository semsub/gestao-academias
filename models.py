from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class Plan(db.Model):
    __tablename__ = "plans"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(80), unique=True, nullable=False)
    price = db.Column(db.Numeric(10, 2), default=0)
    member_limit = db.Column(db.Integer)  # NULL = ilimitado


class Academy(db.Model):
    __tablename__ = "academies"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    cnpj = db.Column(db.String(32))
    phone = db.Column(db.String(32))
    email = db.Column(db.String(200))
    plan_type = db.Column(db.String(80), default="Isento", nullable=False)
    member_limit = db.Column(db.Integer)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class User(db.Model):
    __tablename__ = "users"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    login = db.Column(db.String(120), unique=True, nullable=False)
    email = db.Column(db.String(200))
    password = db.Column(db.Text, nullable=False)
    role = db.Column(db.String(32), nullable=False)
    # super_admin | admin | instructor | student | student_social
    academy_id = db.Column(
        db.Integer, db.ForeignKey("academies.id", ondelete="CASCADE")
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Student(db.Model):
    __tablename__ = "students"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    cpf = db.Column(db.String(20))
    birth_date = db.Column(db.Date)
    phone = db.Column(db.String(32))
    email = db.Column(db.String(200))
    academy_id = db.Column(
        db.Integer,
        db.ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    is_social = db.Column(db.Boolean, default=False, nullable=False)
    status = db.Column(db.String(32), default="ativo", nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class SocialProfile(db.Model):
    __tablename__ = "social_profiles"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    family_income = db.Column(db.Numeric(10, 2))
    dependents = db.Column(db.Integer)
    approved = db.Column(db.Boolean, default=False, nullable=False)
    notes = db.Column(db.Text)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Instructor(db.Model):
    __tablename__ = "instructors"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(200), nullable=False)
    specialty = db.Column(db.String(120))
    phone = db.Column(db.String(32))
    academy_id = db.Column(
        db.Integer,
        db.ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Class(db.Model):
    __tablename__ = "classes"
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(120), nullable=False)
    modality = db.Column(db.String(80))
    schedule = db.Column(db.String(200))
    instructor_id = db.Column(
        db.Integer, db.ForeignKey("instructors.id", ondelete="SET NULL")
    )
    academy_id = db.Column(
        db.Integer,
        db.ForeignKey("academies.id", ondelete="CASCADE"),
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Enrollment(db.Model):
    __tablename__ = "enrollments"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    class_id = db.Column(
        db.Integer,
        db.ForeignKey("classes.id", ondelete="CASCADE"),
        nullable=False,
    )
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Attendance(db.Model):
    __tablename__ = "attendance"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    class_id = db.Column(db.Integer, db.ForeignKey("classes.id", ondelete="SET NULL"))
    date = db.Column(db.Date, nullable=False)
    present = db.Column(db.Boolean, default=True, nullable=False)


class Payment(db.Model):
    __tablename__ = "payments"
    id = db.Column(db.Integer, primary_key=True)
    student_id = db.Column(
        db.Integer,
        db.ForeignKey("students.id", ondelete="CASCADE"),
        nullable=False,
    )
    amount = db.Column(db.Numeric(10, 2), nullable=False)
    status = db.Column(db.String(32), default="pendente", nullable=False)
    # pendente | pago | atrasado
    due_date = db.Column(db.Date, nullable=False)
    payment_date = db.Column(db.Date)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class AuditLog(db.Model):
    __tablename__ = "audit_logs"
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id", ondelete="SET NULL"))
    action = db.Column(db.String(200), nullable=False)
    timestamp = db.Column(db.DateTime, default=datetime.utcnow)


# ----- Configuração de planos (constante) -----
PLANS = [
    {
        "name": "Isento",
        "price": 0.00,
        "member_limit": 10,
        "description": "Plano cortesia (até 10 membros)",
    },
    {
        "name": "Plano JA",
        "price": 85.00,
        "member_limit": 20,
        "description": "Ideal para iniciantes — até 20 membros",
    },
    {
        "name": "Plano Prata",
        "price": 195.00,
        "member_limit": 50,
        "description": "Para academias em crescimento — até 50 membros",
    },
    {
        "name": "Plano Ouro",
        "price": 255.00,
        "member_limit": None,
        "description": "Membros ilimitados, recursos completos",
    },
]


def get_plan(name: str):
    for p in PLANS:
        if p["name"] == name:
            return p
    return None
