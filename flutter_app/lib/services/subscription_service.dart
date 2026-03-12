import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// VIP Subscription tiers and features
enum VipTier {
  free,
  vip,
}

/// Features gated behind VIP subscription
enum VipFeature {
  menuScanning,
  premiumAnimations,
  unlimitedRecipes,
  aiMealPlanning,
  advancedNutrition,
  prioritySupport,
  noAds,
  exclusiveRecipes,
}

class SubscriptionService {
  static const String _revenueCatApiKeyAndroid = 'your_revenuecat_android_key';
  static const String _revenueCatApiKeyIOS = 'your_revenuecat_ios_key';

  static const String vipMonthlyProductId = 'vip_monthly';
  static const String vipYearlyProductId = 'vip_yearly';
  static const double vipMonthlyPrice = 5.99;
  static const double vipYearlyPrice = 49.99;

  // Lazy Firebase instances to avoid crash when Firebase not initialized
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  FirebaseAuth get _auth => FirebaseAuth.instance;

  bool _isInitialized = false;
  CustomerInfo? _customerInfo;

  // Stream controller for subscription status changes
  final _subscriptionController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStream => _subscriptionController.stream;

  // Current VIP status
  bool _isVip = false;
  bool get isVip => _isVip;

  DateTime? _vipExpiresAt;
  DateTime? get vipExpiresAt => _vipExpiresAt;

  /// Initialize RevenueCat
  Future<void> initialize() async {
    if (_isInitialized) return;

    // RevenueCat is only supported on mobile for this app setup.
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      debugPrint('RevenueCat is not supported on this platform.');
      return;
    }

    try {
      final apiKey = defaultTargetPlatform == TargetPlatform.iOS
          ? _revenueCatApiKeyIOS
          : _revenueCatApiKeyAndroid;

      if (apiKey.startsWith('your_revenuecat_')) {
        debugPrint('RevenueCat API key is not configured. Skipping init.');
        return;
      }

      await Purchases.configure(
        PurchasesConfiguration(apiKey)..appUserID = _auth.currentUser?.uid,
      );

      // Listen for customer info updates
      Purchases.addCustomerInfoUpdateListener((customerInfo) {
        _customerInfo = customerInfo;
        _updateVipStatus(customerInfo);
      });

      // Get initial customer info
      _customerInfo = await Purchases.getCustomerInfo();
      _updateVipStatus(_customerInfo!);

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing RevenueCat: $e');
    }
  }

  /// Update VIP status based on customer info
  void _updateVipStatus(CustomerInfo customerInfo) {
    final entitlements = customerInfo.entitlements.active;
    final hasVip = entitlements.containsKey('vip');

    if (hasVip) {
      _isVip = true;
      final expiration = entitlements['vip']?.expirationDate;
      if (expiration != null) {
        _vipExpiresAt = DateTime.parse(expiration);
      }
    } else {
      _isVip = false;
      _vipExpiresAt = null;
    }

    _subscriptionController.add(_isVip);

    // Update Firestore
    _syncWithFirestore();
  }

  /// Sync subscription status with Firestore
  Future<void> _syncWithFirestore() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'isVip': _isVip,
        'vipExpiresAt':
            _vipExpiresAt != null ? Timestamp.fromDate(_vipExpiresAt!) : null,
      });
    } catch (e) {
      debugPrint('Error syncing subscription with Firestore: $e');
    }
  }

  /// Get available products
  Future<List<StoreProduct>> getProducts() async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current != null) {
        return current.availablePackages
            .map((package) => package.storeProduct)
            .toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting products: $e');
      return [];
    }
  }

  /// Purchase VIP subscription
  Future<bool> purchaseVip({bool yearly = false}) async {
    try {
      final offerings = await Purchases.getOfferings();
      final current = offerings.current;

      if (current == null) {
        throw Exception('No offerings available');
      }

      Package? package;
      if (yearly) {
        package = current.annual;
      } else {
        package = current.monthly;
      }

      if (package == null) {
        throw Exception('Package not found');
      }

      final customerInfo = await Purchases.purchasePackage(package);
      _updateVipStatus(customerInfo);

      return _isVip;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      debugPrint('Error purchasing VIP: $e');
      rethrow;
    } catch (e) {
      debugPrint('Error purchasing VIP: $e');
      rethrow;
    }
  }

  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateVipStatus(customerInfo);
      return _isVip;
    } catch (e) {
      debugPrint('Error restoring purchases: $e');
      return false;
    }
  }

  /// Check if a specific feature is available
  bool hasAccess(VipFeature feature) {
    if (_isVip) return true;

    // Free tier features
    switch (feature) {
      case VipFeature.menuScanning:
      case VipFeature.premiumAnimations:
      case VipFeature.aiMealPlanning:
      case VipFeature.advancedNutrition:
      case VipFeature.exclusiveRecipes:
        return false;
      case VipFeature.unlimitedRecipes:
      case VipFeature.prioritySupport:
      case VipFeature.noAds:
        return false;
    }
  }

  /// Get free tier limits
  Map<String, int> getFreeTierLimits() {
    return {
      'recipesPerMonth': 10,
      'aiSearchesPerDay': 5,
      'savedRecipes': 20,
      'collections': 3,
    };
  }

  /// Login user to RevenueCat
  Future<void> loginUser(String userId) async {
    try {
      await Purchases.logIn(userId);
      final customerInfo = await Purchases.getCustomerInfo();
      _updateVipStatus(customerInfo);
    } catch (e) {
      debugPrint('Error logging in to RevenueCat: $e');
    }
  }

  /// Logout user from RevenueCat
  Future<void> logoutUser() async {
    try {
      await Purchases.logOut();
      _isVip = false;
      _vipExpiresAt = null;
      _subscriptionController.add(false);
    } catch (e) {
      debugPrint('Error logging out of RevenueCat: $e');
    }
  }

  /// Get subscription management URL
  Future<String?> getManagementUrl() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (e) {
      return null;
    }
  }

  /// Dispose stream controller
  void dispose() {
    _subscriptionController.close();
  }
}

// Singleton instance
final subscriptionService = SubscriptionService();
