# Flytt - Multi-Service Ride & Delivery Platform

Flytt is a comprehensive Flutter-based mobile application that provides ride-hailing, package delivery, and two-wheel vehicle rental services. Built with modern architecture and real-time features, Flytt offers a seamless experience for passengers and drivers alike.

## Features

### 🚗 Ride Services
- **Real-time ride booking** with live driver tracking
- **Multiple vehicle types**: Standard cars, luxury vehicles, and shared rides
- **Smart pricing** with dynamic surge pricing based on demand
- **Route optimization** using Google Maps integration
- **Scheduled rides** for future bookings
- **Ride history** and receipts

### 📦 Package Delivery
- **Multi-stop deliveries** with optimized routing
- **Package size options**: Small, Medium, Large, Extra Large
- **Weight and dimension-based pricing**
- **Real-time package tracking**
- **Delivery proof** with signatures and photos
- **Scheduled pickups**

### 🛴 Two-Wheel Rentals
- **E-scooter and E-bike rentals**
- **Hourly pricing** with transparent rates
- **Battery level indicators**
- **Vehicle clustering** on map for easy discovery
- **Owner ratings and reviews**
- **Direct messaging** with vehicle owners

### 💳 Payment & Pricing
- **Multiple payment methods**: Cash, Credit/Card
- **Country-specific pricing** (Tunisia, France, Switzerland, Germany, USA)
- **Night-time surcharges** (10 PM - 6 AM)
- **Dynamic surge pricing** during peak hours
- **Saved payment cards** for quick checkout
- **Promotional codes** and discounts

### 🌍 Localization
- **Multi-language support**: English, French, Arabic
- **Auto-detection** of user location and language
- **RTL support** for Arabic
- **Country-specific currency** display

### 👤 User Features
- **Email/password authentication** via Supabase
- **Profile management** with phone number and personal info
- **Saved locations** (Home, Work, Favorites)
- **Ride preferences** and settings
- **Rating system** for drivers and passengers
- **In-app notifications**

## Tech Stack

### Frontend
- **Flutter** - Cross-platform mobile framework
- **Dart** - Programming language
- **Provider** - State management
- **Google Maps Flutter** - Maps and location services

### Backend & Services
- **Supabase** - Backend as a Service (Authentication, Database, Real-time)
- **PostgreSQL** - Database with Row Level Security (RLS)
- **Google Maps API** - Geocoding, Directions, Places
- **Google Polyline Algorithm** - Route encoding/decoding

### Key Packages
```yaml
dependencies:
  flutter: sdk: flutter
  supabase_flutter: ^2.9.1
  google_maps_flutter: ^2.10.0
  geolocator: ^13.0.2
  provider: ^6.1.2
  http: ^1.2.2
  shared_preferences: ^2.3.4
  google_polyline_algorithm: ^3.1.0
  phone_numbers_parser: ^8.3.0
  flutter_contacts: ^1.1.9+2
```

## Project Structure

```
lib/
├── auth/                      # Authentication screens
│   ├── splash_screen.dart
│   ├── onboarding_screen.dart
│   ├── language_screen.dart
│   ├── signup_screen.dart
│   └── personal_info_screen.dart
├── passenger/                 # Passenger-specific features
│   ├── passenger_home_screen.dart
│   ├── find_rides_screen.dart
│   ├── ride_selection_screen.dart
│   ├── ride_in_progress_screen.dart
│   ├── new_reservation_screen.dart
│   └── saved_location_screen.dart
├── Package/                   # Delivery features
│   ├── package_creation_screen.dart
│   └── delivery_map_full_screen.dart
├── settings/                  # App settings
│   └── pricing_comparison_screen.dart
└── utils/                     # Utilities and helpers
    ├── theme_provider.dart
    ├── app_localizations.dart
    ├── pricing_utils.dart
    ├── surge_pricing_service.dart
    └── shared_preferences_util.dart
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode
- Google Maps API Key
- Supabase Account

### Installation

1. **Clone the repository**
```bash
git clone <repository-url>
cd flytt
```

2. **Install dependencies**
```bash
flutter pub get
```

3. **Configure Google Maps API**
   - Get an API key from [Google Cloud Console](https://console.cloud.google.com/)
   - Enable: Maps SDK, Directions API, Places API, Geocoding API
   - Add the key to:
     - `android/app/src/main/AndroidManifest.xml`
     - `ios/Runner/AppDelegate.swift`
     - `web/index.html`

4. **Configure Supabase**
   - Create a project at [Supabase](https://supabase.com/)
   - Update `lib/main.dart` with your Supabase URL and anon key:
   ```dart
   const supabaseUrl = 'YOUR_SUPABASE_URL';
   const anonKey = 'YOUR_SUPABASE_ANON_KEY';
   ```

5. **Setup Database**
   - Run the SQL scripts in order:
     - `schema.sql` - Database schema
     - `complete_fix.sql` - RLS policies
     - `auto_confirm_emails.sql` - Email auto-confirmation

6. **Run the app**
```bash
flutter run
```

### Build for Production

**Android:**
```bash
flutter build apk --release
```

**iOS:**
```bash
flutter build ios --release
```

## Database Schema

### Main Tables
- **passenger** - User profiles and information
- **payment_cards** - Saved payment methods
- **saved_locations** - User's favorite places
- **rides** - Ride bookings and history
- **packages** - Delivery orders

### Security
- Row Level Security (RLS) enabled on all tables
- User-specific data access policies
- Secure authentication via Supabase Auth

## Configuration

### Pricing Configuration
Edit `lib/utils/pricing_utils.dart` to adjust:
- Base fares per country
- Per-kilometer rates
- Per-minute rates
- Night surcharges
- Minimum fares

### Surge Pricing
Configure in `lib/utils/surge_pricing_service.dart`:
- Peak hours definition
- Surge multipliers
- High-demand zones

## Localization

Add new languages by:
1. Creating translation files in `lib/utils/app_localizations.dart`
2. Adding language codes to supported locales in `lib/main.dart`
3. Updating language selection in `lib/auth/language_screen.dart`

## API Keys Required

- **Google Maps API Key** - For maps, geocoding, and directions
- **Supabase URL & Anon Key** - For backend services

## Known Issues & Solutions

### Build Issues
- If you encounter Kotlin cache errors, run: `flutter clean`
- For Gradle issues, ensure Android Gradle Plugin is 8.7.3+

### Location Permissions
- Ensure location permissions are granted in device settings
- Check `AndroidManifest.xml` and `Info.plist` for proper permission declarations

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support, email support@flytt.app or open an issue in the repository.

## Roadmap

- [ ] Driver app integration
- [ ] In-app chat system
- [ ] Advanced analytics dashboard
- [ ] Loyalty rewards program
- [ ] Corporate accounts
- [ ] Multi-city expansion
- [ ] Electric vehicle charging station finder
- [ ] Carbon footprint tracking

---

**Version:** 1.0.0  
**Last Updated:** November 2025  
**Platform:** iOS, Android, Web
