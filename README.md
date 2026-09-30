# 今天的小事

Expo + Codex workshop reference app. React Native with local persistence, no server account or API key required.

## Start

Install Node.js 22 LTS and Git. In this directory:

```sh
npm ci
npm start
```

Install the matching Expo Go on your iPhone, connect phone and computer to the same network, then scan the terminal QR code using the iPhone camera. Keep the terminal running. Windows does not provide Apple's iOS Simulator; use a physical iPhone.

For a computer preview, use `npm run web`. Browser storage and iPhone storage are separate. This is a development preview, not a standalone installed application.

## Verify

```sh
npx tsc --noEmit
npx expo export --platform web
npx expo export --platform ios --output-dir dist-ios
npx playwright test
```

Tests exercise blank validation, add/edit/filter/delete, persistence, mobile/desktop layout and corrupted storage protection. Windows CI uses a real hosted Windows runner; this does not validate a learner's Codex login, classroom Wi-Fi or physical iPhone by itself.
