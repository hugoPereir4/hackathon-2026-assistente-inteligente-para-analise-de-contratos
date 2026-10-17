from django.conf import settings
from django.conf.urls.static import static
from django.urls import include, path

urlpatterns = [
    path("api/v1/", include(("config.urls_v1", "v1"), namespace="v1")),
]