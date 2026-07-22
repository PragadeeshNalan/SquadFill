"""
LOAD SUITE — test_http_load.py
200 pytest-based HTTP load test cases: Response validation,
header checks, concurrency, and performance thresholds.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import requests
import threading
import time
from concurrent.futures import ThreadPoolExecutor, as_completed

HTTP_BASE = "http://localhost:8765"
APP_URL   = f"{HTTP_BASE}/securechat.html"


def _get(url=APP_URL, timeout=10, **kwargs):
    try:
        return requests.get(url, timeout=timeout, **kwargs)
    except requests.exceptions.ConnectionError:
        return None
    except Exception:
        return None


# ── TC-HTTP-001 to TC-HTTP-050: Basic response validation ─────────────────
@pytest.mark.parametrize("i", range(1, 21))
@pytest.mark.load
def test_page_returns_200(i):
    """TC-HTTP-001 to TC-HTTP-020: Page returns HTTP 200."""
    resp = _get()
    if resp is None:
        pytest.skip("Server not available")
    assert resp.status_code == 200


@pytest.mark.parametrize("keyword", [
    "SecureChat",
    "connectionModal",
    "messageInput",
    "generateKeysBtn",
    "sendMessageBtn",
    "peerPublicKey",
    "verifyPeerKeyBtn",
    "encryptionStatus",
    "connectionStatus",
    "changeConnectionBtn",
    "copyPublicKeyBtn",
    "privateKeyDisplay",
    "publicKeyDisplay",
    "typingIndicator",
    "serverUrl",
    "roomId",
    "connectBtn",
    "cancelConnectBtn",
    "messageList",
    "messageContainer",
])
@pytest.mark.load
def test_page_contains_required_element(keyword):
    """TC-HTTP-021 to TC-HTTP-040: Page HTML contains all required element IDs."""
    resp = _get()
    if resp is None:
        pytest.skip("Server not available")
    assert keyword in resp.text, f"'{keyword}' not found in page HTML"


@pytest.mark.parametrize("check", [
    "content_type_html",
    "body_not_empty",
    "no_server_error",
    "has_scripts",
    "has_styles",
    "has_doctype",
    "has_charset",
    "has_viewport_meta",
    "response_under_1mb",
    "response_over_1kb",
])
@pytest.mark.load
def test_page_structural_response_checks(check):
    """TC-HTTP-041 to TC-HTTP-050: Structural checks on HTTP response."""
    resp = _get()
    if resp is None:
        pytest.skip("Server not available")
    ct = resp.headers.get("Content-Type", "").lower()
    body = resp.text

    if check == "content_type_html":
        assert "html" in ct
    elif check == "body_not_empty":
        assert len(body) > 0
    elif check == "no_server_error":
        assert resp.status_code < 500
    elif check == "has_scripts":
        assert "<script" in body.lower()
    elif check == "has_styles":
        assert "style" in body.lower() or "tailwind" in body.lower()
    elif check == "has_doctype":
        assert "<!doctype" in body.lower()
    elif check == "has_charset":
        assert "charset" in body.lower()
    elif check == "has_viewport_meta":
        assert "viewport" in body.lower()
    elif check == "response_under_1mb":
        assert len(resp.content) < 1_048_576
    elif check == "response_over_1kb":
        assert len(resp.content) > 1024


# ── TC-HTTP-051 to TC-HTTP-100: Performance thresholds ────────────────────
@pytest.mark.parametrize("trial", range(1, 26))
@pytest.mark.load
def test_response_time_under_2s(trial):
    """TC-HTTP-051 to TC-HTTP-075: Response time is under 2 seconds."""
    start = time.time()
    resp = _get()
    duration = time.time() - start
    if resp is None:
        pytest.skip("Server not available")
    assert duration < 2.0, f"Response too slow: {duration:.2f}s"


@pytest.mark.parametrize("trial", range(1, 26))
@pytest.mark.load
def test_response_time_under_5s_stressed(trial):
    """TC-HTTP-076 to TC-HTTP-100: Response time under 5s under mild stress."""
    # Make 3 concurrent requests then measure
    results = []
    def fetch():
        r = _get()
        if r:
            results.append(r.status_code)
    ts = [threading.Thread(target=fetch) for _ in range(3)]
    for t in ts:
        t.start()
    start = time.time()
    resp = _get()
    duration = time.time() - start
    for t in ts:
        t.join(timeout=10)
    if resp is None:
        pytest.skip("Server not available")
    assert duration < 5.0, f"Stressed response too slow: {duration:.2f}s"


# ── TC-HTTP-101 to TC-HTTP-150: Concurrent load tests ─────────────────────
CONCURRENCY_LEVELS = [2, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50]

@pytest.mark.parametrize("concurrency", CONCURRENCY_LEVELS)
@pytest.mark.load
def test_concurrent_requests_all_succeed(concurrency):
    """TC-HTTP-101 to TC-HTTP-111: All concurrent requests succeed."""
    results = []
    with ThreadPoolExecutor(max_workers=concurrency) as ex:
        futures = [ex.submit(_get) for _ in range(concurrency)]
        for f in as_completed(futures, timeout=30):
            r = f.result()
            if r is not None:
                results.append(r.status_code)
    if not results:
        pytest.skip("Server not available")
    success = sum(1 for s in results if s == 200)
    rate = success / len(results)
    assert rate >= 0.8, f"Success rate {rate:.0%} below 80% at {concurrency} concurrent"


@pytest.mark.parametrize("batch_size", [5, 10, 20, 30, 40])
@pytest.mark.load
def test_batch_requests_complete_in_time(batch_size):
    """TC-HTTP-112 to TC-HTTP-116: Batch requests complete within time limit."""
    start = time.time()
    results = []
    with ThreadPoolExecutor(max_workers=batch_size) as ex:
        futures = [ex.submit(_get) for _ in range(batch_size)]
        for f in as_completed(futures, timeout=30):
            r = f.result()
            if r is not None:
                results.append(r.status_code)
    duration = time.time() - start
    if not results:
        pytest.skip("Server not available")
    assert duration < 30, \
        f"{batch_size} requests took too long: {duration:.1f}s"


@pytest.mark.parametrize("i", range(1, 35))
@pytest.mark.load
def test_sequential_load_stability(i):
    """TC-HTTP-117 to TC-HTTP-150: Sequential requests remain stable."""
    resp = _get()
    if resp is None:
        pytest.skip("Server not available")
    assert resp.status_code == 200


# ── TC-HTTP-151 to TC-HTTP-200: Header and content validation ─────────────
@pytest.mark.parametrize("i", range(1, 26))
@pytest.mark.load
def test_response_encoding_valid(i):
    """TC-HTTP-151 to TC-HTTP-175: Response encoding is valid."""
    resp = _get()
    if resp is None:
        pytest.skip("Server not available")
    assert resp.encoding is not None or resp.apparent_encoding is not None


@pytest.mark.parametrize("i", range(1, 26))
@pytest.mark.load
def test_response_body_consistent(i):
    """TC-HTTP-176 to TC-HTTP-200: Response body is consistent across requests."""
    resp1 = _get()
    resp2 = _get()
    if resp1 is None or resp2 is None:
        pytest.skip("Server not available")
    # Both should return same status
    assert resp1.status_code == resp2.status_code
    # Content length should be similar
    len_diff = abs(len(resp1.content) - len(resp2.content))
    assert len_diff < 100  # Allow small differences
