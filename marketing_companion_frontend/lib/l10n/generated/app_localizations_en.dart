// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get languageSettings => 'Language';

  @override
  String get selectLanguage => 'Select app language';

  @override
  String get english => 'English';

  @override
  String get hindi => 'हिंदी';

  @override
  String get appTitle => 'Artisan Catalog';

  @override
  String get signIn => 'Sign in';

  @override
  String get createAccount => 'Create account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get pleaseWait => 'Please wait...';

  @override
  String get alreadyRegistered => 'Already registered? Sign in';

  @override
  String get newArtisanCreateAccount => 'New artisan? Create an account';

  @override
  String get accountCreatedCheckEmail =>
      'Account created. Check your email to confirm it.';

  @override
  String get authenticationFailed => 'Authentication failed.';

  @override
  String get myProducts => 'My Products';

  @override
  String get myProfile => 'My profile';

  @override
  String get signOut => 'Sign out';

  @override
  String get addProduct => 'Add Product';

  @override
  String get yourCatalog => 'Your catalog';

  @override
  String productCount(int count) {
    return '$count products';
  }

  @override
  String get productCountOne => '1 product';

  @override
  String get fetchingProducts => 'Fetching products...';

  @override
  String get couldNotFetchProducts => 'Could not fetch your products.';

  @override
  String get tryAgain => 'Try again';

  @override
  String get noActiveProducts => 'No active products yet';

  @override
  String get addFirstProductMessage =>
      'Add your first product to start building your catalog.';

  @override
  String get publishedProducts => 'Published products';

  @override
  String get noPublishedProducts => 'No published products yet.';

  @override
  String get drafts => 'Drafts';

  @override
  String get noDrafts => 'No drafts yet.';

  @override
  String get archivedProducts => 'Archived products';

  @override
  String get noArchivedProducts => 'No archived products.';

  @override
  String get untitledProduct => 'Untitled product';

  @override
  String get otherCategory => 'Other';

  @override
  String get republish => 'Republish';

  @override
  String get publish => 'Publish';

  @override
  String get archive => 'Archive';

  @override
  String get cancel => 'Cancel';

  @override
  String get publishProductConfirmation => 'Publish this product?';

  @override
  String get archiveProductConfirmation => 'Archive this product?';

  @override
  String get republishProductConfirmation => 'Republish this product?';

  @override
  String get publishProductDescription =>
      'This product will become visible to customers in your catalog.';

  @override
  String get archiveProductDescription =>
      'This product will be removed from your published catalog.';

  @override
  String get republishProductDescription =>
      'This archived product will be published again and visible to customers.';
}
