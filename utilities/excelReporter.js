const ExcelJS = require('exceljs');
const path = require('path');
const fs = require('fs');

async function generateExcelReport() {
    const reportPath = path.join(__dirname, '../reports/e2e_report.json');
    const excelPath = path.join(__dirname, '../reports/E2E_Report.xlsx');

    if (!fs.existsSync(reportPath)) {
        console.log('No JSON report found. Run npm test first.');
        return;
    }

    const reportData = JSON.parse(fs.readFileSync(reportPath, 'utf8'));
    const workbook = new ExcelJS.Workbook();

    // Summary Sheet
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.columns = [
        { header: 'Execution Date', key: 'date', width: 25 },
        { header: 'Total Tests', key: 'total', width: 15 },
        { header: 'Passed', key: 'passed', width: 15 },
        { header: 'Failed', key: 'failed', width: 15 },
        { header: 'Pass %', key: 'percent', width: 15 }
    ];

    const stats = reportData.stats;
    summarySheet.addRow({
        date: new Date().toLocaleString(),
        total: stats.tests,
        passed: stats.passes,
        failed: stats.failures,
        percent: ((stats.passes / stats.tests) * 100).toFixed(2) + '%'
    });

    // Details Sheet
    const detailsSheet = workbook.addWorksheet('Test Details');
    detailsSheet.columns = [
        { header: 'Test Name', key: 'title', width: 45 },
        { header: 'Status', key: 'state', width: 15 },
        { header: 'Duration (ms)', key: 'duration', width: 15 },
        { header: 'Error', key: 'error', width: 50 }
    ];

    reportData.results[0].suites[0].tests.forEach(test => {
        detailsSheet.addRow({
            title: test.fullTitle,
            state: test.state,
            duration: test.duration,
            error: test.err ? test.err.message : ''
        });
    });

    await workbook.xlsx.writeFile(excelPath);
    console.log('Excel report generated at:', excelPath);
}

generateExcelReport();