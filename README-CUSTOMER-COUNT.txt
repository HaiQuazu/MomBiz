MomBiz v1.2 - Customer Count UI

Changed file:
lib/screens/customers/customers_screen.dart

Change:
- Adds a small count badge beside the Customers page title.
- Active tab shows the number of active customers.
- Archived tab shows the number of archived customers.
- The count updates automatically from the existing Firestore customer streams.
- No business logic, customer data, debt calculation, payments, sales, or navigation logic changed.

After replacing the file, run:
flutter analyze
