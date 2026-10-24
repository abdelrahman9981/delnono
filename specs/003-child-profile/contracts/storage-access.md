# Contract: Cloud Storage Security Rules (003)

`storage.rules`, tested against the Storage emulator in `functions/test/rules/storage.test.ts`.
Deployment is **blocked: Blaze** (D-38); everything runs on the emulator until then.

| Path | Operation | Allowed when | Must be denied (test) |
|------|-----------|--------------|------------------------|
| `prescriptions/{childId}/{visitId}/{file}` | read | the caller is the child's linked guardian (child doc `guardianUid` = caller, guardian doc consent current, `lastActiveAt` within `reverifyAfterDays`), or has custom claim `role == 'doctor'` | other guardian; guardian with outdated consent; inactive guardian; claim `role == 'secretary'`; anonymous |
| `prescriptions/**` | write, delete | never (doctor upload added in 004) | linked guardian; doctor (until 004) |
| any other path | any | never | signed-in guardian |

The app reads photos with the SDK (`getData`), never with download URLs, so every read is checked.
