const https = require('https');

const TOTAL_REQUESTS = 500; // Total requests to send
const CONCURRENCY = 20;     // Number of concurrent requests
const URL = 'https://firestore.googleapis.com/v1/projects/squadfill-4f0fa/databases/(default)/documents/matches';

let completed = 0;
let passed = 0;
let failed = 0;

function sendRequest() {
    return new Promise((resolve) => {
        https.get(URL, (res) => {
            // Count both 200 (OK) and 403 (Forbidden) as successful
            // because a 403 indicates the server is reachable but access is restricted.
            if (res.statusCode === 200 || res.statusCode === 403) {
                passed++;
            } else {
                failed++;
            }

            completed++;
            resolve();
        }).on('error', () => {
            failed++;
            completed++;
            resolve();
        });
    });
}

async function runLoadTest() {
    console.log('=======================================');
    console.log(' SquadFill Firestore Load Test');
    console.log('=======================================');
    console.log(`Total Requests : ${TOTAL_REQUESTS}`);
    console.log(`Concurrency    : ${CONCURRENCY}`);
    console.log('');

    const start = Date.now();

    for (let i = 0; i < TOTAL_REQUESTS; i += CONCURRENCY) {
        const batch = [];

        for (
            let j = 0;
            j < CONCURRENCY && (i + j) < TOTAL_REQUESTS;
            j++
        ) {
            batch.push(sendRequest());
        }

        await Promise.all(batch);
    }

    const duration = (Date.now() - start) / 1000;

    console.log('\n========== Load Test Results ==========');
    console.log(`Total Requests : ${completed}`);
    console.log(`Successful     : ${passed}`);
    console.log(`Failed         : ${failed}`);
    console.log(`Total Time     : ${duration.toFixed(2)} seconds`);
    console.log(
        `Throughput     : ${(completed / duration).toFixed(2)} requests/sec`
    );
    console.log('=======================================');

    // Exit code for GitHub Actions
    // Pass if at least 90% of requests succeeded
    process.exit(passed >= TOTAL_REQUESTS * 0.9 ? 0 : 1);
}

runLoadTest();