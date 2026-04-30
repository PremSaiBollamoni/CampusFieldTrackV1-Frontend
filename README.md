# 📍 Campus FieldTrack - Flutter Frontend

<div align="center">

<img src="https://readme-typing-svg.demolab.com?font=Fira+Code&size=32&duration=2800&pause=2000&color=3B82F6&center=true&vCenter=true&width=940&lines=Real-time+GPS+Tracking+%F0%9F%93%8D;Intelligent+Stop+Detection+%F0%9F%8E%AF;Beautiful+Analytics+%F0%9F%93%8A;Export+to+GPX%2FCSV%2FJSON+%F0%9F%92%BE" alt="Typing SVG" />

<br/>
<br/>

![Flutter](https://img.shields.io/badge/Flutter-3.41.8-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-NDK_27-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

<br/>

**🚀 Real-time GPS tracking app for field sessions with intelligent stop detection and comprehensive analytics**

<br/>

[![GitHub Stars](https://img.shields.io/github/stars/PremSaiBollamoni/CampusFieldTrackV1-Frontend?style=social)](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend/stargazers)
[![GitHub Forks](https://img.shields.io/github/forks/PremSaiBollamoni/CampusFieldTrackV1-Frontend?style=social)](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend/network/members)
[![GitHub Issues](https://img.shields.io/github/issues/PremSaiBollamoni/CampusFieldTrackV1-Frontend)](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend/issues)

<br/>

[Features](#-features) • [Installation](#-installation) • [Architecture](#-architecture) • [API Integration](#-api-integration) • [Configuration](#-configuration)

</div>

---

<div align="center">

## 🎯 **What Makes This Special?**

</div>

<table>
<tr>
<td width="33%" align="center">
<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/World%20Map.png" width="80" />
<h3>🗺️ Live Tracking</h3>
<p>Google Maps-style camera with smooth following and forward offset positioning</p>
</td>
<td width="33%" align="center">
<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Bullseye.png" width="80" />
<h3>🎯 Smart Detection</h3>
<p>Intelligent stop detection with GPS jitter tolerance and auto-merging</p>
</td>
<td width="33%" align="center">
<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Objects/Chart%20Increasing.png" width="80" />
<h3>📊 Analytics</h3>
<p>Beautiful charts and comprehensive session statistics</p>
</td>
</tr>
</table>

---

## ✨ Features

<details open>
<summary><b>🗺️ Live Tracking</b></summary>
<br/>

- ✅ **Real-time GPS tracking** with sub-10m accuracy
- ✅ **Google Maps-style camera** with smooth following and forward offset
- ✅ **Dynamic movement threshold** (5m walking → 12m running)
- ✅ **Live polyline rendering** with route visualization
- ✅ **Speed-adaptive updates** for optimal performance

</details>

<details open>
<summary><b>🎯 Intelligent Stop Detection</b></summary>
<br/>

- ✅ **120-second duration threshold** to avoid false stops
- ✅ **15m GPS jitter tolerance** for accurate stop identification
- ✅ **25m stop merging radius** to consolidate nearby stops
- ✅ **Automatic checkpoint creation** at significant stops

</details>

<details open>
<summary><b>📊 Comprehensive Analytics</b></summary>
<br/>

- ✅ **Distance tracking** with Haversine formula precision
- ✅ **Duration monitoring** with pause/resume support
- ✅ **Speed metrics** (current, average, max)
- ✅ **Stop analysis** with arrival/departure timestamps
- ✅ **Weekly activity charts** with FL Chart visualization

</details>

<details open>
<summary><b>👤 User Management</b></summary>
<br/>

- ✅ **Profile management** with username and email editing
- ✅ **Password change** with current password verification
- ✅ **About screen** with app information and version
- ✅ **Settings panel** with profile and about navigation

</details>

<details open>
<summary><b>👨‍💼 Admin Dashboard</b></summary>
<br/>

- ✅ **Role-based access** (ADMIN/USER) with automatic routing
- ✅ **Real-time statistics** (total users, sessions today, distance, stops)
- ✅ **Interactive map** showing all user sessions with routes
- ✅ **User selection** to filter and view individual user routes
- ✅ **Session switcher** to toggle between all sessions or specific ones
- ✅ **Excel export** for all users or individual user data
- ✅ **Professional UI** with glassmorphism and gradient effects

</details>

<details open>
<summary><b>💾 Data Export</b></summary>
<br/>

- ✅ **GPX format** for GPS applications
- ✅ **CSV format** for spreadsheet analysis
- ✅ **JSON format** for custom processing
- ✅ **Excel export** (admin only) with formatted spreadsheets
- ✅ **Downloads folder export** for easy file access
- ✅ **Clipboard fallback** if storage permission denied

</details>

<details open>
<summary><b>🔐 Authentication & Security</b></summary>
<br/>

- ✅ **JWT-based authentication** with secure token storage
- ✅ **Login/Register** with email validation
- ✅ **Role-based routing** (Admin → Dashboard, User → Home)
- ✅ **Auto-sync to backend** after session completion
- ✅ **Secure storage** using flutter_secure_storage

</details>

<details open>
<summary><b>🎨 Modern UI/UX</b></summary>
<br/>

- ✅ **Premium gradient design** with animated login screen
- ✅ **Glass morphism effects** with backdrop blur
- ✅ **Smooth animations** with custom curves
- ✅ **Responsive layout** using Sizer package
- ✅ **Dark theme** optimized for outdoor use
- ✅ **Intuitive navigation** with bottom navigation bar

</details>

---

## 🚀 Installation

<div align="center">

### 📋 Prerequisites

</div>

```bash
✅ Flutter SDK: 3.41.8 or higher
✅ Dart SDK: 3.11.5 or higher
✅ Android Studio: with NDK 27.0.12077973
✅ Android Device: API level 21+ (Android 5.0+)
```

<div align="center">

### 🛠️ Setup Steps

</div>

<details>
<summary><b>1️⃣ Clone the repository</b></summary>

```bash
git clone https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend.git
cd CampusFieldTrackV1-Frontend
```

</details>

<details>
<summary><b>2️⃣ Install dependencies</b></summary>

```bash
flutter pub get
```

</details>

<details>
<summary><b>3️⃣ Configure API endpoint</b></summary>

Edit `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://YOUR_SERVER_IP:8080/api';
```

</details>

<details>
<summary><b>4️⃣ Run the app</b></summary>

```bash
flutter run
```

</details>

<details>
<summary><b>5️⃣ Build APK (Optional)</b></summary>

```bash
flutter build apk --release
```

📦 Output: `build/app/outputs/flutter-apk/app-release.apk`

</details>

---

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                          # App entry point with role-based routing
├── routes/
│   └── app_routes.dart               # Navigation routes (login, home, admin, profile, about)
├── services/
│   ├── tracking_service.dart         # GPS tracking logic
│   ├── api_service.dart              # Backend API client with admin endpoints
│   ├── export_service.dart           # File export (GPX/CSV/JSON)
│   └── file_writer_mobile.dart       # Platform-specific file I/O
├── presentation/
│   ├── auth_screen/
│   │   └── login_screen.dart         # Premium gradient login/register UI
│   ├── home_dashboard_screen/
│   │   ├── home_dashboard_screen.dart
│   │   └── widgets/                  # Dashboard components
│   ├── admin_dashboard_screen/
│   │   └── admin_dashboard_screen.dart # Admin panel with map and export
│   ├── profile_screen/
│   │   └── profile_screen.dart       # User profile management
│   ├── about_screen/
│   │   └── about_screen.dart         # App information
│   ├── live_tracking_screen/
│   │   ├── live_tracking_screen.dart # Real-time tracking UI
│   │   └── widgets/                  # Tracking controls
│   ├── activity_history_screen/
│   │   └── activity_history_screen.dart
│   ├── activity_detail_screen/
│   │   └── activity_detail_screen.dart
│   └── settings_screen/
│       └── settings_screen.dart      # Settings with profile/about navigation
└── theme/
    └── app_theme.dart                # Color scheme & styles
```

### Key Technologies

| Technology | Purpose |
|------------|---------|
| **flutter_map** | Interactive map rendering with OpenStreetMap tiles |
| **geolocator** | GPS location services and permissions |
| **dio** | HTTP client for REST API communication |
| **fl_chart** | Beautiful charts for analytics visualization |
| **flutter_secure_storage** | Encrypted JWT token storage |
| **permission_handler** | Runtime permission management |
| **shared_preferences** | Local session persistence |

---

## 🔌 API Integration

### Base Configuration

```dart
class ApiService {
  static const String baseUrl = 'http://20.40.5.66:8080/api';
  
  // JWT token stored securely
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
}
```

### Endpoints Used

#### Authentication
```dart
POST /auth/register
POST /auth/login         // Returns JWT token + user role
```

#### Session Management
```dart
GET  /sessions              // Get all user sessions
GET  /sessions/{id}         // Get session by ID
POST /sessions/full-sync    // Upload complete session
```

#### User Management
```dart
GET  /user?id={userId}      // Get user profile
PUT  /user?id={userId}      // Update user profile
PUT  /user/password?id={userId}  // Change password
```

#### Admin Endpoints
```dart
GET  /admin/stats           // Dashboard statistics
GET  /admin/users           // All users (excludes admins)
GET  /admin/sessions/all    // All sessions with routes
GET  /admin/export/all      // Export all users to Excel
GET  /admin/export/user/{userId}  // Export single user to Excel
```

### Request Example

```dart
// Auto-sync after tracking stops
final response = await _apiService.post('/sessions/full-sync', {
  'start_time': session.startTime.toIso8601String(),
  'end_time': session.endTime?.toIso8601String(),
  'duration_seconds': session.durationSeconds,
  'distance_km': session.distanceKm,
  'route_points': session.routePoints.map((p) => {
    'lat': p.lat,
    'lng': p.lng,
    'altitude': p.altitude,
    'speed': p.speed,
    'accuracy': p.accuracy,
    'timestamp': p.timestamp.toIso8601String(),
  }).toList(),
  'checkpoints': session.checkpoints.map((c) => {
    'lat': c.location.latitude,
    'lng': c.location.longitude,
    'arrived_at': c.arrivedAt.toIso8601String(),
    'departed_at': c.departedAt?.toIso8601String(),
  }).toList(),
});
```

---

## 🎯 Key Features Deep Dive

### 1. GPS Tracking Service

**Location Stream Processing:**
```dart
_positionStream = Geolocator.getPositionStream(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 5, // Update every 5 meters
  ),
).listen((Position position) {
  _processLocationUpdate(position);
});
```

**Stop Detection Algorithm:**
- Speed < 1.5 km/h for 120 seconds
- Location variance < 15 meters
- Merge stops within 25 meters

### 2. Camera Follow Logic

**Dynamic Threshold:**
```dart
double threshold;
if (speed < 3.0) threshold = 0.005;      // ~5m walking
else if (speed < 8.0) threshold = 0.008; // ~8m jogging
else threshold = 0.012;                   // ~12m running
```

**Forward Offset:**
```dart
// User positioned at 65% screen height
final offsetTarget = _calculateOffsetTarget(userLoc, routePoints);
_mapController.move(offsetTarget, 17.0);
```

### 3. Export Formats

**GPX (GPS Exchange Format):**
```xml
<gpx version="1.1">
  <trk>
    <trkseg>
      <trkpt lat="12.9716" lon="77.5946">
        <ele>920.5</ele>
        <time>2026-04-30T12:30:45Z</time>
        <speed>1.25</speed>
      </trkpt>
    </trkseg>
  </trk>
</gpx>
```

**CSV (Comma-Separated Values):**
```csv
timestamp,latitude,longitude,altitude_m,speed_ms,accuracy_m
2026-04-30T12:30:45Z,12.9716,77.5946,920.5,1.25,8.2
```

---

## 🔧 Configuration

### Android Permissions

Required permissions in `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.MANAGE_EXTERNAL_STORAGE" />
```

### Environment Variables

No environment variables needed for frontend. API endpoint is configured in code.

---

## 🐛 Troubleshooting

### Common Issues

**1. GPS not working**
- Enable location services in device settings
- Grant location permission when prompted
- Ensure GPS signal is available (outdoor environment)

**2. Backend connection failed**
- Verify backend is running on correct IP:port
- Check firewall settings allow port 8080
- Update `baseUrl` in `api_service.dart`

**3. Export permission denied**
- Grant storage permission when prompted
- For Android 11+, enable "All files access" in settings
- Fallback: data copied to clipboard

**4. Build errors**
- Run `flutter clean && flutter pub get`
- Verify Flutter SDK version: `flutter --version`
- Check NDK version in Android Studio (27.0.12077973)

---

## 📈 Performance Optimization

- **UI debouncing**: Map updates batched to 500ms intervals
- **Polyline caching**: Avoid rebuilding unchanged routes
- **Lazy loading**: Activity history paginated
- **Background tracking**: Continues when app minimized
- **Battery optimization**: GPS accuracy balanced with power consumption

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🔗 Related Repositories

<div align="center">

| Repository | Description | Link |
|------------|-------------|------|
| 🎨 **Frontend** | Flutter Mobile App | [View Repo](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend) |
| ⚙️ **Backend** | Spring Boot REST API | [View Repo](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Backend) |

</div>

---

<div align="center">

## 💖 Support This Project

If you find this project helpful, please consider giving it a ⭐!

[![GitHub Stars](https://img.shields.io/github/stars/PremSaiBollamoni/CampusFieldTrackV1-Frontend?style=social)](https://github.com/PremSaiBollamoni/CampusFieldTrackV1-Frontend/stargazers)

</div>

---

## 🙏 Acknowledgments

<div align="center">

Made with ❤️ by **Prem Sai Bollamoni**

[![GitHub](https://img.shields.io/badge/GitHub-PremSaiBollamoni-181717?style=for-the-badge&logo=github)](https://github.com/PremSaiBollamoni)

<br/>

**Special Thanks To:**

🗺️ **OpenStreetMap** • 🦋 **Flutter Community** • 📍 **Geolocator Plugin** • 📊 **FL Chart**

</div>

---

<div align="center">

### 📜 License

This project is licensed under the MIT License

---

**Built with 💙 using Flutter**

<img src="https://raw.githubusercontent.com/Tarikul-Islam-Anik/Animated-Fluent-Emojis/master/Emojis/Travel%20and%20places/Rocket.png" width="40" />

[⬆ Back to top](#-campus-fieldtrack---flutter-frontend)

</div>
