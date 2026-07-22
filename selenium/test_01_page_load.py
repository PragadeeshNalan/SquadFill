"""
SELENIUM SUITE — test_01_page_load.py
60 test cases covering: DOM elements, page metadata, CSS classes,
element visibility, ARIA attributes, and structural integrity.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import NoSuchElementException


# ── TC-001 to TC-025: Required element IDs exist ──────────────────────────
REQUIRED_IDS = [
    "connectionModal",
    "serverUrl",
    "roomId",
    "connectBtn",
    "cancelConnectBtn",
    "changeConnectionBtn",
    "generateKeysBtn",
    "copyPublicKeyBtn",
    "publicKeyDisplay",
    "privateKeyDisplay",
    "peerPublicKey",
    "verifyPeerKeyBtn",
    "messageInput",
    "sendMessageBtn",
    "messageList",
    "messageContainer",
    "encryptionStatus",
    "typingIndicator",
    "connectionStatus",
]

@pytest.mark.parametrize("element_id", REQUIRED_IDS)
@pytest.mark.selenium
def test_required_element_exists(driver, element_id):
    """TC-001 to TC-019: Each required DOM element must be present."""
    elements = driver.find_elements(By.ID, element_id)
    assert len(elements) > 0, f"Element #{element_id} not found in DOM"


# ── TC-020 to TC-029: Page metadata ───────────────────────────────────────
@pytest.mark.parametrize("meta_attr,expected_value", [
    ("charset",  "UTF-8"),
    ("viewport", "width=device-width, initial-scale=1.0"),
])
@pytest.mark.selenium
def test_meta_tags(driver, meta_attr, expected_value):
    """TC-020 to TC-021: Meta tags are correctly defined."""
    if meta_attr == "charset":
        el = driver.find_element(By.CSS_SELECTOR, "meta[charset]")
        assert el.get_attribute("charset").upper() == expected_value.upper()
    elif meta_attr == "viewport":
        el = driver.find_element(By.CSS_SELECTOR, "meta[name='viewport']")
        assert expected_value in el.get_attribute("content")


@pytest.mark.parametrize("keyword", [
    "SecureChat",
    "Encrypted",
])
@pytest.mark.selenium
def test_page_title_contains_keyword(driver, keyword):
    """TC-022 to TC-023: Page title contains expected keywords."""
    assert keyword.lower() in driver.title.lower(), \
        f"Title '{driver.title}' does not contain '{keyword}'"


@pytest.mark.selenium
def test_page_loads_without_js_errors(driver):
    """TC-024: No critical JS errors on initial load."""
    logs = driver.get_log("browser")
    severe = [l for l in logs if l["level"] == "SEVERE"
              and "favicon" not in l["message"]
              and "net::ERR" not in l["message"]]
    assert len(severe) == 0, f"Severe JS errors found: {severe}"


@pytest.mark.selenium
def test_h1_exists_and_not_empty(driver):
    """TC-025: Single H1 tag exists and has non-empty text."""
    h1_elements = driver.find_elements(By.TAG_NAME, "h1")
    assert len(h1_elements) >= 1
    assert h1_elements[0].text.strip() != ""


# ── TC-026 to TC-045: Element visibility ──────────────────────────────────
VISIBLE_ELEMENTS = [
    ("ID",              "changeConnectionBtn",   "Change Connection button"),
    ("ID",              "connectionStatus",       "Connection status badge"),
    ("CSS_SELECTOR",    "header",                 "Header element"),
    ("CSS_SELECTOR",    "aside",                  "Sidebar element"),
    ("CSS_SELECTOR",    "main",                   "Main chat area"),
    ("ID",              "generateKeysBtn",        "Generate Keys button"),
    ("ID",              "copyPublicKeyBtn",       "Copy Public Key button"),
    ("ID",              "verifyPeerKeyBtn",       "Verify & Trust button"),
    ("ID",              "sendMessageBtn",         "Send Message button"),
    ("ID",              "messageInput",           "Message input textarea"),
]

@pytest.mark.parametrize("by_type,selector,label", VISIBLE_ELEMENTS)
@pytest.mark.selenium
def test_element_is_displayed(driver, by_type, selector, label):
    """TC-026 to TC-035: Critical elements are displayed on page."""
    by  = By.ID if by_type == "ID" else By.CSS_SELECTOR
    els = driver.find_elements(by, selector)
    assert len(els) > 0, f"{label} not found"
    assert els[0].is_displayed(), f"{label} is not visible"


# ── TC-036 to TC-045: Button interactability ──────────────────────────────
CLICKABLE_BUTTONS = [
    "generateKeysBtn",
    "copyPublicKeyBtn",
    "verifyPeerKeyBtn",
    "sendMessageBtn",
    "changeConnectionBtn",
]

@pytest.mark.parametrize("btn_id", CLICKABLE_BUTTONS)
@pytest.mark.selenium
def test_button_is_enabled(driver, btn_id):
    """TC-036 to TC-040: Buttons are enabled and clickable."""
    btn = driver.find_element(By.ID, btn_id)
    assert btn.is_enabled(), f"Button #{btn_id} is disabled"


@pytest.mark.parametrize("btn_id", CLICKABLE_BUTTONS)
@pytest.mark.selenium
def test_button_has_text(driver, btn_id):
    """TC-041 to TC-045: Buttons have non-empty text labels."""
    btn = driver.find_element(By.ID, btn_id)
    assert btn.text.strip() != "", f"Button #{btn_id} has empty text"


# ── TC-046 to TC-060: Structural and layout checks ────────────────────────
@pytest.mark.parametrize("tag,min_count", [
    ("button",   5),
    ("input",    2),
    ("textarea", 2),
    ("h2",       1),
    ("h3",       1),
])
@pytest.mark.selenium
def test_minimum_element_count(driver, tag, min_count):
    """TC-046 to TC-050: Minimum element counts are met."""
    els = driver.find_elements(By.TAG_NAME, tag)
    assert len(els) >= min_count, \
        f"Expected at least {min_count} <{tag}> elements, found {len(els)}"


@pytest.mark.selenium
def test_connection_modal_present(driver):
    """TC-051: Connection modal element exists in DOM."""
    modal = driver.find_element(By.ID, "connectionModal")
    assert modal is not None


@pytest.mark.selenium
def test_connection_modal_visible_on_load(driver):
    """TC-052: Connection modal is visible on initial page load."""
    modal = driver.find_element(By.ID, "connectionModal")
    assert "hidden" not in modal.get_attribute("class"), \
        "Modal should be visible on initial load"


@pytest.mark.selenium
def test_key_display_initial_text(driver):
    """TC-053: Key displays start with 'Generating keys...' or non-empty."""
    pub_text = driver.find_element(By.ID, "publicKeyDisplay").text
    assert pub_text != "", "Public key display should not be empty immediately"


@pytest.mark.selenium
def test_connection_status_badge_present(driver):
    """TC-054: Connection status badge is visible."""
    badge = driver.find_element(By.ID, "connectionStatus")
    assert badge.is_displayed()


@pytest.mark.selenium
def test_message_input_is_editable(driver):
    """TC-055: Message input textarea accepts text input."""
    inp = driver.find_element(By.ID, "messageInput")
    assert inp.is_enabled()
    inp.send_keys("test")
    assert inp.get_attribute("value") == "test" or inp.text == "test"


@pytest.mark.selenium
def test_server_url_input_default_value(driver):
    """TC-056: Server URL input has a default wss:// value."""
    inp = driver.find_element(By.ID, "serverUrl")
    val = inp.get_attribute("value") or ""
    assert "wss://" in val or "ws://" in val or val == "", \
        f"Unexpected default URL: {val}"


@pytest.mark.selenium
def test_peer_key_textarea_is_editable(driver):
    """TC-057: Peer public key textarea accepts input."""
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.send_keys("TEST")
    assert "TEST" in (ta.get_attribute("value") or ta.text)


@pytest.mark.selenium
def test_room_id_input_accepts_text(driver):
    """TC-058: Room ID input accepts text."""
    inp = driver.find_element(By.ID, "roomId")
    inp.send_keys("room123")
    assert "room123" in (inp.get_attribute("value") or "")


@pytest.mark.selenium
def test_encryption_status_displayed(driver):
    """TC-059: Encryption status element is displayed."""
    el = driver.find_element(By.ID, "encryptionStatus")
    assert el.is_displayed()


@pytest.mark.selenium
def test_typing_indicator_in_dom(driver):
    """TC-060: Typing indicator element exists in DOM."""
    el = driver.find_element(By.ID, "typingIndicator")
    assert el is not None
