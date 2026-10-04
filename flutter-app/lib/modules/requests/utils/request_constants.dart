/// Matches the backend configuration for Request validation limits.
class RequestConstants {
  static const double minBudget = 0.0; // budget > 0
  static const double maxBudget = 1000000000.0; // Reasonable upper bound for LKR if needed, backend specific? Wait, let's just do min > 0
  static const double minRoomSize = 0.0;
  static const double maxRoomSize = 10000.0;
  static const int minDescriptionLength = 10;
  static const int maxDescriptionLength = 2000;
  static final RegExp hexColorRegex = RegExp(r'^#?[0-9A-Fa-f]{6}$');
}
