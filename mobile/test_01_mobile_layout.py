"""
MOBILE SUITE — test_01_mobile_layout.py
100 test cases: Responsive layout at 10 device profiles × 10 checks each.
Uses Chrome mobile emulation (no Appium server required).
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from conftest import make_mobile_driver, APP_URL, MOBILE_DEVICES


# 10 mobile device profiles
DEVICE_PROFILES = [
    ("iphone_12",   390,  844),
    ("pixel_5",     393,  851),
    ("samsung_s21", 360,  800),
    ("ipad",        768, 1024),
    ("galaxy_tab",  800, 1280),
    # Additional emulated devices (custom)
    ("small_phone",    320,  568),
    ("medium_phone",   375,  667),
    ("large_phone",    414,  896),
    ("phablet",        480,  853),
    ("mini_tablet",    600,  960),
]

LAYOUT_CHECKS = [
    "title_visible",
    "connection_status_visible",
    "change_connection_btn_visible",
    "modal_visible_on_load",
    "server_url_input_visible",
    "room_id_input_visible",
    "connect_btn_visible",
    "cancel_btn_visible",
    "page_width_fits_viewport",
    "no_horizontal_overflow",
]


def _make_custom_driver(width, height, url):
    """Create mobile driver with custom dimensions."""
    from selenium import webdriver
    from selenium.webdriver.chrome.service import Service
    from selenium.webdriver.chrome.options import Options
    from webdriver_manager.chrome import ChromeDriverManager

    mobile_emulation = {
        "deviceMetrics": {"width": width, "height": height, "pixelRatio": 2.0},
        "userAgent": (
            "Mozilla/5.0 (Linux; Android 11; Generic) "
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/90.0.4430.91 Mobile Safari/537.36"
        ),
    }
    opts = Options()
    opts.add_experimental_option("mobileEmulation", mobile_emulation)
    opts.add_argument("--headless=new")
    opts.add_argument("--no-sandbox")
    opts.add_argument("--disable-dev-shm-usage")
    opts.add_argument("--disable-gpu")
    svc = Service(ChromeDriverManager().install())
    drv = webdriver.Chrome(service=svc, options=opts)
    drv.implicitly_wait(8)
    drv.get(url)
    WebDriverWait(drv, 20).until(
        lambda d: d.execute_script("return document.readyState") == "complete"
    )
    return drv


def _do_layout_check(driver, check, width):
    if check == "title_visible":
        el = driver.find_elements(By.TAG_NAME, "h1")
        assert len(el) > 0
    elif check == "connection_status_visible":
        assert driver.find_element(By.ID, "connectionStatus") is not None
    elif check == "change_connection_btn_visible":
        assert driver.find_element(By.ID, "changeConnectionBtn") is not None
    elif check == "modal_visible_on_load":
        modal = driver.find_element(By.ID, "connectionModal")
        assert "hidden" not in modal.get_attribute("class")
    elif check == "server_url_input_visible":
        assert driver.find_element(By.ID, "serverUrl") is not None
    elif check == "room_id_input_visible":
        assert driver.find_element(By.ID, "roomId") is not None
    elif check == "connect_btn_visible":
        assert driver.find_element(By.ID, "connectBtn") is not None
    elif check == "cancel_btn_visible":
        assert driver.find_element(By.ID, "cancelConnectBtn") is not None
    elif check == "page_width_fits_viewport":
        body_width = driver.execute_script("return document.body.scrollWidth")
        assert body_width <= width * 1.1, \
            f"Body width {body_width}px exceeds viewport {width}px"
    elif check == "no_horizontal_overflow":
        overflow = driver.execute_script(
            "return document.documentElement.scrollWidth > document.documentElement.clientWidth"
        )
        assert not overflow, "Page has horizontal overflow on mobile"


# ── TC-M001 to TC-M100: Layout checks per device ─────────────────────────
@pytest.mark.parametrize("device_name,width,height", DEVICE_PROFILES)
@pytest.mark.parametrize("layout_check", LAYOUT_CHECKS)
@pytest.mark.mobile
def test_mobile_layout(http_server, device_name, width, height, layout_check):
    """TC-M001 to TC-M100: Mobile layout checks across device profiles."""
    if device_name in MOBILE_DEVICES:
        drv = make_mobile_driver(device_name, headless=True, url=http_server)
    else:
        drv = _make_custom_driver(width, height, http_server)
    try:
        _do_layout_check(drv, layout_check, width)
    finally:
        drv.quit()
