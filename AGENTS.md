# MomBiz project rules

## Current phase and source of truth

- This is a documentation and design phase. Wait for the user's approval before implementing the application.
- Do not change `pubspec.yaml` or dependency lockfiles, install packages, configure Firebase, create a database, or scaffold features during this phase.
- Read [Product requirements](docs/PRODUCT_REQUIREMENTS.md) and [Decisions](docs/DECISIONS.md) before changing the project.
- User instructions take precedence. Keep confirmed requirements, proposals, and TBDs distinct; a proposal is not approval. Record subsequent approvals in `docs/DECISIONS.md`.
- Do not invent business rules. Resolve missing rules with the user before implementing behavior that depends on them.

## Product rules

- Build for Mom: simple workflows, large tap targets and amounts, minimal typing, clear confirmations and errors, easy customer/product search, and KHR-first displays.
- Give customers stable identities independent of names. An optional buyer name/note does not create another customer or transfer debt away from the customer account.
- Products and categories must remain flexible. Mom enters quantity and unit price for every sale; preserve the actual price and transaction details in the sale. Product edits must never rewrite historical sales.
- Preserve the actual sale/payment date separately from when the record was entered. Do not replace the entry time with a later sync time.
- Discounts are manual; preserve the actual discount used. Do not assign discounts automatically.
- Derive debt from financial history. Do not implement an editable customer-debt number. Existing debt does not prevent further purchases; partial payments are normal.
- Cash, ABA QR, ACLEDA QR, and Other are manually recorded payment methods. No automatic bank detection in V1.
- Support KHR and USD; never hard-code an exchange rate or revalue old transactions using a current rate. Preserve original amounts/currencies and the actual conversion rate used.
- Preserve financial history. Prefer void/cancel over permanent deletion; exclude voided records from balances under the approved model.
- Chick reservations use a queue. Approximately five days is an observed pattern, not an approved scheduling algorithm. Never move customers automatically without Mom's confirmation; preserve understandable date-change history.
- Chick pickup must reuse ordinary sale/payment accounting. Do not add inventory management.
- Cloud recovery on another phone and practical offline work are requirements. Keep different users' data isolated, including cached data on account changes.
- Keep future Khmer/English localization possible without implementing localization yet. Build the dashboard only after the data model and underlying features are stable.
- Respect the V1 exclusions in the product requirements; do not expand scope silently.

## Decisions that require approval before dependent implementation

- Safe money representation, quantity/discount precision, rounding, and exact exchange-rate arithmetic. Do not use `double` blindly for money or conversion calculations.
- Mixed USD/KHR debt and payment settlement, including what currency a debt remains owed in.
- Exact sale/payment voiding, correction, and linked-record behavior.
- Chick scheduling, statuses, cancellation replacement, and pickup linkage.
- Firebase ownership, authentication/recovery, and offline synchronization design before backend setup.
- The current general hold on application implementation also remains in effect until the user approves proceeding.

## Engineering rules for approved implementation

- Separate widgets, business logic, and data access. Use strongly typed, null-safe Dart models; keep financial rules testable without Flutter or Firebase.
- Follow the approved architecture, keeping names consistent and boundaries understandable to a learning developer. Create abstractions and reusable widgets only when useful.
- Add packages only when justified by approved work. Keep Firebase SDK types and serialization in the data layer.
- Centralize error handling where it helps; do not silently swallow errors. Make failures and unsynced work understandable to Mom.
- Preserve financial snapshots, record identities, and relevant audit timestamps. Retried saves and chick pickup must not create duplicate financial effects.
- Require ownership checks and Firestore Security Rules for cloud access; test user isolation and approved financial-write constraints.
- Document non-obvious business rules in comments. Avoid comments that merely restate code.
- Use focused business-logic tests for money, balances, voiding, dates, and queue rules; widget tests for important workflows; integration/security tests for sync and recovery when implemented.
- For Dart changes, format changed files, run `flutter analyze`, and run relevant `flutter test` checks. Report failures or checks not run. Documentation-only changes need link/content review, not application tests or dependency resolution.
- Keep changes scoped and preserve unrelated work. Summarize what changed, validation, and unresolved decisions.
