import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettings;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select app language'**
  String get selectLanguage;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'हिंदी'**
  String get hindi;

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Artisan Catalog'**
  String get appTitle;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccount;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseWait.
  ///
  /// In en, this message translates to:
  /// **'Please wait...'**
  String get pleaseWait;

  /// No description provided for @alreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'Already registered? Sign in'**
  String get alreadyRegistered;

  /// No description provided for @newArtisanCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'New artisan? Create an account'**
  String get newArtisanCreateAccount;

  /// No description provided for @accountCreatedCheckEmail.
  ///
  /// In en, this message translates to:
  /// **'Account created. Check your email to confirm it.'**
  String get accountCreatedCheckEmail;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication failed.'**
  String get authenticationFailed;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My Products'**
  String get myProducts;

  /// No description provided for @myProfile.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get myProfile;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add Product'**
  String get addProduct;

  /// No description provided for @yourCatalog.
  ///
  /// In en, this message translates to:
  /// **'Your catalog'**
  String get yourCatalog;

  /// No description provided for @productCount.
  ///
  /// In en, this message translates to:
  /// **'{count} products'**
  String productCount(int count);

  /// No description provided for @productCountOne.
  ///
  /// In en, this message translates to:
  /// **'1 product'**
  String get productCountOne;

  /// No description provided for @fetchingProducts.
  ///
  /// In en, this message translates to:
  /// **'Fetching products...'**
  String get fetchingProducts;

  /// No description provided for @couldNotFetchProducts.
  ///
  /// In en, this message translates to:
  /// **'Could not fetch your products.'**
  String get couldNotFetchProducts;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @noActiveProducts.
  ///
  /// In en, this message translates to:
  /// **'No active products yet'**
  String get noActiveProducts;

  /// No description provided for @addFirstProductMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first product to start building your catalog.'**
  String get addFirstProductMessage;

  /// No description provided for @publishedProducts.
  ///
  /// In en, this message translates to:
  /// **'Published products'**
  String get publishedProducts;

  /// No description provided for @noPublishedProducts.
  ///
  /// In en, this message translates to:
  /// **'No published products yet.'**
  String get noPublishedProducts;

  /// No description provided for @drafts.
  ///
  /// In en, this message translates to:
  /// **'Drafts'**
  String get drafts;

  /// No description provided for @noDrafts.
  ///
  /// In en, this message translates to:
  /// **'No drafts yet.'**
  String get noDrafts;

  /// No description provided for @archivedProducts.
  ///
  /// In en, this message translates to:
  /// **'Archived products'**
  String get archivedProducts;

  /// No description provided for @noArchivedProducts.
  ///
  /// In en, this message translates to:
  /// **'No archived products.'**
  String get noArchivedProducts;

  /// No description provided for @untitledProduct.
  ///
  /// In en, this message translates to:
  /// **'Untitled product'**
  String get untitledProduct;

  /// No description provided for @otherCategory.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherCategory;

  /// No description provided for @republish.
  ///
  /// In en, this message translates to:
  /// **'Republish'**
  String get republish;

  /// No description provided for @publish.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publish;

  /// No description provided for @archive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @publishProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Publish this product?'**
  String get publishProductConfirmation;

  /// No description provided for @archiveProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Archive this product?'**
  String get archiveProductConfirmation;

  /// No description provided for @republishProductConfirmation.
  ///
  /// In en, this message translates to:
  /// **'Republish this product?'**
  String get republishProductConfirmation;

  /// No description provided for @publishProductDescription.
  ///
  /// In en, this message translates to:
  /// **'This product will become visible to customers in your catalog.'**
  String get publishProductDescription;

  /// No description provided for @archiveProductDescription.
  ///
  /// In en, this message translates to:
  /// **'This product will be removed from your published catalog.'**
  String get archiveProductDescription;

  /// No description provided for @republishProductDescription.
  ///
  /// In en, this message translates to:
  /// **'This archived product will be published again and visible to customers.'**
  String get republishProductDescription;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'My artisan profile'**
  String get profileTitle;

  /// No description provided for @shareProfile.
  ///
  /// In en, this message translates to:
  /// **'Share profile'**
  String get shareProfile;

  /// No description provided for @publicProfileDetails.
  ///
  /// In en, this message translates to:
  /// **'Public profile details'**
  String get publicProfileDetails;

  /// No description provided for @profileDescription.
  ///
  /// In en, this message translates to:
  /// **'These details help customers discover and contact you.'**
  String get profileDescription;

  /// No description provided for @publicName.
  ///
  /// In en, this message translates to:
  /// **'Public name'**
  String get publicName;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @craft.
  ///
  /// In en, this message translates to:
  /// **'Craft'**
  String get craft;

  /// No description provided for @district.
  ///
  /// In en, this message translates to:
  /// **'District'**
  String get district;

  /// No description provided for @state.
  ///
  /// In en, this message translates to:
  /// **'State'**
  String get state;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get whatsappNumber;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get saveProfile;

  /// No description provided for @createPublicProfile.
  ///
  /// In en, this message translates to:
  /// **'Create your public artisan profile.'**
  String get createPublicProfile;

  /// No description provided for @profileLoaded.
  ///
  /// In en, this message translates to:
  /// **'Your profile is loaded.'**
  String get profileLoaded;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved successfully.'**
  String get profileSaved;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to load your profile. Please try again.'**
  String get profileLoadFailed;

  /// No description provided for @profileSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to save your profile. Please try again.'**
  String get profileSaveFailed;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required.'**
  String get fieldRequired;

  /// No description provided for @pleaseSignInAgain.
  ///
  /// In en, this message translates to:
  /// **'Please sign in again.'**
  String get pleaseSignInAgain;

  /// No description provided for @saveBeforeSharing.
  ///
  /// In en, this message translates to:
  /// **'Save your public profile before sharing it.'**
  String get saveBeforeSharing;

  /// No description provided for @shareProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'My profile'**
  String get shareProfileTitle;

  /// No description provided for @shareProfileText.
  ///
  /// In en, this message translates to:
  /// **'Explore my handmade products and artisan profile:'**
  String get shareProfileText;

  /// No description provided for @shareFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to share your profile. Please try again.'**
  String get shareFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
