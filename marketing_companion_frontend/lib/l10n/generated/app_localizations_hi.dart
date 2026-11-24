// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get languageSettings => 'भाषा';

  @override
  String get selectLanguage => 'ऐप की भाषा चुनें';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get hindi => 'हिंदी';

  @override
  String get appTitle => 'कारीगर कैटलॉग';

  @override
  String get signIn => 'लॉग इन करें';

  @override
  String get createAccount => 'खाता बनाएँ';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get pleaseWait => 'कृपया प्रतीक्षा करें...';

  @override
  String get alreadyRegistered => 'पहले से खाता है? लॉग इन करें';

  @override
  String get newArtisanCreateAccount => 'नए कारीगर हैं? खाता बनाएँ';

  @override
  String get accountCreatedCheckEmail =>
      'खाता बन गया है। पुष्टि करने के लिए अपना ईमेल देखें।';

  @override
  String get authenticationFailed => 'लॉग इन नहीं हो सका।';

  @override
  String get myProducts => 'मेरे उत्पाद';

  @override
  String get myProfile => 'मेरी प्रोफ़ाइल';

  @override
  String get signOut => 'लॉग आउट';

  @override
  String get addProduct => 'उत्पाद जोड़ें';

  @override
  String get yourCatalog => 'आपका कैटलॉग';

  @override
  String productCount(int count) {
    return '$count उत्पाद';
  }

  @override
  String get productCountOne => '1 उत्पाद';

  @override
  String get fetchingProducts => 'उत्पाद लोड हो रहे हैं...';

  @override
  String get couldNotFetchProducts => 'आपके उत्पाद लोड नहीं हो सके।';

  @override
  String get tryAgain => 'फिर कोशिश करें';

  @override
  String get noActiveProducts => 'अभी कोई सक्रिय उत्पाद नहीं है';

  @override
  String get addFirstProductMessage =>
      'अपना कैटलॉग बनाने के लिए पहला उत्पाद जोड़ें।';

  @override
  String get publishedProducts => 'प्रकाशित उत्पाद';

  @override
  String get noPublishedProducts => 'अभी कोई प्रकाशित उत्पाद नहीं है।';

  @override
  String get drafts => 'ड्राफ्ट';

  @override
  String get noDrafts => 'अभी कोई ड्राफ्ट नहीं है।';

  @override
  String get archivedProducts => 'आर्काइव किए गए उत्पाद';

  @override
  String get noArchivedProducts => 'कोई आर्काइव किया गया उत्पाद नहीं है।';

  @override
  String get untitledProduct => 'बिना नाम का उत्पाद';

  @override
  String get otherCategory => 'अन्य';

  @override
  String get republish => 'फिर से प्रकाशित करें';

  @override
  String get publish => 'प्रकाशित करें';

  @override
  String get archive => 'आर्काइव करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get publishProductConfirmation => 'क्या इस उत्पाद को प्रकाशित करें?';

  @override
  String get archiveProductConfirmation => 'क्या इस उत्पाद को आर्काइव करें?';

  @override
  String get republishProductConfirmation =>
      'क्या इस उत्पाद को फिर से प्रकाशित करें?';

  @override
  String get publishProductDescription =>
      'यह उत्पाद ग्राहकों को आपके कैटलॉग में दिखाई देगा।';

  @override
  String get archiveProductDescription =>
      'यह उत्पाद आपके प्रकाशित कैटलॉग से हट जाएगा।';

  @override
  String get republishProductDescription =>
      'यह आर्काइव किया गया उत्पाद फिर से ग्राहकों को दिखाई देगा।';

  @override
  String get profileTitle => 'मेरी कारीगर प्रोफ़ाइल';

  @override
  String get shareProfile => 'प्रोफ़ाइल शेयर करें';

  @override
  String get publicProfileDetails => 'सार्वजनिक प्रोफ़ाइल की जानकारी';

  @override
  String get profileDescription =>
      'इस जानकारी से ग्राहक आपको खोज और संपर्क कर सकते हैं।';

  @override
  String get publicName => 'सार्वजनिक नाम';

  @override
  String get bio => 'परिचय';

  @override
  String get craft => 'कारीगरी';

  @override
  String get district => 'ज़िला';

  @override
  String get state => 'राज्य';

  @override
  String get whatsappNumber => 'व्हाट्सऐप नंबर';

  @override
  String get saveProfile => 'प्रोफ़ाइल सेव करें';

  @override
  String get createPublicProfile => 'अपनी सार्वजनिक कारीगर प्रोफ़ाइल बनाएँ।';

  @override
  String get profileLoaded => 'आपकी प्रोफ़ाइल लोड हो गई है।';

  @override
  String get profileSaved => 'प्रोफ़ाइल सफलतापूर्वक सेव हो गई।';

  @override
  String get profileLoadFailed =>
      'प्रोफ़ाइल लोड नहीं हो सकी। कृपया फिर कोशिश करें।';

  @override
  String get profileSaveFailed =>
      'प्रोफ़ाइल सेव नहीं हो सकी। कृपया फिर कोशिश करें।';

  @override
  String get fieldRequired => 'यह जानकारी देना आवश्यक है।';

  @override
  String get pleaseSignInAgain => 'कृपया फिर से लॉग इन करें।';

  @override
  String get saveBeforeSharing =>
      'शेयर करने से पहले अपनी सार्वजनिक प्रोफ़ाइल सेव करें।';

  @override
  String get shareProfileTitle => 'मेरी प्रोफ़ाइल';

  @override
  String get shareProfileText =>
      'मेरे हस्तनिर्मित उत्पाद और कारीगर प्रोफ़ाइल देखें:';

  @override
  String get shareFailed => 'प्रोफ़ाइल शेयर नहीं हो सकी। कृपया फिर कोशिश करें।';
}
