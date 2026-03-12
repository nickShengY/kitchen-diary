import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../main.dart' show firebaseInitialized;
import '../services/subscription_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final SubscriptionService _subscriptionService = subscriptionService;
  
  bool _isLoading = false;
  bool _isVip = false;
  DateTime? _vipExpiresAt;
  List<StoreProduct> _products = [];
  String? _errorMessage;
  StreamSubscription<bool>? _subscription;

  bool get isLoading => _isLoading;
  bool get isVip => _isVip;
  DateTime? get vipExpiresAt => _vipExpiresAt;
  List<StoreProduct> get products => _products;
  String? get errorMessage => _errorMessage;

  SubscriptionProvider() {
    _init();
  }

  Future<void> _init() async {
    // Skip initialization if Firebase is not available
    if (!firebaseInitialized && kDebugMode) {
      debugPrint('⚠️ Subscription service skipped - Firebase not initialized');
      notifyListeners();
      return;
    }
    
    try {
      await _subscriptionService.initialize();
      
      _isVip = _subscriptionService.isVip;
      _vipExpiresAt = _subscriptionService.vipExpiresAt;
      
      // Listen for subscription changes
      _subscription = _subscriptionService.subscriptionStream.listen((isVip) {
        _isVip = isVip;
        _vipExpiresAt = _subscriptionService.vipExpiresAt;
        notifyListeners();
      });
      
      // Load products
      await loadProducts();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Subscription initialization failed: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> loadProducts() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      _products = await _subscriptionService.getProducts();
    } catch (e) {
      _errorMessage = 'Failed to load subscription options';
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> purchaseMonthly() async {
    return _purchase(yearly: false);
  }

  Future<bool> purchaseYearly() async {
    return _purchase(yearly: true);
  }

  Future<bool> _purchase({required bool yearly}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _subscriptionService.purchaseVip(yearly: yearly);
      _isVip = success;
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Purchase failed. Please try again.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      final success = await _subscriptionService.restorePurchases();
      _isVip = success;
      
      if (!success) {
        _errorMessage = 'No active subscriptions found.';
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _errorMessage = 'Failed to restore purchases.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  bool hasAccess(VipFeature feature) {
    return _subscriptionService.hasAccess(feature);
  }

  Map<String, int> getFreeTierLimits() {
    return _subscriptionService.getFreeTierLimits();
  }

  Future<String?> getManagementUrl() async {
    return await _subscriptionService.getManagementUrl();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
