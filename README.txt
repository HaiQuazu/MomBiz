MomBiz v1.2 UI polish

Replace:
  lib/screens/customers/customer_details_screen.dart
  lib/screens/sales/sale_form_screen.dart

Changes only:
1. Customer Details edit action is inset 8 px from the right edge.
2. New Sale -> Products picker product photo is enlarged:
   44x44 -> 52x52
   radius 14 -> 16
3. The small selected-product thumbnail inside the input remains 28x28.
4. No business logic changes.
5. Queue auto-fill and free local product pictures are preserved.

After replacing:
  flutter analyze

Then hot reload:
  r

If the currently open route does not visibly refresh, use:
  R
