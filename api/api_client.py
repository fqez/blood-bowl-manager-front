"""API client for Blood Bowl Manager backend."""

import logging
from typing import Any, Dict, Optional
from urllib.parse import urljoin

import requests
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry

from config.settings import (
    API_BASE_URL,
    API_RETRY_ATTEMPTS,
    API_TIMEOUT,
    get_auth_token,
)

logger = logging.getLogger(__name__)


def _create_session() -> requests.Session:
    """Create a requests session with retry logic."""
    session = requests.Session()

    retry_strategy = Retry(
        total=API_RETRY_ATTEMPTS,
        backoff_factor=0.5,
        status_forcelist=[500, 502, 503, 504],
    )
    adapter = HTTPAdapter(max_retries=retry_strategy)
    session.mount("http://", adapter)
    session.mount("https://", adapter)

    return session


def _get_headers() -> Dict[str, str]:
    """Get request headers including auth token if available."""
    headers = {"Content-Type": "application/json"}
    token = get_auth_token()
    if token:
        headers["Authorization"] = f"Bearer {token}"
    return headers


def fetch_data(endpoint: str) -> Optional[Dict[str, Any]]:
    """Fetch data from an API endpoint.

    Args:
        endpoint: Full URL or path relative to API_BASE_URL

    Returns:
        Response JSON data or None if request failed
    """
    # Handle both full URLs and relative paths
    if endpoint.startswith(("http://", "https://")):
        url = endpoint
    else:
        url = urljoin(API_BASE_URL, endpoint.lstrip("/"))

    session = _create_session()

    try:
        response = session.get(
            url,
            headers=_get_headers(),
            timeout=API_TIMEOUT,
        )
        response.raise_for_status()
        return response.json()
    except requests.Timeout:
        logger.error(f"Request to {url} timed out after {API_TIMEOUT}s")
        return None
    except requests.RequestException as e:
        logger.error(f"Error fetching data from {url}: {e}")
        return None


def post_data(endpoint: str, data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    """Post data to an API endpoint.

    Args:
        endpoint: Full URL or path relative to API_BASE_URL
        data: JSON data to send

    Returns:
        Response JSON data or None if request failed
    """
    if endpoint.startswith(("http://", "https://")):
        url = endpoint
    else:
        url = urljoin(API_BASE_URL, endpoint.lstrip("/"))

    session = _create_session()

    try:
        response = session.post(
            url,
            json=data,
            headers=_get_headers(),
            timeout=API_TIMEOUT,
        )
        response.raise_for_status()
        return response.json()
    except requests.RequestException as e:
        logger.error(f"Error posting data to {url}: {e}")
        return None
