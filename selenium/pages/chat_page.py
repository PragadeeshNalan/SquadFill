"""Page Object Model for SecureChat."""
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
import time


class ChatPage:
    # ── Locators ───────────────────────────────────────────────────────────
    TITLE              = (By.TAG_NAME, "h1")
    CONNECTION_STATUS  = (By.ID, "connectionStatus")
    MODAL              = (By.ID, "connectionModal")
    SERVER_URL_INPUT   = (By.ID, "serverUrl")
    ROOM_ID_INPUT      = (By.ID, "roomId")
    CONNECT_BTN        = (By.ID, "connectBtn")
    CANCEL_BTN         = (By.ID, "cancelConnectBtn")
    CHANGE_CONN_BTN    = (By.ID, "changeConnectionBtn")
    GENERATE_KEYS_BTN  = (By.ID, "generateKeysBtn")
    COPY_KEY_BTN       = (By.ID, "copyPublicKeyBtn")
    PUBLIC_KEY_DISPLAY = (By.ID, "publicKeyDisplay")
    PRIVATE_KEY_DISPLAY= (By.ID, "privateKeyDisplay")
    PEER_KEY_TEXTAREA  = (By.ID, "peerPublicKey")
    VERIFY_PEER_BTN    = (By.ID, "verifyPeerKeyBtn")
    MESSAGE_INPUT      = (By.ID, "messageInput")
    SEND_BTN           = (By.ID, "sendMessageBtn")
    MESSAGE_LIST       = (By.ID, "messageList")
    MESSAGE_CONTAINER  = (By.ID, "messageContainer")
    ENCRYPTION_STATUS  = (By.ID, "encryptionStatus")
    TYPING_INDICATOR   = (By.ID, "typingIndicator")

    def __init__(self, driver):
        self.driver = driver
        self.wait   = WebDriverWait(driver, 15)

    # ── Modal helpers ──────────────────────────────────────────────────────
    def close_modal(self):
        self.driver.execute_script(
            "document.getElementById('connectionModal').classList.add('hidden');"
        )
        time.sleep(0.2)

    def open_modal(self):
        self.driver.find_element(*self.CHANGE_CONN_BTN).click()
        time.sleep(0.2)

    def is_modal_visible(self):
        modal = self.driver.find_element(*self.MODAL)
        return "hidden" not in modal.get_attribute("class")

    def fill_connection(self, url, room_id):
        self.driver.find_element(*self.SERVER_URL_INPUT).clear()
        self.driver.find_element(*self.SERVER_URL_INPUT).send_keys(url)
        self.driver.find_element(*self.ROOM_ID_INPUT).clear()
        self.driver.find_element(*self.ROOM_ID_INPUT).send_keys(room_id)

    def click_connect(self):
        self.driver.find_element(*self.CONNECT_BTN).click()

    def click_cancel(self):
        self.driver.find_element(*self.CANCEL_BTN).click()

    # ── Key helpers ────────────────────────────────────────────────────────
    def get_public_key_text(self):
        return self.driver.find_element(*self.PUBLIC_KEY_DISPLAY).text

    def get_private_key_text(self):
        return self.driver.find_element(*self.PRIVATE_KEY_DISPLAY).text

    def click_generate_keys(self):
        self.driver.find_element(*self.GENERATE_KEYS_BTN).click()

    def set_peer_key(self, key_text):
        ta = self.driver.find_element(*self.PEER_KEY_TEXTAREA)
        ta.clear()
        ta.send_keys(key_text)

    def click_verify_peer(self):
        self.driver.find_element(*self.VERIFY_PEER_BTN).click()

    # ── Message helpers ────────────────────────────────────────────────────
    def type_message(self, text):
        inp = self.driver.find_element(*self.MESSAGE_INPUT)
        inp.clear()
        inp.send_keys(text)

    def click_send(self):
        self.driver.find_element(*self.SEND_BTN).click()

    def get_message_count(self):
        items = self.driver.find_elements(By.CSS_SELECTOR, "#messageList > div")
        return len(items)

    def get_encryption_status_text(self):
        return self.driver.find_element(*self.ENCRYPTION_STATUS).text

    def wait_for_key_generation(self, timeout=30):
        """Wait until the public key display is no longer 'Generating keys...'"""
        self.wait = WebDriverWait(self.driver, timeout)
        self.wait.until(
            lambda d: d.find_element(By.ID, "publicKeyDisplay").text
            not in ("Generating keys...", "")
        )

    # ── JS helpers ─────────────────────────────────────────────────────────
    def js(self, script):
        return self.driver.execute_script(script)

    def dismiss_alert_if_present(self):
        try:
            WebDriverWait(self.driver, 2).until(EC.alert_is_present())
            self.driver.switch_to.alert.accept()
            return True
        except Exception:
            return False
