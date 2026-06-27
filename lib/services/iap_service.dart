import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

class IapService {
  static final InAppPurchase _iap = InAppPurchase.instance;

  static const Set<String> productIds = {
    'tymefly_plus_monthly',
    'tymefly_premium_monthly',
    'tymefly_legacy_monthly',
    'tymefly_ai_monthly',
  };

  static Future<bool> isAvailable() {
    return _iap.isAvailable();
  }

  static Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds);

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    return response.productDetails;
  }

  static Future<void> buy(ProductDetails product) async {
    final purchaseParam = PurchaseParam(productDetails: product);
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  static Stream<List<PurchaseDetails>> get purchases {
    return _iap.purchaseStream;
  }

  static Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }
}
