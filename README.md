# Scoops Cash Flow

A local-first iPhone app for tracking paychecks and scoops (expenses), built with SwiftUI. The App Store name is Scoops and the in-app product name is Scoops Cash Flow. Open `MCF.xcodeproj` in Xcode and run the `MCF` target on an iOS 17 or newer simulator or device.

The ledger is stored as JSON in the app's Application Support directory. Amounts are stored in integer cents; the running balance, pay period totals, and category reports are derived from the ledger. Use Settings → Export ledger backup to create a JSON copy of the data.

## Included

- Opening balance setup and currency selection
- Running available cash with carry-forward pay periods
- Paycheck and additional income entry
- Scoop (expense) entry, editing, deletion, search, and category filtering
- Custom categories and reassignment when deleting a category
- Active and historical period reporting
- Category spending charts and local JSON export
- Optional Face ID, Touch ID, or device passcode app lock
- iPhone-only distribution target

No bank integrations or network services are used.
