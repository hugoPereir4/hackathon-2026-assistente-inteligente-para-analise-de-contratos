from uuid import uuid4

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager
from django.core.validators import MaxValueValidator
from django.db import models
from django.utils.translation import gettext_lazy as _


class Base(models.Model):
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        abstract = True


class CompanyManager(BaseUserManager):
    def _normalize(self, email):
        return self.normalize_email((email or "").strip().lower())

    def create_company(self, email, cnpj, password=None, **extra_fields):
        email = self._normalize(email)
        if not email:
            raise ValueError(_("Companies must have an email"))

        company = self.model(email=email, cnpj=cnpj, **extra_fields)

        company.set_password(password)
        company.save(using=self._db)

        return company


class Company(AbstractBaseUser, Base):
    password = models.CharField(_("password"), max_length=128, db_column="password_hash")
    last_login = None

    cnpj = models.CharField(max_length=14, unique=True)
    email = models.EmailField(max_length=255, unique=True)
    legal_name = models.CharField(max_length=255, null=True, blank=True)
    cnae_primary = models.CharField(max_length=255, null=True, blank=True)
    company_size = models.CharField(max_length=255, null=True, blank=True)
    founded_on = models.DateField(null=True, blank=True)
    address_city = models.CharField(max_length=255, null=True, blank=True)
    address_state = models.CharField(max_length=2, null=True, blank=True)
    confirmed = models.BooleanField(
        default=False, help_text="Usuário confirmou os dados vindos da API de CNPJ."
    )

    objects = CompanyManager()

    # O Django aceita um único USERNAME_FIELD; o login por CNPJ é feito
    # em core.classes.auth_backend.EmailOrCnpjBackend.
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["cnpj"]

    class Meta:
        db_table = "company"

    def get_short_name(self):
        return self.legal_name or self.email

    def __str__(self):
        return self.legal_name or self.email

    def save(self, *args, **kwargs):
        if self.email:
            self.email = self.email.strip().lower()
        super().save(*args, **kwargs)


class CompanyFact(Base):
    class Source(models.TextChoices):
        USER = "user", "User"
        CNPJ_API = "cnpj_api", "CNPJ API"
        AI = "ai", "AI"

    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name="facts")
    fact_key = models.CharField(max_length=100, help_text="Ex.: iso_9001, annual_revenue")
    label = models.CharField(max_length=255)
    value_json = models.JSONField()
    source = models.CharField(max_length=20, choices=Source.choices, default=Source.USER)
    confirmed = models.BooleanField(default=False)

    class Meta:
        db_table = "company_facts"
        constraints = [
            models.UniqueConstraint(
                fields=["company", "fact_key"], name="unique_company_fact_key"
            ),
        ]

    def __str__(self):
        return f"{self.company} · {self.fact_key}"


class Document(Base):
    class DocType(models.TextChoices):
        CONTRACT = "contract", "Contract"
        TENDER = "tender", "Tender"
        PROPOSAL = "proposal", "Proposal"

    class Status(models.TextChoices):
        UPLOADED = "uploaded", "Uploaded"
        PROCESSING = "processing", "Processing"
        READY = "ready", "Ready"
        FAILED = "failed", "Failed"

    class Outcome(models.TextChoices):
        GOOD_FIT = "good_fit", "Good fit"
        HIGH_RISK = "high_risk", "High risk"
        INCOMPATIBLE = "incompatible", "Incompatible"
        INSUFFICIENT_DATA = "insufficient_data", "Insufficient data"

    company = models.ForeignKey(Company, on_delete=models.CASCADE, related_name="documents")
    doc_type = models.CharField(max_length=20, choices=DocType.choices, null=True, blank=True)
    filename = models.CharField(max_length=255)
    file_path = models.CharField(max_length=500)
    text_content = models.TextField(
        null=True, blank=True, help_text="Texto extraído do PDF/DOCX."
    )
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.UPLOADED)
    score = models.PositiveSmallIntegerField(
        null=True,
        blank=True,
        validators=[MaxValueValidator(100)],
        help_text="0-100",
    )
    outcome = models.CharField(max_length=20, choices=Outcome.choices, null=True, blank=True)
    analysis_json = models.JSONField(
        null=True,
        blank=True,
        help_text="Resumo, prazos, valores, requisitos, riscos, findings, perguntas.",
    )
    chat_json = models.JSONField(default=list, blank=True, help_text="Histórico do Q&A.")

    class Meta:
        db_table = "documents"
        constraints = [
            models.CheckConstraint(
                condition=models.Q(score__lte=100), name="document_score_max_100"
            ),
        ]

    def __str__(self):
        return self.filename


class DocumentAnswerBatch(Base):
    class Status(models.TextChoices):
        PENDING = "pending", "Pending"
        CONFIRMED = "confirmed", "Confirmed"

    id = models.UUIDField(primary_key=True, default=uuid4, editable=False)
    document = models.ForeignKey(Document, on_delete=models.CASCADE, related_name="answer_batches")
    analysis_fingerprint = models.CharField(max_length=64)
    original_answers = models.JSONField()
    proposals = models.JSONField()
    fact_snapshots = models.JSONField()
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PENDING)
    approved_proposals = models.JSONField(default=list)
    overwrite_authorizations = models.JSONField(default=list)
    confirmed_at = models.DateTimeField(null=True, blank=True)
    reanalysis_status = models.CharField(
        max_length=20, choices=Document.Status.choices, null=True, blank=True,
    )
    reanalysis_error = models.TextField(blank=True, default="")

    class Meta:
        db_table = "document_answer_batches"
