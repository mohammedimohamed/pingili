class Business {
  final String id;
  final String name;
  final String slug;
  final String? logoUrl;
  final String themeColor;
  final String tagline;

  Business({
    required this.id,
    required this.name,
    required this.slug,
    this.logoUrl,
    this.themeColor = '#f97316',
    this.tagline = 'Order Ready Notification',
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      logoUrl: json['logo_url'] as String?,
      themeColor: json['theme_color'] as String? ?? '#f97316',
      tagline: json['tagline'] as String? ?? 'Order Ready Notification',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'logo_url': logoUrl,
      'theme_color': themeColor,
      'tagline': tagline,
    };
  }
}
