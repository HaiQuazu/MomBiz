MomBiz v1.2 — Quick Create patch + analyzer fix

This package contains the full replacement files from the Quick Create patch, with the 6 use_build_context_synchronously analyzer infos corrected.

Behavior kept:
- Add customer directly from customer pickers.
- Add product directly from product pickers.
- Return and select the newly created item automatically.

Analyzer-safety change:
- sheetContext is now checked with sheetContext.mounted after async gaps before it is used.
- Existing State mounted checks are preserved.

After replacing the files, run:
  flutter analyze

Expected target:
  No issues found!
