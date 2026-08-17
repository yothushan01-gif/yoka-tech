# YOKA TECH PRO v4 — Advanced Shop App

This version adds the project dependencies and structure for the requested production features.

## Added feature modules
- 🔐 Owner / Cashier / Technician role-ready login architecture
- 📄 PDF invoice generation / printing dependencies
- 📷 Barcode & QR camera scanning dependency
- 💾 Persistent local stock, sales, repairs and expenses
- 📊 Daily / monthly / yearly sales-ready data
- 💰 Automatic stock deduction and profit calculation
- 🔧 Repair advance / balance tracking
- ☁️ Cloud-backup integration point

## Important setup for cloud + WhatsApp
Real cloud sync and WhatsApp sending require YOUR Firebase project credentials and your preferred WhatsApp provider/account. Those credentials must not be hard-coded into a public project. After adding Firebase configuration, enable Authentication + Firestore (or another database) and configure backups.

## Build
Install Flutter + Android Studio, then:
flutter pub get
flutter build apk --release

APK:
build/app/outputs/flutter-apk/app-release.apk

## Phone-only note
A phone cannot simply install the ZIP. The Flutter project must be compiled by a Flutter/Android build environment (computer or cloud build service) first.

## Security
Before real shop deployment, add Firebase authentication, role-based Firestore security rules, secure backup, and proper invoice/business settings.
