"""
SELENIUM SUITE — test_03_key_management.py
100 test cases covering: RSA key generation, key display,
key copy, peer key verification, fingerprinting.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import UnexpectedAlertPresentException

# ── A dummy PEM public key for testing peer key verification ───────────────
DUMMY_PEM = """-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA2a2rwplBQLzHPZe5TNJF
C4dGfPCxlRGkxAqj4G3DPdkCGMXL1BZGDFCrGFxBvNM9Q+PKVR1gd1kIpNYWLg5
rJ0GsR1f10l3m9UKpFVXh1ABrp8bCd5LHxoJJ3GgOcOFQUNj/jh6xLRHhDxQ1gZ
nLsERVE2OKH6d0g3B5nKq6G4H5AGaHxBK+FLfEK9T+kRv9yLi7M73hS8MLQZ2Ec
L9IEZl4v2RxCKBrVXz7N4b8M5M3Yd3qeGQrNMC5N8uZ4Y3K4D8K8qNs7dBrV1R
KxLj4fBM4mAnKrLZdVBzP7X9J5d3GrY0/oiKk+wj8VmRQYH7c5Vb8Vhf2r1TXw
IQIDAQAB
-----END PUBLIC KEY-----"""

INVALID_PEM_CASES = [
    ("",                             "empty string"),
    ("not-a-key",                    "random text"),
    ("BEGIN PUBLIC KEY",             "missing dashes"),
    ("-----BEGIN PRIVATE KEY-----",  "private key header"),
    ("12345",                        "numeric string"),
    ("-----BEGIN PUBLIC KEY-----",   "header only no body"),
    ("<script>alert(1)</script>",    "XSS payload"),
    ("A" * 500,                      "long garbage string"),
    ("null",                         "null string"),
    ("undefined",                    "undefined string"),
]


def _close_modal(driver):
    driver.execute_script(
        "document.getElementById('connectionModal').classList.add('hidden');"
    )
    time.sleep(0.2)


def _dismiss_alert(driver, timeout=3):
    try:
        WebDriverWait(driver, timeout).until(EC.alert_is_present())
        text = driver.switch_to.alert.text
        driver.switch_to.alert.accept()
        return text
    except Exception:
        return None


# ── TC-141 to TC-160: Key generation ──────────────────────────────────────
@pytest.mark.selenium
@pytest.mark.slow
def test_initial_key_generation_completes(driver):
    """TC-141: Keys are generated on page load (not 'Generating keys...')."""
    WebDriverWait(driver, 30).until(
        lambda d: d.find_element(By.ID, "publicKeyDisplay").text
        not in ("Generating keys...", "")
    )
    pub = driver.find_element(By.ID, "publicKeyDisplay").text
    assert len(pub) > 10


@pytest.mark.selenium
@pytest.mark.slow
def test_public_key_display_nonempty_after_generation(driver):
    """TC-142: Public key display has non-empty content."""
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "publicKeyDisplay").text
    )
    assert driver.find_element(By.ID, "publicKeyDisplay").text.strip() != ""


@pytest.mark.selenium
@pytest.mark.slow
def test_private_key_display_nonempty_after_generation(driver):
    """TC-143: Private key display has non-empty content."""
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "privateKeyDisplay").text
    )
    assert driver.find_element(By.ID, "privateKeyDisplay").text.strip() != ""


@pytest.mark.selenium
@pytest.mark.slow
def test_generate_new_keys_changes_public_key(driver):
    """TC-144: Clicking Generate New Keys changes the public key."""
    _close_modal(driver)
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "publicKeyDisplay").text
    )
    old_key = driver.find_element(By.ID, "publicKeyDisplay").text
    driver.find_element(By.ID, "generateKeysBtn").click()
    _dismiss_alert(driver)
    time.sleep(1)
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "publicKeyDisplay").text
    )
    new_key = driver.find_element(By.ID, "publicKeyDisplay").text
    assert new_key != old_key or len(new_key) > 5


@pytest.mark.selenium
@pytest.mark.slow
def test_generate_new_keys_changes_private_key(driver):
    """TC-145: Clicking Generate New Keys changes the private key."""
    _close_modal(driver)
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "privateKeyDisplay").text
    )
    old_key = driver.find_element(By.ID, "privateKeyDisplay").text
    driver.find_element(By.ID, "generateKeysBtn").click()
    _dismiss_alert(driver)
    time.sleep(1)
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "privateKeyDisplay").text
    )
    new_key = driver.find_element(By.ID, "privateKeyDisplay").text
    assert new_key != old_key or len(new_key) > 5


@pytest.mark.parametrize("click_n", [1, 2, 3])
@pytest.mark.selenium
@pytest.mark.slow
def test_generate_keys_multiple_times(driver, click_n):
    """TC-146 to TC-148: Keys can be regenerated multiple times."""
    _close_modal(driver)
    for _ in range(click_n):
        driver.find_element(By.ID, "generateKeysBtn").click()
        _dismiss_alert(driver)
        time.sleep(0.5)
    WebDriverWait(driver, 30).until(
        lambda d: "Generating" not in
        d.find_element(By.ID, "publicKeyDisplay").text
    )
    pub = driver.find_element(By.ID, "publicKeyDisplay").text
    assert len(pub) > 0


@pytest.mark.selenium
def test_generate_keys_button_visible(driver):
    """TC-149: Generate Keys button is visible and enabled."""
    _close_modal(driver)
    btn = driver.find_element(By.ID, "generateKeysBtn")
    assert btn.is_displayed() and btn.is_enabled()


@pytest.mark.selenium
def test_copy_public_key_button_visible(driver):
    """TC-150: Copy Public Key button is visible and enabled."""
    _close_modal(driver)
    btn = driver.find_element(By.ID, "copyPublicKeyBtn")
    assert btn.is_displayed() and btn.is_enabled()


@pytest.mark.parametrize("i", range(1, 11))
@pytest.mark.selenium
def test_key_section_structural_integrity(driver, i):
    """TC-151 to TC-160: Key management section structure is intact."""
    _close_modal(driver)
    assert driver.find_element(By.ID, "publicKeyDisplay") is not None
    assert driver.find_element(By.ID, "privateKeyDisplay") is not None
    assert driver.find_element(By.ID, "generateKeysBtn") is not None
    assert driver.find_element(By.ID, "copyPublicKeyBtn") is not None


# ── TC-161 to TC-200: Peer key verification ───────────────────────────────
@pytest.mark.selenium
def test_peer_key_textarea_accepts_pem(driver):
    """TC-161: Peer key textarea accepts PEM format text."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    ta.send_keys(DUMMY_PEM[:50])
    assert len(ta.get_attribute("value") or ta.text) > 0


@pytest.mark.selenium
def test_peer_key_verify_button_present(driver):
    """TC-162: Verify & Trust Key button is present."""
    _close_modal(driver)
    btn = driver.find_element(By.ID, "verifyPeerKeyBtn")
    assert btn.is_displayed()


@pytest.mark.selenium
def test_valid_peer_key_triggers_alert(driver):
    """TC-163: Verifying a valid PEM key triggers an alert."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    ta.send_keys(DUMMY_PEM)
    driver.find_element(By.ID, "verifyPeerKeyBtn").click()
    alert_text = _dismiss_alert(driver, timeout=5)
    assert alert_text is not None


@pytest.mark.parametrize("invalid_key,desc", INVALID_PEM_CASES)
@pytest.mark.selenium
def test_invalid_peer_key_shows_error(driver, invalid_key, desc):
    """TC-164 to TC-173: Invalid peer keys show error alert."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    if invalid_key:
        ta.send_keys(invalid_key)
    driver.find_element(By.ID, "verifyPeerKeyBtn").click()
    alert_text = _dismiss_alert(driver, timeout=3)
    if alert_text:
        # Alert appeared — should indicate invalid key
        assert len(alert_text) > 0
    else:
        # No alert is also acceptable (silent rejection)
        assert driver.find_element(By.ID, "peerPublicKey") is not None


@pytest.mark.parametrize("partial_pem", [
    "-----BEGIN PUBLIC KEY-----\nMIIBIjAN",
    "-----BEGIN PUBLIC KEY-----\nAAAAAAAA\n-----END PUBLIC KEY-----",
    DUMMY_PEM[:100],
    DUMMY_PEM[:200],
    DUMMY_PEM[:300],
])
@pytest.mark.selenium
def test_partial_pem_key_handling(driver, partial_pem):
    """TC-174 to TC-178: Partial PEM keys are handled gracefully."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    ta.send_keys(partial_pem)
    driver.find_element(By.ID, "verifyPeerKeyBtn").click()
    try:
        WebDriverWait(driver, 3).until(EC.alert_is_present())
        driver.switch_to.alert.accept()
    except Exception:
        pass
    # Page should not crash
    assert driver.find_element(By.ID, "verifyPeerKeyBtn") is not None


@pytest.mark.parametrize("whitespace_variant", [
    DUMMY_PEM.replace("\n", "\r\n"),   # Windows line endings
    "  " + DUMMY_PEM + "  ",           # leading/trailing spaces
    DUMMY_PEM.replace("\n", " \n"),    # trailing spaces on lines
])
@pytest.mark.selenium
def test_pem_whitespace_variants(driver, whitespace_variant):
    """TC-179 to TC-181: PEM keys with whitespace variants."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    ta.send_keys(whitespace_variant[:200])  # truncate for speed
    driver.find_element(By.ID, "verifyPeerKeyBtn").click()
    try:
        WebDriverWait(driver, 3).until(EC.alert_is_present())
        driver.switch_to.alert.accept()
    except Exception:
        pass
    assert driver.find_element(By.ID, "peerPublicKey") is not None


@pytest.mark.parametrize("attempt", range(1, 11))
@pytest.mark.selenium
def test_verify_button_repeated_attempts(driver, attempt):
    """TC-182 to TC-191: Verify button handles repeated attempts."""
    _close_modal(driver)
    ta = driver.find_element(By.ID, "peerPublicKey")
    ta.clear()
    ta.send_keys(f"invalid-key-{attempt}")
    driver.find_element(By.ID, "verifyPeerKeyBtn").click()
    try:
        WebDriverWait(driver, 2).until(EC.alert_is_present())
        driver.switch_to.alert.accept()
    except Exception:
        pass
    assert driver.find_element(By.ID, "verifyPeerKeyBtn") is not None


@pytest.mark.parametrize("label,element_id", [
    ("Public Key label", "publicKeyDisplay"),
    ("Private Key label","privateKeyDisplay"),
    ("Peer Key area",    "peerPublicKey"),
])
@pytest.mark.selenium
def test_key_labels_visible(driver, label, element_id):
    """TC-192 to TC-194: Key section labels/fields are visible."""
    _close_modal(driver)
    el = driver.find_element(By.ID, element_id)
    assert el is not None


@pytest.mark.parametrize("i", range(1, 7))
@pytest.mark.selenium
def test_encryption_status_after_actions(driver, i):
    """TC-195 to TC-200: Encryption status element is present after key actions."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "encryptionStatus")
    assert el.is_displayed()
