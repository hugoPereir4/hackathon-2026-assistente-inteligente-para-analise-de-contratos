from rest_framework import serializers

from core.models import DocumentAnswerBatch


class AnswerInputSerializer(serializers.Serializer):
    pergunta_id = serializers.CharField(max_length=255)
    texto = serializers.CharField(max_length=10000)


class AnswerPreviewSerializer(serializers.Serializer):
    respostas = AnswerInputSerializer(many=True, allow_empty=False, max_length=100)


class AnswerConfirmationSerializer(serializers.Serializer):
    propostas_aprovadas = serializers.ListField(
        child=serializers.CharField(max_length=255), allow_empty=False, max_length=100,
    )
    autorizar_substituicao = serializers.ListField(
        child=serializers.CharField(max_length=255), required=False, default=list, max_length=100,
    )


class DocumentAnswerBatchSerializer(serializers.ModelSerializer):
    class Meta:
        model = DocumentAnswerBatch
        fields = (
            "id", "document", "analysis_fingerprint", "original_answers", "proposals",
            "status", "approved_proposals", "overwrite_authorizations", "created_at",
            "confirmed_at", "reanalysis_status", "reanalysis_error",
        )
        read_only_fields = fields
