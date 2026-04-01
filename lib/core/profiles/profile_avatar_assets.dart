class ProfileAvatarAssets {
  static const List<String> male = [
    'male_01',
    'male_02',
  ];

  static const List<String> female = [
    'female_01',
    'female_02',
    'female_03',
  ];

  static const List<String> all = [
    'male_01',
    'male_02',
    'female_01',
    'female_02',
    'female_03',
  ];

  static String assetByKey(String key) {
    if (key.startsWith('male_')) {
      return 'assets/profile/avatars/male/$key.png';
    }
    if (key.startsWith('female_')) {
      return 'assets/profile/avatars/female/$key.png';
    }
    return 'assets/profile/avatars/female/female_01.png';
  }
}
