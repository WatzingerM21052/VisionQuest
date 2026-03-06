/// Modell für Achievements
class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.targetCount,
    required this.type,
    this.objectLabel,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  final String id;
  final String title;
  final String description;
  final String? objectLabel; // Optional: nur für OBJECT_SCAN
  final String icon;
  final AchievementRarity rarity;
  final int targetCount;
  final AchievementType type;
  bool isUnlocked;
  DateTime? unlockedDate;

  Achievement copyWith({
    String? id,
    String? title,
    String? description,
    String? objectLabel,
    String? icon,
    AchievementRarity? rarity,
    int? targetCount,
    AchievementType? type,
    bool? isUnlocked,
    DateTime? unlockedDate,
  }) {
    return Achievement(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      objectLabel: objectLabel ?? this.objectLabel,
      icon: icon ?? this.icon,
      rarity: rarity ?? this.rarity,
      targetCount: targetCount ?? this.targetCount,
      type: type ?? this.type,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
}

enum AchievementType {
  objectScan, // Scanne X von Objekt Y
  milestone, // Erreiche Level/XP/Streak
  meta, // Spezielle/Alle Achievements
}

enum AchievementRarity {
  common('Häufig', '⭐'),
  uncommon('Selten', '⭐⭐'),
  rare('Sehr Selten', '⭐⭐⭐'),
  epic('Episch', '⭐⭐⭐⭐'),
  legendary('Legendär', '⭐⭐⭐⭐⭐');

  const AchievementRarity(this.displayName, this.stars);

  final String displayName;
  final String stars;
}

/// Vordefinierte Achievements
final allAchievements = [
  // Object Scan Achievements
  Achievement(
    id: 'phone_finder',
    title: 'Handy-Finder',
    description: 'Finde 5 verschiedene Handys',
    objectLabel: 'cell phone',
    icon: '📱',
    rarity: AchievementRarity.common,
    targetCount: 5,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'people_watcher',
    title: 'Menschenbeobachter',
    description: 'Erkenne 10 Personen',
    objectLabel: 'person',
    icon: '👤',
    rarity: AchievementRarity.uncommon,
    targetCount: 10,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'book_lover',
    title: 'Bücher-Liebhaber',
    description: 'Finde 8 verschiedene Bücher',
    targetCount: 8,
    objectLabel: 'book',
    icon: '📚',
    rarity: AchievementRarity.uncommon,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'tech_master',
    title: 'Tech-Meister',
    description: 'Sammle eine komplette Tech-Sammlung (Laptop, Maus, Tastatur)',
    objectLabel: 'laptop',
    icon: '💻',
    rarity: AchievementRarity.rare,
    targetCount: 3,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'beverage_collector',
    title: 'Getränke-Sammler',
    description: 'Erkenne alle Trinkgefäße (Becher, Flasche, Weinglas)',
    objectLabel: 'cup',
    icon: '🥤',
    rarity: AchievementRarity.uncommon,
    targetCount: 3,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'chair_expert',
    title: 'Möbel-Experte',
    description: 'Finde 7 verschiedene Stühle',
    objectLabel: 'chair',
    icon: '🪑',
    rarity: AchievementRarity.common,
    targetCount: 7,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'time_keeper',
    title: 'Zeit-Beobachter',
    description: 'Erkenne 5 verschiedene Uhren',
    objectLabel: 'clock',
    icon: '⏰',
    rarity: AchievementRarity.uncommon,
    targetCount: 5,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'tv_enthusiast',
    title: 'TV-Enthusiast',
    description: 'Finde 10 Fernseher',
    objectLabel: 'tv',
    icon: '📺',
    rarity: AchievementRarity.rare,
    targetCount: 10,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'keyboard_warrior',
    title: 'Tastatur-Krieger',
    description: 'Erkenne 5 verschiedene Tastaturen',
    objectLabel: 'keyboard',
    icon: '⌨️',
    rarity: AchievementRarity.uncommon,
    targetCount: 5,
    type: AchievementType.objectScan,
  ),
  Achievement(
    id: 'adventurer',
    title: 'Abenteurer',
    description: 'Finde einen Rucksack',
    objectLabel: 'backpack',
    icon: '🎒',
    rarity: AchievementRarity.common,
    targetCount: 1,
    type: AchievementType.objectScan,
  ),

  // Milestone Achievements
  Achievement(
    id: 'scanner_master',
    title: 'Scanner-Meister',
    description: 'Scanne insgesamt 100 Objekte',
    icon: '📸',
    rarity: AchievementRarity.rare,
    targetCount: 100,
    type: AchievementType.milestone,
  ),
  Achievement(
    id: 'level_10',
    title: 'Stufe 10',
    description: 'Erreiche Level 10',
    icon: '🔟',
    rarity: AchievementRarity.epic,
    targetCount: 10,
    type: AchievementType.milestone,
  ),
  Achievement(
    id: 'streak_champion',
    title: 'Streak-Champion',
    description: 'Halte eine 7-Tage-Streak',
    icon: '🔥',
    rarity: AchievementRarity.rare,
    targetCount: 7,
    type: AchievementType.milestone,
  ),
  Achievement(
    id: 'xp_collector',
    title: 'XP-Sammler',
    description: 'Sammle 1000 Erfahrungspunkte',
    icon: '💎',
    rarity: AchievementRarity.uncommon,
    targetCount: 1000,
    type: AchievementType.milestone,
  ),

  // Meta Achievements
  Achievement(
    id: 'completionist',
    title: 'Perfektionist',
    description: 'Schalte alle anderen Achievements frei',
    icon: '🏆',
    rarity: AchievementRarity.legendary,
    targetCount: 14, // Anzahl aller anderen Achievements
    type: AchievementType.meta,
  ),
];
