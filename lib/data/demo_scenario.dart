class DemoScenario {
  static Map<String, dynamic> create() {
    final provinceIds = [
      'p_ash',
      'p_briar',
      'p_crown',
      'p_dale',
      'p_elm',
      'p_ford',
      'p_han',
      'p_jade',
      'p_west',
      'p_south',
      'p_north',
      'p_east',
    ];
    final owner = [
      'force_green',
      'force_green',
      'force_red',
      'force_red',
      'force_blue',
      'force_blue',
      'force_green',
      'force_green',
      'force_red',
      'force_red',
      'force_blue',
      'force_blue',
    ];
    final names = [
      '재의 들',
      '가시 숲',
      '왕관 언덕',
      '해 질녘 골짜기',
      '느릅 강',
      '여울 요새',
      '한중',
      '옥문',
      '서릉',
      '남령',
      '북원',
      '동해',
    ];
    final positions = [
      [.18, .25],
      [.42, .16],
      [.70, .26],
      [.76, .62],
      [.45, .78],
      [.17, .66],
      [.30, .43],
      [.54, .38],
      [.87, .40],
      [.66, .82],
      [.26, .83],
      [.86, .17],
    ];
    final adj = [
      ['p_briar', 'p_ford'],
      ['p_ash', 'p_crown', 'p_elm'],
      ['p_briar', 'p_dale'],
      ['p_crown', 'p_elm'],
      ['p_briar', 'p_dale', 'p_ford'],
      ['p_ash', 'p_elm', 'p_han'],
      ['p_ash', 'p_crown', 'p_west'],
      ['p_crown', 'p_dale', 'p_north'],
      ['p_dale', 'p_elm', 'p_south'],
      ['p_elm', 'p_ford', 'p_han'],
      ['p_crown', 'p_briar', 'p_east'],
      ['p_briar', 'p_jade', 'p_north'],
    ];
    final provinces = <Map<String, dynamic>>[];
    for (var i = 0; i < provinceIds.length; i++) {
      provinces.add({
        'id': provinceIds[i],
        'name': names[i],
        'ownerForceId': owner[i],
        'adjacentProvinceIds': adj[i],
        'land': 35 + i * 3,
        'publicLoyalty': 65 + i,
        'soldiers': 900 + i * 120,
        'gold': 180 + i * 25,
        'food': 600 + i * 100,
        'floodControl': 25 + i * 3,
        'governorId': i < 6 ? 'officer_${i * 3 + 1}' : null,
        'settlementType': switch (i) {
          0 || 4 || 7 => 'large',
          1 || 2 || 3 || 5 || 6 || 8 => 'medium',
          _ => 'small',
        },
        'officerIds': i < 6
            ? [
                'officer_${i * 3 + 1}',
                'officer_${i * 3 + 2}',
                'officer_${i * 3 + 3}',
              ]
            : <String>[],
        'mapX': positions[i][0],
        'mapY': positions[i][1],
      });
    }
    final officers = <Map<String, dynamic>>[];
    for (var i = 0; i < 18; i++) {
      final force = owner[i ~/ 3];
      officers.add({
        'id': 'officer_${i + 1}',
        'name': '가상 장수 ${i + 1}',
        'forceId': force,
        'provinceId': provinceIds[i ~/ 3],
        'war': 52 + (i * 7) % 42,
        'intelligence': 48 + (i * 11) % 45,
        'charisma': 50 + (i * 13) % 43,
        'loyalty': 72 + i % 20,
        'status': i % 3 == 0 ? 'RULER' : 'OFFICER',
      });
    }
    officers.addAll([
      {
        'id': 'officer_free_1',
        'name': '떠도는 책사',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 38,
        'intelligence': 92,
        'charisma': 70,
        'loyalty': 0,
        'status': 'FREE',
      },
      {
        'id': 'officer_free_2',
        'name': '변방의 장수',
        'forceId': 'free',
        'provinceId': 'free',
        'war': 86,
        'intelligence': 48,
        'charisma': 55,
        'loyalty': 0,
        'status': 'FREE',
      },
    ]);
    return {
      'id': 'generic_prototype',
      'year': 193,
      'month': 1,
      'playerForceId': 'force_green',
      'randomSeed': 42,
      'forces': [
        {
          'id': 'force_green',
          'name': '푸른 연맹',
          'rulerId': 'officer_1',
          'gold': 800,
          'food': 1200,
          'provinceIds': ['p_ash', 'p_briar', 'p_han', 'p_jade'],
          'officerIds': [
            'officer_1',
            'officer_2',
            'officer_3',
            'officer_4',
            'officer_5',
            'officer_6',
          ],
          'mapColorValue': 0xff267d70,
          'bannerIndex': 0,
        },
        {
          'id': 'force_red',
          'name': '붉은 왕좌',
          'rulerId': 'officer_7',
          'gold': 700,
          'food': 1000,
          'provinceIds': ['p_crown', 'p_dale', 'p_west', 'p_south'],
          'officerIds': [
            'officer_7',
            'officer_8',
            'officer_9',
            'officer_10',
            'officer_11',
            'officer_12',
          ],
          'aiPersonality': 'aggressive',
          'mapColorValue': 0xffa3483d,
          'bannerIndex': 1,
        },
        {
          'id': 'force_blue',
          'name': '청동 회의',
          'rulerId': 'officer_13',
          'gold': 650,
          'food': 950,
          'provinceIds': ['p_elm', 'p_ford', 'p_north', 'p_east'],
          'officerIds': [
            'officer_13',
            'officer_14',
            'officer_15',
            'officer_16',
            'officer_17',
            'officer_18',
          ],
          'aiPersonality': 'diplomatic',
          'mapColorValue': 0xff4d568d,
          'bannerIndex': 2,
        },
      ],
      'provinces': provinces,
      'officers': officers,
    };
  }
}
