"""
Shared conftest for all Selenium and Mobile test suites.
Starts a local HTTP server serving securechat.html.
"""
import os
import time
import threading
import http.server
import socketserver
import pytest
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
from webdriver_manager.chrome import ChromeDriverManager

# ── Paths ──────────────────────────────────────────────────────────────────
ROOT_DIR  = os.path.dirname(os.path.abspath(__file__))
APP_DIR   = os.path.join(ROOT_DIR, "app")
APP_FILE  = os.path.join(APP_DIR, "securechat.html")
HTTP_PORT = 8765
WS_PORT   = 8766
APP_URL   = f"http://localhost:{HTTP_PORT}/securechat.html"


class _QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


# ── Session-scoped HTTP server ─────────────────────────────────────────────
_server_started = False
_httpd = None

@pytest.fixture(scope="session", autouse=True)
def http_server():
    global _httpd, _server_started
    orig = os.getcwd()
    os.chdir(APP_DIR)
    socketserver.TCPServer.allow_reuse_address = True
    _httpd = socketserver.TCPServer(("", HTTP_PORT), _QuietHandler)
    t = threading.Thread(target=_httpd.serve_forever, daemon=True)
    t.start()
    _server_started = True
    time.sleep(0.5)
    yield APP_URL
    _httpd.shutdown()
    os.chdir(orig)


# ── Chrome desktop driver ──────────────────────────────────────────────────
def _make_chrome_options(headless=True, extra_args=None):
    opts = Options()
    if headless:
        opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--window-size=1920,1080")
    opts.add_argument("--disable-extensions")
    opts.add_argument("--disable-popup-blocking")
    if extra_args:
        for a in extra_args:
            opts.add_argument(a)
    return opts


@pytest.fixture(scope="function")
def driver(http_server):
    opts = _make_chrome_options()
    svc  = Service(ChromeDriverManager().install())
    drv  = webdriver.Chrome(service=svc, options=opts)
    drv.implicitly_wait(8)
    drv.get(http_server)
    WebDriverWait(drv, 20).until(
        lambda d: d.execute_script("return document.readyState") == "complete"
    )
    yield drv
    drv.quit()


@pytest.fixture(scope="function")
def driver_no_modal(driver):
    """Desktop driver with connection modal dismissed."""
    driver.execute_script(
        "document.getElementById('connectionModal').classList.add('hidden');"
    )
    time.sleep(0.3)
    return driver


# ── Mobile Chrome emulation driver ────────────────────────────────────────
MOBILE_DEVICES = {
    "iphone_12": {
        "deviceMetrics": {"width": 390, "height": 844, "pixelRatio": 3.0},
        "userAgent": (
            "Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) "
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1"
        ),
    },
    "pixel_5": {
        "deviceMetrics": {"width": 393, "height": 851, "pixelRatio": 2.75},
        "userAgent": (
            "Mozilla/5.0 (Linux; Android 11; Pixel 5) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36"
        ),
    },
    "ipad": {
        "deviceMetrics": {"width": 768, "height": 1024, "pixelRatio": 2.0},
        "userAgent": (
            "Mozilla/5.0 (iPad; CPU OS 14_0 like Mac OS X) "
            "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15A372 Safari/604.1"
        ),
    },
    "samsung_s21": {
        "deviceMetrics": {"width": 360, "height": 800, "pixelRatio": 3.0},
        "userAgent": (
            "Mozilla/5.0 (Linux; Android 11; SM-G991B) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.105 Mobile Safari/537.36"
        ),
    },
    "galaxy_tab": {
        "deviceMetrics": {"width": 800, "height": 1280, "pixelRatio": 2.0},
        "userAgent": (
            "Mozilla/5.0 (Linux; Android 10; SM-T870) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Safari/537.36"
        ),
    },
}


def make_mobile_driver(device_name="iphone_12", headless=True, url=APP_URL):
    device = MOBILE_DEVICES.get(device_name, MOBILE_DEVICES["iphone_12"])
    opts = Options()
    opts.add_experimental_option("mobileEmulation", device)
    if headless:
        opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    opts.add_argument("--disable-extensions")
    svc = Service(ChromeDriverManager().install())
    drv = webdriver.Chrome(service=svc, options=opts)
    drv.implicitly_wait(8)
    drv.get(url)
    WebDriverWait(drv, 20).until(
        lambda d: d.execute_script("return document.readyState") == "complete"
    )
    return drv


@pytest.fixture(scope="function")
def mobile_driver(http_server):
    drv = make_mobile_driver("iphone_12", headless=True, url=http_server)
    yield drv
    drv.quit()


@pytest.fixture(scope="function")
def mobile_driver_no_modal(mobile_driver):
    mobile_driver.execute_script(
        "document.getElementById('connectionModal').classList.add('hidden');"
    )
    time.sleep(0.3)
    return mobile_driver
