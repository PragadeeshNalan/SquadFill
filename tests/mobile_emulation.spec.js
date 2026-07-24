const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');

describe('Mobile Emulation Suite (500)', function() {
    let driver;
    before(async () => {
        let options = new chrome.Options().addArguments('--headless', '--no-sandbox');
        driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
    });
    after(async () => await driver.quit());

    for (let i = 1; i <= 500; i++) {
        it(`Mobile Profile #${i}: Resize & Render`, async function() {
            await driver.manage().window().setRect({ width: 375, height: 812 }); // iPhone X
            await driver.get('http://localhost:54321');
        });
    }
});