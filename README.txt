MomBiz — Dashboard Today cards tappable

Replace only:
  lib/screens/home/dashboard_screen.dart

Changes only:
- Tap Sales today -> opens TodaySalesScreen
- Tap Received today -> opens TodayPaymentsScreen
- Small right arrow added to both Today cards
- Quick Actions unchanged
- Recent Activity unchanged
- Dashboard calculations unchanged
- No other UI/business logic changed

Expected existing report files:
  lib/screens/reports/today_sales_screen.dart
  lib/screens/reports/today_payments_screen.dart

After replacing:
  flutter analyze

Then:
  r
