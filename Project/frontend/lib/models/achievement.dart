/// Repräsentiert ein Achievement im VisionQuest Spiel.
///
/// Achievements werden durch verschiedene Aktionen freigeschaltet:
/// - [AchievementType.objectScan]: Erkenne bestimmte Objekte X-mal
/// - [AchievementType.milestone]: Erreiche spielinterne Meilensteine (Level, XP, Streak)
/// - [AchievementType.meta]: Meta-Achievements (z.B. alle anderen freischalten)
class Achievement {
  /// Erstellt ein neues Achievement.
  ///
  /// [id] ist der eindeutige Identifier (z.B. 'phone_finder')
  /// [objectLabel] ist nur bei [AchievementType.objectScan] erforderlich
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

  /// Eindeutige ID des Achievements (wird im Backend gespeichert)
  final String id;

  /// Anzeigename des Achievements
  final String title;

  /// Beschreibung was zu tun ist
  final String description;

  /// Label des zu erkennenden Objekts (nur bei objectScan-Type)
  final String? objectLabel;

  /// Emoji-Icon zur Darstellung
  final String icon;

  /// Seltenheit bestimmt die Sterne-Anzeige
  final AchievementRarity rarity;

  /// Anzahl der benötigten Scans/Level/XP für Freischaltung
  final int targetCount;

  /// Type bestimmt wie das Achievement freigeschaltet wird
  final AchievementType type;

  /// Gibt an ob das Achievement bereits freigeschaltet wurde
  bool isUnlocked;

  /// Zeitpunkt der Freischaltung (null wenn noch gesperrt)
  /// Zeitpunkt der Freischaltung (null wenn noch gesperrt)
  DateTime? unlockedDate;

  /// Erstellt eine Kopie mit optional geänderten Werten.
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

/// Definiert die Art wie ein Achievement freigeschaltet wird.
enum AchievementType {
  /// Erkenne ein bestimmtes Objekt X-mal (z.B. "5 Handys scannen")
  objectScan,

  /// Erreiche einen Spielfortschritt (Level, XP, Streak)
  milestone,

  /// Meta-Achievement (z.B. "Alle anderen Achievements freischalten")
  meta,
}

/// Bestimmt die Seltenheit und Sternanzahl eines Achievements.
enum AchievementRarity {
  /// Häufig - 1 Stern
  common('Häufig', '⭐'),

  /// Selten - 2 Sterne
  uncommon('Selten', '⭐⭐'),

  /// Sehr Selten - 3 Sterne
  rare('Sehr Selten', '⭐⭐⭐'),

  /// Episch - 4 Sterne
  epic('Episch', '⭐⭐⭐⭐'),

  /// Legendär - 5 Sterne
  legendary('Legendär', '⭐⭐⭐⭐⭐');

  const AchievementRarity(this.displayName, this.stars);

  final String displayName;
  final String stars;
}

/// Globale Liste aller verfügbaren Achievements in VisionQuest.
///
/// Strukturiert in drei Kategorien:
/// 1. **Object Scan** (10 Achievements) - Erkenne bestimmte Objekte
/// 2. **Milestone** (4 Achievements) - Erreiche Spielfortschritte
/// 3. **Meta** (1 Achievement) - Completionist-Achievement
///
/// Insgesamt: 15 Achievements
final allAchievements = [
  // ========== OBJECT SCAN ACHIEVEMENTS (10) ==========
  // Diese Achievements werden im Scanner als Quests angezeigt
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

  // ========== MILESTONE ACHIEVEMENTS (4) ==========
  // Diese werden automatisch bei Erreichen des Ziels freigeschaltet
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

  // ========== META ACHIEVEMENT (1) ==========
  // Wird freigeschaltet wenn alle anderen (14) freigeschaltet sind
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
