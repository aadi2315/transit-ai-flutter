# 🚆 Transit AI — Multimodal Smart Transit & Contactless Ticketing

> An ultra-premium, visionOS-inspired Flutter transit application engineered for smart cities with multimodal route discovery, offline-resilient dynamic QR passes, live TOTP anti-fraud verification, and unified UPI fare checkout.

---

## ✨ Key Features

- **Dynamic Interactive Route Search**:
  - Full keyboard typing with instant place autocomplete & suggestion chips.
  - GPS-assisted origin detection and quick swap (`⇅`).
  - Multimodal connection details (BRTS, Metro, Feeder, Walk intervals).

- **Offline-Resilient Dynamic QR Ticketing**:
  - AES-256 authenticated GTFS payload tokens (`TKN-AMD-9987-OFFLINE`).
  - Real-time rotating Anti-Fraud TOTP countdown timer.
  - Turnstile & digital receipt collapsible accordion.

- **Unified UPI Fare Checkout**:
  - Instant one-tap UPI payment gateway integration (`GPay`, `PhonePe`, `Paytm`).
  - Fare breakdown with live corridor discount calculations.

- **Google Maps Integration Ready**:
  - Modular configuration via `TransitMapConfig.googleMapsApiKey`.
  - Seamless toggle between step-by-step Route Legs and interactive Explore Map.

- **VisionOS Glassmorphic UI & Dynamic Theming**:
  - High-definition unblurred GIFT City aerial wallpapers with adaptive lighting.
  - Dual-mode support: Deep Space Dark Mode & Crystal Radiant Light Mode.
  - Tactile micro-animations and frosted glass cards (`BackdropFilter`).

- **Secure Auth & Account Management**:
  - Distinct Login and Sign Up flows with password strength indicator.
  - Standalone top bar navigation with persistent back history.

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.x or later)
- Dart SDK (3.x or later)
- Chrome / Edge (for Web) or Android Studio (for Android)

### Run Locally (Web)
```bash
flutter pub get
flutter run -d web-server --web-port=8080 --web-hostname=localhost
```

### Run Tests
```bash
flutter test
```

### Analyze Codebase
```bash
flutter analyze
```

---

## 🛠️ Tech Stack
- **Framework**: Flutter / Dart
- **Typography**: Google Fonts (Space Grotesk, Plus Jakarta Sans, JetBrains Mono)
- **Icons**: Material Icons & Phosphor icons
- **State Management**: Reactive ValueNotifiers & ChangeNotifiers

