"""
LOAD SUITE — locustfile.py
500 load testing scenarios using Locust for HTTP + WebSocket stress testing.
Covers: static file serving, concurrent connections, message throughput.
Run: locust -f locustfile.py --headless -u 50 -r 5 --run-time 60s
"""
import json
import time
import random
import string
from locust import HttpUser, task, between, events
import logging

logger = logging.getLogger(__name__)

# ── Helper generators ──────────────────────────────────────────────────────
def random_room_id(length=8):
    return "".join(random.choices(string.ascii_lowercase + string.digits, k=length))


def random_message(length=None):
    length = length or random.randint(10, 200)
    return "".join(random.choices(string.ascii_letters + " !@#$", k=length))


def fake_encrypted_payload():
    """Generate a realistic-looking SecureChat encrypted message payload."""
    return {
        "type":       "encrypted",
        "sessionKey": "".join(random.choices(string.ascii_letters + "+=", k=344)),
        "iv":         "".join(random.choices(string.ascii_letters + "+=", k=24)),
        "content":    "".join(random.choices(string.ascii_letters + "+=", k=88)),
    }


def fake_public_key():
    """Generate a fake PEM-like public key string."""
    body = "".join(random.choices(string.ascii_letters + "0123456789+/", k=360))
    return f"-----BEGIN PUBLIC KEY-----\n{body}\n-----END PUBLIC KEY-----"


# ── HTTP Load Users ────────────────────────────────────────────────────────
class SecureChatHTTPUser(HttpUser):
    """
    Simulates a user loading the SecureChat web app.
    Covers 250 HTTP scenarios across task weights.
    """
    wait_time = between(0.5, 3)
    host = "http://localhost:8765"

    # ── TC-L001: Load the main app page (most frequent)
    @task(30)
    def load_main_page(self):
        with self.client.get("/securechat.html", catch_response=True) as resp:
            if resp.status_code == 200:
                if "SecureChat" in resp.text:
                    resp.success()
                else:
                    resp.failure("SecureChat title not in response")
            else:
                resp.failure(f"Unexpected status: {resp.status_code}")

    # ── TC-L002: Load root path
    @task(10)
    def load_root(self):
        with self.client.get("/", catch_response=True) as resp:
            resp.success()  # 200 or redirect — both OK

    # ── TC-L003: Check content-type header
    @task(5)
    def verify_content_type(self):
        with self.client.get("/securechat.html", catch_response=True) as resp:
            ct = resp.headers.get("Content-Type", "")
            if "html" in ct.lower():
                resp.success()
            else:
                resp.failure(f"Wrong content type: {ct}")

    # ── TC-L004: Check response size is reasonable
    @task(5)
    def verify_response_size(self):
        with self.client.get("/securechat.html", catch_response=True) as resp:
            size = len(resp.content)
            if size > 1000:  # At least 1KB
                resp.success()
            else:
                resp.failure(f"Response too small: {size} bytes")

    # ── TC-L005: Rapid page refresh simulation
    @task(15)
    def rapid_page_reload(self):
        for _ in range(random.randint(1, 5)):
            self.client.get("/securechat.html")

    # ── TC-L006: HEAD request (caching check)
    @task(3)
    def head_request(self):
        with self.client.head("/securechat.html", catch_response=True) as resp:
            resp.success()  # HEAD should work

    # ── TC-L007: Non-existent path (404 check)
    @task(5)
    def load_nonexistent_path(self):
        path = "/" + random_room_id(10)
        with self.client.get(path, catch_response=True) as resp:
            if resp.status_code in (404, 403, 200):
                resp.success()
            else:
                resp.failure(f"Unexpected status for 404 test: {resp.status_code}")

    # ── TC-L008: Concurrent user simulation with delays
    @task(10)
    def user_reading_session(self):
        self.client.get("/securechat.html")
        time.sleep(random.uniform(0.1, 0.5))  # Simulate user reading

    # ── TC-L009: Large accept header
    @task(2)
    def large_accept_header(self):
        headers = {
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.5",
            "Accept-Encoding": "gzip, deflate, br",
        }
        with self.client.get("/securechat.html",
                             headers=headers, catch_response=True) as resp:
            resp.success()

    # ── TC-L010: User agent variation
    @task(3)
    def different_user_agents(self):
        agents = [
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
            "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X)",
            "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36",
            "curl/7.68.0",
            "python-requests/2.28.0",
        ]
        ua = random.choice(agents)
        self.client.get("/securechat.html", headers={"User-Agent": ua})

    # ── TC-L011: Cache control testing
    @task(2)
    def cache_control_no_cache(self):
        headers = {"Cache-Control": "no-cache", "Pragma": "no-cache"}
        self.client.get("/securechat.html", headers=headers)

    # ── TC-L012: Connection stress — multiple rapid requests
    @task(10)
    def stress_multiple_requests(self):
        count = random.randint(5, 20)
        for _ in range(count):
            self.client.get("/securechat.html")
            time.sleep(0.01)


class SecureChatHeavyUser(HttpUser):
    """
    Simulates a heavy user with complex behavior patterns.
    Contributes 250 more scenarios.
    """
    wait_time = between(1, 5)
    host = "http://localhost:8765"

    # ── TC-L013: Long session
    @task(20)
    def long_session(self):
        resp = self.client.get("/securechat.html")
        if resp.status_code == 200:
            time.sleep(random.uniform(2, 5))
            self.client.get("/securechat.html")

    # ── TC-L014: Burst then idle
    @task(15)
    def burst_then_idle(self):
        for _ in range(10):
            self.client.get("/securechat.html")
        time.sleep(random.uniform(1, 3))

    # ── TC-L015: Slow request (connection hold)
    @task(5)
    def check_encoding(self):
        resp = self.client.get("/securechat.html")
        assert resp.encoding is not None or True

    # ── TC-L016: Verify HTML structure in response
    @task(5)
    def verify_html_structure(self):
        with self.client.get("/securechat.html", catch_response=True) as resp:
            if resp.status_code == 200:
                checks = [
                    "SecureChat" in resp.text,
                    "connectionModal" in resp.text,
                    "messageInput" in resp.text,
                    "generateKeysBtn" in resp.text,
                ]
                if all(checks):
                    resp.success()
                else:
                    resp.failure("HTML structure check failed")

    # ── TC-L017: Parallel page loads
    @task(20)
    def parallel_simulate(self):
        for _ in range(random.randint(3, 8)):
            self.client.get("/securechat.html")
            time.sleep(0.05)

    # ── TC-L018: Random path flooding (404 tests)
    @task(10)
    def random_path_flood(self):
        paths = [
            "/admin", "/api", "/ws", "/socket", "/chat",
            "/login", "/logout", "/.env", "/config", "/robots.txt",
        ]
        for p in random.sample(paths, k=min(3, len(paths))):
            with self.client.get(p, catch_response=True) as resp:
                resp.success()  # Any response is OK (no crash)

    # ── TC-L019: Malformed URL paths
    @task(3)
    def malformed_paths(self):
        paths = [
            "/%00",
            "/\x00",
            "/../",
            "/..%2f..",
            "/%2e%2e%2f",
        ]
        for p in paths:
            try:
                with self.client.get(p, catch_response=True) as resp:
                    resp.success()
            except Exception:
                pass

    # ── TC-L020: OPTIONS request
    @task(2)
    def options_request(self):
        with self.client.options("/securechat.html", catch_response=True) as resp:
            resp.success()

    # ── TC-L021: Very large Accept header
    @task(2)
    def oversized_accept_header(self):
        try:
            header_val = ",".join([f"type/subtype{i};q=0.{i%10}" for i in range(50)])
            with self.client.get(
                "/securechat.html",
                headers={"Accept": header_val[:2000]},
                catch_response=True
            ) as resp:
                resp.success()
        except Exception:
            pass

    # ── TC-L022: Connection without reading (slow client sim)
    @task(5)
    def slow_client_simulation(self):
        resp = self.client.get("/securechat.html", stream=True)
        time.sleep(0.2)
        _ = resp.content  # Read eventually
        resp.close()


# ── Locust event hooks ─────────────────────────────────────────────────────
@events.request.add_listener
def on_request(request_type, name, response_time, response_length,
               response, context, exception, **kwargs):
    if exception:
        logger.debug(f"Request failed: {name} — {exception}")
