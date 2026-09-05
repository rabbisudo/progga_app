# প্রজ্ঞা (Progga) - Mobile Client 📱

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

**প্রজ্ঞা (Progga)** হলো বাংলাদেশের এইচএসসি, বিশ্ববিদ্যালয় ভর্তি ও বিসিএস/চাকরি প্রার্থীদের জন্য একটি আধুনিক, প্রিমিয়াম ও ইন্টেলিজেন্ট MCQ এক্সাম ও একাডেমি প্রিপারেশন প্ল্যাটফর্ম।

---

## ✨ ফিচারসমূহ (Key Features)

- 📝 **লাইভ ও প্র্যাকটিস এক্সাম**: বিষয় ও অধ্যায়ভিত্তিক রিয়েল-টাইম MCQ পরীক্ষা।
- 🔄 **স্পেসড রিপিটেশন (Spaced Repetition)**: কঠিন ও ভুল হওয়া প্রশ্নগুলোর স্বয়ংক্রিয় রিভিশন ট্র্যাকার।
- 🏆 **লিডারবোর্ড ও অ্যানালিটিক্স**: বিস্তারিত পারফরম্যান্স অ্যানালাইসিস এবং লাইভ র‍্যাংকিং।
- 🔔 **ইন-অ্যাপ আপডেট নোটিফিকেশন**: স্বয়ংক্রিয় ভার্সন চেক ও আপগ্রেড ডিরেকশন।
- 🌗 **ডার্ক ও লাইট মোড**: আধুনিক ও চোখের জন্য আরামদায়ক কালার স্কিম।
- 🔐 **নিরাপদ অ্যাথেন্টিকেশন**: Google Sign-In এবং সিকিউর ক্রেডেনশিয়াল স্টোরেজ।

---

## 🛠️ টেকনোলজি স্ট্যাক (Tech Stack)

- **Framework:** [Flutter](https://flutter.dev) (Dart 3.x)
- **State Management:** [Riverpod 2.x](https://riverpod.dev) (Annotations + Generator)
- **Navigation:** [GoRouter](https://pub.dev/packages/go_router)
- **Networking:** [Dio](https://pub.dev/packages/dio) with Interceptors & JWT Token Handling
- **Local Storage:** [Hive](https://pub.dev/packages/hive) & [FlutterSecureStorage](https://pub.dev/packages/flutter_secure_storage)
- **Push Notification:** Firebase Cloud Messaging (FCM)

---

## 🚀 রান ও বিল্ড গাইড (Run & Build)

### ১. ডিপেনডেন্সি ইনস্টল:
```bash
flutter pub get
```

### ২. ডেভেলপমেন্ট মোডে রান:
```bash
flutter run
```

### ৩. প্রোডাকশন রিলিজ বিল্ড (App Bundle for Play Store):
```bash
flutter clean
flutter pub get
flutter build appbundle --release
```

---

## 📄 লাইসেন্স (License)

This project is licensed under the [MIT License](LICENSE).
