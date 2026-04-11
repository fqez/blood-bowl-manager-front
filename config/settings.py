"""Application settings and configuration."""

import os
from typing import Optional

# API Configuration
API_BASE_URL = os.getenv("API_BASE_URL", "http://localhost:8000")
API_TIMEOUT = int(os.getenv("API_TIMEOUT", "30"))
API_RETRY_ATTEMPTS = int(os.getenv("API_RETRY_ATTEMPTS", "3"))

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ASSETS_DIR = os.path.join(BASE_DIR, "assets")
IMAGES_DIR = os.path.join(ASSETS_DIR, "images")

# Auth token storage (in-memory for now)
_auth_token: Optional[str] = None


def set_auth_token(token: str) -> None:
    """Store authentication token."""
    global _auth_token
    _auth_token = token


def get_auth_token() -> Optional[str]:
    """Retrieve stored authentication token."""
    return _auth_token


def clear_auth_token() -> None:
    """Clear stored authentication token."""
    global _auth_token
    _auth_token = None
