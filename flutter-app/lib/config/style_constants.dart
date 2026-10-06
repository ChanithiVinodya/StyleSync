/// Shared style constants across StyleSync client application.
/// Used for home discovery cards, designer matching, and project request forms.
library;

class AppStyleItem {
  final String title;
  final String tag;
  final String? assetPath;
  final String fallbackUrl;

  const AppStyleItem({
    required this.title,
    required this.tag,
    this.assetPath,
    required this.fallbackUrl,
  });
}

class AppStyleConstants {
  /// Constant list of 6 standard style tags matching backend/designer profile metadata
  static const List<String> styleTags = [
    'Modern Minimalist',
    'Scandinavian',
    'Industrial',
    'Bohemian',
    'Coastal',
    'Traditional',
  ];

  /// Curated styles for the Home screen discovery row
  static const List<AppStyleItem> homeStyles = [
    AppStyleItem(
      title: 'Modern Minimalist',
      tag: 'Minimalist',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=800&q=80',
    ),
    AppStyleItem(
      title: 'Scandinavian',
      tag: 'Scandinavian',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?auto=format&fit=crop&w=800&q=80',
    ),
    AppStyleItem(
      title: 'Industrial',
      tag: 'Industrial',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?auto=format&fit=crop&w=800&q=80',
    ),
    AppStyleItem(
      title: 'Bohemian',
      tag: 'Boho Chic',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1586023492125-27b2c045efd7?auto=format&fit=crop&w=800&q=80',
    ),
    AppStyleItem(
      title: 'Coastal',
      tag: 'Coastal',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1507652313519-d4e9174996dd?auto=format&fit=crop&w=800&q=80',
    ),
    AppStyleItem(
      title: 'Traditional',
      tag: 'Traditional',
      assetPath: null,
      // TODO: replace with curated style reference images
      fallbackUrl:
          'https://images.unsplash.com/photo-1618221195710-dd6b41faaea6?auto=format&fit=crop&w=800&q=80',
    ),
  ];
}
