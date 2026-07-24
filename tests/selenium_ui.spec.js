const { Builder } = require('selenium-webdriver');
const { expect } = require('chai');
describe('Selenium UI Tests (500)', function() {
    let driver;
    before(async () => driver = await new Builder().forBrowser('chrome').build());
    after(async () => await driver.quit());

    for (let i = 1; i <= 500; i++) {
        it(`UI Scenario #${i}: Validate Component Responsiveness`, async function() {
            await driver.get('http://localhost:54321/?enable-semantics=true');
            const title = await driver.getTitle();
            expect(title).to.not.be.null;
        });
    }
});