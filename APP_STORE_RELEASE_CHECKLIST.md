# App Store Release Checklist

## Completed in this update

- [x] Record balance corrections as signed, dated ledger events instead of editing the opening balance.
- [x] Include adjustments in the running available cash and date-based historical cash calculations.
- [x] Keep adjustments out of pay-period income and expense totals.
- [x] Allow adjustments to be edited and deleted from transaction history.
- [x] Protect the on-device ledger and generated backup file with iOS Complete Data Protection.
- [x] Add an in-app privacy policy screen and a Delete all local data action.
- [x] Add a 1024 × 1024 app icon to the asset catalog.
- [x] Add optional Face ID/device-passcode app lock using Apple LocalAuthentication.
- [x] Limit the app target to iPhone.
- [x] Add the planned support email to the in-app and draft privacy policies.
- [ ] Rebuild and run the app in local Xcode after these changes. This environment currently cannot access a Simulator runtime to finish asset catalog compilation.

## Still needed before submission

- [ ] Ask Apple Developer Support whether Apple’s financial-app rule applies to this offline personal ledger. App Review Guideline 3.2.1(viii) mentions money-management apps.
- [x] Purchase Apple Developer Program membership (reported by user); confirm enrollment is active in App Store Connect.
- [x] Set the Bundle ID to the user-provided `com.mcf.scoops`.
- [x] Choose the public name Scoops and in-app brand Scoops Cash Flow.
- [ ] Confirm the seller name shown in the active developer account.
- [ ] Confirm the support email is monitored and keep the contact details current.
- [x] Add the provided public privacy-policy and support URLs to the draft metadata and in-app privacy screen.
- [ ] Confirm both public pages load and contain the current policy/contact details; enter their URLs in App Store Connect.
- [ ] Test Face ID/passcode lock behavior on a real iPhone and in a simulator.
- [ ] Test the complete ledger flows on supported iOS versions and devices, including persistence, adjustments, period boundaries, edit/delete, negative balances, and backup export.
- [ ] Run TestFlight with external testers and fix the issues they find.
- [ ] Complete App Store Connect privacy, age-rating, encryption/export-compliance, availability, pricing, screenshot, and metadata fields.
- [ ] Submit a release build to App Review and explain the app’s offline, manual record-keeping behavior in the review notes.
