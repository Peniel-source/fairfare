// Avatars a passenger can choose from, drawn by DiceBear
// (https://www.dicebear.com, "Personas" style).
//
// Nobody gets an avatar at random: until a passenger picks one, their
// initials are shown. Each preset fixes every option (hair, skin tone,
// facial hair, face, colors), so a preset looks the same for everyone, and only
// the preset id is stored (passengers/{uid}.avatar).

enum AvatarGroup { women, men }

class AvatarPreset {
  const AvatarPreset({
    required this.id,
    required this.group,
    required this.hair,
    required this.skinColor,
    required this.clothingColor,
    this.hairColor = '362c47',
    this.eyes = 'open',
    this.mouth = 'smile',
    this.facialHair,
  });

  /// Stored on the passenger, e.g. 'w03'. Must match [kAvatarIdPattern].
  final String id;
  final AvatarGroup group;
  final String hair;
  final String skinColor;
  final String clothingColor;
  final String hairColor;
  final String eyes;
  final String mouth;

  /// Null for no facial hair.
  final String? facialHair;

  /// SVG from the DiceBear API. Tan background (AppColors.tan).
  Uri get url => Uri.https('api.dicebear.com', '/9.x/personas/svg', {
    'seed': 'fairfare-$id',
    'hair': hair,
    'hairColor': hairColor,
    'skinColor': skinColor,
    'clothingColor': clothingColor,
    'eyes': eyes,
    'mouth': mouth,
    if (facialHair == null)
      'facialHairProbability': '0'
    else ...{
      'facialHair': facialHair!,
      'facialHairProbability': '100',
    },
    'backgroundColor': 'eee1cd',
  });
}

/// The shape of a valid avatar id; the security rules and the backend check
/// the same pattern.
final kAvatarIdPattern = RegExp(r'^[wm]0[1-8]$');

const avatarPresets = <AvatarPreset>[
  AvatarPreset(
    id: 'w01',
    group: AvatarGroup.women,
    hair: 'long',
    skinColor: '623d36',
    clothingColor: 'f3b63a',
    mouth: 'lips',
  ),
  AvatarPreset(
    id: 'w02',
    group: AvatarGroup.women,
    hair: 'curlyBun',
    skinColor: '92594b',
    clothingColor: 'e24553',
    eyes: 'happy',
    mouth: 'bigSmile',
  ),
  AvatarPreset(
    id: 'w03',
    group: AvatarGroup.women,
    hair: 'bobCut',
    skinColor: 'b16a5b',
    clothingColor: '54d7c7',
    eyes: 'glasses',
  ),
  AvatarPreset(
    id: 'w04',
    group: AvatarGroup.women,
    hair: 'extraLong',
    skinColor: '623d36',
    clothingColor: '7555ca',
    mouth: 'lips',
  ),
  AvatarPreset(
    id: 'w05',
    group: AvatarGroup.women,
    hair: 'straightBun',
    skinColor: '92594b',
    clothingColor: '6dbb58',
    eyes: 'happy',
  ),
  AvatarPreset(
    id: 'w06',
    group: AvatarGroup.women,
    hair: 'curly',
    skinColor: 'd78774',
    clothingColor: 'f55d81',
    hairColor: '6c4545',
    mouth: 'bigSmile',
  ),
  AvatarPreset(
    id: 'w07',
    group: AvatarGroup.women,
    hair: 'bobBangs',
    skinColor: '623d36',
    clothingColor: '456dff',
    eyes: 'happy',
    mouth: 'lips',
  ),
  AvatarPreset(
    id: 'w08',
    group: AvatarGroup.women,
    hair: 'bunUndercut',
    skinColor: 'e5a07e',
    clothingColor: 'f3b63a',
    hairColor: '6c4545',
    mouth: 'smile',
  ),
  AvatarPreset(
    id: 'm01',
    group: AvatarGroup.men,
    hair: 'fade',
    skinColor: '623d36',
    clothingColor: '456dff',
    mouth: 'bigSmile',
  ),
  AvatarPreset(
    id: 'm02',
    group: AvatarGroup.men,
    hair: 'buzzcut',
    skinColor: '92594b',
    clothingColor: '6dbb58',
    facialHair: 'beardMustache',
    eyes: 'happy',
  ),
  AvatarPreset(
    id: 'm03',
    group: AvatarGroup.men,
    hair: 'shortCombover',
    skinColor: 'b16a5b',
    clothingColor: 'e24553',
    eyes: 'glasses',
    mouth: 'smirk',
  ),
  AvatarPreset(
    id: 'm04',
    group: AvatarGroup.men,
    hair: 'curlyHighTop',
    skinColor: '623d36',
    clothingColor: 'f3b63a',
    mouth: 'bigSmile',
  ),
  AvatarPreset(
    id: 'm05',
    group: AvatarGroup.men,
    hair: 'bald',
    skinColor: '92594b',
    clothingColor: '7555ca',
    facialHair: 'goatee',
    eyes: 'happy',
    mouth: 'smirk',
  ),
  AvatarPreset(
    id: 'm06',
    group: AvatarGroup.men,
    hair: 'cap',
    skinColor: '623d36',
    clothingColor: '54d7c7',
    eyes: 'open',
  ),
  AvatarPreset(
    id: 'm07',
    group: AvatarGroup.men,
    hair: 'balding',
    skinColor: 'd78774',
    clothingColor: 'f55d81',
    facialHair: 'shadow',
    eyes: 'happy',
  ),
  AvatarPreset(
    id: 'm08',
    group: AvatarGroup.men,
    hair: 'shortComboverChops',
    skinColor: 'e5a07e',
    clothingColor: '456dff',
    facialHair: 'beardMustache',
    hairColor: '6c4545',
    mouth: 'smirk',
  ),
];

/// The preset with [id], or null for no avatar or an unknown id.
AvatarPreset? avatarPresetById(String? id) {
  if (id == null) return null;
  for (final preset in avatarPresets) {
    if (preset.id == id) return preset;
  }
  return null;
}
