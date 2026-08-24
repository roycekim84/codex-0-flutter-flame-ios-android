class DifficultyProfile {
  const DifficultyProfile({
    required this.id,
    required this.name,
    required this.tagline,
    required this.description,
    required this.accentValue,
  });

  final String id, name, tagline, description;
  final int accentValue;

  static const all = [
    DifficultyProfile(
      id: 'dawn',
      name: '연맹의 새벽',
      tagline: '첫 장정을 위한 난세',
      description: '자원이 넉넉하고 주변 세력이 약합니다.',
      accentValue: 0xff6e9f88,
    ),
    DifficultyProfile(
      id: 'balance',
      name: '삼국의 균형',
      tagline: '가장 표준적인 난이도',
      description: '세력·자원·외교가 균형을 이루는 기본 난이도입니다.',
      accentValue: 0xffd3a457,
    ),
    DifficultyProfile(
      id: 'clash',
      name: '패권의 격돌',
      tagline: '강자와 맞서는 전쟁',
      description: '적의 공격성과 외교 압박이 높아집니다.',
      accentValue: 0xffc9794d,
    ),
    DifficultyProfile(
      id: 'chaos',
      name: '천하의 격변',
      tagline: '숙련자를 위한 극한의 난세',
      description: '강력한 적과 빈번한 재해를 견뎌야 합니다.',
      accentValue: 0xffa95757,
    ),
  ];

  static DifficultyProfile byId(String? id) =>
      all.firstWhere((profile) => profile.id == id, orElse: () => all[1]);
}
