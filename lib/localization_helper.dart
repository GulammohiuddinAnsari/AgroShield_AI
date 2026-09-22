class LocalizationHelper {
  static final LocalizationHelper instance = LocalizationHelper._init();
  LocalizationHelper._init();

  String currentLang = 'en'; // 'en' for English, 'hi' for Hindi

  void toggleLanguage() {
    currentLang = currentLang == 'en' ? 'hi' : 'en';
  }

  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Home / Scanner Screen
      'app_title': 'AgroShield AI',
      'scanner_title': 'Crop Health Scanner',
      'scanner_subtitle': 'Capture or upload a leaf to run real-time AI diagnosis.',
      'capture_photo': 'Capture Leaf Photo',
      'upload_gallery': 'Upload from Gallery',
      'run_diagnosis': 'Run AI Diagnosis',
      'clear_image': 'Clear Image',
      'model_ready': 'Offline TFLite Model Ready',
      'loading_model': 'Loading Model...',
      'analyzing': 'Analyzing leaf patterns...',
      'running_ai': 'Running neural network model locally.',
      'no_image': 'No leaf selected yet',
      'image_hint': 'Take a photo or choose from gallery',
      
      // Result Screen
      'analysis_title': 'Disease Analysis & Remedies',
      'detected_condition': 'Detected Condition',
      'confidence_match': 'Match',
      'crop_type': 'Crop Type',
      'severity': 'Severity',
      'treatment_remedy': 'Treatment Remedy',
      'prevention_guidelines': 'Prevention Guidelines',
      'iot_action': 'IoT Hardware Action',
      'no_treatment': 'No treatment data found.',
      'no_prevention': 'No prevention data found.',
      'standard_monitoring': 'Standard monitoring.',

      // History Screen
      'history_title': 'Scan History & Timeline',
      'no_history': 'No scan history found yet.\nScan a leaf to start building your timeline!',
      'confidence': 'Confidence',
      'delete_title': 'Delete History Item',
      'delete_content': 'Are you sure you want to remove this scan from your history?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'delete_success': 'Scan removed from history',
    },
    'hi': {
      // Home / Scanner Screen
      'app_title': 'एग्रोशील्ड एआई',
      'scanner_title': 'फसल स्वास्थ्य स्कैनर',
      'scanner_subtitle': 'वास्तविक समय एआई निदान के लिए पत्ती की फोटो लें या अपलोड करें।',
      'capture_photo': 'पत्ती की फोटो खींचें',
      'upload_gallery': 'गैलरी से अपलोड करें',
      'run_diagnosis': 'एआई निदान चलाएं',
      'clear_image': 'छवि साफ़ करें',
      'model_ready': 'ऑफ़लाइन TFLite मॉडल तैयार है',
      'loading_model': 'मॉडल लोड हो रहा है...',
      'analyzing': 'पत्ती के पैटर्न का विश्लेषण किया जा रहा है...',
      'running_ai': 'स्थानीय रूप से न्यूरल नेटवर्क मॉडल चल रहा है।',
      'no_image': 'अभी तक कोई पत्ती नहीं चुनी गई',
      'image_hint': 'फोटो लें या गैलरी से चुनें',

      // Result Screen
      'analysis_title': 'रोग विश्लेषण और उपचार',
      'detected_condition': 'पहचाने गए लक्षण',
      'confidence_match': 'मिलान',
      'crop_type': 'फसल का प्रकार',
      'severity': 'गंभीरता',
      'treatment_remedy': 'उपचार उपाय',
      'prevention_guidelines': 'रोकथाम दिशानिर्देश',
      'iot_action': 'IoT हार्डवेयर कार्रवाई',
      'no_treatment': 'कोई उपचार डेटा नहीं मिला।',
      'no_prevention': 'कोई रोकथाम डेटा नहीं मिला।',
      'standard_monitoring': 'मानक निगरानी।',

      // History Screen
      'history_title': 'स्कैन इतिहास और समयरेखा',
      'no_history': 'अभी तक कोई स्कैन इतिहास नहीं मिला।\nअपनी समयरेखा बनाने के लिए एक पत्ती स्कैन करें!',
      'confidence': 'विश्वास',
      'delete_title': 'इतिहास आइटम हटाएं',
      'delete_content': 'क्या आप वाकई इस स्कैन को अपने इतिहास से हटाना चाहते हैं?',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'delete_success': 'स्कैन इतिहास से हटा दिया गया',
    },
  };

  String translate(String key) {
    return _localizedValues[currentLang]?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}