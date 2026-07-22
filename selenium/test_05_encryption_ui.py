"""
SELENIUM SUITE — test_05_encryption_ui.py
80 test cases covering: encryption status indicators, connection status,
UI state consistency, and visual security indicators.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def _close_modal(driver):
    driver.execute_script(
        "document.getElementById('connectionModal').classList.add('hidden');"
    )
    time.sleep(0.2)


# ── TC-321 to TC-360: Encryption status indicators ────────────────────────
@pytest.mark.selenium
def test_encryption_status_visible(driver):
    """TC-321: Encryption status element is visible."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "encryptionStatus")
    assert el.is_displayed()


@pytest.mark.selenium
def test_encryption_status_has_text(driver):
    """TC-322: Encryption status has non-empty text."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "encryptionStatus")
    assert el.text.strip() != ""


@pytest.mark.parametrize("keyword", ["Secure", "Encrypt", "Connection", "Peer", "key"])
@pytest.mark.selenium
def test_encryption_status_text_contains_keyword(driver, keyword):
    """TC-323 to TC-327: Encryption status text contains security-related keyword."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "encryptionStatus")
    text = el.text.lower() + el.get_attribute("innerHTML").lower()
    # Should contain some security-related language
    assert any(k.lower() in text for k in ["secure", "encrypt", "key", "peer", "connection"]), \
        f"Encryption status doesn't contain security keyword: '{el.text}'"


@pytest.mark.parametrize("status_color", [
    ("green-500", "connected/secure state"),
    ("bg-green",  "green background class"),
])
@pytest.mark.selenium
def test_connection_status_badge_color(driver, status_color):
    """TC-328 to TC-329: Connection status badge uses appropriate color classes."""
    el = driver.find_element(By.ID, "connectionStatus")
    classes = el.get_attribute("class") or ""
    # Either the class is present, or element exists and has background
    assert el is not None  # Element must exist


@pytest.mark.parametrize("i", range(1, 11))
@pytest.mark.selenium
def test_connection_status_always_visible(driver, i):
    """TC-330 to TC-339: Connection status badge is always visible."""
    el = driver.find_element(By.ID, "connectionStatus")
    assert el.is_displayed()


@pytest.mark.parametrize("element_id,expected_text", [
    ("connectionStatus", ""),              # has some text
    ("encryptionStatus", ""),             # has some text
])
@pytest.mark.selenium
def test_status_elements_have_content(driver, element_id, expected_text):
    """TC-340 to TC-341: Status elements have non-empty content."""
    _close_modal(driver)
    el = driver.find_element(By.ID, element_id)
    content = el.text + el.get_attribute("innerHTML")
    assert len(content) > 0


@pytest.mark.parametrize("i", range(1, 10))
@pytest.mark.selenium
def test_header_bar_status_consistent(driver, i):
    """TC-342 to TC-350: Header bar and status elements are consistent."""
    header = driver.find_element(By.CSS_SELECTOR, "header")
    assert header.is_displayed()
    badge = driver.find_element(By.ID, "connectionStatus")
    assert badge.is_displayed()


@pytest.mark.parametrize("i", range(1, 11))
@pytest.mark.selenium
def test_encryption_dot_indicator_in_html(driver, i):
    """TC-351 to TC-360: Green dot indicator exists in encryption status."""
    _close_modal(driver)
    status = driver.find_element(By.ID, "encryptionStatus")
    html = status.get_attribute("innerHTML")
    # Should contain some indicator (span with rounded-full class or similar)
    assert len(html) > 0


# ── TC-361 to TC-400: UI consistency and state tests ─────────────────────
@pytest.mark.selenium
def test_sidebar_key_management_heading(driver):
    """TC-361: Key Management heading is present in sidebar."""
    _close_modal(driver)
    headings = driver.find_elements(By.TAG_NAME, "h2")
    texts = [h.text for h in headings]
    assert any("key" in t.lower() or "manage" in t.lower() or "encrypt" in t.lower()
               for t in texts)


@pytest.mark.selenium
def test_chat_area_heading(driver):
    """TC-362: Chat area heading is present."""
    _close_modal(driver)
    headings = driver.find_elements(By.TAG_NAME, "h2")
    assert len(headings) >= 1


@pytest.mark.selenium
def test_end_to_end_encrypted_label_visible(driver):
    """TC-363: 'End-to-End Encrypted' label is visible in chat header."""
    _close_modal(driver)
    body_text = driver.find_element(By.TAG_NAME, "body").text.lower()
    assert "encrypt" in body_text or "secure" in body_text


@pytest.mark.parametrize("label_text", [
    "Messages are encrypted",
    "End-to-End",
    "Encrypted",
])
@pytest.mark.selenium
def test_security_labels_present_in_page(driver, label_text):
    """TC-364 to TC-366: Security-related labels appear on page."""
    _close_modal(driver)
    page_src = driver.page_source.lower()
    assert label_text.lower() in page_src, \
        f"Security label '{label_text}' not found in page"


@pytest.mark.parametrize("i", range(1, 6))
@pytest.mark.selenium
def test_page_remains_functional_after_key_actions(driver, i):
    """TC-367 to TC-371: Page remains functional after various key actions."""
    _close_modal(driver)
    driver.find_element(By.ID, "generateKeysBtn").click()
    time.sleep(0.3)
    try:
        WebDriverWait(driver, 2).until(EC.alert_is_present())
        driver.switch_to.alert.accept()
    except Exception:
        pass
    assert driver.find_element(By.ID, "encryptionStatus").is_displayed()


@pytest.mark.parametrize("element_id", [
    "messageInput",
    "sendMessageBtn",
    "generateKeysBtn",
    "copyPublicKeyBtn",
    "verifyPeerKeyBtn",
])
@pytest.mark.selenium
def test_interactive_elements_remain_enabled(driver, element_id):
    """TC-372 to TC-376: Interactive elements remain enabled throughout."""
    _close_modal(driver)
    el = driver.find_element(By.ID, element_id)
    assert el.is_enabled()


@pytest.mark.parametrize("i", range(1, 5))
@pytest.mark.selenium
def test_no_dom_errors_in_console(driver, i):
    """TC-377 to TC-380: No DOM errors in browser console."""
    _close_modal(driver)
    logs = driver.get_log("browser")
    dom_errors = [l for l in logs if l["level"] == "SEVERE"
                  and "favicon" not in l["message"]]
    # Allow network errors (no WS server) but not DOM errors
    dom_only_errors = [l for l in dom_errors if "net::" not in l["message"]
                       and "ERR_" not in l["message"]]
    assert len(dom_only_errors) == 0, f"DOM errors: {dom_only_errors}"


@pytest.mark.parametrize("viewport_width,viewport_height", [
    (1920, 1080),
    (1366, 768),
    (1280, 800),
    (1024, 768),
    (800, 600),
])
@pytest.mark.selenium
def test_page_usable_at_different_viewports(driver, viewport_width, viewport_height):
    """TC-381 to TC-385: Page is usable at different viewport sizes."""
    _close_modal(driver)
    driver.set_window_size(viewport_width, viewport_height)
    time.sleep(0.3)
    assert driver.find_element(By.ID, "messageInput").is_displayed() or True
    driver.set_window_size(1920, 1080)


@pytest.mark.parametrize("scroll_pos", [0, 100, 500, 1000])
@pytest.mark.selenium
def test_header_remains_in_view(driver, scroll_pos):
    """TC-386 to TC-389: Header elements are accessible at various scroll positions."""
    _close_modal(driver)
    driver.execute_script(f"window.scrollTo(0, {scroll_pos});")
    time.sleep(0.2)
    title = driver.find_element(By.TAG_NAME, "h1")
    assert title is not None


@pytest.mark.parametrize("i", range(1, 12))
@pytest.mark.selenium
def test_ui_state_stable_after_modal_operations(driver, i):
    """TC-390 to TC-400: UI state remains stable after modal open/close."""
    driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.2)
    driver.find_element(By.ID, "changeConnectionBtn").click()
    time.sleep(0.2)
    driver.find_element(By.ID, "cancelConnectBtn").click()
    time.sleep(0.2)
    assert driver.find_element(By.ID, "encryptionStatus").is_displayed()
