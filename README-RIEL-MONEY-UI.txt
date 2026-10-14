MomBiz v1.2 - Riel Money UI update

What changed
- Riel money fields add thousands separators while Mom types.
  Example: 100000 -> 100,000
- New sale price and discount entry are riel-only in the normal UI.
- Product default price entry is riel-only in the normal UI.
- Existing customer debt entry is riel-only in the normal UI.
- Important money-entry fields use the word "រៀល" instead of the symbol "៛".
- The USD/KHR Exchange Rate card is hidden from More because Mom uses riel only.
- USD support remains in the data model for backward compatibility and legacy records.
- Existing legacy USD product data is preserved unless a new riel price is entered.
- Khmer full-stop character "។" was removed from available app/localization text.
- Stored money values are unchanged: commas are display/input formatting only.

Important
- payment_form_screen.dart was not available in the uploaded project files, so this patch does not change the Record Payment amount field. Do not replace that screen with guessed code.

After copying the files into D:\mombiz run:
  flutter analyze

Target:
  No issues found!

Then hot restart the app and test:
1. Add/Edit Product: typing 100000 shows 100,000 and "រៀល".
2. New Sale: product price and discount format with commas; currency is Riel only.
3. Add/Edit Customer: old debt typing 100000 shows 100,000 and "រៀល".
4. Existing sales/debts still calculate exactly as before.
5. More screen no longer shows the Exchange Rate card.
