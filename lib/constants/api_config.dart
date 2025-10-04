class ApiConfig {
  // Backend URL - Update this when migrating to different hosting
  static const String baseUrl = 'https://key-match-backend-nsx5nsymuq-uc.a.run.app';
  
  // API endpoints - Include /api prefix for backend routes
  static const String apiBaseUrl = '$baseUrl/api';
  
  // WebSocket URL for real-time features
  static const String webSocketUrl = 'wss://key-match-backend-nsx5nsymuq-uc.a.run.app';
  
  // Image uploads URL
  static const String uploadsUrl = '$baseUrl/uploads';
  
  // Environment configuration
  static const bool isProduction = true;
  static const bool enableLogging = false; // Disable logging in production for better performance
  
  // Optimized timeout configurations
  static const int connectionTimeout = 15000; // Reduced from 30 seconds
  static const int receiveTimeout = 15000; // Reduced from 30 seconds
  
  // Rate limiting
  static const int maxRetries = 2; // Reduced from 3
  static const int retryDelay = 500; // Reduced from 1000ms
  
  // Stripe configuration
  static const String stripePublishableKey = 'pk_live_51Ri0VmDX8VApD7AKld7sIAOmzvSIV2RwpP95WhGZiovgJ7PjZrwQ5zC4U8AO2EUg7RNLoqLFPKw4esKQbwqfkYa200N7USCiCE';
} 