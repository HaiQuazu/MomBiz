MomBiz v1.2 — Logic Safety Fix
==============================

Apply this patch ON TOP OF the working Quick Create + analyzer-fixed version.
Copy the included lib/ files into the matching D:\mombiz\lib\ paths.

What this fixes
---------------
1. Chick Queue pickup is now atomic:
   - the sale is created AND the reservation is marked Picked Up in one Firestore transaction
   - if the transaction fails, neither change is committed
   - prevents the old "sale saved but reservation still waiting" duplicate-sale risk

2. Archived customer consistency:
   - an existing chick reservation can still load its original customer even if that customer was archived later
   - Queue -> Create Sale can still preselect that archived reservation customer to finish the old reservation
   - normal New Sale is disabled on an archived customer's details page
   - payments are not disabled, so an archived customer can still pay existing debt

3. Product archive/restore is now usable:
   - Edit Product has Archive product / Restore product
   - archived products disappear from active pickers but existing sale snapshots/receipts remain unchanged

4. Money validation is safer:
   - KHR input must be whole riel (no silent decimal rounding)
   - a non-empty invalid discount is rejected instead of silently becoming 0

Important
---------
- No new packages.
- No Firestore collection/schema migration.
- Existing quick-create behavior is preserved.
- Existing product photos are preserved.
- This patch does NOT modify payment_form_screen.dart because that file was not provided in the uploaded project files.

After replacing files
---------------------
Run:
  flutter analyze

Target:
  No issues found!

Then hot restart with:
  R

Quick tests
-----------
A. Chick Queue -> Picked Up -> Create Sale -> Save -> close receipt
   Expected: one sale, reservation becomes Picked Up.

B. Archive a customer who already has a waiting chick reservation
   Expected: reservation can still be edited and fulfilled.
   Archived Customer Details: New Sale should be disabled.

C. Edit Product
   Expected: Archive product works; switch Products to Archived; Restore product works.

D. KHR fields
   Expected: whole values such as 5000 work. Decimal KHR such as 5000.5 is rejected when saving.
