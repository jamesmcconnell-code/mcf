# Scoops App Store Metadata — Draft

Use this as a starting point in App Store Connect. Confirm the app name is available, verify every claim against the release build, and adjust the copy before submitting.

## Product page

**Name:** Scoops  
**Subtitle:** Paychecks, scoops & cash flow  
**Promotional text:** Make every paycheck go a little further. Track available cash, record each scoop, and see what carries forward.

**Description:**

Scoops Cash Flow is a manual ledger for keeping a running tally of the income and expenses you enter. Start with an opening balance, record paychecks and other income, and log each expense as a scoop.

See the balance calculated from your entries, review totals for a pay period, and look back at past periods and spending by category. Pay periods start when you choose; Scoops does not connect to a bank or automatically import or verify transactions.

With Scoops, you can:

- Set an opening balance and choose a currency
- Record paychecks and other income
- Add, edit, categorize, backdate, or delete expense entries (“scoops”)
- Record a dated balance adjustment
- View the running balance and pay-period totals based on your entries
- Review past pay periods and spending by category
- Export a JSON ledger backup
- Optionally lock the app with Face ID, Touch ID, or your device passcode

Your ledger is stored on your device. Scoops does not connect to financial accounts or send your ledger to the developer or a third-party server. If you export a backup, you choose where it is saved or shared.

Scoops is a manual record-keeping and arithmetic tool. It does not provide financial, tax, investment, or legal advice, or recommend financial decisions.

**Keywords:** budget,expenses,spending,paycheck,cash,balance,ledger,tracker

## App Review notes draft

Scoops is an offline, manually entered cash-flow ledger. It has no account sign-in, bank connection, payment or money-transfer feature, lending, investing, or financial advice. No demo credentials are required.

To review the main flow:

1. On first launch, enter an opening cash balance and tap **Get started**.
2. On Overview, start a pay period and enter a paycheck.
3. Tap **Add a scoop**, choose a category, and save an amount.
4. Open **Periods** to review the period, or **Scoops** to review category spending.
5. In **Settings**, review the privacy information, export a backup, or enable the optional app lock.

The app lock uses Apple LocalAuthentication. If testing in Simulator, Face ID/passcode behavior may depend on the simulator’s authentication setup. The core ledger flow does not require app lock.

## Details still needed in App Store Connect

- Privacy-policy URL: https://main--scoops--jamesmcconnell-code.aem.live/#privacy-policy
- Support URL: https://main--scoops--jamesmcconnell-code.aem.live/#support
- Seller/contact details from the active developer account
- App Store screenshots captured from the release build
- App category, age-rating answers, privacy declarations, and export-compliance answers
- App availability and Free price setting
- App Review classification response for Guideline 3.2.1(viii)
