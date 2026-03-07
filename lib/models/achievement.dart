import 'package:flutter/material.dart';

enum AchievementId {
  firstSteps,
  perfectScore,
  speedDemon,
  persistence,
  mathExplorer,
  centuryClub,
  streakMaster,
  divisionMaster,
  hardModeHero,
  thousandClub,
}

class Achievement {
  final AchievementId id;
  final String name;
  final String description;
  final String hint;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.hint,
    required this.icon,
    required this.color,
  });

  static const List<Achievement> all = [
    Achievement(
      id: AchievementId.firstSteps,
      name: 'First Steps',
      description: 'Complete your first session',
      hint: 'Start practicing!',
      icon: Icons.child_care,
      color: Color(0xFF4CAF50),
    ),
    Achievement(
      id: AchievementId.perfectScore,
      name: 'Perfect Score',
      description: '100% correct on first try',
      hint: 'Get every answer right the first time',
      icon: Icons.star,
      color: Color(0xFFFFD700),
    ),
    Achievement(
      id: AchievementId.speedDemon,
      name: 'Speed Demon',
      description: 'Finish 10+ problems in under 2 minutes',
      hint: 'Be quick!',
      icon: Icons.bolt,
      color: Color(0xFFFF9800),
    ),
    Achievement(
      id: AchievementId.persistence,
      name: 'Persistence',
      description: 'Complete 10 sessions',
      hint: 'Keep coming back!',
      icon: Icons.fitness_center,
      color: Color(0xFF9C27B0),
    ),
    Achievement(
      id: AchievementId.mathExplorer,
      name: 'Math Explorer',
      description: 'Use all 4 operations',
      hint: 'Try every operation type',
      icon: Icons.explore,
      color: Color(0xFF2196F3),
    ),
    Achievement(
      id: AchievementId.centuryClub,
      name: 'Century Club',
      description: 'Solve 100 problems',
      hint: 'Keep solving!',
      icon: Icons.looks_one,
      color: Color(0xFF607D8B),
    ),
    Achievement(
      id: AchievementId.streakMaster,
      name: 'Streak Master',
      description: '3 sessions in a row with >60% first-try',
      hint: 'Build a streak!',
      icon: Icons.local_fire_department,
      color: Color(0xFFFF5722),
    ),
    Achievement(
      id: AchievementId.divisionMaster,
      name: 'Division Master',
      description: '10 division problems correct on first try',
      hint: 'Practice division!',
      icon: Icons.auto_awesome,
      color: Color(0xFF00BCD4),
    ),
    Achievement(
      id: AchievementId.hardModeHero,
      name: 'Hard Mode Hero',
      description: 'Complete Hard with >70% first-try',
      hint: 'Try the hardest difficulty',
      icon: Icons.emoji_events,
      color: Color(0xFFE91E63),
    ),
    Achievement(
      id: AchievementId.thousandClub,
      name: 'Thousand Club',
      description: 'Earn 1000 total XP',
      hint: 'Keep earning XP!',
      icon: Icons.auto_awesome,
      color: Color(0xFF673AB7),
    ),
  ];
}
