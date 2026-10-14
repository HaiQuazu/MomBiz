MomBiz v1.2 - Existing Customer Debt / Opening Balance

Purpose
-------
This patch lets Mom add debt that existed before MomBiz was introduced.

Example:
Customer already owed 100,000 KHR before MomBiz.
Edit/create the customer -> Existing debt before MomBiz -> enter 100000 KHR.
MomBiz then treats the customer's debt as:

previous debt + active MomBiz sales - active payments

Important behavior
------------------
- Previous debt is NOT recorded as a new sale.
- It does NOT increase Today's Sales or monthly sales.
- It DOES increase the customer's outstanding debt.
- Normal Record Payment can reduce it because Customer Details passes the
  full outstanding balance to the existing payment flow.
- KHR and USD remain separate.
- Existing customers without these Firestore fields automatically use 0.
- Customer list, Customer Details, Dashboard and Business Insights all include it.
- Quick Create and prior safety fixes are preserved in the replacement files.
- No new Firestore collection is created.

Files
-----
lib/models/customer.dart
lib/services/customer_service.dart
lib/services/business_insights_service.dart
lib/screens/customers/customer_form_screen.dart
lib/screens/customers/customer_details_screen.dart
lib/screens/customers/customers_screen.dart
lib/screens/home/dashboard_screen.dart

After replacement
-----------------
flutter analyze

Target:
No issues found!

Then test:
1. Create/Edit a customer and set old debt to 100000 KHR.
2. Customer list shows 100,000 KHR debt.
3. Customer Details shows 100,000 KHR.
4. Dashboard outstanding debt increases by 100,000 KHR.
5. Business Insights outstanding debt/customer count includes the customer.
6. Record a payment for that customer and confirm the debt decreases.
7. Today's Sales must NOT increase because old debt is not a sale.
