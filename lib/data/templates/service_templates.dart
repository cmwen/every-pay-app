import 'package:everypay/domain/entities/service_template.dart';

const serviceTemplates = <ServiceTemplate>[
  // Entertainment & Streaming
  ServiceTemplate(
    id: 'tpl-netflix',
    name: 'Netflix',
    provider: 'Netflix Inc.',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-spotify',
    name: 'Spotify',
    provider: 'Spotify AB',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-disney-plus',
    name: 'Disney+',
    provider: 'The Walt Disney Company',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-apple-music',
    name: 'Apple Music',
    provider: 'Apple Inc.',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-youtube-premium',
    name: 'YouTube Premium',
    provider: 'Google LLC',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-hbo-max',
    name: 'HBO Max',
    provider: 'Warner Bros. Discovery',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-amazon-prime',
    name: 'Amazon Prime',
    provider: 'Amazon.com Inc.',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'yearly',
  ),
  ServiceTemplate(
    id: 'tpl-apple-tv-plus',
    name: 'Apple TV+',
    provider: 'Apple Inc.',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-hulu',
    name: 'Hulu',
    provider: 'The Walt Disney Company',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-peacock',
    name: 'Peacock',
    provider: 'NBCUniversal',
    defaultCategoryId: 'cat-entertainment',
    defaultBillingCycle: 'monthly',
  ),

  // Software & Cloud
  ServiceTemplate(
    id: 'tpl-icloud',
    name: 'iCloud+',
    provider: 'Apple Inc.',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-google-one',
    name: 'Google One',
    provider: 'Google LLC',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-microsoft-365',
    name: 'Microsoft 365',
    provider: 'Microsoft Corporation',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'yearly',
  ),
  ServiceTemplate(
    id: 'tpl-dropbox',
    name: 'Dropbox',
    provider: 'Dropbox Inc.',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-adobe-cc',
    name: 'Adobe Creative Cloud',
    provider: 'Adobe Inc.',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-notion',
    name: 'Notion',
    provider: 'Notion Labs Inc.',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-github',
    name: 'GitHub Pro',
    provider: 'GitHub Inc.',
    defaultCategoryId: 'cat-software',
    defaultBillingCycle: 'monthly',
  ),

  // Utilities & Bills
  ServiceTemplate(
    id: 'tpl-electricity',
    name: 'Electricity',
    defaultCategoryId: 'cat-utilities',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-gas',
    name: 'Gas',
    defaultCategoryId: 'cat-utilities',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-water',
    name: 'Water',
    defaultCategoryId: 'cat-utilities',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-internet',
    name: 'Internet',
    defaultCategoryId: 'cat-utilities',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-phone-plan',
    name: 'Phone Plan',
    defaultCategoryId: 'cat-utilities',
    defaultBillingCycle: 'monthly',
  ),

  // Insurance
  ServiceTemplate(
    id: 'tpl-health-insurance',
    name: 'Health Insurance',
    defaultCategoryId: 'cat-insurance',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-car-insurance',
    name: 'Car Insurance',
    defaultCategoryId: 'cat-insurance',
    defaultBillingCycle: 'yearly',
  ),
  ServiceTemplate(
    id: 'tpl-home-insurance',
    name: 'Home Insurance',
    defaultCategoryId: 'cat-insurance',
    defaultBillingCycle: 'yearly',
  ),
  ServiceTemplate(
    id: 'tpl-life-insurance',
    name: 'Life Insurance',
    defaultCategoryId: 'cat-insurance',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-pet-insurance',
    name: 'Pet Insurance',
    defaultCategoryId: 'cat-insurance',
    defaultBillingCycle: 'monthly',
  ),

  // Health & Fitness
  ServiceTemplate(
    id: 'tpl-gym',
    name: 'Gym Membership',
    defaultCategoryId: 'cat-health',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-apple-fitness',
    name: 'Apple Fitness+',
    provider: 'Apple Inc.',
    defaultCategoryId: 'cat-health',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-peloton',
    name: 'Peloton',
    provider: 'Peloton Interactive',
    defaultCategoryId: 'cat-health',
    defaultBillingCycle: 'monthly',
  ),

  // Education
  ServiceTemplate(
    id: 'tpl-coursera',
    name: 'Coursera Plus',
    provider: 'Coursera Inc.',
    defaultCategoryId: 'cat-education',
    defaultBillingCycle: 'monthly',
  ),
  ServiceTemplate(
    id: 'tpl-duolingo',
    name: 'Duolingo Plus',
    provider: 'Duolingo Inc.',
    defaultCategoryId: 'cat-education',
    defaultBillingCycle: 'yearly',
  ),
];
