# App Privacy answers (App Store Connect) — draft

App Store Connect → the app → App Privacy → Get Started. Answers match the app's privacy manifest
(`ios/Runner/PrivacyInfo.xcprivacy`) and what the app stores (BRD; Law 151/2020 review pending).

**Do you or your third-party partners collect data from this app?** Yes.

| Data type (Apple) | Collected | Linked to the user | Used for tracking | Purposes | What it is |
|---|---|---|---|---|---|
| Contact Info → Name | Yes | Yes | No | App Functionality | The guardian's name; the children's names |
| Contact Info → Phone Number | Yes | Yes | No | App Functionality | Sign-in number (Firebase phone auth), contact for bookings |
| Health & Fitness → Health | Yes | Yes | No | App Functionality | Children's weight, length, head circumference, vaccine doses, visits, allergies (entered by the clinic or the guardian) |
| Other Data → Other Data Types | Yes | Yes | No | App Functionality | Children's birth date and sex; bookings; consent records |
| Identifiers → User ID | Yes | Yes | No | App Functionality | Firebase account id |
| Diagnostics | No | — | — | — | No crash or analytics SDK in this build |
| Location, Contacts, Photos, Browsing, Search, Purchases, Financial, Usage Data | No | — | — | — | Not collected |

- **Tracking:** No. No ads, no ad SDKs, no data shared with data brokers.
- **Payments:** none in the app (cash at the clinic).
- **Data deletion:** in the app, «حسابي» → «حذف الحساب» deletes the account; the clinic keeps the
  medical record for the period the legal review sets (BRD D-32).
- **Data location:** Firebase (Google Cloud), Firestore in me-central1 (Doha) (BRD D-53).
- **Children:** the users are parents/guardians (18+); children's data is entered by them or by the
  clinic. Not a "Made for Kids" app.
