class AppConstants {
  AppConstants._();

  static const String appName = 'Athar';
  static const String appNameArabic = 'أثر';

  static const List<String> itemTypes = [
    'Passport',
    'Phone',
    'Wallet',
    'Bag',
    'Clothing',
    'Jewelry',
    'Keys',
    'Other',
  ];

  static const List<String> itemTypesArabic = [
    'جواز سفر',
    'هاتف',
    'محفظة',
    'حقيبة',
    'ملابس',
    'مجوهرات',
    'مفاتيح',
    'أخرى',
  ];

  static const List<String> hajjLocations = [
    'Mina',
    'Arafat',
    'Muzdalifah',
    'Masjid Al-Haram',
    'Jamarat',
    'Hotel Area',
    'Other',
  ];

  static const List<String> hajjLocationsArabic = [
    'منى',
    'عرفات',
    'مزدلفة',
    'المسجد الحرام',
    'الجمرات',
    'منطقة الفنادق',
    'أخرى',
  ];

  static const List<String> transportMethods = [
    'Walking',
    'Bus',
    'Car',
    'Train',
    'Other',
  ];

  static const List<String> transportMethodsArabic = [
    'مشياً',
    'حافلة',
    'سيارة',
    'قطار',
    'أخرى',
  ];

  static const double aiMatchThreshold = 0.6;

  static const String passwordPattern = r'^(?=.*[A-Z])(?=.*\d).{8,}$';
}
