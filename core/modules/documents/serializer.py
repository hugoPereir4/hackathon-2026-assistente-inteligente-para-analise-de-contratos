from pathlib import PurePosixPath

from django.conf import settings
from rest_framework import serializers

from core.models import Document
from core.modules.documents.service.document_service import create_document


class DocumentAnalysisRequestSerializer(serializers.Serializer):
    retry_failed = serializers.BooleanField(default=False)


class DocumentSerializer(serializers.ModelSerializer):
    file = serializers.FileField(write_only=True)
    cobertura = serializers.SerializerMethodField()

    class Meta:
        model = Document
        fields = (
            "id", "doc_type", "filename", "status", "created_at", "file",
            "score", "outcome", "cobertura",
        )
        read_only_fields = (
            "id", "filename", "status", "created_at", "score", "outcome", "cobertura",
        )

    def get_cobertura(self, instance):
        analysis = instance.analysis_json or {}
        return analysis.get("aderencia", {}).get("cobertura")

    def validate_file(self, uploaded_file):
        filename = uploaded_file.name.replace("\\", "/")
        if PurePosixPath(filename).suffix.lower() != ".pdf":
            raise serializers.ValidationError("Envie um arquivo PDF.")

        max_size = settings.MAX_DOCUMENT_UPLOAD_SIZE
        if uploaded_file.size > max_size:
            limit_mb = max_size // (1024 * 1024)
            raise serializers.ValidationError(
                f"O arquivo excede o limite de {limit_mb} MB."
            )

        signature = uploaded_file.read(5)
        uploaded_file.seek(0)
        if signature != b"%PDF-":
            raise serializers.ValidationError("O conteúdo enviado não é um PDF válido.")

        return uploaded_file

    def create(self, validated_data):
        uploaded_file = validated_data.pop("file")
        company = validated_data.pop("company")
        return create_document(
            company=company,
            uploaded_file=uploaded_file,
            doc_type=validated_data.get("doc_type"),
        )


class DocumentDetailSerializer(DocumentSerializer):
    analysis_desatualizada = serializers.SerializerMethodField()

    def get_analysis_desatualizada(self, instance):
        from core.modules.documents.service.answer_service import analysis_is_stale

        return analysis_is_stale(instance)

    class Meta(DocumentSerializer.Meta):
        fields = DocumentSerializer.Meta.fields + ("analysis_json", "analysis_desatualizada")
        read_only_fields = DocumentSerializer.Meta.read_only_fields + ("analysis_json", "analysis_desatualizada")
