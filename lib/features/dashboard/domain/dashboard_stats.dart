class DashboardStat {
  final String label;
  final String value;
  final String? icon;
  final String? change;
  final bool? isPositive;

  DashboardStat({
    required this.label,
    required this.value,
    this.icon,
    this.change,
    this.isPositive,
  });

  factory DashboardStat.fromJson(Map<String, dynamic> json) {
    return DashboardStat(
      label: json['label'] as String,
      value: json['value'] as String,
      icon: json['icon'] as String?,
      change: json['change'] as String?,
      isPositive: json['is_positive'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      if (icon != null) 'icon': icon,
      if (change != null) 'change': change,
      if (isPositive != null) 'is_positive': isPositive,
    };
  }
}
