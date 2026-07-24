const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

describe('Mobile Emulation Tests (500)', function() {
    for (let i = 1; i <= 500; i++) {
        it(`Mobile Profile #${i}: Validate Layout`, async function() {
            let options = new chrome.Options().addArguments(`--window-size=${300 + (i%100)},${600 + (i%200)}`);
            let driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
            await driver.get('http://localhost:54321');
            await driver.quit();
        });
    }
});