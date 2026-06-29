class FootballLeague {
  const FootballLeague({
    required this.id,
    required this.name,
    this.searchTerms = const [],
  });

  final String? id;
  final String name;
  final List<String> searchTerms;
}

const footballLeagues = <FootballLeague>[
  FootballLeague(id: 'WC', name: 'Dünya Kupası'),
  FootballLeague(id: 'PL', name: 'Premier Lig'),
  FootballLeague(id: 'BL1', name: 'Bundesliga'),
  FootballLeague(id: 'PD', name: 'LaLiga'),
  FootballLeague(id: 'SA', name: 'Serie A'),
  FootballLeague(id: 'FL1', name: 'Ligue 1'),
  FootballLeague(id: 'CL', name: 'Şampiyonlar Ligi'),
  FootballLeague(id: 'DED', name: 'Eredivisie'),
  FootballLeague(id: 'PPL', name: 'Portekiz Ligi'),
  FootballLeague(id: 'BSA', name: 'Brasileirao'),
];
