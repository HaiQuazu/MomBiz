MomBiz v1.2 — Full Riel display patch

Replace:
  lib/utils/money_utils.dart

What changes:
- KHR amounts formatted by MoneyUtils now show the full Khmer word "រៀល"
  instead of the symbol "៛".
- Example: 507,700៛ -> 507,700 រៀល
- Parsing still accepts old values/symbols, so existing data is safe.
- USD parsing/storage support is preserved internally.

After replacing, run:
  flutter analyze

Then hot restart (R) and check receipt, sale totals, payment summary,
customer balance, dashboard debt, and activity amounts.
