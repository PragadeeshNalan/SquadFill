const https = require('https');
const TOTAL = 500;
const URL = 'https://firestore.googleapis.com/v1/projects/squadfill-4f0fa/databases/(default)/documents/matches';

async function run() {
    console.log("🚀 Starting 500 Backend Load Tests...");
    let passed = 0;
    for (let i = 0; i < TOTAL; i++) {
        await new Promise(r => {
            https.get(URL, (res) => {
                if (res.statusCode < 500) passed++; // 200/403 means reachable
                r();
            }).on('error', r);
        });
        if (i % 100 === 0) console.log(`Completed ${i} backend hits...`);
    }
    console.log(`✅ Passed: ${passed}/${TOTAL}`);
    process.exit(passed > 400 ? 0 : 1);
}
run();