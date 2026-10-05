MomBiz v1.2 — Products screen revised

Replace:
  lib/screens/products/products_screen.dart

Changes:
- Restores the old floating Add Product button (easier access).
- Removes the large Add Product card from above the list.
- Products move back up into that space.
- Main product thumbnails stay larger at 52x52.
- Thumbnail corner radius is 16.
- Fallback icon is slightly larger.
- No business logic changes.

After replacing:
  flutter analyze

Then:
  r

If needed:
  R
