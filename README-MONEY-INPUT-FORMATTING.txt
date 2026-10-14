MomBiz v1.2 — Riel money input formatting scan/fix

What was scanned:
- Product default price
- Customer existing/opening debt
- New Sale item price
- New Sale discount
- Record Payment amount received
- Shared KHR display formatting

Result:
- Product price already uses RielInputFormatter.
- Customer old debt already uses RielInputFormatter.
- Sale item price already uses RielInputFormatter.
- Sale discount already uses RielInputFormatter.
- Record Payment was the missing money-entry field; it now uses RielInputFormatter for KHR.

Behavior:
1000 -> 1,000
10000 -> 10,000
100000 -> 100,000
1000000 -> 1,000,000

The commas are display/input formatting only. Firestore still receives the same whole-r­iel integer value.
The payment form shows រៀល for KHR. USD payment choice is only surfaced when the customer actually has a USD outstanding balance; existing USD support is not deleted.

Also included:
- corrected riel_input_formatter.dart without the unnecessary cast lint
- shared MoneyUtils display using the full word រៀល
- payment example hint updated from 100000 to 100,000
