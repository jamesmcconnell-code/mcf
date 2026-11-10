# Scoops App Store Metadata — Draft

Use this as a starting point in App Store Connect. Confirm the app name is available, verify every claim against the release build, and adjust the copy before submitting.

## Product page

**Name:** Scoops  
**Subtitle:** Paychecks, scoops & cash flow  
**Promotional text:** Make every paycheck go a little further. Track available cash, record each scoop, and see what carries forward.

**Description:**

Your paycheck is the start. Each expense is a scoop out of the cash you have available.

Scoops Cash Flow helps you record income and spending, see what remains in your current pay period, and keep track of cash that carries forward. Pay periods are yours to start whenever you choose—your available cash never resets automatically.

With Scoops, you can:

- Set an opening balance and choose a currency
- Record paychecks and additional income
- Add, edit, categorize, backdate, or delete scoops
- See running available cash and current-period totals
- Review past pay periods and spending by category
- Export a JSON ledger backup
- Optionally lock the app with Face ID, Touch ID, or your device passcode

Your ledger is stored on your device. Scoops does not connect to banks or send your financial data to a developer or third-party server.

Scoops is a personal record-keeping tool. It does not provide financial, tax, investment, or legal advice.

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
