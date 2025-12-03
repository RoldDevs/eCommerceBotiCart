import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeColors {
  final String primary;
  final String secondary;
  final String accent;
  final String background;
  final String card;
  final String text;

  ThemeColors({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.background,
    required this.card,
    required this.text,
  });

  factory ThemeColors.fromMap(Map<String, dynamic> map) {
    return ThemeColors(
      primary: map['primary'] ?? '#0D1B2A',
      secondary: map['secondary'] ?? '#1B263B',
      accent: map['accent'] ?? '#F4A261',
      background: map['background'] ?? '#415A77',
      card: map['card'] ?? '#778DA9',
      text: map['text'] ?? '#E0E1DD',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primary': primary,
      'secondary': secondary,
      'accent': accent,
      'background': background,
      'card': card,
      'text': text,
    };
  }
}

class PharmacyTheme {
  final String id;
  final String themeName;
  final String description;
  final double price;
  final String availability;
  final ThemeColors colors;
  final DateTime? createdAt;

  PharmacyTheme({
    required this.id,
    required this.themeName,
    required this.description,
    required this.price,
    required this.availability,
    required this.colors,
    this.createdAt,
  });

  factory PharmacyTheme.fromFirestore(Map<String, dynamic> data, String id) {
    return PharmacyTheme(
      id: id,
      themeName: data['themeName'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      availability: data['availability'] ?? 'paid',
      colors: data['colors'] != null
          ? ThemeColors.fromMap(Map<String, dynamic>.from(data['colors']))
          : ThemeColors.fromMap({}),
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] is DateTime
                ? data['createdAt'] as DateTime
                : (data['createdAt'] as Timestamp).toDate())
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'themeName': themeName,
      'description': description,
      'price': price,
      'availability': availability,
      'colors': colors.toMap(),
      'createdAt': createdAt,
    };
  }

  PharmacyTheme copyWith({
    String? id,
    String? themeName,
    String? description,
    double? price,
    String? availability,
    ThemeColors? colors,
    DateTime? createdAt,
  }) {
    return PharmacyTheme(
      id: id ?? this.id,
      themeName: themeName ?? this.themeName,
      description: description ?? this.description,
      price: price ?? this.price,
      availability: availability ?? this.availability,
      colors: colors ?? this.colors,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
