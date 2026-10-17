from django.urls import include, path
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenBlacklistView, TokenRefreshView

from core.views import ViewCompanyMe, DocumentViewSet, ViewRegister, ViewTokenObtainPair

router = DefaultRouter()
router.register(r"documents", DocumentViewSet, basename="document")


urlpatterns = [
    path("", include(router.urls)),
    path("companies/me/", ViewCompanyMe.as_view(), name="company_me"),
    path("auth/register/", ViewRegister.as_view(), name="register"),
    path("auth/login/", ViewTokenObtainPair.as_view(), name="token_obtain_pair"),
    path("auth/refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("auth/logout/", TokenBlacklistView.as_view(), name="token_blacklist")
]
