import { defineConfig } from '@playwright/test';
export default defineConfig({
  testDir: './tests', timeout: 30000, workers: 1,
  reporter: [['list'], ['json', {outputFile:'evidence/results.json'}]],
  use: {baseURL:'http://127.0.0.1:4179', screenshot:'only-on-failure', trace:'retain-on-failure'},
  webServer:{command:'npx http-server dist -p 4179 -c-1',url:'http://127.0.0.1:4179',reuseExistingServer:!process.env.CI,timeout:60000},
  projects:[{name:'mobile',use:{viewport:{width:390,height:844}}},{name:'desktop',use:{viewport:{width:1280,height:800}}}]
});
