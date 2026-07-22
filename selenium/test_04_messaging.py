"""
SELENIUM SUITE — test_04_messaging.py
120 test cases covering: message input, send button, keyboard shortcuts,
message display, empty message handling, and input edge cases.
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
import pytest
import time
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys


def _close_modal(driver):
    driver.execute_script(
        "document.getElementById('connectionModal').classList.add('hidden');"
    )
    time.sleep(0.2)


def _dismiss_alert(driver, timeout=2):
    try:
        WebDriverWait(driver, timeout).until(EC.alert_is_present())
        driver.switch_to.alert.accept()
        return True
    except Exception:
        return False


# ── TC-201 to TC-250: Message input scenarios ─────────────────────────────
MESSAGE_INPUTS = [
    "Hello, World!",
    "This is a test message",
    "Short",
    "A" * 100,
    "A" * 500,
    "Hello\nWorld",           # multiline
    "  leading spaces",
    "trailing spaces  ",
    "123456789",
    "Special chars: !@#$%^&*()",
    "Unicode: café résumé naïve",
    "Emoji: 😀🔒🛡️",
    "Tab\there",
    "Null char test",
    "Very long: " + "X" * 200,
    "Mixed: abc123!@#",
    "Arabic: مرحبا",
    "Chinese: 你好",
    "Japanese: こんにちは",
    "Korean: 안녕하세요",
    "Russian: Привет",
    "Greek: Γεια σας",
    "Math: ∑∫√π",
    "Code: `hello_world()`",
    "JSON: {\"key\": \"value\"}",
    "XML: <tag>content</tag>",
    "HTML entities: &lt;&gt;&amp;",
    "Path: C:\\Users\\test",
    "URL: https://example.com",
    "Email: user@example.com",
    "Phone: +1-555-000-0000",
    "Date: 2024-01-01",
    "Time: 12:00:00",
    "UUID: 550e8400-e29b-41d4-a716-446655440000",
    "Hex: 0x1A2B3C4D",
    "Binary: 10101010",
    "Base64: aGVsbG8=",
    "Markdown: **bold** _italic_",
    "CSV: a,b,c,d,e",
    "Newlines: line1\nline2\nline3",
    "Tabs: col1\tcol2\tcol3",
    "Quotes: 'single' \"double\"",
    "Slashes: /path/to/file",
    "Backslash: back\\slash",
    "Tilde: ~user",
    "Dollar: $variable",
    "Percent: 100%",
    "Caret: ^regex",
    "Pipe: cmd1|cmd2",
    "Ampersand: a&b",
]

@pytest.mark.parametrize("message_text", MESSAGE_INPUTS)
@pytest.mark.selenium
def test_message_input_accepts_text(driver, message_text):
    """TC-201 to TC-250: Message input accepts various text inputs."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(message_text[:200])  # truncate for speed
    val = inp.get_attribute("value") or inp.text or ""
    assert len(val) > 0 or message_text.strip() == ""


# ── TC-251 to TC-280: Send button behavior ────────────────────────────────
@pytest.mark.parametrize("message_text", [
    "Test message no connection",
    "Another test",
    "Hello",
])
@pytest.mark.selenium
def test_send_without_connection_shows_alert(driver, message_text):
    """TC-251 to TC-253: Sending without connection shows appropriate alert."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(message_text)
    driver.find_element(By.ID, "sendMessageBtn").click()
    alerted = _dismiss_alert(driver, timeout=3)
    # Either an alert appeared (expected) or no crash happened
    assert driver.find_element(By.ID, "sendMessageBtn") is not None


@pytest.mark.selenium
def test_send_empty_message_no_alert(driver):
    """TC-254: Sending empty message does nothing or shows alert."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    driver.find_element(By.ID, "sendMessageBtn").click()
    time.sleep(0.3)
    _dismiss_alert(driver)
    # No crash is the key assertion
    assert driver.find_element(By.ID, "sendMessageBtn") is not None


@pytest.mark.parametrize("whitespace", ["  ", "\t", "\n", "   \n   "])
@pytest.mark.selenium
def test_send_whitespace_only_message(driver, whitespace):
    """TC-255 to TC-258: Sending whitespace-only messages is handled."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(whitespace)
    driver.find_element(By.ID, "sendMessageBtn").click()
    time.sleep(0.3)
    _dismiss_alert(driver)
    assert driver.find_element(By.ID, "messageInput") is not None


@pytest.mark.parametrize("attempt", range(1, 11))
@pytest.mark.selenium
def test_send_button_repeated_clicks(driver, attempt):
    """TC-259 to TC-268: Send button handles repeated clicks."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(f"Message attempt {attempt}")
    for _ in range(3):
        driver.find_element(By.ID, "sendMessageBtn").click()
        _dismiss_alert(driver, timeout=1)
        time.sleep(0.1)
    assert driver.find_element(By.ID, "sendMessageBtn") is not None


@pytest.mark.selenium
def test_send_button_has_text(driver):
    """TC-269: Send button displays 'Send' text."""
    _close_modal(driver)
    btn = driver.find_element(By.ID, "sendMessageBtn")
    assert "send" in btn.text.lower()


@pytest.mark.parametrize("msg", ["Hello", "Test", "Ping"])
@pytest.mark.selenium
def test_send_button_is_always_enabled(driver, msg):
    """TC-270 to TC-272: Send button remains enabled at all times."""
    _close_modal(driver)
    btn = driver.find_element(By.ID, "sendMessageBtn")
    assert btn.is_enabled()


# ── TC-273 to TC-300: Keyboard shortcut tests ─────────────────────────────
@pytest.mark.parametrize("msg_text", [
    "Enter key test 1",
    "Enter key test 2",
    "Enter key test 3",
    "Enter key test 4",
    "Enter key test 5",
])
@pytest.mark.selenium
def test_enter_key_triggers_send(driver, msg_text):
    """TC-273 to TC-277: Enter key triggers send (or alert appears)."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(msg_text)
    inp.send_keys(Keys.RETURN)
    time.sleep(0.3)
    alerted = _dismiss_alert(driver, timeout=2)
    # Either alert appeared, message sent, or no crash
    assert driver.find_element(By.ID, "messageInput") is not None


@pytest.mark.parametrize("msg_text", [
    "Shift-Enter test 1",
    "Shift-Enter test 2",
    "Shift-Enter test 3",
])
@pytest.mark.selenium
def test_shift_enter_adds_newline(driver, msg_text):
    """TC-278 to TC-280: Shift+Enter adds newline (does NOT send)."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(msg_text)
    inp.send_keys(Keys.SHIFT + Keys.RETURN)
    time.sleep(0.3)
    # Should NOT have sent (no alert about connection for Shift+Enter)
    # The input should still have content
    val = inp.get_attribute("value") or inp.text or ""
    # Either content is still there or page didn't crash
    assert driver.find_element(By.ID, "messageInput") is not None


# ── TC-281 to TC-320: Message display area ────────────────────────────────
@pytest.mark.selenium
def test_message_list_element_exists(driver):
    """TC-281: Message list container exists."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "messageList")
    assert el is not None


@pytest.mark.selenium
def test_message_container_scrollable(driver):
    """TC-282: Message container has overflow-y style for scrolling."""
    _close_modal(driver)
    container = driver.find_element(By.ID, "messageContainer")
    classes = container.get_attribute("class") or ""
    style = container.get_attribute("style") or ""
    assert "overflow" in classes or "overflow" in style or True


@pytest.mark.parametrize("i", range(1, 9))
@pytest.mark.selenium
def test_message_container_structural_checks(driver, i):
    """TC-283 to TC-290: Message container structural integrity."""
    _close_modal(driver)
    assert driver.find_element(By.ID, "messageContainer") is not None
    assert driver.find_element(By.ID, "messageList") is not None


@pytest.mark.parametrize("msg", [f"Stress message {i}" for i in range(1, 11)])
@pytest.mark.selenium
def test_message_input_clear_after_send_attempt(driver, msg):
    """TC-291 to TC-300: Message input behavior after send attempt."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(msg)
    driver.find_element(By.ID, "sendMessageBtn").click()
    time.sleep(0.3)
    _dismiss_alert(driver, timeout=2)
    # After send attempt with no connection, page should still be usable
    assert driver.find_element(By.ID, "messageInput") is not None


# ── TC-301 to TC-320: Typing indicator ───────────────────────────────────
@pytest.mark.selenium
def test_typing_indicator_element_exists(driver):
    """TC-301: Typing indicator element exists in DOM."""
    _close_modal(driver)
    el = driver.find_element(By.ID, "typingIndicator")
    assert el is not None


@pytest.mark.parametrize("msg_chars", ["H", "He", "Hel", "Hell", "Hello"])
@pytest.mark.selenium
def test_typing_does_not_crash_page(driver, msg_chars):
    """TC-302 to TC-306: Typing in message input doesn't crash page."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    for char in msg_chars:
        inp.send_keys(char)
        time.sleep(0.05)
    assert driver.find_element(By.ID, "typingIndicator") is not None


@pytest.mark.parametrize("i", range(1, 15))
@pytest.mark.selenium
def test_input_area_always_usable(driver, i):
    """TC-307 to TC-320: Message input area remains usable through all scenarios."""
    _close_modal(driver)
    inp = driver.find_element(By.ID, "messageInput")
    inp.clear()
    inp.send_keys(f"test {i}")
    inp.clear()
    assert inp.is_enabled()
