import 'dart:async';

/// Mobile storefront purchases are intentionally not implemented here.
/// VIP purchases require native store billing on iOS/Android; web checkout is
/// handled separately by Stripe. This service fails closed until a secure
/// server-verified entitlement flow is added.
enum VipFeature {
  menuScanning,
  premiumAnimations,
  unlimitedRecipes,
  aiMealPlanning,
  advancedNutrition,
  prioritySupport,
  noAds,
  exclusiveRecipes
}

class StoreProduct {
  const StoreProduct();
}

class SubscriptionService {
  final _subscriptionController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStream => _subscriptionController.stream;
  bool get isVip => false;
  DateTime? get vipExpiresAt => null;
  Future<void> initialize() async {}
  Future<List<StoreProduct>> getProducts() async => const [];
  Future<bool> purchaseVip({bool yearly = false}) async => false;
  Future<bool> restorePurchases() async => false;
  bool hasAccess(VipFeature feature) => false;
  Map<String, int> getFreeTierLimits() => const {
        'recipesPerMonth': 10,
        'aiSearchesPerDay': 0,
        'savedRecipes': 20,
        'collections': 3
      };
  Future<void> loginUser(String userId) async {}
  Future<void> logoutUser() async {}
  Future<String?> getManagementUrl() async => null;
  void dispose() => _subscriptionController.close();
}

final subscriptionService = SubscriptionService();
