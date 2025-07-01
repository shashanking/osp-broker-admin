# OSP Broker Admin Dashboard

A Flutter-based admin dashboard for OSP Broker management system with authentication, role-based access, and real-time data visualization.

## 📋 Project Structure

The project follows a feature-first architecture with clear separation of concerns:

```
lib/
├── core/
│   ├── infrastructure/     # Core services and utilities
│   │   ├── api_urls.dart    # API endpoint constants
│   │   ├── dio_provider.dart # Dio HTTP client setup
│   │   └── base_api_service.dart # Base API service with token management
│   └── presentation/        # Common UI components and themes
├── features/
│   ├── auth/              # Authentication feature
│   │   ├── application/     # Business logic (providers, notifiers)
│   │   ├── domain/         # Data models and interfaces
│   │   └── presentation/    # UI components
│   ├── dashboard/          # Main dashboard feature
│   ├── splash/             # Splash screen
│   └── settings/           # User settings
└── main.dart              # Application entry point
```

## 🚀 Recent Updates (June 2024)

### Authentication & Navigation Fixes

1. **Splash Screen Navigation**
   - Implemented proper auth state handling during app startup
   - Added minimum splash duration (3 seconds) for better UX
   - Fixed race conditions in auth state transitions

2. **Auth State Management**
   - Refactored `AuthNotifier` to handle token validation
   - Added proper error handling for 401/404 responses
   - Implemented token refresh flow

3. **Navigation Flow**
   - Fixed navigation between splash → login/dashboard
   - Added proper route protection
   - Implemented deep linking support

## 🔧 Technical Stack

- **Flutter**: ^3.16.0
- **State Management**: Riverpod
- **Routing**: GoRouter
- **Local Storage**: Hive
- **HTTP Client**: Dio
- **UI Framework**: Material 3
- **Code Generation**: Freezed, JSON Serializable

## 🏗️ Project Initialization

1. **Dependencies Installation**
   ```bash
   flutter pub get
   ```

2. **Code Generation**
   ```bash
   flutter pub run build_runner watch --delete-conflicting-outputs
   ```

3. **Run the App**
   ```bash
   flutter run -d chrome --web-renderer html
   ```

## 🔄 Important Flows

### Authentication Flow
1. App starts → Shows splash screen
2. Checks for existing auth token
3. If valid token → Navigate to Dashboard
4. If no/invalid token → Show Login screen
5. After login → Store tokens and redirect to Dashboard

### State Management
- Uses Riverpod for state management
- `AuthNotifier` handles auth state
- `DashboardNotifier` manages dashboard data
- Providers are organized by feature

## 🧠 Key Implementation Details

### 1. Auth State Management
- `AuthState` is a sealed class with states: initial, loading, authenticated, unauthenticated, error
- Tokens are stored securely using Hive
- Automatic token refresh before expiration

### 2. Navigation
- Nested navigation with persistent sidebar
- Route protection based on auth state
- Deep linking support

### 3. API Integration
- Base API service with token injection
- Error handling and retry logic
- Request/response logging

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

## 🚨 Common Issues & Solutions

### 1. Provider Initialization Errors
Ensure proper initialization order in `main.dart`:
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `Hive.initFlutter()`
3. Create `ProviderContainer`
4. Initialize providers in correct order

### 2. Navigation Issues
- Always check `mounted` before navigation
- Use `GoRouter` for all navigation
- Handle deep links in router configuration

## 📝 Next Steps

1. **Immediate**
   - [ ] Add loading states for async operations
   - [ ] Implement proper error boundaries
   - [ ] Add analytics events

2. **Next Iteration**
   - [ ] Add user profile management
   - [ ] Implement role-based access control
   - [ ] Add push notifications

3. **Future Enhancements**
   - [ ] Dark mode support
   - [ ] Offline data persistence
   - [ ] Multi-language support

## 📑 Forum Feature: UI Modularization (June 2025)

### Overview
- The forum admin UI has been fully modularized for maintainability and scalability.
- Large monolithic forum page split into smaller widgets/files:
  - `forum_tabs.dart`: Custom pill-shaped tab bar with badge counts.
  - `forum_categories_table.dart`: Forum categories table and row widgets.
  - `forum_forums_table.dart`: Forums list table and row widgets.
  - `forum_threads_table.dart`: Threads list table and row widgets.
- Main page (`forums_page.dart`) now only manages state and high-level composition.

### Key Points
- All UI/UX matches Figma designs; no visual changes during refactor.
- State management for tab switching is handled in the main page.
- Placeholder/mock data arrays are local to the build method for easy migration to real data later.
- All old inline table/tab code and unused methods have been removed.
- Each widget file is <400 lines for readability and future maintenance.


## 📚 Documentation

- [Flutter Documentation](https://docs.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)
- [GoRouter Documentation](https://gorouter.dev/)

## 👥 Team

- Shashank (Current Maintainer)

## 📄 License

This project is proprietary and confidential.
