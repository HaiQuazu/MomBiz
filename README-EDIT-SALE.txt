MomBiz v1.2 - Edit Saved Sale / Price Correction

PURPOSE
-------
Allows Mom to correct the price of a sale after it has already been saved.
Example: product default price is 58,000 riel, but the special customer price
was 57,000 riel and Mom forgot to change it before saving.

WHAT CHANGED
------------
1. Receipt now has an Edit sale button for active KHR sales.
2. Edit Sale reuses the existing sale form and preloads:
   - customer
   - sale date
   - products
   - quantities
   - saved sale prices
   - discount
   - note
3. Customer, products and quantities are locked while correcting an existing
   sale. This keeps customer history and Chick Queue pickup history safe.
4. Price each remains editable. Discount, date and note also remain editable.
5. Save changes updates the SAME Firestore sale document. It does not create a
   duplicate sale.
6. Product default price is never changed by editing a sale.
7. Receipt reloads immediately after saving so the corrected total is shown.
8. Dashboard, customer debt, reports and Business Insights update naturally
   because they already watch the sale data.
9. Safety check: lowering a sale is blocked if it would make the customer's
   active payments greater than their total debt. MomBiz does not currently
   support negative customer credit.
10. Old USD sales remain readable, but Edit Sale is intentionally offered only
    for KHR sales because the current normal MomBiz workflow is Riel-only.

FILES
-----
lib/services/sale_service.dart
lib/screens/sales/sale_form_screen.dart
lib/screens/receipts/sale_receipt_screen.dart

TEST
----
1. flutter analyze
2. Open an existing receipt (KHR).
3. Tap Edit sale.
4. Confirm customer/product/quantity are locked.
5. Change 58,000 to 57,000.
6. Save changes.
7. Receipt should refresh to 57,000.
8. Customer outstanding debt should decrease by 1,000.
9. Product default price should still be 58,000.
10. Reopen the same receipt and confirm there is only one sale record.
11. If the customer has already paid enough that lowering the sale would create
    a negative balance, MomBiz should block the correction with a clear message.
