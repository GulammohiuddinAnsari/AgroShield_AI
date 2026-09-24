import 'package:flutter/foundation.dart';

class LocalizationHelper extends ChangeNotifier {
  static final LocalizationHelper instance = LocalizationHelper._init();
  LocalizationHelper._init();

  String currentLang = 'en'; // 'en' for English, 'hi' for Hindi

  void toggleLanguage() {
    currentLang = currentLang == 'en' ? 'hi' : 'en';
    notifyListeners(); // Triggers a global rebuild across all pages
  }

  final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // General App & Common
      'app_title': 'AgroShield AI',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'confidence': 'Confidence',

      // Home Dashboard
      'smart_agri_title': 'Smart Agriculture',
      'smart_agri_desc': 'Use climate insights, crop health AI and agri-business tools in one app.',
      'scanner_title_text': 'AI Crop Health Scanner',
      'scanner_sub_text': 'Detect common potato and tomato leaf conditions offline.',
      'climate_title_text': 'Climate & Seasonal Intelligence',
      'climate_sub_text': 'View a simple seasonal outlook, crop risk and farm actions.',
      'hero_main_title': 'Protect. Predict. Prosper.',
      'hero_main_sub': 'Climate-aware farming decisions connected to an agri-business marketplace.',
      'history_tooltip': 'Scan history & timeline',

      // Climate Screen
      'climate_title': 'Climate Intelligence',
      'refresh_sensors': 'Refresh sensors',
      'live_farm_sensors': 'Live Farm Sensors',
      'firebase_live': 'Firebase LIVE',
      'firebase_live_sensor_data': 'Firebase Live Sensor Data',
      'firebase_desc': 'Connected to Firebase Realtime Database. The latest Plant_Sensor record is read automatically every 3 seconds.',
      'firebase_endpoint': 'Firebase sensor endpoint',
      'auto_refresh_3s': 'Auto refresh every 3 seconds',
      'soil_moisture_raw': 'Soil moisture RAW',
      'ldr_raw': 'LDR RAW',
      'temperature_c': 'Temperature °C',
      'temperature_f': 'Temperature °F',
      'data_status': 'Data status',
      'offline_status': 'Offline',
      'live_status': 'LIVE',
      'raw_sensor_val': 'Raw sensor value',
      'live_temp': 'Live temperature',
      'converted_c': 'Converted from °C',
      'rel_humidity': 'Relative humidity',
      'no_api_resp': 'No API response',
      'sensor_connected': 'Sensor API connected',
      'firebase_connected_msg': 'Firebase connected. The newest Plant_Sensor record is displayed without converting soil moisture or LDR to percentages.',
      'recommended_farm_actions': 'Recommended farm actions',
      'business_opportunity': 'Business opportunity',
      'open_business_hub': 'Open Agri Business Hub',

      // Scanner Screen
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
      'no_treatment': 'No treatment data found.',
      'no_prevention': 'No prevention data found.',

      // History Screen
      'history_title': 'Scan History & Timeline',
      'no_history': 'No scan history found yet.\nScan a leaf to start building your timeline!',
      'delete_title': 'Delete History Item',
      'delete_content': 'Are you sure you want to remove this scan from your history?',
      'delete_success': 'Scan removed from history',

      // Business Hub Screen
      'business_title': 'Agri Business Hub',
      'market_tab': 'Market',
      'services_tab': 'Services',
      'sell_tab': 'Sell Produce',
      'revenue_tab': 'Revenue',
      'climate_market': 'Climate-linked marketplace',
      'climate_market_desc': 'Products can be promoted based on farm and seasonal needs.',
      'premium_title': 'AgroShield Premium',
      'premium_desc': 'Advanced reports, deeper analytics and personalized farm insights — ₹99/month.',
      'premium_active': 'Premium Active',
      'join_btn': 'Join',
      'active_btn': 'Active',
      'buy_btn': 'Buy',
      'farm_services': 'Farm Services',
      'farm_services_desc': 'Book useful services without leaving the app.',
      'book_btn': 'Book',
      'sell_produce_title': 'Sell My Produce',
      'sell_produce_desc': 'Demo listings show how farmers can connect with buyers.',
      'list_btn': 'List',
      'business_analytics': 'Business Analytics',
      'business_analytics_desc': 'Live demo values from actions performed in this session.',
      'platform_revenue': 'Platform revenue',
      'transactions': 'Transactions',
      'revenue_model': 'Revenue model',
    },
    'hi': {
      // General App & Common
      'app_title': 'एग्रोशील्ड एआई',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'confidence': 'विश्वास',

      // Home Dashboard
      'smart_agri_title': 'स्मार्ट कृषि',
      'smart_agri_desc': 'एक ही ऐप में जलवायु अंतर्दृष्टि, फसल स्वास्थ्य एआई और कृषि-व्यवसाय टूल का उपयोग करें।',
      'scanner_title_text': 'एआई फसल स्वास्थ्य स्कैनर',
      'scanner_sub_text': 'ऑफ़लाइन सामान्य आलू और टमाटर की पत्ती की स्थिति का पता लगाएं।',
      'climate_title_text': 'जलवायु और मौसमी बुद्धिमत्ता',
      'climate_sub_text': 'एक साधारण मौसमी दृष्टिकोण, फसल जोखिम और कृषि कार्य देखें।',
      'hero_main_title': 'सुरक्षा करें। अनुमान लगाएं। समृद्ध बनें।',
      'hero_main_sub': 'कृषि-व्यवसाय बाजार से जुड़े जलवायु-जागरूक कृषि निर्णय।',
      'history_tooltip': 'स्कैन इतिहास और समयरेखा',

      // Climate Screen
      'climate_title': 'जलवायु बुद्धिमत्ता',
      'refresh_sensors': 'सेंसर रीफ्रेश करें',
      'live_farm_sensors': 'लाइव फार्म सेंसर',
      'firebase_live': 'फ़ायरबेस लाइव',
      'firebase_live_sensor_data': 'फ़ायरबेस लाइव सेंसर डेटा',
      'firebase_desc': 'फ़ायरबेस रियलटाइम डेटाबेस से कनेक्ट किया गया। नवीनतम Plant_Sensor रिकॉर्ड स्वचालित रूप से हर 3 सेकंड में पढ़ा जाता है।',
      'firebase_endpoint': 'फ़ायरबेस सेंसर एंडपॉइंट',
      'auto_refresh_3s': 'हर 3 सेकंड में ऑटो रीफ्रेश',
      'soil_moisture_raw': 'मिट्टी की नमी रॉ',
      'ldr_raw': 'एलडीआर रॉ',
      'temperature_c': 'तापमान °C',
      'temperature_f': 'तापमान °F',
      'data_status': 'डेटा स्थिति',
      'offline_status': 'ऑफ़लाइन',
      'live_status': 'लाइव',
      'raw_sensor_val': 'रॉ सेंसर मान',
      'live_temp': 'लाइव तापमान',
      'converted_c': '°C से रूपांतरित',
      'rel_humidity': 'सापेक्ष आर्द्रता',
      'no_api_resp': 'कोई API प्रतिक्रिया नहीं',
      'sensor_connected': 'सेंसर API कनेक्टेड',
      'firebase_connected_msg': 'फ़ायरबेस कनेक्टेड। मिट्टी की नमी या एलडीआर को प्रतिशत में परिवर्तित किए बिना नवीनतम Plant_Sensor रिकॉर्ड प्रदर्शित किया जाता है।',
      'recommended_farm_actions': 'अनुशंसित कृषि कार्य',
      'business_opportunity': 'व्यापार अवसर',
      'open_business_hub': 'कृषि व्यवसाय केंद्र खोलें',

      // Scanner Screen
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
      'no_treatment': 'कोई उपचार डेटा नहीं मिला।',
      'no_prevention': 'कोई रोकथाम डेटा नहीं मिला।',

      // History Screen
      'history_title': 'स्कैन इतिहास और समयरेखा',
      'no_history': 'अभी तक कोई स्कैन इतिहास नहीं मिला।\nअपनी समयरेखा बनाने के लिए एक पत्ती स्कैन करें!',
      'delete_title': 'इतिहास आइटम हटाएं',
      'delete_content': 'क्या आप वाकई इस स्कैन को अपने इतिहास से हटाना चाहते हैं?',
      'delete_success': 'स्कैन इतिहास से हटा दिया गया',

      // Business Hub Screen
      'business_title': 'कृषि व्यवसाय केंद्र',
      'market_tab': 'बाज़ार',
      'services_tab': 'सेवाएं',
      'sell_tab': 'उत्पाद बेचें',
      'revenue_tab': 'राजस्व',
      'climate_market': 'जलवायु-संबद्ध बाज़ार',
      'climate_market_desc': 'खेती और मौसमी आवश्यकताओं के आधार पर उत्पादों का प्रचार किया जा सकता है।',
      'premium_title': 'एग्रोशील्ड प्रीमियम',
      'premium_desc': 'उन्नत रिपोर्ट, गहन विश्लेषण और व्यक्तिगत कृषि अंतर्दृष्टि — ₹99/माह।',
      'premium_active': 'प्रीमियम सक्रिय',
      'join_btn': 'शामिल हों',
      'active_btn': 'सक्रिय',
      'buy_btn': 'खरीदें',
      'farm_services': 'कृषि सेवाएं',
      'farm_services_desc': 'ऐप छोड़े बिना उपयोगी सेवाएं बुक करें।',
      'book_btn': 'बुक करें',
      'sell_produce_title': 'मेरी उपज बेचें',
      'sell_produce_desc': 'डेमो लिस्टिंग दिखाती है कि किसान खरीदारों से कैसे जुड़ सकते हैं।',
      'list_btn': 'सूची',
      'business_analytics': 'व्यापार विश्लेषण',
      'business_analytics_desc': 'इस सत्र में निष्पादित क्रियाओं से लाइव डेमो मान।',
      'platform_revenue': 'प्लेटफ़ॉर्म राजस्व',
      'transactions': 'लेन-देन',
      'revenue_model': 'राजस्व मॉडल',
    },
  };

  String translate(String key) {
    return _localizedValues[currentLang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}