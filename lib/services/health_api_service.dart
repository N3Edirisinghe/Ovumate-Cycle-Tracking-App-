import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ovumate/models/chat_message.dart';
import 'package:easy_localization/easy_localization.dart';

class HealthAPIService {
  // Health knowledge base with comprehensive information
  static const Map<String, Map<String, dynamic>> _healthKnowledgeBase = {
    'menstrual_cycle': {
      'en': {
        'title': 'Menstrual Cycle',
        'description': 'The menstrual cycle is a natural process that occurs in women of reproductive age.',
        'phases': [
          'Menstrual Phase (Days 1-5): Period occurs, uterine lining sheds',
          'Follicular Phase (Days 1-13): Follicles mature in ovaries',
          'Ovulatory Phase (Day 14): Egg is released from ovary',
          'Luteal Phase (Days 15-28): Uterus prepares for pregnancy'
        ],
        'tips': [
          'Track your cycle length (typically 21-35 days)',
          'Monitor symptoms and patterns',
          'Maintain a healthy lifestyle with regular exercise',
          'Eat a balanced diet rich in iron and vitamins'
        ]
      },
      'si': {
        'title': 'මාසික චක්‍රය',
        'description': 'මාසික චක්‍රය යනු ගැබ්ගැනීමේ වයසේ සිටින කාන්තාවන් තුළ සිදුවන ස්වාභාවික ක්‍රියාවලියකි.',
        'phases': [
          'මාසික අවධිය (දින 1-5): රුධිරය ගලයි, ගර්භාශයේ ඇතුළත තට්ටුව ඉවත් වේ',
          'බීජකෝෂ අවධිය (දින 1-13): බීජකෝෂ ගැබ්ගැනීමේ අවයවවල පරිණත වේ',
          'බීජ මුක්ෂණ අවධිය (දින 14): බීජය බීජකෝෂයෙන් මුදා හරිනු ලැබේ',
          'පීතු අවධිය (දින 15-28): ගර්භාශය ගැබ්ගැනීම සඳහා සූදානම් වේ'
        ],
        'tips': [
          'ඔබේ චක්‍රයේ දිග ලියාපදිංචි කරන්න (සාමාන්‍යයෙන් 21-35 දින)',
          'රෝග ලක්ෂණ සහ රටා අධීක්ෂණය කරන්න',
          'සාමාන්‍ය ව්‍යායාම සමඟ සෞඛ්‍ය සම්පන්න ජීවන රටාවක් පවත්වාගන්න',
          'යකඩ සහ විටමින් බහුල සමබර ආහාර වේලක් අනුභව කරන්න'
        ]
      },
      'ta': {
        'title': 'மாதவிடாய் சுழற்சி',
        'description': 'மாதவிடாய் சுழற்சி என்பது இனப்பெருக்க வயதில் உள்ள பெண்களுக்கு நிகழும் இயற்கையான செயல்முறையாகும்.',
        'phases': [
          'மாதவிடாய் கட்டம் (நாட்கள் 1-5): மாதவிடாய் நிகழ்கிறது, கருப்பை உட்படலம் உதிர்கிறது',
          'ஃபோலிகுலர் கட்டம் (நாட்கள் 1-13): கருப்பையில் நுண்குமிழ்கள் முதிர்ச்சியடைகின்றன',
          'கருமுட்டை வெளியீட்டு கட்டம் (நாள் 14): கருமுட்டை கருப்பையிலிருந்து வெளியிடப்படுகிறது',
          'லூட்டியல் கட்டம் (நாட்கள் 15-28): கருப்பை கர்ப்பத்திற்கு தயாராகிறது'
        ],
        'tips': [
          'உங்கள் சுழற்சி நீளத்தை கண்காணிக்கவும் (பொதுவாக 21-35 நாட்கள்)',
          'அறிகுறிகள் மற்றும் வடிவங்களை கண்காணிக்கவும்',
          'வழக்கமான உடற்பயிற்சியுடன் ஆரோக்கியமான வாழ்க்கை முறையை பராமரிக்கவும்',
          'இரும்பு மற்றும் வைட்டமின்கள் நிறைந்த சமச்சீர் உணவை சாப்பிடவும்'
        ]
      }
    },
    'ovulation': {
      'en': {
        'title': 'Ovulation & Fertility',
        'description': 'Ovulation is when a mature egg is released from the ovary, making pregnancy possible.',
        'signs': [
          'Cervical mucus becomes clear and stretchy',
          'Basal body temperature increases slightly',
          'Mild pelvic pain or twinges',
          'Increased libido and energy',
          'Breast tenderness'
        ],
        'tracking': [
          'Use ovulation predictor kits',
          'Monitor cervical mucus changes',
          'Track basal body temperature',
          'Use fertility tracking apps',
          'Watch for physical symptoms'
        ]
      },
      'si': {
        'title': 'බීජ මුක්ෂණය සහ ගැබ්ගැනීම',
        'description': 'බීජ මුක්ෂණය යනු පරිණත බීජයක් බීජකෝෂයෙන් මුදා හරිනු ලැබීමයි, එමගින් ගැබ්ගැනීම හැකි වේ.',
        'signs': [
          'ගර්භාශයේ ලේඛනය පැහැදිලි සහ දිගු වේ',
          'මූලික ශරීර උෂ්ණත්වය ටිකක් ඉහළ යේ',
          'සැහැල්ලු උදර වේදනාව හෝ ඇදීම',
          'ආශාව සහ ශක්තිය වැඩි වේ',
          'ස්තන වේදනාව'
        ],
        'tracking': [
          'බීජ මුක්ෂණ පුරෝකථන කට්ටල භාවිතා කරන්න',
          'ගර්භාශයේ ලේඛන වෙනස්කම් අධීක්ෂණය කරන්න',
          'මූලික ශරීර උෂ්ණත්වය ලියාපදිංචි කරන්න',
          'ගැබ්ගැනීම ලුහුබැඳීමේ යෙදුම් භාවිතා කරන්න',
          'ශාරීරික රෝග ලක්ෂණ නිරීක්ෂණය කරන්න'
        ]
      },
      'ta': {
        'title': 'கருமுட்டை வெளியீடு & கருவுறுதல்',
        'description': 'கருமுட்டை வெளியீடு என்பது முதிர்ந்த கருமுட்டை கருப்பையிலிருந்து வெளியிடப்படும்போது, கர்ப்பம் சாத்தியமாகிறது.',
        'signs': [
          'கருப்பை வாய் சளி தெளிவாகவும் நீட்டிக்கக்கூடியதாகவும் மாறுகிறது',
          'அடிப்படை உடல் வெப்பநிலை சற்று அதிகரிக்கிறது',
          'லேசான இடுப்பு வலி அல்லது சுழற்சி',
          'பாலியல் விருப்பம் மற்றும் ஆற்றல் அதிகரிப்பு',
          'மார்பக வலி'
        ],
        'tracking': [
          'கருமுட்டை வெளியீட்டு முன்னறிவிப்பு கருவிகளை பயன்படுத்தவும்',
          'கருப்பை வாய் சளி மாற்றங்களை கண்காணிக்கவும்',
          'அடிப்படை உடல் வெப்பநிலையை கண்காணிக்கவும்',
          'கருவுறுதல் கண்காணிப்பு பயன்பாடுகளை பயன்படுத்தவும்',
          'உடல் அறிகுறிகளை கவனிக்கவும்'
        ]
      }
    },
    'period_health': {
      'en': {
        'title': 'Period Health & Management',
        'description': 'Managing your period health involves understanding symptoms and maintaining wellness.',
        'common_symptoms': [
          'Cramps and abdominal pain',
          'Fatigue and mood changes',
          'Bloating and water retention',
          'Headaches and back pain',
          'Food cravings'
        ],
        'management': [
          'Use heating pads for cramps',
          'Practice gentle exercise like yoga',
          'Stay hydrated and eat nutritious foods',
          'Get adequate rest and sleep',
          'Consider over-the-counter pain relief if needed'
        ]
      },
      'si': {
        'title': 'මාසික රෝග සෞඛ්‍යය සහ කළමනාකරණය',
        'description': 'ඔබේ මාසික රෝග සෞඛ්‍යය කළමනාකරණය කිරීමට රෝග ලක්ෂණ තේරුම්ගැනීම සහ සෞඛ්‍යය පවත්වාගැනීම ඇතුළත් වේ.',
        'common_symptoms': [
          'ඇදීම් සහ උදර වේදනාව',
          'අවසානය සහ මනෝභාව වෙනස්කම්',
          'ඉදිමීම සහ ජලය රඳවා ගැනීම',
          'හිසරදය සහ පිටුපස වේදනාව',
          'ආහාර ආශාව'
        ],
        'management': [
          'ඇදීම් සඳහා උණුසුම් තට්ටු භාවිතා කරන්න',
          'යෝගා වැනි සැහැල්ලු ව්‍යායාම කරන්න',
          'ජලය පානය කර පෝෂණ සහිත ආහාර අනුභව කරන්න',
          'ප්‍රමාණවත් විවේකය සහ නින්ද ලබාගන්න',
          'අවශ්‍ය නම් ඖෂධසාලාවලින් ලබාගත හැකි වේදනා නිවාරණ භාවිතා කරන්න'
        ]
      },
      'ta': {
        'title': 'மாதவிடாய் ஆரோக்கியம் & மேலாண்மை',
        'description': 'உங்கள் மாதவிடாய் ஆரோக்கியத்தை நிர்வகிப்பது அறிகுறிகளை புரிந்துகொள்வது மற்றும் நல்வாழ்வை பராமரிப்பதை உள்ளடக்குகிறது.',
        'common_symptoms': [
          'பிடிப்புகள் மற்றும் வயிற்று வலி',
          'சோர்வு மற்றும் மனநிலை மாற்றங்கள்',
          'வீக்கம் மற்றும் நீர் தேக்கம்',
          'தலைவலி மற்றும் முதுகு வலி',
          'உணவு நாட்டம்'
        ],
        'management': [
          'பிடிப்புகளுக்கு வெப்ப பேட்களை பயன்படுத்தவும்',
          'யோகா போன்ற மென்மையான உடற்பயிற்சி செய்யவும்',
          'நீரேற்றத்துடன் இருங்கள் மற்றும் சத்தான உணவுகளை சாப்பிடவும்',
          'போதுமான ஓய்வு மற்றும் தூக்கம் பெறவும்',
          'தேவைப்பட்டால் மருந்து கடையில் கிடைக்கும் வலி நிவாரணத்தை கருத்தில் கொள்ளவும்'
        ]
      }
    },
    'reproductive_health': {
      'en': {
        'title': 'Reproductive Health',
        'description': 'Maintaining reproductive health is crucial for overall wellness and future family planning.',
        'key_aspects': [
          'Regular gynecological check-ups',
          'STI prevention and testing',
          'Contraception options',
          'Fertility awareness',
          'Healthy lifestyle choices'
        ],
        'prevention': [
          'Practice safe sex',
          'Get regular health screenings',
          'Maintain good hygiene',
          'Eat a balanced diet',
          'Exercise regularly'
        ]
      },
      'si': {
        'title': 'ප්‍රජනන සෞඛ්‍යය',
        'description': 'ප්‍රජනන සෞඛ්‍යය පවත්වාගැනීම සමස්ත සෞඛ්‍යය සහ අනාගත පවුල් සැලසුම් සඳහා තීරණාත්මක වේ.',
        'key_aspects': [
          'සාමාන්‍ය ගයිනකොලොජික පරීක්ෂණ',
          'ලිංගික රෝග වළක්වා ගැනීම සහ පරීක්ෂණ',
          'ගැබ්ගැනීම වළක්වා ගැනීමේ විකල්ප',
          'ගැබ්ගැනීම පිළිබඳ දැනුම',
          'සෞඛ්‍ය සම්පන්න ජීවන තේරීම්'
        ],
        'prevention': [
          'ආරක්ෂිත ලිංගික ජීවිතයක් ගත කරන්න',
          'සාමාන්‍ය සෞඛ්‍ය පරීක්ෂණ ලබාගන්න',
          'හොඳ සනීපාරක්ෂාව පවත්වාගන්න',
          'සමබර ආහාර වේලක් අනුභව කරන්න',
          'සාමාන්‍ය ව්‍යායාම කරන්න'
        ]
      },
      'ta': {
        'title': 'இனப்பெருக்க ஆரோக்கியம்',
        'description': 'இனப்பெருக்க ஆரோக்கியத்தை பராமரிப்பது ஒட்டுமொத்த நல்வாழ்வு மற்றும் எதிர்கால குடும்ப திட்டமிடலுக்கு முக்கியமானது.',
        'key_aspects': [
          'வழக்கமான மகளிர் நல பரிசோதனைகள்',
          'பாலியல் நோய் தடுப்பு மற்றும் சோதனை',
          'கருத்தடை விருப்பங்கள்',
          'கருவுறுதல் விழிப்புணர்வு',
          'ஆரோக்கியமான வாழ்க்கை முறை தேர்வுகள்'
        ],
        'prevention': [
          'பாதுகாப்பான உடலுறவை கடைபிடிக்கவும்',
          'வழக்கமான ஆரோக்கிய பரிசோதனைகளை பெறவும்',
          'நல்ல சுகாதாரத்தை பராமரிக்கவும்',
          'சமச்சீர் உணவை சாப்பிடவும்',
          'வழக்கமாக உடற்பயிற்சி செய்யவும்'
        ]
      }
    },
    'nutrition_wellness': {
      'en': {
        'title': 'Nutrition & Wellness',
        'description': 'Proper nutrition is essential for menstrual health and overall wellness.',
        'key_nutrients': [
          'Iron: Prevents anemia, found in leafy greens, lean meats',
          'Calcium: Supports bone health, found in dairy, fortified foods',
          'Magnesium: Reduces cramps, found in nuts, whole grains',
          'Omega-3: Reduces inflammation, found in fish, seeds',
          'B Vitamins: Energy and mood support, found in whole grains'
        ],
        'foods_to_include': [
          'Dark leafy greens (spinach, kale)',
          'Lean proteins (fish, chicken, legumes)',
          'Whole grains and complex carbohydrates',
          'Fresh fruits and vegetables',
          'Healthy fats (avocado, nuts, olive oil)'
        ],
        'foods_to_limit': [
          'Excessive caffeine and alcohol',
          'High sugar and processed foods',
          'Excessive salt intake',
          'Trans fats and fried foods'
        ]
      },
      'si': {
        'title': 'පෝෂණය සහ සෞඛ්‍යය',
        'description': 'මාසික සෞඛ්‍යය සහ සමස්ත සෞඛ්‍යය සඳහා නිසි පෝෂණය අත්‍යවශ්‍ය වේ.',
        'key_nutrients': [
          'යකඩ: රක්තහීනතාව වළක්වයි, කොළ ගස්, මස් වල ඇත',
          'කැල්සියම්: අස්ථි සෞඛ්‍යය, කිරි නිෂ්පාදන වල ඇත',
          'මැග්නීසියම්: ඇදීම් අඩු කරයි, ගෙඩි, ධාන්‍ය වල ඇත',
          'ඔමේගා-3: දැවිල්ල අඩු කරයි, මත්ස්‍ය, බීජ වල ඇත',
          'B විටමින්: ශක්තිය සහ මනෝභාවය, ධාන්‍ය වල ඇත'
        ],
        'foods_to_include': [
          'තද කොළ ගස් (පාලක්, කේල්)',
          'කෙට්ටු ප්‍රෝටීන් (මාළු, කුකුල්, ධාන්‍ය)',
          'සම්පූර්ණ ධාන්‍ය සහ සංකීර්ණ කාබෝහයිඩ්‍රේට්',
          'නැවුම් පලතුරු සහ එළවළු',
          'සෞඛ්‍ය සම්පන්න මේද (අලිගැට, ගෙඩි, ඔලිව් තෙල්)'
        ],
        'foods_to_limit': [
          'අධික කැෆේන් සහ මධ්‍යසාර',
          'අධික සීනි සහ සැකසූ ආහාර',
          'අධික ලුණු ගැනීම',
          'ට්‍රාන්ස් මේද සහ බැදපු ආහාර'
        ]
      },
      'ta': {
        'title': 'ஊட்டச்சத்து & நல்வாழ்வு',
        'description': 'மாதவிடாய் ஆரோக்கியம் மற்றும் ஒட்டுமொத்த நல்வாழ்வுக்கு சரியான ஊட்டச்சத்து அவசியம்.',
        'key_nutrients': [
          'இரும்பு: இரத்த சோகையை தடுக்கிறது, பச்சை கீரைகள், மெலிந்த இறைச்சி',
          'கால்சியம்: எலும்பு ஆரோக்கியத்தை ஆதரிக்கிறது, பால் பொருட்கள், வலுவூட்டப்பட்ட உணவுகள்',
          'மெக்னீசியம்: பிடிப்புகளை குறைக்கிறது, கொட்டைகள், முழு தானியங்கள்',
          'ஒமேகா-3: வீக்கத்தை குறைக்கிறது, மீன், விதைகள்',
          'B வைட்டமின்கள்: ஆற்றல் மற்றும் மனநிலை ஆதரவு, முழு தானியங்கள்'
        ],
        'foods_to_include': [
          'அடர் பச்சை இலை காய்கறிகள் (கீரை, கேல்)',
          'மெலிந்த புரதங்கள் (மீன், கோழி, பருப்பு)',
          'முழு தானியங்கள் மற்றும் சிக்கலான கார்போஹைட்ரேட்டுகள்',
          'புதிய பழங்கள் மற்றும் காய்கறிகள்',
          'ஆரோக்கியமான கொழுப்புகள் (வெண்ணெய் பழம், கொட்டைகள், ஆலிவ் எண்ணெய்)'
        ],
        'foods_to_limit': [
          'அதிகப்படியான காஃபின் மற்றும் ஆல்கஹால்',
          'அதிக சர்க்கரை மற்றும் பதப்படுத்தப்பட்ட உணவுகள்',
          'அதிகப்படியான உப்பு உட்கொள்ளல்',
          'டிரான்ஸ் கொழுப்புகள் மற்றும் வறுத்த உணவுகள்'
        ]
      }
    },
    'exercise_wellness': {
      'en': {
        'title': 'Exercise & Physical Wellness',
        'description': 'Regular exercise can help manage menstrual symptoms and improve overall health.',
        'beneficial_exercises': [
          'Yoga: Reduces stress and menstrual pain',
          'Walking: Low-impact cardiovascular exercise',
          'Swimming: Full-body, gentle exercise',
          'Pilates: Core strengthening and flexibility',
          'Light strength training: Improves bone density'
        ],
        'exercise_timing': [
          'Menstrual phase: Gentle activities like yoga, walking',
          'Follicular phase: Gradually increase intensity',
          'Ovulatory phase: Peak energy, can do intense workouts',
          'Luteal phase: Moderate activities, listen to your body'
        ],
        'benefits': [
          'Reduces menstrual cramps and pain',
          'Improves mood and reduces stress',
          'Enhances sleep quality',
          'Boosts energy levels',
          'Supports healthy weight management'
        ]
      },
      'si': {
        'title': 'ව්‍යායාම සහ ශාරීරික සෞඛ්‍යය',
        'description': 'නිතිපතා ව්‍යායාම මාසික රෝග ලක්ෂණ කළමනාකරණයට සහ සමස්ත සෞඛ්‍යය වැඩිදියුණු කිරීමට උදව් කරයි.',
        'beneficial_exercises': [
          'යෝගා: ආතතිය සහ මාසික වේදනාව අඩු කරයි',
          'ඇවිදීම: අඩු බලපෑම් හෘද වාහිනී ව්‍යායාම',
          'පිහිනීම: සම්පූර්ණ ශරීර, මෘදු ව්‍යායාම',
          'පිලේට්ස්: මධ්‍යම ශක්තිමත් කිරීම සහ නම්‍යතාව',
          'සැහැල්ලු ශක්ති පුහුණුව: අස්ථි ඝනත්වය වැඩි කරයි'
        ],
        'exercise_timing': [
          'මාසික අවධිය: යෝගා, ඇවිදීම වැනි මෘදු ක්‍රියාකාරකම්',
          'බීජකෝෂ අවධිය: ක්‍රමයෙන් තීව්‍රතාව වැඩි කරන්න',
          'බීජ මුක්ෂණ අවධිය: උපරිම ශක්තිය, තීව්‍ර ව්‍යායාම කළ හැක',
          'පීතු අවධිය: මධ්‍යම ක්‍රියාකාරකම්, ඔබේ ශරීරයට අහන්න'
        ],
        'benefits': [
          'මාසික ඇදීම් සහ වේදනාව අඩු කරයි',
          'මනෝභාවය වැඩිදියුණු කර ආතතිය අඩු කරයි',
          'නින්දේ ගුණාත්මකභාවය වැඩි කරයි',
          'ශක්ති මට්ටම් ඉහළ නංවයි',
          'සෞඛ්‍ය සම්පන්න බර කළමනාකරණයට සහාය වේ'
        ]
      },
      'ta': {
        'title': 'உடற்பயிற்சி & உடல் நல்வாழ்வு',
        'description': 'வழக்கமான உடற்பயிற்சி மாதவிடாய் அறிகுறிகளை நிர்வகிக்கவும் ஒட்டுமொத்த ஆரோக்கியத்தை மேம்படுத்தவும் உதவும்.',
        'beneficial_exercises': [
          'யோகா: மன அழுத்தத்தையும் மாதவிடாய் வலியையும் குறைக்கிறது',
          'நடைபயிற்சி: குறைந்த தாக்க இதய வாஸ்குலர் உடற்பயிற்சி',
          'நீச்சல்: முழு உடல், மென்மையான உடற்பயிற்சி',
          'பிலேட்ஸ்: மையப்பகுதி வலுவூட்டல் மற்றும் நெகிழ்வு',
          'லேசான வலிமை பயிற்சி: எலும்பு அடர்த்தியை மேம்படுத்துகிறது'
        ],
        'exercise_timing': [
          'மாதவிடாய் கட்டம்: யோகா, நடைபயிற்சி போன்ற மென்மையான செயல்பாடுகள்',
          'ஃபோலிகுலர் கட்டம்: படிப்படியாக தீவிரத்தை அதிகரிக்கவும்',
          'கருமுட்டை வெளியீட்டு கட்டம்: உச்ச ஆற்றல், தீவிர பயிற்சிகள் செய்யலாம்',
          'லூட்டியல் கட்டம்: மிதமான செயல்பாடுகள், உங்கள் உடலைக் கேளுங்கள்'
        ],
        'benefits': [
          'மாதவிடாய் பிடிப்புகள் மற்றும் வலியை குறைக்கிறது',
          'மனநிலையை மேம்படுத்தி மன அழுத்தத்தை குறைக்கிறது',
          'தூக்க தரத்தை மேம்படுத்துகிறது',
          'ஆற்றல் அளவுகளை அதிகரிக்கிறது',
          'ஆரோக்கியமான எடை மேலாண்மைக்கு ஆதரவளிக்கிறது'
        ]
      }
    },
    'mental_health': {
      'en': {
        'title': 'Mental Health & Emotional Wellness',
        'description': 'Understanding and managing the emotional aspects of menstrual health.',
        'common_symptoms': [
          'Mood swings and irritability',
          'Anxiety and stress',
          'Depression or sadness',
          'Changes in appetite',
          'Sleep disturbances'
        ],
        'coping_strategies': [
          'Practice mindfulness and meditation',
          'Maintain regular sleep schedule',
          'Exercise regularly for mood boost',
          'Connect with supportive friends/family',
          'Consider professional counseling if needed'
        ],
        'stress_management': [
          'Deep breathing exercises',
          'Progressive muscle relaxation',
          'Journaling and self-reflection',
          'Engaging in hobbies',
          'Limiting stressful situations'
        ]
      },
      'si': {
        'title': 'මානසික සෞඛ්‍යය සහ චිත්තවේගීය සෞඛ්‍යය',
        'description': 'මාසික සෞඛ්‍යයේ චිත්තවේගීය අංශ තේරුම්ගැනීම සහ කළමනාකරණය කිරීම.',
        'common_symptoms': [
          'මනෝභාව වෙනස්කම් සහ කෝපකාරිත්වය',
          'කනස්සල්ල සහ ආතතිය',
          'මානසික අවපීඩනය හෝ දුක',
          'ආහාර රුචිකත්වයේ වෙනස්කම්',
          'නින්දේ ගැටලු'
        ],
        'coping_strategies': [
          'සිහිය සහ භාවනාව පුහුණු කරන්න',
          'නිතිපතා නින්දේ කාලසටහනක් පවත්වන්න',
          'මනෝභාවය වැඩිදියුණු කිරීම සඳහා නිතිපතා ව්‍යායාම කරන්න',
          'සහයෝගී මිතුරන්/පවුලේ අය සමඟ සම්බන්ධ වන්න',
          'අවශ්‍ය නම් වෘත්තීය උපදේශනය සලකා බලන්න'
        ],
        'stress_management': [
          'ගැඹුරු හුස්ම ගැනීමේ ව්‍යායාම',
          'ක්‍රමානුකූල මාංශ පේශි ලිහිල් කිරීම',
          'දිනපොත ලිවීම සහ ස්වයං මෙනෙහෙයීම',
          'විනෝදාස්වාදයේ නිරත වීම',
          'ආතති සහගත තත්ත්වයන් සීමා කිරීම'
        ]
      },
      'ta': {
        'title': 'மன ஆரோக்கியம் & உணர்ச்சி நல்வாழ்வு',
        'description': 'மாதவிடாய் ஆரோக்கியத்தின் உணர்ச்சி அம்சங்களை புரிந்துகொள்வதும் நிர்வகிப்பதும்.',
        'common_symptoms': [
          'மனநிலை மாற்றங்கள் மற்றும் எரிச்சல்',
          'பதட்டம் மற்றும் மன அழுத்தம்',
          'மனச்சோர்வு அல்லது சோகம்',
          'பசியில் மாற்றங்கள்',
          'தூக்கக் கோளாறுகள்'
        ],
        'coping_strategies': [
          'நினைவாற்றல் மற்றும் தியானத்தை பயிற்சி செய்யுங்கள்',
          'வழக்கமான தூக்க அட்டவணையை பராமரிக்கவும்',
          'மனநிலை மேம்பாட்டிற்கு வழக்கமாக உடற்பயிற்சி செய்யவும்',
          'ஆதரவான நண்பர்கள்/குடும்பத்துடன் இணையுங்கள்',
          'தேவைப்பட்டால் தொழில்முறை ஆலோசனையை கருத்தில் கொள்ளுங்கள்'
        ],
        'stress_management': [
          'ஆழமான சுவாச பயிற்சிகள்',
          'படிப்படியான தசை தளர்வு',
          'நாட்குறிப்பு எழுதுதல் மற்றும் சுய-பிரதிபலிப்பு',
          'பொழுதுபோக்குகளில் ஈடுபடுதல்',
          'மன அழுத்தமான சூழ்நிலைகளை குறைத்தல்'
        ]
      }
    },
    'common_problems': {
      'en': {
        'title': 'Common Health Problems & Solutions',
        'description': 'Solutions for frequently encountered menstrual and reproductive health issues.',
        'irregular_periods': [
          'Track your cycle for 3-6 months',
          'Maintain healthy weight',
          'Manage stress levels',
          'Consider hormonal factors',
          'Consult healthcare provider if persistent'
        ],
        'heavy_bleeding': [
          'Use appropriate menstrual products',
          'Monitor iron levels',
          'Avoid aspirin during periods',
          'Consider underlying conditions',
          'Seek medical advice for excessive bleeding'
        ],
        'painful_periods': [
          'Apply heat to lower abdomen',
          'Take over-the-counter pain relievers',
          'Try gentle exercise and stretching',
          'Consider hormonal birth control',
          'Consult doctor for severe pain'
        ]
      },
      'si': {
        'title': 'සාමාන්‍ය සෞඛ්‍ය ගැටලු සහ විසඳුම්',
        'description': 'නිතර හමුවන මාසික සහ ප්‍රජනන සෞඛ්‍ය ගැටලු සඳහා විසඳුම්.',
        'irregular_periods': [
          'මාස 3-6ක් ඔබේ චක්‍රය ලියාපදිංචි කරන්න',
          'සෞඛ්‍ය සම්පන්න බරක් පවත්වන්න',
          'ආතතියේ මට්ටම් කළමනාකරණය කරන්න',
          'හෝමෝන සාධක සලකා බලන්න',
          'දිගටම පවතින නම් සෞඛ්‍ය සේවා සපයන්නා සමඟ සම්බන්ධ වන්න'
        ],
        'heavy_bleeding': [
          'සුදුසු මාසික නිෂ්පාදන භාවිතා කරන්න',
          'යකඩ මට්ටම් අධීක්ෂණය කරන්න',
          'මාසික කාලයේදී ඇස්පිරින් වළකින්න',
          'යටින් පවතින රෝගී තත්ත්වයන් සලකා බලන්න',
          'අධික ලේ ගැලීම සඳහා වෛද්‍ය උපදෙස් ලබාගන්න'
        ],
        'painful_periods': [
          'පහළ උදරයට උණුසුම යොදන්න',
          'ඖෂධසාලාවෙන් ලබාගත හැකි වේදනා නාශක ගන්න',
          'මෘදු ව්‍යායාම සහ දිගු කිරීම උත්සාහ කරන්න',
          'හෝමෝන උපත් පාලනය සලකා බලන්න',
          'දරුණු වේදනාව සඳහා වෛද්‍යවරයා සමඟ සලකා බලන්න'
        ]
      },
      'ta': {
        'title': 'பொதுவான ஆரோக்கிய பிரச்சனைகள் & தீர்வுகள்',
        'description': 'அடிக்கடி எதிர்கொள்ளும் மாதவிடாய் மற்றும் இனப்பெருக்க ஆரோக்கிய பிரச்சினைகளுக்கான தீர்வுகள்.',
        'irregular_periods': [
          '3-6 மாதங்களுக்கு உங்கள் சுழற்சியை கண்காணிக்கவும்',
          'ஆரோக்கியமான எடையை பராமரிக்கவும்',
          'மன அழுத்த நிலைகளை நிர்வகிக்கவும்',
          'ஹார்மோன் காரணிகளை கருத்தில் கொள்ளவும்',
          'தொடர்ந்தால் சுகாதார வழங்குநரை அணுகவும்'
        ],
        'heavy_bleeding': [
          'பொருத்தமான மாதவிடாய் பொருட்களை பயன்படுத்தவும்',
          'இரும்பு அளவுகளை கண்காணிக்கவும்',
          'மாதவிடாய் காலத்தில் ஆஸ்பிரின் தவிர்க்கவும்',
          'அடிப்படை நிலைமைகளை கருத்தில் கொள்ளவும்',
          'அதிகப்படியான இரத்தப்போக்கிற்கு மருத்துவ ஆலோசனை பெறவும்'
        ],
        'painful_periods': [
          'கீழ் வயிற்றில் வெப்பத்தை பயன்படுத்தவும்',
          'மருந்து கடையில் கிடைக்கும் வலி நிவாரணிகளை எடுத்துக்கொள்ளவும்',
          'மென்மையான உடற்பயிற்சி மற்றும் நீட்டிப்பை முயற்சிக்கவும்',
          'ஹார்மோன் கருத்தடையை கருத்தில் கொள்ளவும்',
          'கடுமையான வலிக்கு மருத்துவரை அணுகவும்'
        ]
      }
    }
  };

  // Detect language from user input
  static String _detectLanguage(String text) {
    final sinhalaPattern = RegExp(r'[\u0D80-\u0DFF]');
    final tamilPattern = RegExp(r'[\u0B80-\u0BFF]');
    
    if (sinhalaPattern.hasMatch(text)) {
      return 'si';
    } else if (tamilPattern.hasMatch(text)) {
      return 'ta';
    }
    return 'en';
  }

  // Enhanced comprehensive health response system
  static ChatMessage getHealthResponse(String userInput, String language) {
    final detectedLang = language.isEmpty ? _detectLanguage(userInput) : language;
    final input = userInput.toLowerCase();
    
    // Enhanced topic detection with more keywords
    String? topic = _detectHealthTopic(input);
    
    if (topic != null && _healthKnowledgeBase.containsKey(topic)) {
      return _buildStructuredResponse(topic, detectedLang);
    }
    
    // Enhanced fallback system with context-aware responses
    return _generateContextualResponse(input, detectedLang);
  }
  
  // Advanced topic detection
  static String? _detectHealthTopic(String input) {
    final topicKeywords = {
      'menstrual_cycle': [
        'cycle', 'period', 'menstrual', 'monthly', 'bleeding', 'flow',
        'මාසික', 'චක්‍ර', 'රුධිර', 'ගලන', 'වැගිරීම',
        'மாதவிடாய்', 'சுழற்சி', 'பீரியட்', 'இரத்தப்போக்கு', 'ஓட்டம்'
      ],
      'ovulation': [
        'ovulation', 'fertility', 'pregnant', 'conception', 'egg', 'fertile',
        'බීජ', 'ගැබ්', 'මුක්ෂණ', 'ගර්භ', 'සැදීම',
        'கருமுட்டை', 'கருவுறுதல்', 'கருத்தரித்தல்', 'கர்ப்பம்', 'கருவுறும்'
      ],
      'period_health': [
        'pain', 'cramp', 'symptom', 'ache', 'discomfort', 'relief', 'management',
        'වේදනා', 'රෝග', 'ලක්ෂණ', 'ඇදීම', 'කළමනාකරණ',
        'வலி', 'பிடிப்பு', 'அறிகுறி', 'வேதனை', 'நிவாரணம்', 'மேலாண்மை'
      ],
      'reproductive_health': [
        'reproductive', 'health', 'checkup', 'doctor', 'examination', 'prevention',
        'සෞඛ්‍ය', 'ප්‍රජනන', 'පරීක්ෂණ', 'වෛද්‍ය', 'වළක්වා',
        'இனப்பெருக்கம்', 'ஆரோக்கியம்', 'பரிசோதனை', 'மருத்துவர்', 'தடுப்பு'
      ],
      'nutrition_wellness': [
        'nutrition', 'diet', 'food', 'vitamin', 'mineral', 'eating',
        'පෝෂණය', 'ආහාර', 'විටමින්', 'ඛනිජ', 'කමින්',
        'ஊட்டச்சத்து', 'உணவு', 'வைட்டமின்', 'தாதுக்கள்', 'உண்ணுதல்'
      ],
      'exercise_wellness': [
        'exercise', 'workout', 'fitness', 'yoga', 'walking', 'physical',
        'ව්‍යායාම', 'යෝගා', 'ඇවිදීම', 'ශාරීරික', 'ව්‍යායාම',
        'உடற்பயிற்சி', 'யோகா', 'நடைபயிற்சி', 'உடல்', 'பயிற்சி'
      ],
      'mental_health': [
        'mental', 'mood', 'stress', 'anxiety', 'depression', 'emotional',
        'මානසික', 'මනෝභාවය', 'ආතතිය', 'කනස්සල්ල', 'චිත්තවේගීය',
        'மன', 'மனநிலை', 'மன அழுத்தம்', 'பதட்டம்', 'மனச்சோர்வு', 'உணர்ச்சி'
      ],
      'common_problems': [
        'problem', 'issue', 'irregular', 'heavy', 'painful', 'trouble',
        'ගැටලුව', 'ප්‍රශ්නය', 'අක්‍රමවත්', 'දරුණු', 'කරදරකාරී',
        'பிரச்சனை', 'கேள்வி', 'ஒழுங்கற்ற', 'அதிகமான', 'வேதனையான', 'சிரமம்'
      ]
    };
    
    for (final entry in topicKeywords.entries) {
      for (final keyword in entry.value) {
        if (input.contains(keyword)) {
          return entry.key;
        }
      }
    }
    
    return null;
  }
  
  // Build structured response
  static ChatMessage _buildStructuredResponse(String topic, String language) {
    final knowledge = _healthKnowledgeBase[topic]![language] ?? _healthKnowledgeBase[topic]!['en']!;
    
    String response = '🏥 ${knowledge['title']}\n\n${knowledge['description']}\n\n';
    
    if (knowledge.containsKey('phases')) {
      final label = language == 'si' ? 'අවධි:' : (language == 'ta' ? 'கட்டங்கள்:' : 'Phases:');
      response += '📅 $label\n';
      for (final phase in knowledge['phases']) {
        response += '• $phase\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('signs')) {
      final label = language == 'si' ? 'ලක්ෂණ:' : (language == 'ta' ? 'அறிகுறிகள்:' : 'Signs & Symptoms:');
      response += '🔍 $label\n';
      for (final sign in knowledge['signs']) {
        response += '• $sign\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('tips')) {
      final label = language == 'si' ? 'උපදෙස්:' : (language == 'ta' ? 'பயனுள்ள குறிப்புகள்:' : 'Helpful Tips:');
      response += '💡 $label\n';
      for (final tip in knowledge['tips']) {
        response += '• $tip\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('management')) {
      final label = language == 'si' ? 'කළමනාකරණය:' : (language == 'ta' ? 'மேலாண்மை & பராமரிப்பு:' : 'Management & Care:');
      response += '🛠️ $label\n';
      for (final item in knowledge['management']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('tracking')) {
      final label = language == 'si' ? 'ලුහුබැඳීම:' : (language == 'ta' ? 'கண்காணிப்பு முறைகள்:' : 'Tracking Methods:');
      response += '📊 $label\n';
      for (final item in knowledge['tracking']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('prevention')) {
      final label = language == 'si' ? 'වළක්වා ගැනීම:' : (language == 'ta' ? 'தடுப்பு & பராமரிப்பு:' : 'Prevention & Care:');
      response += '🛡️ $label\n';
      for (final item in knowledge['prevention']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('key_aspects')) {
      final label = language == 'si' ? 'ප්‍රධාන අංග:' : (language == 'ta' ? 'முக்கிய அம்சங்கள்:' : 'Key Aspects:');
      response += '🎯 $label\n';
      for (final item in knowledge['key_aspects']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('common_symptoms')) {
      final label = language == 'si' ? 'සාමාන්‍ය ලක්ෂණ:' : (language == 'ta' ? 'பொதுவான அறிகுறிகள்:' : 'Common Symptoms:');
      response += '⚠️ $label\n';
      for (final item in knowledge['common_symptoms']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('key_nutrients')) {
      response += '🥗 ${language == 'si' ? 'ප්‍රධාන පෝෂක:' : 'Key Nutrients:'}\n';
      for (final item in knowledge['key_nutrients']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('foods_to_include')) {
      response += '✅ ${language == 'si' ? 'ඇතුළත් කළ යුතු ආහාර:' : 'Foods to Include:'}\n';
      for (final item in knowledge['foods_to_include']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('foods_to_limit')) {
      response += '❌ ${language == 'si' ? 'සීමා කළ යුතු ආහාර:' : 'Foods to Limit:'}\n';
      for (final item in knowledge['foods_to_limit']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('beneficial_exercises')) {
      response += '🏃‍♀️ ${language == 'si' ? 'ප්‍රයෝජනවත් ව්‍යායාම:' : 'Beneficial Exercises:'}\n';
      for (final item in knowledge['beneficial_exercises']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('exercise_timing')) {
      response += '⏰ ${language == 'si' ? 'ව්‍යායාම කාලය:' : 'Exercise Timing:'}\n';
      for (final item in knowledge['exercise_timing']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('benefits')) {
      response += '🌟 ${language == 'si' ? 'ප්‍රතිලාභ:' : 'Benefits:'}\n';
      for (final item in knowledge['benefits']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('coping_strategies')) {
      response += '🛡️ ${language == 'si' ? 'මුහුණ දීමේ උපාය:' : 'Coping Strategies:'}\n';
      for (final item in knowledge['coping_strategies']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('stress_management')) {
      response += '😌 ${language == 'si' ? 'ආතතිය කළමනාකරණය:' : 'Stress Management:'}\n';
      for (final item in knowledge['stress_management']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('irregular_periods')) {
      response += '📅 ${language == 'si' ? 'අක්‍රමවත් මාසික:' : 'Irregular Periods:'}\n';
      for (final item in knowledge['irregular_periods']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('heavy_bleeding')) {
      response += '🩸 ${language == 'si' ? 'අධික ලේ ගැලීම:' : 'Heavy Bleeding:'}\n';
      for (final item in knowledge['heavy_bleeding']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    if (knowledge.containsKey('painful_periods')) {
      response += '😣 ${language == 'si' ? 'වේදනාකාරී මාසික:' : 'Painful Periods:'}\n';
      for (final item in knowledge['painful_periods']) {
        response += '• $item\n';
      }
      response += '\n';
    }
    
    // Add helpful closing advice
    final closingAdvice = language == 'si' 
        ? '\n📞 වැදගත්: දරුණු රෝග ලක්ෂණ හෝ අසාමාන්‍ය තත්ත්වයන් සඳහා වෛද්‍යවරයකු සමඟ සම්බන්ධ වන්න.'
        : '\n📞 Important: Consult with a healthcare provider for severe symptoms or unusual conditions.';
    
    response += closingAdvice;

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response.trim(),
      type: MessageType.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }
  
  // Generate contextual response for unmatched queries
  static ChatMessage _generateContextualResponse(String input, String language) {
    final generalHealthTopics = {
      'en': {
        'greeting': ['hi', 'hello', 'help'],
        'general': ['what', 'how', 'why', 'when', 'where'],
        'concern': ['worried', 'concerned', 'problem', 'issue'],
        'emergency': ['urgent', 'emergency', 'severe', 'serious'],
      },
      'si': {
        'greeting': ['හායි', 'කොහොමද', 'උදව්'],
        'general': ['කුමක්', 'කොහොමද', 'ඇයි', 'කවදා', 'කොහේ'],
        'concern': ['කனගාටුයි', 'ගැටලුව', 'ප්‍රශ්නය'],
        'emergency': ['හදිසි', 'දරුණු', 'බරපතළ'],
      },
      'ta': {
        'greeting': ['வணக்கம்', 'ஹாய்', 'உதவி'],
        'general': ['என்ன', 'எப்படி', 'ஏன்', 'எப்போது', 'எங்கே'],
        'concern': ['கவலை', 'பிரச்சனை', 'கேள்வி'],
        'emergency': ['அவசரம்', 'தீவிரம்', 'கடுமையான'],
      }
    };
    
    String response;
    
    // Check for greetings
    if (_containsAnyKeyword(input, generalHealthTopics['en']!['greeting']!) || 
        _containsAnyKeyword(input, generalHealthTopics['si']!['greeting']!) ||
        _containsAnyKeyword(input, generalHealthTopics['ta']!['greeting']!)) {
      if (language == 'si') {
        response = '👋 ආයුබෝවන්! මම ඔබගේ AI සෞඛ්‍ය සහායකයායි. මට ඔබට උදව් කළ හැකි ක්ෂේත්‍ර:\n\n🩸 මාසික සෞඛ්‍යය\n🤱 ගැබ්ගැනීම සහ ප්‍රජනනය\n💊 සෞඛ්‍ය කළමනාකරණය\n🏥 වෛද්‍ය උපදෙස්\n\nඔබට කුමක් දැනගන්න අවශ්‍යද?';
      } else if (language == 'ta') {
        response = '👋 வணக்கம்! நான் உங்கள் AI ஆரோக்கிய உதவியாளர். நான் உங்களுக்கு உதவக்கூடிய பகுதிகள்:\n\n🩸 மாதவிடாய் ஆரோக்கியம்\n🤱 கருவுறுதல் & இனப்பெருக்கம்\n💊 ஆரோக்கிய மேலாண்மை\n🏥 மருத்துவ வழிகாட்டுதல்\n\nநீங்கள் என்ன தெரிந்துகொள்ள விரும்புகிறீர்கள்?';
      } else {
        response = '👋 Hello! I\'m your AI Health Assistant. I can help you with:\n\n🩸 Menstrual Health\n🤱 Fertility & Reproduction\n💊 Health Management\n🏥 Medical Guidance\n\nWhat would you like to know about?';
      }
    }
    // Check for emergency keywords
    else if (_containsAnyKeyword(input, generalHealthTopics['en']!['emergency']!) || 
             _containsAnyKeyword(input, generalHealthTopics['si']!['emergency']!) ||
             _containsAnyKeyword(input, generalHealthTopics['ta']!['emergency']!)) {
      if (language == 'si') {
        response = '🚨 හදිසි තත්ත්වයක් නම්:\n\n📞 ක්ෂණිකව වෛද්‍යවරයකු හමුවන්න\n🏥 ළඟම ඇති රෝහලට යන්න\n📱 හදිසි සේවා අමතන්න\n\nමම සාමාන්‍ය සෞඛ්‍ය උපදෙස් සහ තොරතුරු ලබා දෙන්නෙමි, නමුත් හදිසි වෛද්‍ය ප්‍රතිකාර සඳහා වෛද්‍යවරයකු අවශ්‍යයි.';
      } else if (language == 'ta') {
        response = '🚨 மருத்துவ அவசரநிலைகளுக்கு:\n\n📞 உடனடியாக உங்கள் மருத்துவரைத் தொடர்பு கொள்ளுங்கள்\n🏥 அருகிலுள்ள மருத்துவமனைக்குச் செல்லுங்கள்\n📱 அவசர சேவைகளை அழைக்கவும்\n\nநான் பொது ஆரோக்கிய தகவல் மற்றும் வழிகாட்டுதலை வழங்குகிறேன், ஆனால் அவசர மருத்துவ பராமரிப்புக்கு ஒரு சுகாதார நிபுணர் தேவை.';
      } else {
        response = '🚨 For medical emergencies:\n\n📞 Contact your doctor immediately\n🏥 Visit the nearest hospital\n📱 Call emergency services\n\nI provide general health information and guidance, but emergency medical care requires a healthcare professional.';
      }
    }
    // General health guidance
    else {
      if (language == 'si') {
        response = '🤔 ඔබේ ප්‍රශ්නය සම්බන්ධයෙන් මට උදව් කිරීමට කැමතියි!\n\n💬 මට උදව් කළ හැකි ක්ෂේත්‍ර:\n• මාසික චක්‍රය සහ සෞඛ්‍යය\n• බීජ මුක්ෂණය සහ ගැබ්ගැනීම\n• සෞඛ්‍ය කළමනාකරණය\n• ජීවන රටා උපදෙස්\n\n🔍 කරුණාකර ඔබේ ප්‍රශ්නය වඩාත් නිශ්චිතව කියන්න, එවිට මට වඩා හොඳ උදව්වක් ලබා දිය හැකිය.';
      } else if (language == 'ta') {
        response = '🤔 உங்கள் கேள்விக்கு உதவ நான் விரும்புகிறேன்!\n\n💬 நான் உதவக்கூடியவை:\n• மாதவிடாய் சுழற்சி மற்றும் ஆரோக்கியம்\n• கருமுட்டை உற்பத்தி மற்றும் கருவுறுதல்\n• ஆரோக்கிய மேலாண்மை\n• வாழ்க்கைமுறை வழிகாட்டுதல்\n\n🔍 உங்கள் கேள்வியை இன்னும் குறிப்பாகக் கூறுங்கள், அதனால் நான் சிறந்த உதவியை வழங்க முடியும்.';
      } else {
        response = '🤔 I\'d love to help with your question!\n\n💬 I can assist with:\n• Menstrual cycle and health\n• Ovulation and fertility\n• Health management\n• Lifestyle guidance\n\n🔍 Please be more specific about your question so I can provide better assistance.';
      }
    }

    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: response,
      type: MessageType.text,
      sender: MessageSender.bot,
      timestamp: DateTime.now(),
    );
  }
  
  // Helper method to check for keywords
  static bool _containsAnyKeyword(String input, List<String> keywords) {
    return keywords.any((keyword) => input.contains(keyword));
  }

  // Get language-specific greeting
  static String getGreeting(String language) {
    switch (language) {
      case 'si':
        return '👋 ආයුබෝවන්! මම ඔබගේ AI සෞඛ්‍ය සහායකයායි. මාසික සෞඛ්‍යය, ගැබ්ගැනීම සහ ප්‍රජනන සෞඛ්‍යය පිළිබඳ ඔබට උදව් කළ හැකිය.';
      case 'ta':
        return '👋 வணக்கம்! நான் உங்கள் AI ஆரோக்கிய உதவியாளர். மாதவிடாய் ஆரோக்கியம், கருவுறுதல் மற்றும் இனப்பெருக்க ஆரோக்கியம் குறித்து உங்களுக்கு உதவ முடியும்.';
      default:
        return '👋 Hello! I\'m your AI Health Assistant. I can help you with menstrual health, fertility, and reproductive health.';
    }
  }

  // Get language-specific suggestions
  static List<String> getSuggestions(String language) {
    // Use translation keys instead of hardcoded strings
    return [
      'health_ai.chat.suggestions.menstrual_cycle'.tr(),
      'health_ai.chat.suggestions.ovulation_fertility'.tr(),
      'health_ai.chat.suggestions.period_symptoms'.tr(),
      'health_ai.chat.suggestions.health_checkups'.tr(),
      'health_ai.chat.suggestions.lifestyle_advice'.tr()
    ];
  }
}
