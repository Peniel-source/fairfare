import 'package:fairfare/features/profile/domain/entities/avatar_preset.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('8 women and 8 men, with unique ids the rules accept', () {
    final ids = avatarPresets.map((p) => p.id).toSet();
    expect(ids, hasLength(avatarPresets.length));
    for (final group in AvatarGroup.values) {
      expect(avatarPresets.where((p) => p.group == group), hasLength(8));
    }
    for (final id in ids) {
      expect(kAvatarIdPattern.hasMatch(id), isTrue, reason: id);
    }
  });

  test('a preset fixes every look option, so it is never random', () {
    final url = avatarPresetById('m02')!.url;
    expect(url.host, 'api.dicebear.com');
    expect(url.path, '/9.x/personas/svg');
    expect(url.queryParameters, containsPair('seed', 'fairfare-m02'));
    for (final key in ['hair', 'skinColor', 'eyes', 'mouth', 'facialHair']) {
      expect(url.queryParameters, contains(key));
    }
    expect(url.queryParameters['facialHairProbability'], '100');
    expect(
      avatarPresetById('w01')!.url.queryParameters['facialHairProbability'],
      '0',
    );
  });

  test('unknown or missing ids give no preset', () {
    expect(avatarPresetById(null), isNull);
    expect(avatarPresetById('w09'), isNull);
  });
}
