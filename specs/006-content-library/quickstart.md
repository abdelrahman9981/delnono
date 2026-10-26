# Quickstart: Content Library

1. `cd functions && npm run build && npx firebase emulators:start --import=../emulator-seed` (demo-delnono).
2. App: `flutter run --dart-define=USE_EMULATOR=true` → «محتوى» without signing in: 3 published videos and 3 tips; chips filter; search «ملح» finds «هل ينفع نحط ملح قبل عمر سنه»; tap → vertical player; airplane mode → list still opens, video says it needs internet.
3. Sign in as +201000000001 (code 123456): «مناسب لسن …» for the selected child under 4.
4. Dashboard `flutter run -d chrome -t lib/dashboard/main.dart --dart-define=USE_EMULATOR=true`: sec1@demo.delnono creates a video draft from `https://youtube.com/shorts/ZHEaiIOfg2s` (thumbnail shows), a `https://vimeo.com/1` link is refused, no publish button; doctor@demo.delnono publishes, the app shows it; audit log has `content.published`.
5. Tests: `flutter test`, `cd functions && npm test`, `npm run test:rules`, `flutter test integration_test/content_test.dart -d <simulator>`.
