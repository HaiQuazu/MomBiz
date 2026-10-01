MomBiz v1.1 - Change Chick Product setting

Adds a proper setting so Mom can change which product is used by:
Queue -> Picked Up / Create Sale

Replace:
- lib/screens/home/home_screen.dart

Add:
- lib/screens/settings/chick_product_screen.dart

No Firestore migration.
No Firebase Storage.
No paid service.

The current chick product ID is still stored in SharedPreferences through
AppSettingsService, and Queue auto-fill continues to use it.

After replacing:
  flutter analyze

Then hot restart:
  R

Test:
More -> Chick product -> choose Chicks -> Use for chick queue
Then:
Queue -> Picked Up / Create Sale
