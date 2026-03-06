/// Modell für Achievements
class Achievement {
  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.objectLabel,
    required this.icon,
    required this.rarity,
    required this.targetCount,
    this.isUnlocked = false,
    this.unlockedDate,
  });

  final String id;
  final String title;
  final String description;
  final String objectLabel;
  final String icon;
  final AchievementRarity rarity;
  final int targetCount;
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
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedDate: unlockedDate ?? this.unlockedDate,
    );
  }
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
  Achievement(
    id: 'phone_finder',
    title: 'Handy-Finder',
    description: 'Finde 5 verschiedene Handys',
    objectLabel: 'cell phone',
    icon: '📱',
    rarity: AchievementRarity.common,
    targetCount: 5,
  ),
  Achievement(
    id: 'people_watcher',
    title: 'Menschenbeobachter',
    description: 'Erkenne 10 Personen',
    objectLabel: 'person',
    icon: '👤',
    rarity: AchievementRarity.uncommon,
    targetCount: 10,
  ),
  Achievement(
    id: 'book_lover',
    title: 'Bücher-Liebhaber',
    description: 'Finde 8 verschiedene Bücher',
    targetCount: 8,
    objectLabel: 'book',
    icon: '📚',
    rarity: AchievementRarity.uncommon,
  ),
  Achievement(
    id: 'tech_master',
    title: 'Tech-Meister',
    description: 'Sammle eine komplette Tech-Sammlung (Laptop, Maus, Tastatur)',
    objectLabel: 'laptop',
    icon: '💻',
    rarity: AchievementRarity.rare,
    targetCount: 3,
  ),
  Achievement(
    id: 'beverage_collector',
    title: 'Getränke-Sammler',
    description: 'Erkenne alle Trinkgefäße (Becher, Flasche, Weinglas)',
    objectLabel: 'cup',
    icon: '🥤',
    rarity: AchievementRarity.uncommon,
    targetCount: 3,
  ),
  Achievement(
    id: 'chair_expert',
    title: 'Möbel-Experte',
    description: 'Finde 7 verschiedene Stühle',
    objectLabel: 'chair',
    icon: '🪑',
    rarity: AchievementRarity.common,
    targetCount: 7,
  ),
  Achievement(
    id: 'time_keeper',
    title: 'Zeit-Beobachter',
    description: 'Erkenne 5 verschiedene Uhren',
    objectLabel: 'clock',
    icon: '⏰',
    rarity: AchievementRarity.uncommon,
    targetCount: 5,
  ),
  Achievement(
    id: 'tv_enthusiast',
    title: 'TV-Enthusiast',
    description: 'Finde 10 Fernseher',
    objectLabel: 'tv',
    icon: '📺',
    rarity: AchievementRarity.rare,
    targetCount: 10,
  ),
  Achievement(
    id: 'keyboard_warrior',
    title: 'Tastatur-Krieger',
    description: 'Erkenne 5 verschiedene Tastaturen',
    objectLabel: 'keyboard',
    icon: '⌨️',
    rarity: AchievementRarity.uncommon,
    targetCount: 5,
  ),
  Achievement(
    id: 'adventurer',
    title: 'Abenteurer',
    description: 'Finde einen Rucksack',
    objectLabel: 'backpack',
    icon: '🎒',
    rarity: AchievementRarity.common,
    targetCount: 1,
  ),
];
