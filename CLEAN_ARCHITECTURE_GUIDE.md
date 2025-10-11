# MIL Hub - Clean Architecture Implementation

## Architecture Overview

This project follows Clean Architecture principles to ensure maintainability, testability, and scalability. The architecture is divided into three main layers:

### 1. Domain Layer (Business Logic)
- **Location**: `lib/features/{feature}/domain/`
- **Purpose**: Contains business logic, entities, and use cases
- **Dependencies**: None (pure Dart)

#### Entities
- Pure Dart classes representing business objects
- Independent of any external framework
- Example: `UserEntity`, `PostEntity`

#### Use Cases
- Encapsulate business logic for specific operations
- Single responsibility principle
- Example: `SignInWithEmailUseCase`, `GetUserPostsUseCase`

#### Repositories (Interfaces)
- Abstract classes defining data contracts
- Domain layer doesn't know about implementation details

### 2. Data Layer (Data Management)
- **Location**: `lib/features/{feature}/data/`
- **Purpose**: Handles data sources, models, and repository implementations
- **Dependencies**: Domain layer interfaces

#### Models
- Data transfer objects that extend domain entities
- Handle serialization/deserialization
- Example: `UserModel extends UserEntity`

#### Data Sources
- Abstract interfaces for remote/local data access
- Implementations for Firebase, API, local storage
- Example: `AuthRemoteDataSource`, `AuthLocalDataSource`

#### Repository Implementations
- Concrete implementations of domain repositories
- Coordinate between data sources
- Handle error mapping and network connectivity

### 3. Presentation Layer (UI)
- **Location**: `lib/features/{feature}/presentation/`
- **Purpose**: Handles user interface and user interactions
- **Dependencies**: Domain layer use cases

#### BLoC Pattern
- **Events**: User actions and system events
- **States**: Different UI states (loading, success, error)
- **BLoC**: Business logic controllers that process events and emit states

#### Screens
- UI components that render based on BLoC states
- Minimal business logic
- Focus on user experience

#### Widgets
- Reusable UI components
- Stateless when possible
- Well-defined interfaces

## Project Structure

```
lib/
├── core/                           # Shared across all features
│   ├── constants/                  # App-wide constants
│   │   ├── app_constants.dart     
│   │   └── api_constants.dart
│   ├── di/                        # Dependency injection
│   │   ├── service_locator.dart
│   │   └── injection_container.dart
│   ├── errors/                    # Error handling
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/                   # Network layer
│   │   ├── http_client.dart
│   │   └── network_info.dart
│   ├── theme/                     # App theming
│   │   ├── app_colors.dart
│   │   ├── app_text_styles.dart
│   │   └── app_theme.dart
│   ├── utils/                     # Utility functions
│   │   ├── validators.dart
│   │   └── formatters.dart
│   └── widgets/                   # Shared widgets
│       ├── loading_indicator.dart
│       ├── error_display.dart
│       └── custom_app_bar.dart
├── features/                      # Feature modules
│   ├── auth/                      # Authentication feature
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_data_source.dart
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository_impl.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user_entity.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_email.dart
│   │   │       ├── sign_up_with_email.dart
│   │   │       └── sign_out.dart
│   │   ├── presentation/
│   │   │   ├── bloc/
│   │   │   │   ├── auth_bloc.dart
│   │   │   │   ├── auth_event.dart
│   │   │   │   └── auth_state.dart
│   │   │   ├── screens/
│   │   │   │   ├── new_login_screen.dart
│   │   │   │   └── new_signup_screen.dart
│   │   │   └── widgets/
│   │   │       └── auth_wrapper.dart
│   │   └── di/
│   │       └── auth_injection.dart
│   ├── learn/                     # Learning module (to be restructured)
│   ├── community/                 # Community features (to be restructured)
│   ├── check/                     # Fact-checking features (to be restructured)
│   └── admin/                     # Admin features
└── main.dart                      # App entry point
```

## Dependency Flow

```
Presentation Layer (UI)
       ↓
Domain Layer (Business Logic)
       ↓
Data Layer (External Data)
```

### Key Principles

1. **Dependency Inversion**: Higher layers don't depend on lower layers
2. **Single Responsibility**: Each class has one reason to change
3. **Open/Closed**: Open for extension, closed for modification
4. **Interface Segregation**: Clients shouldn't depend on unused interfaces

## Error Handling

### Exception Types
- `AuthException`: Authentication-related errors
- `NetworkException`: Network connectivity issues
- `ServerException`: Server/API errors
- `ValidationException`: Input validation errors

### Failure Types
- `AuthFailure`: Authentication failures
- `NetworkFailure`: Network-related failures
- `ServerFailure`: Server-side failures
- `ValidationFailure`: Validation failures
- `UnknownFailure`: Unexpected errors

### Error Flow
1. Data sources throw specific exceptions
2. Repository implementations catch exceptions and return failures
3. Use cases handle failures and return results
4. BLoCs emit error states
5. UI displays user-friendly error messages

## State Management

### BLoC Pattern Implementation
- **Events**: Represent user intentions and system events
- **States**: Represent different UI states
- **BLoC**: Process events and emit states

### State Types
- `Initial`: App startup state
- `Loading`: Operations in progress
- `Success`: Successful operations with data
- `Error`: Failed operations with error messages

## Dependency Injection

### Service Locator Pattern
- Simple and lightweight DI solution
- Singleton and factory registrations
- Easy to test and mock

### Registration Types
- **Singleton**: Single instance throughout app lifecycle
- **Factory**: New instance for each request

## Testing Strategy

### Unit Tests
- Domain layer: Test business logic in isolation
- Use cases: Test with mock repositories
- BLoCs: Test event processing and state emission

### Integration Tests
- Data layer: Test repository implementations
- Network: Test API interactions
- Database: Test local storage

### Widget Tests
- Presentation layer: Test UI components
- BLoC integration: Test widget-BLoC interactions

## Development Guidelines

### Code Organization
1. Create feature modules following Clean Architecture
2. Keep domain layer pure (no external dependencies)
3. Use dependency injection for loose coupling
4. Implement proper error handling
5. Write comprehensive tests

### Adding New Features
1. Create feature directory structure
2. Define domain entities and use cases
3. Implement data sources and repositories
4. Create BLoC for state management
5. Build UI screens and widgets
6. Set up dependency injection
7. Write tests

### Best Practices
- Prefer composition over inheritance
- Use immutable data structures
- Implement proper logging
- Follow consistent naming conventions
- Document complex business logic
- Use code generation when appropriate

## Migration Progress

### Completed Features
- ✅ Authentication (Clean Architecture implemented)
- ✅ Core infrastructure and shared components

### Pending Features
- 🔄 Learn module (to be restructured)
- 🔄 Community features (to be restructured)
- 🔄 Check/fact-checking features (to be restructured)
- ✅ Admin features (already well-structured)

### Next Steps
1. Restructure remaining features to Clean Architecture
2. Implement comprehensive testing
3. Add offline capabilities
4. Optimize performance
5. Enhance user experience

## Resources

- [Clean Architecture by Robert C. Martin](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [Flutter Testing Guide](https://flutter.dev/docs/testing)
- [Dependency Injection in Flutter](https://medium.com/flutter-community/dependency-injection-in-flutter-f19fb66a0740)