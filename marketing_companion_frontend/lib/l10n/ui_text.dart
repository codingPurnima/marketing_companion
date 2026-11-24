
import 'package:flutter/widgets.dart';

class UiText {
  static bool isHindi(BuildContext context) =>
      Localizations.localeOf(context).languageCode == 'hi';

  static String get(BuildContext context, String key) {
    final hindi = isHindi(context);

    const en = <String, String>{
      'archived': 'Archived',
      'noArchived': 'No archived products yet.',
      'republish': 'Republish',
      'speakGenerate': 'Speak to generate catalog',
      'describeProduct': 'Describe your product',
      'generateCatalog': 'Generate Catalog',
      'startInput': 'Start voice input',
      'stopRecording': 'Stop recording',
      'imageUnavailable': 'Image preview unavailable',
      'untitled': 'Untitled',
      'editProduct': 'Edit product',
      'publishProduct': 'Publish product',
      'unpublishProduct': 'Unpublish product',
      'shareProduct': 'Share product',
      'noImage': 'No image attached',
      'enhancedPreview': 'Enhanced image preview',
      'enhancing': 'Image enhancement is processing.',
      'enhanceFailed': 'Image enhancement failed. You can try again.',
      'enhancedPreviewFailed':
          'Enhanced image is ready, but its preview could not be loaded.',
      'original': 'Use original',
      'enhanced': 'Use enhanced',
      'testEnhancement': 'Test image enhancement',
      'viewEdit': 'View and Edit product',
      'reviewDraft': 'Review and edit draft',
      'productTitle': 'Product title',
      'description': 'Description',
      'category': 'Product Category',
      'pottery': 'Pottery',
      'textiles': 'Textiles',
      'weaving': 'Weaving',
      'woodwork': 'Woodwork',
      'metalwork': 'Metalwork',
      'jewelry': 'Jewelry',
      'paintings': 'Paintings',
      'other': 'Other',
      'priceOptional': 'Price in INR (optional)',
      'images': 'Product images',
      'chooseImage': 'Choose product image',
      'changeImage': 'Change product image',
      'removeImage': 'Remove selected image',
      'uploadLater':
          'This image will be uploaded when you enhance it or save the draft.',
      'comparison': 'Image comparison',
      'noEnhanced': 'No enhanced version available yet.',
      'enhanceImage': 'Enhance product image',
      'updateProduct': 'Update product',
      'retryUpload': 'Retry image upload',
      'saveDraft': 'Save as draft',
      'cancelEditing': 'Cancel editing',
      'selected': 'Currently selected',
      'tapSelect': 'Tap to select',
      'priceNotSet': 'Price not set',
      'productActions': 'Product actions',
      'action': 'Action',
      'loadDrafts': 'Load drafts',
      'noProductsLoaded': 'No products loaded yet.',
      'signOutConfirmTitle': 'Sign out?',
      'signOutConfirm':
          'Are you sure you want to sign out of your account?',
      'cancel': 'Cancel',
      'signOut': 'Sign out',
      'voiceAssistant': 'Artisan Voice Assistant',
      'listening': 'Listening…',
      'voiceHint': 'Try "Load my products" or "Edit blue vase"',
      'speak': 'Speak',
      'runCommand': 'Run command',
      'voiceReady': 'Voice input is ready.',
      'speechUnavailable':
          'Speech recognition is unavailable on this device.',
      'listeningMessage': 'Listening...',
      'capturedMessage': 'Voice input captured. Review the transcription.',
      'publishBeforeShare': 'Publish this product before sharing it.',
      'backProducts': 'Back to products',
      'addProduct': 'Add Product',
      'editProductScreen': 'Edit Product',
      'imageRecordMissing': 'Image record not found.',
      'imageUpdated': 'Image selection updated.',
      'editingMessage': 'Editing product. Update the details and save.',
      'enterTitleDescription':
          'Enter the product title and description first.',
      'chooseImageFirst': 'Choose a product image first.',
      'invalidCategory': 'Choose a valid product category.',
      'invalidPrice': 'Enter a valid price.',
      'createDraftFailed': 'Could not create the product draft.',
      'imageMissing': 'No uploaded product image was found.',
      'enhancedSelected': 'Enhanced image selected.',
      'originalSelected': 'Original image selected',
      'cancelledEditing': 'Product editing cancelled.',
      'clarifyCommand': 'Could you please clarify your command?',
      'whichProduct': 'Which product are you referring to?',
      'savedDraft': 'Draft saved successfully.',
      'savedDraftWithImage': 'Draft saved and image uploaded successfully.',
    };

    const hi = <String, String>{
      'archived': 'आर्काइव किए गए',
      'noArchived': 'अभी कोई आर्काइव उत्पाद नहीं है।',
      'republish': 'फिर से प्रकाशित करें',
      'speakGenerate': 'बोलकर कैटलॉग बनाएँ',
      'describeProduct': 'अपने उत्पाद के बारे में बताएँ',
      'generateCatalog': 'कैटलॉग बनाएँ',
      'startInput': 'बोलकर इनपुट दें',
      'stopRecording': 'रिकॉर्डिंग रोकें',
      'imageUnavailable': 'इमेज का प्रीव्यू उपलब्ध नहीं है',
      'untitled': 'बिना नाम का उत्पाद',
      'editProduct': 'उत्पाद संपादित करें',
      'publishProduct': 'उत्पाद प्रकाशित करें',
      'unpublishProduct': 'प्रकाशन हटाएँ',
      'shareProduct': 'उत्पाद शेयर करें',
      'noImage': 'कोई इमेज नहीं जोड़ी गई',
      'enhancedPreview': 'बेहतर की गई इमेज का प्रीव्यू',
      'enhancing': 'इमेज बेहतर की जा रही है।',
      'enhanceFailed': 'इमेज बेहतर नहीं हो सकी। फिर कोशिश करें।',
      'enhancedPreviewFailed':
          'बेहतर इमेज तैयार है, लेकिन प्रीव्यू लोड नहीं हो सका।',
      'original': 'मूल इमेज इस्तेमाल करें',
      'enhanced': 'बेहतर इमेज इस्तेमाल करें',
      'testEnhancement': 'इमेज सुधार जाँचें',
      'viewEdit': 'उत्पाद देखें और संपादित करें',
      'reviewDraft': 'ड्राफ्ट देखें और संपादित करें',
      'productTitle': 'उत्पाद का नाम',
      'description': 'विवरण',
      'category': 'उत्पाद श्रेणी',
      'pottery': 'मिट्टी के बर्तन',
      'textiles': 'कपड़ा',
      'weaving': 'बुनाई',
      'woodwork': 'लकड़ी का काम',
      'metalwork': 'धातु का काम',
      'jewelry': 'आभूषण',
      'paintings': 'चित्रकारी',
      'other': 'अन्य',
      'priceOptional': 'कीमत (₹, वैकल्पिक)',
      'images': 'उत्पाद की इमेज',
      'chooseImage': 'उत्पाद की इमेज चुनें',
      'changeImage': 'इमेज बदलें',
      'removeImage': 'चुनी हुई इमेज हटाएँ',
      'uploadLater':
          'इमेज बेहतर करने या ड्राफ्ट सेव करने पर अपलोड होगी।',
      'comparison': 'इमेज की तुलना',
      'noEnhanced': 'अभी बेहतर की गई इमेज उपलब्ध नहीं है।',
      'enhanceImage': 'उत्पाद की इमेज बेहतर करें',
      'updateProduct': 'उत्पाद अपडेट करें',
      'retryUpload': 'इमेज अपलोड फिर से करें',
      'saveDraft': 'ड्राफ्ट सेव करें',
      'cancelEditing': 'एडिटिंग रद्द करें',
      'selected': 'अभी चुनी गई',
      'tapSelect': 'चुनने के लिए टैप करें',
      'priceNotSet': 'कीमत नहीं दी गई',
      'productActions': 'उत्पाद विकल्प',
      'action': 'कार्य',
      'loadDrafts': 'ड्राफ्ट लोड करें',
      'noProductsLoaded': 'अभी कोई उत्पाद लोड नहीं है।',
      'signOutConfirmTitle': 'लॉग आउट करें?',
      'signOutConfirm':
          'क्या आप अपने खाते से लॉग आउट करना चाहते हैं?',
      'cancel': 'रद्द करें',
      'signOut': 'लॉग आउट',
      'voiceAssistant': 'कारीगर वॉइस असिस्टेंट',
      'listening': 'सुन रहा है…',
      'voiceHint': 'जैसे "मेरे उत्पाद दिखाओ" या "नीला फूलदान संपादित करो"',
      'speak': 'बोलें',
      'runCommand': 'कमांड चलाएँ',
      'voiceReady': 'वॉइस इनपुट तैयार है।',
      'speechUnavailable': 'इस डिवाइस पर वॉइस पहचान उपलब्ध नहीं है।',
      'listeningMessage': 'सुन रहा है...',
      'capturedMessage': 'आवाज़ रिकॉर्ड हो गई। ट्रांसक्रिप्शन जाँचें।',
      'publishBeforeShare': 'शेयर करने से पहले उत्पाद प्रकाशित करें।',
      'backProducts': 'उत्पादों पर वापस जाएँ',
      'addProduct': 'उत्पाद जोड़ें',
      'editProductScreen': 'उत्पाद संपादित करें',
      'imageRecordMissing': 'इमेज रिकॉर्ड नहीं मिला।',
      'imageUpdated': 'इमेज का चयन अपडेट हो गया।',
      'editingMessage': 'उत्पाद एडिट हो रहा है। विवरण अपडेट करके सेव करें।',
      'enterTitleDescription': 'पहले उत्पाद का नाम और विवरण लिखें।',
      'chooseImageFirst': 'पहले उत्पाद की इमेज चुनें।',
      'invalidCategory': 'सही उत्पाद श्रेणी चुनें।',
      'invalidPrice': 'सही कीमत दर्ज करें।',
      'createDraftFailed': 'उत्पाद ड्राफ्ट नहीं बन सका।',
      'imageMissing': 'अपलोड की गई उत्पाद इमेज नहीं मिली।',
      'enhancedSelected': 'बेहतर की गई इमेज चुनी गई।',
      'originalSelected': 'वास्तविक इमेज चुनी गई।',
      'cancelledEditing': 'उत्पाद एडिटिंग रद्द कर दी गई।',
      'clarifyCommand': 'कृपया अपना कमांड स्पष्ट करें।',
      'whichProduct': 'आप किस उत्पाद की बात कर रहे हैं?',
      'savedDraft': 'ड्राफ्ट सेव हो गया।',
      'savedDraftWithImage': 'ड्राफ्ट इमेज के साथ सेव हो गया।',
    };

    return (hindi ? hi : en)[key] ?? key;
  }

  static String category(BuildContext context, String value) {
    final key = value.toLowerCase().trim();
    const keys = {
      'pottery': 'pottery',
      'textiles': 'textiles',
      'weaving': 'weaving',
      'woodwork': 'woodwork',
      'metalwork': 'metalwork',
      'jewelry': 'jewelry',
      'paintings': 'paintings',
      'other': 'other',
    };
    return get(context, keys[key] ?? 'other');
  }

  static String status(BuildContext context, String value) {
    final key = value.toLowerCase().trim();
    if (key == 'published') {
      return isHindi(context) ? 'प्रकाशित' : 'Published';
    }
    if (key == 'archived') {
      return isHindi(context) ? 'आर्काइव' : 'Archived';
    }
    return isHindi(context) ? 'ड्राफ्ट' : 'Draft';
  }
}
