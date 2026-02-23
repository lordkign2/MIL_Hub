# Comprehensive Logging System

This directory contains a comprehensive logging system for the MIL Hub Flutter application that integrates with Firebase Crashlytics for production error tracking and provides detailed console logging during development.

## Features

- **Multiple Log Levels**: Debug, Info, Warning, Error, Fatal
- **Firebase Crashlytics Integration**: Automatic error reporting in production
- **Build Configuration**: Different behavior for debug, profile, and release builds
- **Privacy & Security**: Automatic sanitization of sensitive data
- **Context Support**: Rich contextual information with logs
- **Performance Monitoring**: Built-in execution time tracking
- **Error Handling**: Comprehensive error catching and reporting
- **Dependency Injection**: Easy integration with existing architecture

## Architecture

### Core Components

1. **LoggingService** (`logging_service.dart`)
   - Abstract interface for logging operations
   - Concrete implementation with Crashlytics integration
   - Support for different log levels and contexts

2. **LogLevel** (`log_level.dart`)
   - Enum defining log severity levels
   - Comparison operators for filtering

3. **LoggingConfig** (`logging_config.dart`)
   - Configuration for different build modes
   - Privacy settings and sensitive data handling

4. **LogSanitizer** (`log_sanitizer.dart`)
   - Automatic removal of sensitive information
   - Pattern-based data sanitization

5. **ErrorHandler** (`error_handler.dart`)
   - Global error handling setup
   - Safe execution zones with error catching

6. **LoggingExtensions** (`logging_extensions.dart`)
   - Extension methods for common logging scenarios
   - Performance monitoring and user action tracking

## Usage

### Basic Logging

```dart
import 'package:mil_hub/core/services/logging/logging_facade.dart';

class MyService {
  final LoggingService _logger = sl<LoggingService>();
  
  void doSomething() {
    _logger.info('Starting operation', context: {'operation': 'do_something'});
    
    try {
      // Your code here
      _logger.info('Operation completed successfully');
    } catch (error, stackTrace) {
      _logger.error('Operation failed', error: error, stackTrace: stackTrace);
    }
  }
}
```

### Using Extensions

```dart
// Performance monitoring
final result = await _logger.logExecutionTime(
  'database_query',
  () => database.fetchData(),
  context: {'table': 'users'},
);

// User actions
_logger.logUserAction(
  'button_clicked',
  parameters: {'button_id': 'submit_form'},
  screen: 'registration',
);

// Network requests
_logger.logNetworkRequest(
  'GET',
  'https://api.example.com/users',
  statusCode: 200,
  responseTime: 250,
);
```

### Error Handling

```dart
final errorHandler = sl<ErrorHandler>();

// Wrap operations with error handling
final result = errorHandler.withErrorHandling(
  () => riskyOperation(),
  context: {'operation': 'risky_operation'},
);

// Async error handling
final result = await errorHandler.withAsyncErrorHandling(
  () async => await riskyAsyncOperation(),
  context: {'operation': 'risky_async_operation'},
);

// Safe zones
final safeZone = errorHandler.createSafeZone(zoneName: 'ui_operations');
final result = safeZone.execute(() => uiOperation(), fallback: defaultValue);
```

## Configuration

### Debug Mode
- Console logging enabled
- Crashlytics disabled
- All log levels shown
- Verbose output with emojis and colors

### Release Mode
- Console logging disabled
- Crashlytics enabled
- Info level and above only
- Sensitive data automatically sanitized

### Profile Mode
- Console logging enabled
- Crashlytics disabled
- Info level and above only
- Optimized for performance testing

## Privacy & Security

The logging system automatically sanitizes:

- Passwords and tokens
- Email addresses
- Phone numbers
- Credit card numbers
- JWT tokens
- Custom sensitive keywords

## Integration with Clean Architecture

The logging system integrates seamlessly with the existing Clean Architecture:

1. **Data Layer**: Log network requests and database operations
2. **Domain Layer**: Log business logic and use case execution
3. **Presentation Layer**: Log user interactions and UI events

## Best Practices

1. **Use Context**: Always provide relevant context information
2. **Choose Right Level**: Use appropriate log levels for different scenarios
3. **Avoid Sensitive Data**: Never log passwords, tokens, or personal information
4. **Performance**: Use extensions for performance monitoring
5. **Error Handling**: Use the ErrorHandler for consistent error reporting

## Firebase Crashlytics Integration

In release builds, the logging system automatically:

- Records errors and exceptions to Crashlytics
- Includes contextual information as custom keys
- Provides breadcrumb logs for debugging
- Sets user identifiers for better error tracking

## Dependency Injection

The logging system is registered as a singleton in the dependency injection container:

```dart
// Core services
sl.registerSingleton<LoggingService>(LoggingServiceImpl());
sl.registerSingleton<ErrorHandler>(ErrorHandler(sl<LoggingService>()));
```

This ensures consistent configuration and state throughout the application.
