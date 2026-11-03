import 'package:flutter_test/flutter_test.dart';
import 'package:toukh_provider/domain/entities/provider_profile.dart';

ProviderProfile _profile(Map<String, dynamic> data) =>
    ProviderProfile.fromFirestore('s1', {'serviceType': 'other_shops', ...data});

void main() {
  test('a menu-based other store gets the menu builder', () {
    expect(_profile({'orderMode': 'menu'}).hasMenu, isTrue);
  });

  test('a request-based other store keeps its gallery', () {
    expect(_profile({'orderMode': 'custom_requests'}).hasMenu, isFalse);
  });

  test('home service providers still have no menu', () {
    expect(_profile({'serviceType': 'homeService'}).hasMenu, isFalse);
  });
}
