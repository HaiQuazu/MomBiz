# MomBiz decisions and implementation proposals

Status: Firebase initialization is implemented and verified working on Android by the user. Further application work requires approval; the current update is documentation only.

This document separates **confirmed decisions** from **unapproved proposals** and **TBD questions**. Recommendations below are design suggestions, not additional business requirements or permission to implement. See [Product requirements](PRODUCT_REQUIREMENTS.md) for the full requested behavior and [Project rules](../AGENTS.md) for engineering guardrails.

## 1. Project inspection before the approved startup change

Re-inspected the local project on September 15, 2026 after the user's Firebase setup update. The observations below describe that inspection, before the subsequently approved implementation in section 1.2. The user reports that FlutterFire CLI completed successfully; the generated local files support that report.

| Area | Observed state |
| --- | --- |
| Application | `lib/main.dart` is the generated Flutter counter demo; no MomBiz features are present. |
| Package | `pubspec.yaml`: `mombiz`, version `1.0.0+1`, Dart SDK constraint `^3.12.2`. This constraint does not identify the installed Flutter version. |
| Dependencies | Flutter SDK, `cupertino_icons: ^1.0.8`, and user-added `firebase_core: ^4.15.0`, resolved to `4.15.0` in `pubspec.lock`. Development dependencies remain Flutter SDK `flutter_test` and `flutter_lints: ^6.0.0`. No `firebase_auth`, `cloud_firestore`, or `firebase_storage` dependency is declared. |
| Analysis and tests | `analysis_options.yaml` includes Flutter lints. `test/widget_test.dart` tests the demo counter. |
| Platforms | Generated Android, iOS, web, Windows, macOS, and Linux scaffolds exist. Their presence does not confirm release targets; Android receipt sharing is explicitly requested. |
| Android | Confirmed application ID and namespace: `com.chanthan.mombiz`. `MainActivity` uses the same package. Release builds still reference debug signing; production signing remains future work. Do not change the application ID. |
| Firebase configuration | Existing Firebase project `mombiz-313a8`; generated `lib/firebase_options.dart`, `android/app/google-services.json`, and FlutterFire mappings in `firebase.json` are present. Google Services Gradle plugin is declared and applied. Preserve the user's configuration. |
| Runtime/backend scope | `lib/main.dart` still launches the starter UI without Dart Firebase initialization. No local Firestore rules or application database definition was found. Remote service enablement, database contents, permissions and security rules were not inspected. |
| Documentation and version control | `AGENTS.md`, `docs/PRODUCT_REQUIREMENTS.md`, and this decision document now exist. README remains the starter README. The initial review found no Git repository; this review did not initialize one. |

That configuration review changed only `docs/DECISIONS.md`; it did not change application code or generated files, rerun FlutterFire CLI, or create a Firebase project/database. The user's later approval is recorded in C24 and section 1.2. Earlier documentation-phase restrictions do not undo the user's completed manual setup or this limited approval.

### 1.1 Firebase configuration validation

| Check | Result |
| --- | --- |
| Firebase project | `mombiz-313a8` agrees across the Android Google Services configuration, generated Dart options and FlutterFire mappings. |
| Firebase project number | `401476257902` agrees with the generated Android messaging sender ID. |
| Firebase Android app ID | `1:401476257902:android:27206c83aa7e9f2d9c7e7f` agrees across `google-services.json`, the Android options and both Android mappings in `firebase.json`. This Firebase app ID is distinct from the Android package name. |
| Android identity | Application ID, namespace, matching Google Services client and Kotlin `MainActivity` package are all `com.chanthan.mombiz`. The manifest's `.MainActivity` reference is consistent with that namespace. |
| Native/Dart configuration | Android API key and storage bucket values agree between `google-services.json` and the generated Dart options. A bucket identifier in configuration does not establish that file storage has been enabled or implemented. |
| Gradle integration | `android/settings.gradle.kts` declares `com.google.gms.google-services` version `4.4.4`; `android/app/build.gradle.kts` applies it. `google-services.json` is in the app module. |
| Dart dependency | `firebase_core` is already declared and resolved. Do not add it again. |
| Dart startup | At that inspection, `main.dart` lacked import/use of the generated options and an awaited `Firebase.initializeApp` call before `runApp`. This was subsequently implemented and verified as recorded in section 1.2. |

**Conclusion:** the local Android Firebase configuration looks correct and internally consistent. The configuration layout and package matching agree with the documented Google Services integration. This is a static review, not a successful Android build, runtime initialization test, or verification of cloud access. [Google Services plugin and configuration](https://firebase.google.com/docs/android/google-services-plugin-and-file)

Other generated options exist for web, Windows, iOS and macOS and point to the same Firebase project. iOS/macOS still use `com.example.mombiz`, matching their current starter bundle identifiers; their production identities and release targets remain TBD. Linux is explicitly unconfigured in `DefaultFirebaseOptions`. These observations do not authorize changing any platform or manually replacing the generated options.

### 1.2 Approved Firebase startup implementation — verified on Android

The user approved Firebase initialization in `lib/main.dart` using the existing generated options, with a simple **MomBiz Firebase Connected** screen after initialization. Authentication, Firestore, and all MomBiz business features remain outside this approval.

Implemented behavior:

- Initialize the Flutter binding and await `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before launching the app.
- Show the requested centered success message only when initialization succeeds, replacing the generated counter UI.
- Report initialization exceptions and stack traces through Flutter's error reporting, and display a short startup failure message instead of success when initialization fails.
- Keep the UI minimal and reuse the installed dependency and generated configuration without changing identifiers or adding services.
- Update the existing counter widget test to check the new startup success/failure display. It tests the UI without calling Firebase on the host.

This follows the initialization step in the [official FlutterFire setup guide](https://firebase.google.com/docs/flutter/setup). The screen's requested wording reports SDK initialization success; it does not establish live network connectivity, authentication, database access or data recovery.

Automated validation from the implementation step: the changed Dart files were formatted; `flutter analyze --no-pub` passed with no issues; `flutter test --no-pub` passed (one widget test covering both startup display outcomes).

**Android verification: passed, confirmed by the user.** The user reports that Firebase initialization is working on Android with the existing project `mombiz-313a8` and application ID/namespace `com.chanthan.mombiz`. This records the user's runtime verification; the assistant did not independently rerun the Android app during this documentation update. Authentication, Firestore access, security rules and data recovery have not been verified by this initialization check.

Files changed for the earlier implementation step: `lib/main.dart`, `test/widget_test.dart`, and `docs/DECISIONS.md`. This verification update changes only `docs/DECISIONS.md`; application code, generated Firebase options, dependencies, and Android configuration remain unchanged. No new features are authorized.

## 2. Confirmed decisions

These decisions come from the user's requirements, not from inferred accounting conventions.

| ID | Confirmed decision |
| --- | --- |
| C01 | Build MomBiz around Mom's existing notebook, receipt, customer-debt, and chick-reservation workflows. Keep the UI simple and KHR-first. |
| C02 | Assistant work is limited to explicitly approved steps. C24 authorizes Firebase initialization, its minimal status screen and validation; further application changes need approval. Preserve the user's Firebase setup and Android identifiers. |
| C03 | Customers have permanent identities independent of names. A family-member buyer may be recorded without becoming a customer; the debt belongs to the customer account. |
| C04 | Mom creates products. Product/category examples are not a fixed catalog. Manually enter quantity and unit price for each sale; preserve historical transaction values despite product changes. |
| C05 | A sale supports multiple items and manually chosen discounts. Keep actual sale date distinct from record-entry time. |
| C06 | Financial history is the source of customer debt. Customers can buy while owing money; full and partial payments are supported. Do not expose a manually editable debt total. |
| C07 | Record Cash, ABA QR, ACLEDA QR, and Other manually after Mom confirms receipt of payment. No automatic bank detection in V1. |
| C08 | Support KHR and USD, with no hard-coded rate. Preserve original amounts/currencies and the exact rate actually used for conversions. Never recalculate historical transactions at today's rate. |
| C09 | Money representation, exchange arithmetic, and mixed-currency balance calculations require a proposal and user approval before implementation. Unsafe floating-point assumptions are unacceptable. |
| C10 | Mom must be able to set/override the exchange rate. Automatic National Bank of Cambodia (NBC) retrieval is optional future work. |
| C11 | Generate digital receipts and support Android system sharing. A Telegram bot is outside V1; original receipt/notebook photos are a later possibility. |
| C12 | Chick reservations form a queue with earlier orders generally served earlier. The roughly five-day pattern is descriptive, not a finalized algorithm. |
| C13 | Cancellation may free a place for the next customer only with Mom's confirmation. Date changes must remain understandable in history. Queue statuses need review. |
| C14 | Chick pickup can create an ordinary sale with manually entered price/discount and optional payment. Reuse the normal financial logic. V1 has no stock/inventory management. |
| C15 | Planned backend services remain Firebase Authentication and Cloud Firestore, with Firebase Storage later for files. The user has configured the existing Firebase project/app (C21–C23); authentication, data ownership, database and sync implementation still require approval. |
| C16 | V1 may start with one primary Mom account. Keep future multiple-user support possible; isolate users' data and require Firestore Security Rules. |
| C17 | Prefer void/cancel over permanent deletion of financial records. Voided financial records do not affect balances. Propose the exact sale/payment model before implementing it. |
| C18 | Preserve relevant entry/update/transaction/void timestamps. Keep future audit extensions possible without over-engineering V1. |
| C19 | Separate UI, business logic, and data access; use typed, null-safe Dart, useful error handling, focused tests, and justified packages. Keep the architecture understandable. |
| C20 | Defer localization implementation and the dashboard until their stated prerequisites/approval. Honor all V1 exclusions in the product requirements. |
| C21 | The confirmed Firebase project ID is `mombiz-313a8`. Reuse this project; do not recreate it. |
| C22 | The confirmed Android application ID and namespace are `com.chanthan.mombiz`. Do not change the Android application ID. |
| C23 | The user completed FlutterFire CLI setup. Preserve generated `lib/firebase_options.dart` and the existing native configuration; do not manually replace the generated file. `firebase_core` has already been added. |
| C24 | The user approved only Firebase initialization in `lib/main.dart`, a minimal `MomBiz Firebase Connected` screen after success, and validation including `flutter analyze`. No Authentication, Firestore, customer/product/sale/payment/queue/receipt features are authorized. Report exactly which files changed and stop for approval afterward. |
| C25 | The user confirmed Firebase initialization is working on Android. Mark this startup milestone verified using the user's runtime confirmation. This confirmation does not authorize new features or establish that Authentication, Firestore, security rules or recovery have been tested. |

## 3. Proposed Flutter architecture — unapproved

### P01. Organize by feature with clear responsibilities

Recommendation: group each feature's screens, logic, and persistence together. Keep reusable money primitives separate so ordinary sales and chick pickup use the same calculations. A view model holds screen state; a repository provides access to records; an application service coordinates a workflow involving several records.

Flutter's architecture guidance supports separating views/view models from repositories/services and adding a domain layer where logic is complex or reused. The layout below is a MomBiz-specific proposal based on that guidance. [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide)

```text
lib/
  main.dart                      # Small startup entry point
  app/
    app.dart                     # App shell
    routing/                     # Navigation and authentication redirects
    theme/                       # Readable, accessible styling
    dependencies.dart            # Explicit construction/injection
  core/
    money/                       # Approved exact money/rate primitives only
    errors/                      # Shared failure types and error mapping
    time/                        # Date/clock helpers where needed
    widgets/                     # Widgets actually reused across features
  features/
    auth/
    customers/
    products/
    sales/
      presentation/              # Screens, widgets, view models
      domain/                    # Plain Dart models and financial rules
      application/               # Create/void sale workflows, when approved
      data/                      # Repository implementations and serialization
    payments/
    balances/                    # Derived balances; no editable debt record
    chick_reservations/
    receipts/
    settings/                    # Manual exchange rate and approved settings
test/
  core/
  features/                      # Mirrors implemented responsibilities
integration_test/                # Later: complete workflows and recovery
docs/
  PRODUCT_REQUIREMENTS.md
  DECISIONS.md
```

Other features may use the same subdivisions as `sales`, but create only the folders/classes needed by approved work. This tree does not create or authorize any files. A dashboard folder is deferred.

Proposed dependency rules:

- Widgets display data and forward actions. View models handle input, screen state, and readable errors.
- Domain models and financial functions remain plain Dart, without Firebase or widget imports.
- Put repository contracts with the feature's domain types; keep SDK adapters, serialization, and storage details in `data/`.
- Application services coordinate complex operations through repository contracts. Simple customer/product operations need not acquire a separate use-case class for every action.
- A shared sale workflow handles ordinary purchases and chick pickup. Balance and receipt code consume the saved financial facts rather than maintaining competing calculations.
- Use explicit constructor injection. SDK `ChangeNotifier`/`Listenable` is a possible starting point; state management and routing choices remain TBD. No dependency-injection framework or code generation is currently necessary.
- Keep display formatting at the UI boundary and translatable text separate from business rules. Localization itself remains deferred.

### P02. Major domain models

All names, field layouts, optionality, and status enums here are proposals. These are conceptual Dart models, **not a Firestore schema**. A model does not imply its own collection or a class that must be built immediately.

| Candidate model | Purpose and likely information | Decision dependencies |
| --- | --- | --- |
| `Customer` | Stable `id`, name, phone, optional notes, `createdAt`, `updatedAt`, possible archival status. | Required phone/name rules, duplicate warnings, archival behavior; never identify by name alone. |
| `Product` | Stable `id`, editable name, optional flexible category, timestamps, possible archival status. | Categories as text or separate records, quantity units and archival behavior. No catalog price controls a sale. |
| `Money` / `Currency` | Amount in approved integer units plus KHR/USD currency. | P03 precision and limits. |
| `ExchangeRateSnapshot` | Explicit direction, exact numerator/denominator, source (Manual or later NBC), applicable date and capture time. | P03 scale, timing, rate-selection and rounding rules. Copy actual values into converted transactions. |
| `DiscountSnapshot` | Manual kind/value, exact percentage representation if used, and applied monetary reduction. | Sale/item placement, allowed kinds, precision and rounding. |
| `SaleItem` | Product reference, historical product-name snapshot, quantity, actual manually entered unit price/currency, saved line total. | Quantity/unit precision, one currency per sale versus per item. Name snapshot is proposed to preserve historical descriptions. |
| `Sale` | ID, ownership scope, customer reference, optional buyer name/note, items, discount snapshot, totals, `saleDate`, `createdAt`, `updatedAt`, notes, financial status, optional reservation link/void metadata. | Customer requiredness, P03–P05, historical customer display details. |
| `Payment` | ID, ownership scope, customer reference, original `Money`, manual method, `paymentDate`, `createdAt`, `updatedAt`, note, financial status, applicable conversion/void information. | P04 settlement and allocation, P05 lifecycle. Optional sale linkage does not imply invoice-allocation rules. |
| `PaymentSettlement` | If P04 option A is approved: amount of the received payment applied to a specified debt currency, resulting debt reduction, and conversion snapshot when needed. | Conditional value within a payment; customer-level versus invoice-level allocation is TBD. Never subtract both original payment and converted settlement from the same balance. |
| `CustomerBalance` | Read-only result derived from relevant non-void financial history, possibly separate KHR/USD amounts and information about data completeness. | P04 and offline history coverage. Any later cached total must be rebuildable, not the source of truth. |
| `ChickReservation` | ID, customer, requested chick count, reservation date, scheduled pickup/batch date, queue order, status, notes, timestamps, possible linked sale. | P06 ordering, status, scheduling and pickup rules. |
| `ReservationChange` | Understandable history of schedule/status changes: previous/new date or status, change time, reason/actor where approved. | P06 event detail/retention and whether changes are embedded or stored separately. |
| `ReceiptSnapshot` | Historical customer/buyer/date/items/totals, payment and balance context, currency/rate details, references to the sale/payment and generation time. | Receipt format, sale versus account balance, numbering and regeneration policy. May be a generated value rather than a stored file. |
| `BusinessScope` / `UserProfile` | Account/ownership identity and approved business display settings; possible owner UID or membership reference. | P07 ownership structure, authentication and recovery. Do not build multiple-user management in V1 without a request. |

Important records also need stable IDs and audit information appropriate to their workflow. The proposed `createdAt` meaning is record entry, not network arrival. A separate server-received timestamp may be useful offline; date types and clock authority remain TBD in P08. Financial status and synchronization state must be separate concepts.

## 4. Financial proposals and approval gates

### P03. Exact money and exchange-rate arithmetic — approval required

Recommended representation for review:

1. `Money` stores currency and an integer amount: one unit is one riel for KHR and one cent for USD. Examples: 56,000 KHR is `56000`; USD 12.34 is `1234`. These precisions are proposals awaiting confirmation.
2. Parse entered decimal text exactly into those units. Do not parse through `double` and multiply/round afterward. Inputs with unsupported precision need an approved validation policy.
3. Represent an exchange rate as an exact positive rational number with a stated direction: `numerator / denominator` **KHR per 1 USD**. For illustration only, 4052 is `4052/1`; 4052.25 is `405225/100`. These are examples, not current or default rates.
4. Calculate with exact integers/rationals, retaining remainders until the approved rounding boundary. `BigInt` is a candidate for intermediate multiplication/division; persisted values need explicit bounds and serialization.
5. Each conversion preserves original money, the rate snapshot, and the actual rounded converted amount. Preserve the applicable rounding rule/version if needed to reproduce the result.
6. Percentage discounts and fractional quantities, if approved, must also use an exact representation. Integer basis points are an option only if two decimal places of percentage precision are sufficient; that business requirement is TBD.

Illustrative formulas, not implemented code:

```text
rate = numerator / denominator KHR per USD
KHR result before rounding = USD cents * numerator / (100 * denominator)
USD cents before rounding = KHR riel * 100 * denominator / numerator
```

For example, USD 10.00 at 4052 KHR/USD converts exactly to 40,520 KHR. USD 0.01 at that rate gives 40.52 KHR before rounding; the saved riel amount cannot be selected until Mom approves the rounding policy.

Native Dart integers have a different range from integers on JavaScript web targets; using `int` alone does not remove overflow/precision concerns. `BigInt` supports arbitrary-size integer arithmetic. Firestore's integer representation is signed 64-bit, so bounds and conversion must be explicit at persistence boundaries; do not store a `BigInt` object directly. [Dart number types](https://dart.dev/language/built-in-types), [BigInt API](https://api.dart.dev/dart-core/BigInt-class.html), [Firestore data types](https://firebase.google.com/docs/firestore/manage-data/data-types)

**TBD before financial implementation:** whole riel/cents versus finer price precision; rate input precision and bounds; quantity units/fractions; percentage precision; rounding direction and tie behavior; whether rounding occurs per line, discount, sale, or settlement; treatment of conversion remainders; maximum amounts and overflow handling. No rounding rule is approved by this document.

### P04. Mixed USD/KHR customer balances — approval required

The missing business decision is: **does a USD purchase remain a USD debt, or become a fixed KHR debt at the time of sale?** KHR-first display does not answer this.

| Option | How it works | Consequences to review |
| --- | --- | --- |
| A — preserve debt in its original currency (recommended starting proposal) | Derive KHR and USD balances separately. A payment records what was received and which debt currency it settles, with a stored conversion when currencies differ. | Preserves what the customer owes in each currency. Needs an explicit settlement choice for cross-currency payments and any split across balances. |
| B — fixed KHR posting for every financial record | Save each original amount plus its KHR equivalent at that record's chosen rate. Derive debt from these fixed KHR postings. | Gives one KHR balance, but a USD sale and equal USD payment at different rates may leave a remainder or credit. This must match Mom's actual agreement with customers. |

Example distinguishing the options: a USD 100 sale at 4052 and a later USD 100 payment at 4100. Under A, a same-currency settlement clears the USD 100 debt. Under B, recording each at its own rate gives 405,200 KHR minus 410,000 KHR, a 4,800 KHR credit. Neither outcome is an approved MomBiz business rule.

Proposed option A mechanics for review:

- For each currency, outstanding equals the sum of non-void sale amounts owed in that currency minus non-void payment settlements applied to it. Raw KHR and USD values are never added together.
- A USD 10 debt settled by 40,520 KHR at 4052 records the original KHR receipt, the rate, and a USD 10 debt reduction. It must not also reduce a KHR debt by 40,520 unless a separate approved part of the payment settles that debt.
- Use each payment once. If split settlement is allowed, its portions must reconcile to the received amount under the approved rounding policy.
- The historical rate and saved settlement remain fixed after a rate change. An optional current-rate display estimate must be clearly identified and cannot change recorded debt.
- Customer-level settlement avoids requiring invoice allocation for every old debt payment, but this is a proposal. Receipt meanings may require explicit sale/payment links.

**TBD:** option A or B; one currency per sale or mixed-currency items; who chooses the rate and which date it applies to; settlement across one/both balances; customer-level versus invoice allocation; overpayments/credits; prepayments; change given; opening notebook debt; returns/refunds/write-offs if ever needed. Do not add these extra financial workflows merely because they are questions. Never silently allocate payments to oldest invoices or convert all debts by default.

### P05. Sale/payment voiding and correction — approval required

Recommended model for review:

1. A saved financial record has proposed states `active` and `voided`. These are proposed stored states, not final UI wording. Payment progress is derived from the approved settlement model, not conflated with this lifecycle.
2. Keep saved monetary fields, transaction dates, item/discount/rate snapshots, and identity unchanged. Correct an incorrect posted transaction by confirming a void with a reason, then creating a replacement record when appropriate.
3. Record `voidedAt`, `voidReason`, and, where identity is available, `voidedBy`; an optional replacement reference connects corrections. Retain the original record in readable history.
4. Exclude a voided sale from sales and a voided payment from settlements. Avoid also posting a second reversal that would remove its effect twice.
5. Proposed simplification: no reactivation of a voided record; create a new record instead. This restriction still requires approval.
6. Do not automatically void a payment merely because a linked sale is voided: cash may actually have been received. Show linked records and require a defined correction workflow.

**TBD:** exact statuses/transitions; which fields can be edited after saving; whether drafts exist; reason requirement; undo/reactivation; correction links; treatment of linked payments, resulting credits and receipts; whether voiding a chick sale changes pickup history; concurrent/offline voids; who may void in future shared access. No cascading financial changes are approved.

## 5. Queue, ownership, and synchronization proposals

### P06. Chick scheduling and pickup — approval required

Recommended first workflow for review: Mom chooses/confirms each scheduled date, with the app displaying the existing queue and retaining changes. Introduce date suggestions only after the scheduling rules are agreed. A suggestion must remain editable and must not silently rearrange other reservations.

The examples September 12, September 17, and September 22, and a queue ending January 11, 2027 with a possible new date January 16, describe the present practice. They do not establish five days as an inflexible interval, one customer per date, or a capacity of 100 chicks.

For cancellation, propose showing the next eligible waiting customer and proposed date change for Mom to confirm. Eligibility and handling a customer who cannot come earlier are still TBD. Keep the cancelled reservation and record the replacement customer's previous/new dates.

For pickup, propose a shared workflow that records fulfillment, creates a normal sale at the entered price/discount, optionally records payment, and links those records. Repeated taps/retries must not create repeated sales. This requires a consistency design in P08 before implementation.

**TBD before the queue is implemented:**

- Is the five-day interval a configurable suggestion, a regular batch schedule, or entirely manual? What anchors the first available date and how are existing months of reservations entered?
- Can multiple customers share a date/batch? Does requested quantity affect scheduling or capacity? No inventory is implied.
- Does queue priority follow actual reservation date, entry time, or explicit ordering? How are backdated reservations and ties handled?
- Is queue position stored or derived? Can Mom make priority exceptions, and what history is needed?
- Which statuses and transitions are required? `scheduled`, `pickedUp`, `cancelled`, and `rescheduled` are candidates only. Should rescheduling be a history event while a reservation remains scheduled?
- Can pickup be partial, occur on another date, or involve a different quantity? Can one reservation create several sales? No answer is assumed.
- What happens when cancelling, restoring, or rescheduling a reservation; does Mom move one customer or confirm a larger set of changes?
- How do two devices resolve conflicting date changes or pickup attempts? Which operations can be pending while offline?

### P07. Firebase ownership and account recovery — approval required

Authentication identifies the signed-in person. An ownership scope determines which business records that person may access. One initial account does not establish whether future accounts will share Mom's business or operate independent businesses.

Illustrative path shapes for discussion only, not a database schema:

| Option | Example boundary | Tradeoff |
| --- | --- | --- |
| A — records under the authenticated user | `users/{uid}/...` | Simple for private single-owner data. Shared access or ownership transfer later needs an explicit migration/access design. |
| B — records under a business identity | `businesses/{businessId}/...`, with owner identity and later membership if approved | Separates business identity from login identity and can support shared access later. Adds ownership and rule-validation work now. |

Recommendation for review: option B with one owner initially, if future users are likely to help manage this same business. Otherwise option A may be sufficient. The business/membership collection layout, roles, and provisioning mechanism remain TBD; do not build employee administration or multi-branch behavior.

Future rules must check authorization for the record's scope, constrain ownership changes, and enforce approved financial transitions. Hiding a screen or using an unguessable document ID does not enforce access. Firestore provides authenticated request information and document-based conditions for these checks. [Firestore rule conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)

**TBD before authentication/data setup:** ownership option; whether future accounts share or separate data; sign-in provider (email/password, phone, Google, or another approved method); who controls recovery credentials; business creation/owner transfer; whether client rules suffice for privileged writes; account switching and cached-data cleanup; environment separation, data location and any additional platform production identifiers. The Firebase project and Android identifiers are confirmed in C21–C23 and are no longer TBD. Avoid an anonymous-only sign-in design as the recovery solution without an approved durable account-linking path.

### P08. Offline work, reliable balances, and cloud recovery — approval required

Firestore provides offline access to cached records and synchronizes local changes after reconnection. A cache contains data the app has accessed; it is not automatically the full business history. Concurrent edits to a document use last-write-wins behavior. [Firestore offline behavior](https://firebase.google.com/docs/firestore/manage-data/enable-offline)

Firestore transactions require connectivity, while batched writes can be queued offline. A batch groups writes atomically but does not by itself resolve conflicting business actions from two devices. [Transactions and batched writes](https://firebase.google.com/docs/firestore/manage-data/transactions)

Proposed safeguards to validate before implementing financial persistence:

- Use independent financial record IDs retained across retries, with immutable posted monetary snapshots under P05. Avoid read-modify-write updates to a shared editable customer balance.
- Design atomic boundaries for a sale plus initial payment and for pickup plus sale/payment links. Decide how repeated submissions and simultaneous device actions are detected; stable IDs alone do not guarantee correct fulfillment.
- Show clear saved-on-device, pending, synced, and failed states in language Mom understands. These are synchronization states, not financial statuses. Failed authorization or validation must remain visible and recoverable.
- Choose a strategy for complete balance inputs: load/cache the required history, or use a verified rebuildable summary with a defined completeness boundary. A paginated or partial cache must not be presented as a complete balance. Exact approach is TBD.
- Capture the actual transaction date and original entry time, including when offline. A server timestamp assigned on later synchronization cannot serve as the sole record-entry time. Decide how to store device entry time, server acknowledgment time, time zone, clock skew, and pending timestamps.
- Define conflict handling for voids, corrections, queue moves, and pickup. Do not silently overwrite a financial change or automatically move another customer to reconcile a conflict.
- Validate recovery by signing into a second device and checking synced customers, products, sales, payments, financial snapshots, reservation history, and receipt source data. First sign-in and fetching uncached data need connectivity.
- Data that never reached the cloud cannot be restored from that cloud after device loss. Make pending synchronization visible and decide whether additional backup/export and retention are needed later. Cloud synchronization is not a complete accidental-deletion recovery policy.
- Start by evaluating Firestore's supported offline behavior on the selected release platforms. Add a separate local database/outbox only if a validated requirement needs it; none is selected now.

## 6. TBD questions and when they must be resolved

The questions below remain unanswered after the Firebase configuration update. The project and Android package choices are recorded in C21–C23. Recommendations in P01–P08 must not be promoted to confirmed decisions without the user's approval. Resolve the relevant questions before dependent implementation; every later enhancement does not need to be designed now.

| ID | Open question | Resolve before |
| --- | --- | --- |
| T01 | Approve the feature layout, state approach, release platforms, and first implementation slice? | Application scaffolding or package changes. |
| T02 | Approve whole-riel/cents money, rational rates, bounds, and exact input/serialization rules? | Money models/calculations; P03. |
| T03 | Which rounding mode, precision, rounding boundary and remainder treatment apply to quantities, discounts and conversions? | Any financial calculations; P03. |
| T04 | Does USD debt stay USD or become fixed KHR? How are cross-currency/split payments allocated? | Balance/settlement calculations; P04. |
| T05 | One currency per sale or per item? Can one payment have several methods/currencies, or are these separate records? | Sale/payment forms and persistence. |
| T06 | Fixed and/or percentage discounts in the first release; sale-level and/or item-level; allowed limits and combinations? | Sale totals and discount UI. |
| T07 | Exact void/correction states, editable fields, linked-payment behavior, reasons, undo and audit detail? | Financial lifecycle; P05. |
| T08 | How will existing notebook debt enter the app: historical sales/payments or a separately approved opening-history mechanism? | Migrating real customer balances. Never seed an unexplained editable debt field. |
| T09 | Are overpayments, credits, advance payments, refunds, returns or write-offs needed? What happens if a sale void leaves a payment credit? | Accepting such actions; do not implement new workflows without approval. |
| T10 | Exact queue schedule, batch capacity if any, priority/ties, statuses, cancellation promotion and pickup quantity/linkage? | Chick queue; P06. |
| T11 | Ownership scope, shared versus private future users, login provider and durable recovery process? | Authentication/data setup; P07. Basic project/app configuration is already present. |
| T12 | Offline history coverage, save/retry/atomicity and conflict policy, account cache isolation and timestamps? | Financial persistence and production sync; P08. |
| T13 | Are all sales linked to a customer, or are anonymous/walk-in sales needed? Which customer fields are required and how should similar names be distinguished in search? | Customer and sale workflows. Account debt always needs a stable customer identity. |
| T14 | Product/category editing and archival, units such as bag/bottle/chick, fractional quantities, and snapshot behavior on renaming customers/products? | Product management and historical receipts. |
| T15 | Transaction date-only versus date/time, business time zone, payment backdating, and which date selects a manually chosen rate? | History sorting, rate selection and timestamp model. |
| T16 | Receipt PDF, image, or both; business name/details; numbering; receipt language; meaning of amount paid/remaining balance; payment allocation; historical regeneration? | Receipt generation/share. Do not infer legal/tax invoice requirements. |
| T17 | What should appear when there is no rate or only an older rate? How is Mom prompted to choose/confirm a conversion rate? | Conversion UI; automatic NBC retrieval remains deferred. |
| T18 | Initial UI language and future Khmer/English needs, including Khmer names/font rendering in receipts? | UI content and receipt format. Localization implementation still needs an explicit request. |
| T19 | Data location, environment separation, backup/retention, optional server validation and App Check? | Relevant backend/production configuration. Project `mombiz-313a8` is confirmed; no further setup is authorized by listing these questions here. |
| T20 | If/when the dashboard is approved, how should debt totals and today's payments display multiple currencies and incomplete sync? | Dashboard after stable underlying features. |

## 7. Existing setup and future service/package candidates

`firebase_core` and the FlutterFire configuration are already present from the user's setup. All remaining candidates below are a shortlist, not a dependency commitment. Select compatible versions and verify platform support at the approved implementation stage; the existing SDK constraint alone does not prove compatibility with future package versions. Nothing was installed during this review.

### Firebase services and development tools

| Service/tool | Expected role | Status |
| --- | --- | --- |
| [Firebase Authentication](https://firebase.google.com/docs/auth/flutter/start) | Sign in and recover access to the same cloud data on another phone. | Planned V1 backend; provider and recovery are TBD. |
| [Cloud Firestore](https://firebase.google.com/docs/firestore) | Customers, products, financial records and queue history with cloud synchronization. | Planned V1 backend; ownership/schema/rules require design approval. |
| [Firebase Security Rules](https://firebase.google.com/docs/rules) | Enforce authorized access and approved record constraints; add Storage rules when files are introduced. | Required with the corresponding backend. Not a Flutter package. |
| [Cloud Storage for Firebase](https://firebase.google.com/docs/storage/flutter/start) | Original receipt/notebook photos or stored receipt files if requested. | Later. Generating and sharing a receipt does not itself require cloud file storage. |
| [Firebase Local Emulator Suite](https://firebase.google.com/docs/emulator-suite) | Test authentication, ownership/security rules and data workflows using test data. | Proposed development tool, not installed/configured. |
| [Firebase App Check](https://firebase.google.com/docs/app-check) | Help reject requests from unauthorized app clients. | Evaluate before production; complements authentication/rules, does not replace them. |
| [Cloud Functions for Firebase](https://firebase.google.com/docs/functions) | Trusted validation or coordination if approved consistency needs require it. | Conditional; not a default V1 dependency. Must account for offline workflows. |
| [FlutterFire CLI](https://firebase.google.com/docs/flutter/setup) | Generate app configuration. | Already run successfully by the user for `mombiz-313a8`; generated files inspected. Do not rerun it during this review. |

### Flutter/Dart packages

| Candidate | Reason it may be needed | Selection boundary |
| --- | --- | --- |
| [`firebase_core`](https://pub.dev/packages/firebase_core) | Firebase initialization. | Already declared as `^4.15.0` and resolved to `4.15.0`. Startup initialization is implemented and verified on Android by the user; do not reinstall. |
| [`firebase_auth`](https://pub.dev/packages/firebase_auth) | Authentication client. | After provider/recovery decision. |
| [`cloud_firestore`](https://pub.dev/packages/cloud_firestore) | Cloud record access and supported offline persistence. | After ownership, financial and sync design. |
| [`firebase_storage`](https://pub.dev/packages/firebase_storage) | Upload/download file attachments. | Later, only with approved file-storage scope. |
| [`provider`](https://pub.dev/packages/provider) | Optional wiring for SDK `ChangeNotifier` and dependencies. | Constructor injection and SDK tools may be sufficient; state-management choice is TBD. |
| [`go_router`](https://pub.dev/packages/go_router) | Navigation and authentication redirects. | Optional; evaluate when routing is implemented. |
| [`intl`](https://pub.dev/packages/intl) | Human-readable dates, numbers and currency labels. | Formatting only; it does not define financial arithmetic or authorize localization work. |
| [`pdf`](https://pub.dev/packages/pdf) | Generate receipts if PDF is selected. | Validate receipt layout, fonts/Khmer text and actual sharing needs. |
| [`share_plus`](https://pub.dev/packages/share_plus) | Share PDF/image files through Android's share system. | Depends on approved receipt format. No Telegram/Messenger/WhatsApp-specific integration required. |
| [`printing`](https://pub.dev/packages/printing) | Optional PDF preview, rasterization and sharing. | Do not automatically add alongside another sharing package when one meets the chosen workflow; physical printing is not requested. |
| `flutter_test`, `flutter_lints` | Existing test/lint support. | Already declared; leave unchanged during this phase. |
| [`integration_test`](https://docs.flutter.dev/testing/integration-tests) (Flutter SDK) | End-to-end workflow verification later. | Add only when needed for implemented flows. |

No money library is selected: P03 may use a small exact Dart implementation, subject to approval and tests. No additional local database, connectivity plugin, bank SDK, NBC client, or code-generation package is justified yet. Photo capture/selection packages and localization dependencies can be evaluated if those later features are requested.

## 8. Proposed implementation sequence — awaiting approval

**Completed limited approval:** Firebase startup and the minimal status screen are implemented, and the user has verified initialization on Android (section 1.2). The next step and broader feature sequence below are proposals only.

### Next smallest implementation step — proposed, not approved

Recommend extracting the existing app widget from `lib/main.dart` into `lib/app/app.dart`:

- Keep Firebase initialization and startup error reporting in `main.dart`.
- Move the existing `MyApp` widget unchanged into `lib/app/app.dart`, preserving its constructor, success/failure screens and minimal styling.
- Update the entry-point and widget-test imports; run formatting, `flutter analyze --no-pub` and the existing widget test.

This makes a small part of P01 concrete: startup stays separate from the UI before additional screens are introduced. It requires no new dependency, service, business rule, financial model, navigation framework or extra empty feature folders. It is a MomBiz-specific application of the separation described in the [Flutter architecture guide](https://docs.flutter.dev/app-architecture/guide). Approving this extraction would not approve the rest of P01 or the broader roadmap. No extraction was implemented in this documentation update.

### Broader feature sequence — still awaiting approval

1. **Review these documents.** Resolve/approve the initial architecture and the financial, lifecycle, ownership and queue decisions required for the next slice. Record answers by moving approved proposals into confirmed decisions; unresolved rules stay TBD.
2. **Build a small foundation after approval.** Introduce the agreed app structure, shared UI/error conventions, and exact money/date models. Validate approved arithmetic with pure Dart tests before using it for customer balances.
3. **Implement authentication and persistence.** Reuse the existing Firebase project and generated app configuration. Add only approved services, ownership boundaries, security rules and repositories; verify isolation, offline save/retry behavior and recovery before relying on real business records. Use emulator/test data while validating.
4. **Implement customer and product management.** Stable customer identity, easy search, editable products and flexible categories, with approved archival/input rules.
5. **Implement sales, payments, and balances together.** Multiple items, manual prices, discounts, backdating, rate snapshots, partial/full payment and approved void/correction behavior. Use one tested financial path.
6. **Implement the chick queue.** Approved scheduling/statuses and understandable history; confirmation before moving customers; pickup reuses sale/payment workflows with duplicate protection.
7. **Implement receipt generation and sharing.** Use saved transaction facts and approved payment/balance meanings. Verify actual Android sharing and readable receipt rendering.
8. **Validate readiness.** Test complete workflows with Mom, accessibility/readability, errors, sync failure/reconnect, conflicting actions, and second-phone recovery. Resolve any discovered production gaps before release. Consider a dashboard only after the underlying features are stable and its content is approved.

Implementation checkpoints should use the user's examples: the 2,240,000 KHR two-line sale; the resulting 2,740,000 KHR debt after a 500,000 KHR payment and prior 1,000,000 KHR history; September 12 sale entered September 15; historical price/rate preservation; voided duplicate; and cancellation/pickup without duplicate sales. Add exact-money edge cases and cross-user access tests when those layers exist.

**Current stopping point:** Firebase initialization is verified working on Android by the user. Only this decision document changed in the current update. The proposed app-widget extraction and all new features await approval; financial and other business-model proposals remain unapproved.
