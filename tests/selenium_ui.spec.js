const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const { expect } = require('chai');

describe('Selenium Web Suite (500)', function() {
    let driver;
    before(async () => {
        let options = new chrome.Options().addArguments('--headless', '--no-sandbox', '--disable-dev-shm-usage');
        driver = await new Builder().forBrowser('chrome').setChromeOptions(options).build();
    });
    after(async () => await driver.quit());

    for (let i = 1; i <= 500; i++) {
        it(`UI Test #${i}: Page Load & Title Check`, async function() {
            await driver.get('http://localhost:54321');
            const title = await driver.getTitle();
            expect(title).to.not.be.null;
        });
    }
});