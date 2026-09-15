# MomBiz Product Requirements

## 1. Document status and current phase

MomBiz is a planned production-quality Flutter application for a small business, designed primarily for the owner's mother (referred to as **Mom** in this document).

**The current phase is project inspection and documentation only. Application implementation requires the user's approval.** Do not change `pubspec.yaml`, install packages, configure Firebase, create a database, or implement application features during this phase.

This document records the user's requirements. Items described as possible, potential, future, or TBD are not approved implementation decisions. Architecture proposals, domain-model proposals, candidate services/packages, and unresolved decisions belong in [DECISIONS.md](DECISIONS.md).

## 2. Product purpose

Mom currently uses notebooks, handwritten calculations, receipts, and photos of receipts to run much of her business. MomBiz must simplify that workflow without requiring her to learn complicated accounting software.

The app's main purposes are to:

- Manage customers and record their purchases.
- Track customer debt and customer payments, including how each payment was made.
- Support Cambodian Riel (KHR) and US Dollars (USD).
- Generate and share receipts.
- Manage a special chick reservation queue.
- Back up business data in the cloud and restore it when Mom logs in on another phone.

The interface must be usable by a non-technical person.

## 3. Customers and buyers

### 3.1 Customer records

Each customer needs a permanent record. Customer identity must not depend only on the customer's name because different customers may have similar names.

Customer information should eventually support:

- Name.
- Phone number.
- Optional notes.
- Created date.
- A status such as active/archived, if useful; the need for this field and its exact values are **TBD**.

A customer may continue buying while already owing money. Debt can remain outstanding for weeks or months. Do not introduce an automatic purchase block based on existing debt.

A customer page should eventually show:

- Current outstanding debt.
- Sales history.
- Payment history.
- Chick reservation history.
- Receipts.
- Recent activity.

### 3.2 The buyer may be someone else

A customer may send a child or another family member to buy products. For example:

| Role | Example |
| --- | --- |
| Customer account responsible for debt | Dara |
| Person who came to the shop | Dara's son |

A sale should support a customer reference (`customerId`) and optional buyer information (`buyerName` or `buyerNote`). The buyer does not need a separate customer record. In the example, the debt belongs to Dara.

Whether sales without a customer account are allowed is **TBD**; the requirements do not define an anonymous or walk-in sale workflow.

## 4. Products

Mom must be able to create products herself. The product list mainly avoids repeatedly typing the same names. Products and categories must remain flexible rather than being hard-coded to the examples below.

Example products:

- Animal feed: chick feed, chicken feed, duck feed, pig feed, cow feed, and other animal feed.
- Other products: vaccine, medicine, vitamin, fertilizer, chicks, and other products.

Possible categories include Animal Feed, Medicine, Vaccine, Vitamin, Fertilizer, Chicks, and Other. Categories are optional in the requirements; their exact management and structure are **TBD**.

### 4.1 Mandatory sale-price rule

Product selling prices change frequently. A product record must not control historical sale prices.

For every sale item:

1. Mom selects the product name from the product list.
2. Mom manually enters the quantity.
3. Mom manually enters the unit price for that sale.
4. The saved sale item preserves the actual unit price used.

For example, 20 units of Chicken Feed sold at **56,000 KHR per unit** must remain priced at 56,000 KHR in that transaction even if tomorrow's price is **58,000 KHR per unit**. Changing a product later must never change old transactions.

A future version may suggest the last-used price, but must never automatically force it. This suggestion is not required for the first implementation.

## 5. Sales and orders

A customer can buy multiple products in one sale. The app calculates each line total and the overall sale total.

Example sale for Dara:

| Product | Quantity | Unit price | Line total |
| --- | ---: | ---: | ---: |
| Chicken Feed | 20 | 56,000 KHR | 1,120,000 KHR |
| Chick Feed | 20 | 56,000 KHR | 1,120,000 KHR |
| **Total before any discount** | | | **2,240,000 KHR** |

A sale should eventually support:

- Customer.
- Optional buyer name or note.
- Multiple sale items, each with a product, quantity, and manually entered unit price.
- Currency.
- Discount.
- Total.
- Actual sale date.
- Time the record was created in MomBiz.
- Notes.
- Status; the exact lifecycle is **TBD**.

The requirements do not establish whether a sale can contain items in different currencies. That question must be resolved with the mixed-currency model before implementation.

### 5.1 Actual sale date and entry date

These dates are distinct:

| Field | Meaning |
| --- | --- |
| `saleDate` | When the customer actually bought the products |
| `createdAt` | When the record was entered into MomBiz |

Mom may write a sale in her notebook and enter it later. For example, a customer buys on **September 12**, and Mom records it in MomBiz on **September 15**. Transaction history must still show September 12 as the sale date.

Do not assume `saleDate` and `createdAt` are equal. Exact date/time precision and timezone handling are **TBD**.

### 5.2 Discounts

Discounts are manually chosen by Mom. The app must not decide automatically who receives a discount or when one applies.

The app should allow a sale-level or otherwise appropriate manual discount. Possible forms are:

- A fixed amount.
- A percentage.

The final saved transaction must preserve the actual discount used. Discount placement, supported forms, validation, calculation order, and rounding are **TBD** and must not be invented during implementation.

## 6. Customer debt

Transaction history is the source of truth for customer debt. Do not make an editable single value called "customer debt" the source of truth.

Conceptually, for compatible currency amounts:

```text
Sales - Payments = Outstanding balance
```

Example:

```text
Previous outstanding: 1,000,000 KHR
New sale:             2,240,000 KHR
Payment:               -500,000 KHR
Remaining:            2,740,000 KHR
```

Requirements:

- Allow new purchases despite old unpaid debt.
- Support partial payments as a normal workflow.
- Preserve sufficient transaction history to explain how a balance arose.
- Exclude voided financial records from the balance according to the approved voiding model.

The conceptual formula does not authorize adding USD and KHR directly or choosing a conversion policy. Mixed-currency balances require a proposed model and explicit approval first.

Allocation of payments to individual sales, overpayments/customer credit, and migration of existing notebook debt are **TBD**; no rules for them have been supplied.

## 7. Payments

Customers may pay in full or partially. The currently required payment methods are:

- Cash.
- ABA QR.
- ACLEDA QR.
- Other.

These methods are recorded manually. V1 does not require automatic ABA or ACLEDA bank transaction detection.

Typical workflow:

1. The customer pays using cash, ABA, or ACLEDA.
2. Mom confirms that she received the money.
3. Mom manually records the payment in MomBiz.

A payment should eventually support:

- Customer.
- Amount.
- Currency.
- Payment method.
- Payment date.
- `createdAt`.
- Optional note.
- Exchange-rate snapshot when required.
- Status; exact values and transitions are **TBD**.

The payment date and entry timestamp must be available as separate information. The exact sale/payment relationship and whether one payment can use multiple methods are **TBD**.

## 8. Currency, exchange rates, and safe calculations

### 8.1 Currency support

KHR is the default currency in the user experience because it is used for most of the business. USD must also be supported.

Do not hard-code `1 USD = 4000 KHR`. The rate changes; for example, a rate may be 4052 KHR per USD on one day and different on another day.

When conversion is involved, the transaction must permanently preserve the exact exchange rate actually used. Old transactions must never be recalculated using today's rate.

A transaction should preserve:

- Original amount.
- Original currency.
- Exchange rate used, when applicable.
- Converted amount if required by the approved architecture.

**Before implementing mixed USD/KHR balances, propose a robust model and obtain the user's approval. Do not silently choose a financial architecture.**

### 8.2 Rate source and manual override

MomBiz may later retrieve an official National Bank of Cambodia (NBC) exchange rate. Automatic NBC integration is not required for the first implementation unless explicitly chosen later.

Requirements:

- The app must not depend completely on automatic rate retrieval.
- Mom must be able to manually set or override the rate.
- Historical transactions retain the rate actually used.

A potential interface is:

```text
Today's rate: 1 USD = XXXX KHR
Source: NBC / Manual
```

Mom may choose or edit the rate. This is a proposed UI concept, not a finalized screen design.

### 8.3 Financial representation approval gate

Do not use Dart `double` blindly for money or rely on unsafe floating-point assumptions.

Before implementing the financial calculation layer, propose and obtain approval for:

- A safe representation of amounts and currency precision.
- KHR representation; integer riel values are a likely candidate, not an approved choice.
- USD representation; integer cents or another safe fixed representation should be considered.
- An exchange-rate representation and conversion approach that avoids unexpected floating-point rounding.
- Rounding rules needed for conversion and discounts.

Prefer integer smallest units where appropriate. Exact representations and rounding policies remain **TBD** until approved.

## 9. Receipts

Mom currently writes receipts by hand. When a customer's child or family member buys without money, she may:

1. Write a receipt.
2. Take a photo.
3. Send the photo to the parent/customer.
4. Add the purchase to that customer's debt.

MomBiz should generate digital receipts and support sharing them through the Android share system, including Telegram, Messenger, WhatsApp, and other supported apps. A Telegram bot is not required for V1.

A receipt may show:

- Business/app name.
- Customer and buyer, if applicable.
- Date.
- Products, quantities, unit prices, and line totals.
- Discount and total.
- Amount paid and remaining balance.
- Payment method, if applicable.
- Currency and exchange rate when relevant.

Receipt layout, output format, and the meaning of "remaining balance" (for this sale or for the customer overall) are **TBD**.

Attaching a photo of an original handwritten receipt or notebook page is a possible later feature.

## 10. Chick reservation queue

### 10.1 Reservation workflow

Chick sales have a reservation workflow because availability is limited. They must not be treated exactly like ordinary product purchases.

Customers reserve chicks in advance. Earlier orders should generally be served earlier. Example queue:

| Date in queue example | Customer | Chicks |
| --- | --- | ---: |
| September 12 | Dara | 100 |
| September 17 | Nita | 105 |
| September 22 | Another customer | 100 |

The schedule progresses **approximately every five days**. This is a description of the existing workflow, not an approved fixed scheduling algorithm.

The handwritten queue can extend months into the future. For example, if the queue ends on **January 11, 2027**, a new reservation might be scheduled for **January 16, 2027**.

A reservation should eventually support:

- Customer.
- Number of chicks.
- Reservation date.
- Scheduled pickup/batch date.
- Queue position.
- Status.
- Notes.

Potential statuses are Scheduled, Picked up, Cancelled, and Rescheduled. **Do not finalize these statuses without reviewing the requirements.**

Exact scheduling, batch capacity, how many customers share a date, queue position behavior, exceptions to serving earlier orders first, and partial pickup behavior are **TBD**. Do not convert the example quantities or dates into fixed business rules.

### 10.2 Cancellation and moving another customer forward

If a customer cancels, Mom may replace that customer/date with the next waiting customer.

The app must not automatically move customers without confirmation. Possible future behavior:

1. Mom cancels a reservation.
2. MomBiz shows the next waiting customer.
3. Mom confirms the move.
4. That customer moves forward.

All date changes must remain understandable in the history. The exact selection and rescheduling model is **TBD**.

### 10.3 Pickup and sale creation

Mom should eventually be able to mark a reservation as picked up. A picked-up reservation may then become a normal sale.

Example:

1. Dara reserves 100 chicks.
2. Dara receives 100 chicks at pickup.
3. Mom enters the price per chick and an optional discount.
4. MomBiz creates the sale.
5. If Dara pays, Mom records a payment.
6. If Dara does not pay, the sale becomes part of Dara's debt.

Chick sales and ordinary sales must use the same accounting logic. Exact reservation-to-sale linking and pickup state transitions are **TBD**.

### 10.4 No inventory in V1

V1 does not require inventory or stock management for chicks or other products. Do not calculate remaining feed bags, vaccines, or chicks. Limited chick availability does not authorize building an inventory subsystem.

## 11. Cloud backup, authentication, and offline use

### 11.1 Cloud and recovery

MomBiz must not depend only on local storage. Data must be recoverable when a phone is lost, broken, reset, or the app is deleted.

Mom should be able to log in on another phone and recover her data.

Planned backend services:

- Firebase Authentication.
- Cloud Firestore.
- Firebase Storage later for images/receipts.

These are planned services, not authorization to set them up during the documentation phase. Authentication method, ownership structure, recovery verification, retention, and any additional backup mechanism are **TBD**.

### 11.2 Offline-friendly behavior

The app should remain useful during a temporary internet outage. Where practical, Mom should be able to continue working, and data should sync when connectivity returns.

Do not design the app so that a temporary internet outage makes it useless. Exact offline feature coverage, synchronization conflicts, and how pending or failed synchronization is communicated are **TBD**.

### 11.3 Accounts and data isolation

V1 can start with one primary Mom account. The architecture must leave room for future multiple-user support.

One user's data must not be exposed to another user. Firestore security rules are required before a backend implementation is considered ready. The ownership model and any future shared-business access rules must be decided before implementation.

## 12. Financial history and audit information

Avoid permanently deleting financial history. The preferred correction behavior is to void/cancel incorrect financial records while preserving what happened.

Example of a sale entered twice:

```text
Status: VOIDED
Reason: Duplicate entry
```

The voided record remains visible in history and does not contribute to the balance. The same principle may apply to payments.

**Before implementing sale/payment voiding, propose the exact model.** Statuses, permitted edits, correction workflow, effects on related payments/receipts/reservations, and how offline corrections synchronize are **TBD**. The overall implementation approval gate also applies.

Important records should eventually preserve timestamps such as:

- `createdAt`.
- `updatedAt`.
- Transaction date.
- `voidedAt`, where relevant.

More detailed audit information may be added later. V1 should remain understandable without preventing future audit improvements.

## 13. User experience

Design primarily for Mom, with:

- A very simple interface.
- Large tap targets.
- Large, readable amounts.
- Minimal typing.
- Clear buttons.
- Easy customer search and product search.
- A KHR-first experience.
- Familiar language instead of complicated accounting terminology.
- Clear confirmation dialogs.
- Useful error messages.
- Fast everyday workflows.

Khmer and English are potential future languages. Keep the architecture localization-friendly, but do not implement localization without an explicit request. Initial interface language is **TBD**.

### 13.1 Dashboard comes later

A future dashboard may show:

- Total outstanding customer debt.
- Number of customers with debt.
- Today's payments.
- Quick Add Sale.
- Quick Add Payment.
- Upcoming chick queue.

Do not build the dashboard until the underlying data model and features are stable. Dashboard totals involving multiple currencies depend on the approved financial model.

## 14. Scope

### 14.1 Planned V1 scope

The approximate V1 feature set is:

1. Authentication.
2. Customer management.
3. Product management.
4. Sale creation.
5. Multiple items per sale.
6. Manual unit prices.
7. Discounts.
8. Customer debt calculation.
9. Partial and full payments.
10. KHR and USD support.
11. Cash, ABA QR, ACLEDA QR, and Other payment methods.
12. Chick reservation queue.
13. Receipt generation.
14. Receipt sharing.
15. Firebase cloud sync.
16. Offline-friendly behavior.

The list describes planned scope; unresolved rules must still be approved before their implementation.

### 14.2 Not V1

Do not build these unless explicitly requested later:

- Full inventory management.
- Supplier management.
- Employee payroll.
- A full accounting system.
- Profit/loss accounting.
- Automatic ABA payment detection.
- Automatic ACLEDA payment detection.
- A Telegram bot.
- AI features.
- Complex analytics.
- Multi-branch management.

### 14.3 Other deferred or optional work

- Automatic NBC exchange-rate retrieval: not required for the first implementation unless explicitly selected later.
- Original receipt/notebook image attachments and Firebase Storage usage: later.
- Last-used price suggestions: possible future enhancement.
- Localization: only when explicitly requested.
- Detailed audit expansion: later if needed.
- Additional users: preserve architectural options; V1 may use one primary account.
- Dashboard: only after the data model and core features are stable.

## 15. Engineering requirements

- Separate UI, business logic, and data access clearly.
- Keep business logic out of widgets.
- Use strongly typed Dart models and null safety.
- Centralize error handling where appropriate and never silently swallow errors.
- Use consistent naming and reusable widgets when useful.
- Avoid premature abstraction and unnecessary packages.
- Keep business logic testable.
- Use Firebase responsibly, including user data isolation and security rules.
- Use safe financial representations and deliberate currency precision; do not use unsafe floating-point assumptions.
- Comment on business rules rather than obvious code.
- Keep the architecture understandable to a learning developer.

## 16. Decisions required before implementation

The following areas need explicit proposals or clarification; no implementation may begin before approval of the overall plan:

| Area | Decision required |
| --- | --- |
| Money | Amount representation, supported precision, discount arithmetic, and rounding; the financial calculation layer requires explicit approval. |
| Mixed USD/KHR balances | Balance model, conversion timing, cross-currency payments, and historical rate treatment; requires explicit approval. |
| Exchange rates | Exact rate representation, precision, source/override workflow, and conversion rounding. |
| Financial corrections | Sale/payment statuses, voiding/cancellation behavior, and effects on related records; propose the exact model first. |
| Chick queue | Scheduling and capacity rules, ordering, cancellation replacement, confirmed date changes, pickup behavior, and reviewed statuses. |
| Firebase ownership | Account/business ownership structure, authorization, and future multiple-user boundaries. |
| Other unspecified behavior | Required fields, quantity units/precision, customerless sales, payment allocation/credit, opening notebook debt, date handling, receipt semantics, and offline conflict handling remain TBD. |

See [DECISIONS.md](DECISIONS.md) for confirmed decisions, proposals, and the open-question register. Suggestions in that document do not become confirmed requirements until approved.
