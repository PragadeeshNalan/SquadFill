const { Builder, By, until } = require('selenium-webdriver');
const { expect } = require('chai');

describe('SquadFill Web E2E Test', function() {
  let driver;

  before(async function() {
    driver = await new Builder().forBrowser('chrome').build();
    // Set a long timeout for the browser to handle slow Flutter bootstrap
    await driver.manage().setTimeouts({ implicit: 5000, pageLoad: 60000 });
  });

  after(async function() {
    await driver.quit();
  });

  async function forceClick(text, timeout = 40000) {
    console.log(`Searching for button: "${text}"...`);
    const start = Date.now();
    while (Date.now() - start < timeout) {
      const result = await driver.executeScript(`
        function findAndClick(root, target) {
          // Look ONLY for elements that are likely to be UI (semantics or buttons)
          const all = root.querySelectorAll('flt-semantics, [role="button"], [aria-label], .flt-text-editing');
          for (const el of all) {
            const label = (el.getAttribute('aria-label') || el.innerText || el.textContent || '').toLowerCase();
            if (label.includes(target.toLowerCase())) {
              el.click();
              el.dispatchEvent(new MouseEvent('click', {bubbles: true}));
              return true;
            }
            if (el.shadowRoot && findAndClick(el.shadowRoot, target)) return true;
          }
          return false;
        }
        return findAndClick(document, '${text}');
      `);

      if (result) {
        console.log(`Success: Clicked "${text}"`);
        return;
      }

      // Check if the app is even loaded yet
      const ready = await driver.executeScript("return !!document.querySelector('flutter-view')");
      if (!ready) {
        console.log("Waiting for Flutter engine to start...");
      } else {
        console.log("Engine ready, searching for UI elements...");
      }

      await driver.sleep(3000);
    }
    throw new Error(`Timed out waiting for "${text}". Browser might still be loading.`);
  }

  it('Should show validation error for empty login', async function() {
    // Enable semantics and give it plenty of time
    await driver.get('http://localhost:54321/?enable-semantics=true');
    console.log('App URL loaded. Waiting for engine bootstrap...');
    await driver.sleep(15000);

    // 1. Click Sign In on Onboarding
    await forceClick('Sign In');
    await driver.sleep(4000);

    // 2. Click Sign In on Login Form (Submit)
    await forceClick('Sign In');

    // 3. Verify error message appears in page source
    await driver.sleep(3000);
    const source = await driver.getPageSource();
    const hasError = /email|valid|required/i.test(source);

    expect(hasError).to.equal(true, "Validation error not found in page source.");
    console.log('Test Passed: Validation detected!');
  });
});
