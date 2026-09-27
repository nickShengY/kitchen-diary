# Native iOS validation record

The native client was added without replacing the root React app, Flutter app, original artwork, or production backend code. The Xcode project, native screens, resource exporter, unit tests, UI smoke tests and separate GitHub Actions workflow are included.

## Checks executed during implementation

* Foundation-only Swift core: 31 test cases discovered; 30 passed, zero failures, and the real-repository parity test explicitly skipped because the complete original repository corpus was not mounted in the local Linux environment.
* Catalog literal-parser tests: 8 passed, including comments, Unicode/surrogate pairs, constructors, typed extraction, duplicate precedence and rejection of unexpected executable expressions.
* Account-deletion helper tests: 3 passed for recent authentication and ownership-scoped cleanup. These are unit tests, not deployed Firebase integration tests.

## Checks requiring a macOS/full-repository run

The Native iOS workflow exports the complete original catalog, compares it with actual TypeScript execution, generates 48 ranking/menu cases, runs the Swift parity test, then builds the simulator app and runs native UI smoke tests. It uploads Xcode logs and screenshots. **The existence of the workflow is not a passing build result.** Inspect the actual Actions run before treating simulator compilation, UI tests, or full-corpus parity as verified.

## Before production use

Use a real iOS Firebase registration and final bundle identifier; configure Google and Apple sign-in and the optional deletion endpoint. Validate two-account synchronization, offline recovery, menu-photo consent/analysis, notifications/background timers, account deletion, large text, VoiceOver, rotation, memory and visual parity on devices. Review the bundled privacy manifest against your deployed services. This change does not deploy the optional backend, configure App Store products, implement new StoreKit purchases, or submit an App Store build.
