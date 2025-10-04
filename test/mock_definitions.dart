import 'package:mockito/annotations.dart';
import 'package:key_match/services/auth_service.dart';
import 'package:key_match/services/profile_service.dart';
import 'package:key_match/services/billing_service.dart';

@GenerateMocks([AuthService, ProfileService, BillingService])
void main() {}
