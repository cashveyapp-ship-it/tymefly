import 'dart:async';

import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/theme/app_theme.dart';
import '../../services/iap_service.dart';
import '../../services/plan_service.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool loading = true;
  bool storeAvailable = false;
  List<ProductDetails> products = [];
  late final StreamSubscription<List<PurchaseDetails>> purchaseSub;

  final localPlans = const [
    _Plan('Free', r'$0', '3 free TymeFlys', ['3 total capsules', '1 trusted contact', 'Text, photo, video'], null),
    _Plan('Plus', r'$2.99/mo', 'Simple future memories', ['25 capsules', '3 trusted contacts', 'Photo/video/text'], 'tymefly_plus_monthly'),
    _Plan('Premium', r'$5.99/mo', 'Most popular', ['Unlimited capsules', '5 trusted contacts', 'Longer videos'], 'tymefly_premium_monthly'),
    _Plan('Legacy', r'$9.99/mo', 'Family & long-term vault', ['Legacy vault', 'Priority storage', 'Advanced scheduling'], 'tymefly_legacy_monthly'),
    _Plan('AI+', r'$15.99/mo', 'AI future experiences', ['AI memory movies', 'AI narration', 'AI future letters'], 'tymefly_ai_monthly'),
  ];

  @override
  void initState() {
    super.initState();

    purchaseSub = IapService.purchases.listen((purchases) async {
      for (final purchase in purchases) {
        if (purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored) {
          await PlanService.activatePlan(
            productId: purchase.productID,
            purchaseId: purchase.purchaseID ??
                DateTime.now().millisecondsSinceEpoch.toString(),
          );
          await IapService.completePurchase(purchase);
        }
      }
    });

    loadStore();
  }

  @override
  void dispose() {
    purchaseSub.cancel();
    super.dispose();
  }

  Future<void> loadStore() async {
    try {
      final available = await IapService.isAvailable();
      final loadedProducts =
          available ? await IapService.loadProducts() : <ProductDetails>[];

      if (!mounted) return;

      setState(() {
        storeAvailable = available;
        products = loadedProducts;
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        storeAvailable = false;
        products = [];
        loading = false;
      });
    }
  }

  ProductDetails? productFor(String? id) {
    if (id == null) return null;

    for (final product in products) {
      if (product.id == id) return product;
    }

    return null;
  }

  Future<void> choosePlan(_Plan plan) async {
    if (plan.productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are currently on the Free plan.')),
      );
      return;
    }

    final product = productFor(plan.productId);

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            storeAvailable
                ? '${plan.name} is not active in the store yet.'
                : 'Store is not available on this device.',
          ),
        ),
      );
      return;
    }

    await IapService.buy(product);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        leadingWidth: 70,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: const Color(0xFFE9E9EF),
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Plans',
          style: TextStyle(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).padding.bottom + 40,
        ),
        children: [
          const Text(
            'Choose your TYMEFLY plan',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start free. Upgrade when you are ready to create more future memories.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          if (loading)
            const LinearProgressIndicator()
          else if (!storeAvailable)
            const Text(
              'Store checkout will work after products are created in Google Play Console and App Store Connect.',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          const SizedBox(height: 20),
          ...localPlans.map(
            (plan) => _PlanCard(
              plan: plan,
              storeProduct: productFor(plan.productId),
              onChoose: () => choosePlan(plan),
            ),
          ),
        ],
      ),
    );
  }
}

class _Plan {
  final String name;
  final String price;
  final String tagline;
  final List<String> features;
  final String? productId;

  const _Plan(
    this.name,
    this.price,
    this.tagline,
    this.features,
    this.productId,
  );
}

class _PlanCard extends StatelessWidget {
  final _Plan plan;
  final ProductDetails? storeProduct;
  final VoidCallback onChoose;

  const _PlanCard({
    required this.plan,
    required this.storeProduct,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final isAi = plan.name == 'AI+';
    final displayPrice = storeProduct?.price ?? plan.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isAi ? AppTheme.primary : const Color(0xFFE5E7EB),
          width: isAi ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAi)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'AI Money Maker',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          Text(
            plan.name,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            displayPrice,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            plan.tagline,
            style: const TextStyle(color: AppTheme.textMuted),
          ),
          const SizedBox(height: 14),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppTheme.mint,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(feature)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onChoose,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isAi ? AppTheme.primary : const Color(0xFFF1F4FF),
                foregroundColor: isAi ? Colors.white : AppTheme.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                plan.name == 'Free'
                    ? 'Current Starter Plan'
                    : 'Choose ${plan.name}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}



