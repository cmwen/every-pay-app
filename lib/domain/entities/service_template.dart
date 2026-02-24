class ServiceTemplate {
  final String id;
  final String name;
  final String? provider;
  final String defaultCategoryId;
  final String defaultBillingCycle;
  final double? suggestedAmount;
  final String? logoAsset;
  final String? websiteUrl;

  const ServiceTemplate({
    required this.id,
    required this.name,
    this.provider,
    required this.defaultCategoryId,
    required this.defaultBillingCycle,
    this.suggestedAmount,
    this.logoAsset,
    this.websiteUrl,
  });
}
