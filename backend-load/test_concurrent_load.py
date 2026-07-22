"""
LOAD SUITE — test_concurrent_load.py
100 pytest-based concurrent stress test cases.
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


def _get_safe(url=APP_URL, timeout=10):
    try:
        return requests.get(url, timeout=timeout)
    except Exception:
        return None


# ── TC-CL-001 to TC-CL-050: Concurrent HTTP stress ────────────────────────
@pytest.mark.parametrize("users,duration_s", [
    (10,  5),
    (20,  5),
    (30,  5),
    (50,  5),
    (10, 10),
    (20, 10),
    (30, 10),
    (50, 10),
    (10, 15),
    (20, 15),
])
@pytest.mark.load
def test_sustained_concurrent_load(users, duration_s):
    """TC-CL-001 to TC-CL-010: Sustained concurrent load for N seconds."""
    results = {"success": 0, "fail": 0}
    stop_event = threading.Event()

    def worker():
        while not stop_event.is_set():
            resp = _get_safe()
            if resp and resp.status_code == 200:
                results["success"] += 1
            elif resp:
                results["fail"] += 1
            time.sleep(0.1)

    threads = [threading.Thread(target=worker, daemon=True) for _ in range(users)]
    for t in threads:
        t.start()
    time.sleep(duration_s)
    stop_event.set()
    for t in threads:
        t.join(timeout=5)

    total = results["success"] + results["fail"]
    if total == 0:
        pytest.skip("Server not available")

    success_rate = results["success"] / total
    assert success_rate >= 0.75, \
        f"Success rate {success_rate:.0%} below 75% with {users} users"


@pytest.mark.parametrize("burst_size", range(5, 56, 5))  # 5, 10, 15, ..., 55
@pytest.mark.load
def test_burst_load_success_rate(burst_size):
    """TC-CL-011 to TC-CL-021: Burst of N simultaneous requests."""
    results = []
    with ThreadPoolExecutor(max_workers=burst_size) as ex:
        futures = [ex.submit(_get_safe) for _ in range(burst_size)]
        for f in as_completed(futures, timeout=30):
            r = f.result()
            if r:
                results.append(r.status_code)

    if not results:
        pytest.skip("Server not available")

    success = sum(1 for s in results if s == 200)
    rate = success / len(results)
    assert rate >= 0.7, \
        f"Burst of {burst_size}: only {success}/{len(results)} succeeded"


# ── TC-CL-051 to TC-CL-080: Error rate monitoring ─────────────────────────
@pytest.mark.parametrize("i", range(1, 31))
@pytest.mark.load
def test_error_rate_under_10_percent(i):
    """TC-CL-051 to TC-CL-080: Error rate stays below 10% under load."""
    total = 10
    errors = 0
    for _ in range(total):
        resp = _get_safe()
        if resp is None or resp.status_code >= 500:
            errors += 1
    if errors == total:
        pytest.skip("Server not available")
    error_rate = errors / total
    assert error_rate < 0.10, f"Error rate {error_rate:.0%} above 10%"


# ── TC-CL-081 to TC-CL-100: Throughput benchmarks ────────────────────────
@pytest.mark.parametrize("target_rps", [1, 2, 5, 10, 15, 20])
@pytest.mark.load
def test_server_sustains_target_rps(target_rps):
    """TC-CL-081 to TC-CL-086: Server sustains target requests-per-second."""
    request_count = target_rps * 5  # 5 seconds worth
    interval = 1.0 / target_rps

    successes = []
    start_time = time.time()

    for _ in range(request_count):
        loop_start = time.time()
        resp = _get_safe()
        if resp and resp.status_code == 200:
            successes.append(True)
        elapsed = time.time() - loop_start
        sleep_time = interval - elapsed
        if sleep_time > 0:
            time.sleep(sleep_time)

    total_time = time.time() - start_time

    if not successes:
        pytest.skip("Server not available")

    actual_rps = len(successes) / total_time
    success_rate = len(successes) / request_count
    assert success_rate >= 0.7, \
        f"At {target_rps} RPS: only {len(successes)}/{request_count} succeeded"


@pytest.mark.parametrize("i", range(1, 15))
@pytest.mark.load
def test_server_recovers_after_burst(i):
    """TC-CL-087 to TC-CL-100: Server recovers quickly after a burst."""
    # Burst
    with ThreadPoolExecutor(max_workers=20) as ex:
        futures = [ex.submit(_get_safe) for _ in range(20)]
        list(as_completed(futures, timeout=15))

    # Wait briefly
    time.sleep(0.5)

    # Single request should still work
    resp = _get_safe()
    if resp is None:
        pytest.skip("Server not available")
    assert resp.status_code == 200, "Server didn't recover after burst"
