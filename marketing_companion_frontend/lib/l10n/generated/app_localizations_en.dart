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

  @override
  String get profileTitle => 'My artisan profile';

  @override
  String get shareProfile => 'Share profile';

  @override
  String get publicProfileDetails => 'Public profile details';

  @override
  String get profileDescription =>
      'These details help customers discover and contact you.';

  @override
  String get publicName => 'Public name';

  @override
  String get bio => 'Bio';

  @override
  String get craft => 'Craft';

  @override
  String get district => 'District';

  @override
  String get state => 'State';

  @override
  String get whatsappNumber => 'WhatsApp number';

  @override
  String get saveProfile => 'Save profile';

  @override
  String get createPublicProfile => 'Create your public artisan profile.';

  @override
  String get profileLoaded => 'Your profile is loaded.';

  @override
  String get profileSaved => 'Profile saved successfully.';

  @override
  String get profileLoadFailed =>
      'Unable to load your profile. Please try again.';

  @override
  String get profileSaveFailed =>
      'Unable to save your profile. Please try again.';

  @override
  String get fieldRequired => 'This field is required.';

  @override
  String get pleaseSignInAgain => 'Please sign in again.';

  @override
  String get saveBeforeSharing => 'Save your public profile before sharing it.';

  @override
  String get shareProfileTitle => 'My profile';

  @override
  String get shareProfileText =>
      'Explore my handmade products and artisan profile:';

  @override
  String get shareFailed => 'Unable to share your profile. Please try again.';
}
