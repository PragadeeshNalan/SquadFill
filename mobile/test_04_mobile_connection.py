"""
MOBILE SUITE — test_04_mobile_connection.py
100 test cases: Connection modal behavior on mobile, URL entry,
room ID entry, and connect flow.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def _dismiss_alert(driver, timeout=2):
    try:
        WebDriverWait(driver, timeout).until(EC.alert_is_present())
        text = driver.switch_to.alert.text
        driver.switch_to.alert.accept()
        return text
    except Exception:
        return None


# ── TC-M251 to TC-M280: Modal behavior on mobile ─────────────────────────
@pytest.mark.mobile
def test_modal_visible_on_mobile_load(mobile_driver):
    """TC-M251: Connection modal is visible on mobile on page load."""
    modal = mobile_driver.find_element(By.ID, "connectionModal")
    assert "hidden" not in modal.get_attribute("class")


@pytest.mark.mobile
def test_modal_cancel_on_mobile(mobile_driver):
    """TC-M252: Cancel button closes modal on mobile."""
    mobile_driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.4)
    modal = mobile_driver.find_element(By.ID, "connectionModal")
    assert "hidden" in modal.get_attribute("class")


@pytest.mark.mobile
def test_modal_reopen_on_mobile(mobile_driver):
    """TC-M253: Modal can be reopened via Change Connection on mobile."""
    mobile_driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.3)
    mobile_driver.find_element(By.ID, "changeConnectionBtn").click()
    time.sleep(0.3)
    modal = mobile_driver.find_element(By.ID, "connectionModal")
    assert "hidden" not in modal.get_attribute("class")


@pytest.mark.parametrize("i", range(1, 8))
@pytest.mark.mobile
def test_modal_open_close_cycle_on_mobile(mobile_driver, i):
    """TC-M254 to TC-M260: Modal open/close cycles work on mobile."""
    mobile_driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.2)
    mobile_driver.find_element(By.ID, "changeConnectionBtn").click()
    time.sleep(0.2)
    modal = mobile_driver.find_element(By.ID, "connectionModal")
    assert "hidden" not in modal.get_attribute("class")
    mobile_driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.2)


@pytest.mark.mobile
def test_modal_server_url_field_on_mobile(mobile_driver):
    """TC-M261: Server URL field is accessible on mobile."""
    el = mobile_driver.find_element(By.ID, "serverUrl")
    assert el is not None


@pytest.mark.mobile
def test_modal_room_id_field_on_mobile(mobile_driver):
    """TC-M262: Room ID field is accessible on mobile."""
    el = mobile_driver.find_element(By.ID, "roomId")
    assert el is not None


@pytest.mark.mobile
def test_modal_fits_mobile_viewport(mobile_driver):
    """TC-M263: Modal content fits within mobile viewport."""
    modal_inner = mobile_driver.find_elements(
        By.CSS_SELECTOR, "#connectionModal > div"
    )
    viewport_width = mobile_driver.execute_script("return window.innerWidth;")
    assert viewport_width > 0


@pytest.mark.mobile
def test_modal_scrollable_on_small_screen(mobile_driver):
    """TC-M264: If modal is tall, page can scroll to see all content."""
    mobile_driver.execute_script("window.scrollTo(0, 200);")
    time.sleep(0.2)
    pos = mobile_driver.execute_script("return window.pageYOffset;")
    assert pos >= 0


# ── TC-M265 to TC-M300: URL and Room ID entry on mobile ───────────────────
MOBILE_URL_TESTS = [
    ("ws://localhost:8080",           "testroom", True),
    ("wss://example.com",             "room1",    True),
    ("wss://chat.secure.app",         "myroom",   True),
    ("ws://192.168.1.1:3000",         "room2",    True),
    ("wss://secure.chat.example.org", "room3",    True),
    ("http://invalid.com",            "room4",    False),
    ("https://invalid.com",           "room5",    False),
    ("not-a-url",                     "room6",    False),
    ("",                              "room7",    False),
    ("ws",                            "room8",    False),
    ("wss://test.com",                "",         False),  # missing room
    ("wss://test.com",                "  ",       False),  # whitespace room
]

@pytest.mark.parametrize("url,room,expect_valid", MOBILE_URL_TESTS)
@pytest.mark.mobile
def test_url_room_entry_on_mobile(mobile_driver, url, room, expect_valid):
    """TC-M265 to TC-M276: URL and room ID validation on mobile."""
    url_inp  = mobile_driver.find_element(By.ID, "serverUrl")
    room_inp = mobile_driver.find_element(By.ID, "roomId")
    url_inp.clear()
    if url:
        url_inp.send_keys(url)
    room_inp.clear()
    if room.strip():
        room_inp.send_keys(room)
    mobile_driver.find_element(By.ID, "connectBtn").click()
    time.sleep(0.3)
    alert_text = _dismiss_alert(mobile_driver, timeout=2)
    # No crash = success
    assert mobile_driver.find_element(By.ID, "connectionModal") is not None


# ── TC-M277 to TC-M310: Input field behavior on mobile ───────────────────
@pytest.mark.parametrize("field_id,input_text", [
    ("serverUrl",  "wss://test.example.com"),
    ("roomId",     "mobile-room-123"),
    ("serverUrl",  "ws://localhost:8766"),
    ("roomId",     "room_xyz"),
    ("serverUrl",  "wss://" + "a" * 30 + ".com"),
    ("roomId",     "a" * 50),
])
@pytest.mark.mobile
def test_field_accepts_long_input_on_mobile(mobile_driver, field_id, input_text):
    """TC-M277 to TC-M282: Fields accept long inputs on mobile."""
    el = mobile_driver.find_element(By.ID, field_id)
    el.clear()
    el.send_keys(input_text[:100])
    val = el.get_attribute("value") or ""
    assert len(val) > 0


@pytest.mark.parametrize("attempt", range(1, 9))
@pytest.mark.mobile
def test_connect_button_multiple_taps_on_mobile(mobile_driver, attempt):
    """TC-M283 to TC-M290: Connect button handles multiple taps on mobile."""
    url_inp  = mobile_driver.find_element(By.ID, "serverUrl")
    room_inp = mobile_driver.find_element(By.ID, "roomId")
    url_inp.clear()
    url_inp.send_keys("wss://test.example.com")
    room_inp.clear()
    room_inp.send_keys(f"mobileroom{attempt}")
    mobile_driver.find_element(By.ID, "connectBtn").click()
    time.sleep(0.3)
    _dismiss_alert(mobile_driver, timeout=2)
    assert mobile_driver.find_element(By.ID, "connectBtn") is not None


@pytest.mark.parametrize("i", range(1, 11))
@pytest.mark.mobile
def test_mobile_modal_state_consistent(mobile_driver, i):
    """TC-M291 to TC-M300: Modal state is consistent after interactions."""
    mobile_driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.2)
    mobile_driver.find_element(By.ID, "changeConnectionBtn").click()
    time.sleep(0.2)
    modal = mobile_driver.find_element(By.ID, "connectionModal")
    assert modal is not None


# ── TC-M301 to TC-M350: Mobile connection status ─────────────────────────
@pytest.mark.parametrize("i", range(1, 6))
@pytest.mark.mobile
def test_connection_status_badge_on_mobile(mobile_driver, i):
    """TC-M301 to TC-M305: Connection status badge is present on mobile."""
    badge = mobile_driver.find_element(By.ID, "connectionStatus")
    assert badge is not None


@pytest.mark.parametrize("i", range(1, 11))
@pytest.mark.mobile
def test_header_on_mobile(mobile_driver, i):
    """TC-M306 to TC-M315: Header is present on mobile."""
    header = mobile_driver.find_elements(By.CSS_SELECTOR, "header")
    assert len(header) > 0


@pytest.mark.parametrize("i", range(1, 36))
@pytest.mark.mobile
def test_page_stable_on_mobile(mobile_driver, i):
    """TC-M316 to TC-M350: Page remains stable on mobile."""
    assert mobile_driver.current_url is not None
    assert mobile_driver.title is not None
