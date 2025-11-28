const Map<String, String> countryToLanguage = {
  'FR': 'fr',
  'TN': 'ar',
  'DE': 'de',
  'EE': 'et',
  'LT': 'lt',
  'US': 'en',
  'GB': 'en',
};
String getLanguageForCountry(String countryCode) {
  return countryToLanguage[countryCode.toUpperCase()] ?? 'en';
} 
