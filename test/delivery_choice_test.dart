import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_provider/domain/entities/delivery_config.dart';
import 'package:toukh_provider/features/registration/presentation/widgets/delivery_pricing_fields.dart';

void main() {
  test('no delivery: Havit couriers, no fee settings saved', () {
    final c = const DeliveryChoice(free: true, ownAccount: true).toConfig();
    expect(c.offersDelivery, isFalse);
    expect(c.isFree, isFalse);
    expect(c.manageFromAccount, isFalse);
    expect(c.pricingMode, isNull);
    expect(c.toFirestore().containsKey('priceEgp'), isFalse);
  });

  test('paid delivery is always Havit pricing, never a typed-in fee', () {
    final c = const DeliveryChoice(offers: true, ownAccount: true).toConfig(
      avgPrepMinutes: 20,
    );
    expect(c.offersDelivery, isTrue);
    expect(c.isFree, isFalse);
    expect(c.manageFromAccount, isTrue);
    expect(c.pricingMode, DeliveryPricingMode.app);
    expect(c.usesAppPricing, isTrue);
    expect(c.priceEgp, isNull);
    expect(c.toFirestore()['pricingMode'], 'app');
  });

  test('free delivery through couriers', () {
    final c = const DeliveryChoice(offers: true, free: true).toConfig();
    expect(c.isFree, isTrue);
    expect(c.manageFromAccount, isFalse);
    expect(c.pricingMode, isNull);
    expect(c.usesAppPricing, isFalse);
  });

  test('older fee-based configs read as Havit pricing once edited', () {
    final legacy = DeliveryChoice.fromConfig(
      const DeliveryConfig(
        offersDelivery: true,
        isFree: false,
        pricingMode: DeliveryPricingMode.byRegion,
        innerCityFeeEgp: 15,
        outerCityFeeEgp: 30,
      ),
    );
    expect(legacy.offers, isTrue);
    expect(legacy.free, isFalse);
    expect(legacy.toConfig().pricingMode, DeliveryPricingMode.app);

    // Delivering from the account without "offers delivery" was free.
    final selfOnly = DeliveryChoice.fromConfig(
      const DeliveryConfig(
        offersDelivery: false,
        isFree: false,
        manageFromAccount: true,
      ),
    );
    expect(selfOnly.offers, isTrue);
    expect(selfOnly.free, isTrue);
    expect(selfOnly.ownAccount, isTrue);
  });
}
