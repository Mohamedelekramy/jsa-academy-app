import 'package:flutter/material.dart';
import 'strings_home.dart';
import 'strings_plans.dart';
import 'strings_staff.dart';
import 'strings_children.dart';
import 'strings_schedule.dart';
import 'strings_profile.dart';
import 'strings_bookings.dart';
import 'strings_events.dart';
import 'strings_freeze.dart';
/// كل نصوص التطبيق بالعربي والإنجليزي
class AppStrings {
  static const Map<String, Map<String, String>> _data = {
    'ar': {
      'appName': 'JSA',
      'splashTitle': 'أكاديمية الجفن الدولية الرياضية',
      'welcome': 'مرحباً بك في أكاديمية الجفن',
      'tagline': 'وجهتك المتكاملة للرياضة والتدريب والتأهيل',
      'letsStart': 'يلا نبدأ',
      'langButton': 'EN',
      'hello': 'أهلاً',
      'logout': 'تسجيل الخروج',
      'comingSoon': 'الشاشة الرئيسية في الخطوة الجاية',
      'loginTitle': 'تسجيل الدخول',
      'loginSub': 'أهلاً بعودتك إلى أكاديمية الجفن',
      'registerTitle': 'إنشاء حساب جديد',
      'registerSub': 'انضم لعائلة الجفن الرياضية',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'confirmPassword': 'تأكيد كلمة المرور',
      'fullName': 'الاسم الكامل',
      'phone': 'رقم الجوال',
      'gender': 'النوع',
      'male': 'ذكر',
      'female': 'أنثى',
      'loginBtn': 'دخول',
      'registerBtn': 'إنشاء الحساب',
      'noAccount': 'ليس لديك حساب؟',
      'registerLink': 'سجّل الآن',
      'haveAccount': 'لديك حساب بالفعل؟',
      'loginLink': 'سجّل الدخول',
      'forgotPassword': 'نسيت كلمة المرور؟',
      'resetSent': 'أرسلنا رابط إعادة التعيين على بريدك',
      'errRequired': 'هذا الحقل مطلوب',
      'errEmail': 'اكتب بريداً إلكترونياً صحيحاً',
      'errPhone': 'اكتب رقم جوال صحيح',
      'errPassShort': 'كلمة المرور 6 أحرف على الأقل',
      'errPassMatch': 'كلمتا المرور غير متطابقتين',
      'errGender': 'اختر النوع',
      'errUserNotFound': 'الحساب غير موجود',
      'errWrongPass': 'البريد أو كلمة المرور غير صحيحة',
      'errEmailInUse': 'هذا البريد مسجل بالفعل',
      'errWeakPass': 'كلمة المرور ضعيفة',
      'errNetwork': 'تأكد من اتصال الإنترنت',
      'errTooMany': 'محاولات كثيرة، حاول لاحقاً',
      'errGeneric': 'حدث خطأ، حاول مرة أخرى',
    },
    'en': {
      'appName': 'JSA',
      'splashTitle': 'Al-Jafen International Sports Academy',
      'welcome': 'Welcome to Al-Jafen Academy',
      'tagline':
      'Your complete destination for sports, training and rehabilitation',
      'letsStart': "Let's start",
      'langButton': 'ع',
      'hello': 'Hello',
      'logout': 'Log out',
      'comingSoon': 'Home screen is coming next',
      'loginTitle': 'Sign in',
      'loginSub': 'Welcome back to Al-Jafen Academy',
      'registerTitle': 'Create account',
      'registerSub': 'Join the Al-Jafen sports family',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm password',
      'fullName': 'Full name',
      'phone': 'Mobile number',
      'gender': 'Gender',
      'male': 'Male',
      'female': 'Female',
      'loginBtn': 'Sign in',
      'registerBtn': 'Create account',
      'noAccount': "Don't have an account?",
      'registerLink': 'Sign up',
      'haveAccount': 'Already have an account?',
      'loginLink': 'Sign in',
      'forgotPassword': 'Forgot password?',
      'resetSent': 'Reset link sent to your email',
      'errRequired': 'This field is required',
      'errEmail': 'Enter a valid email',
      'errPhone': 'Enter a valid mobile number',
      'errPassShort': 'Password must be at least 6 characters',
      'errPassMatch': 'Passwords do not match',
      'errGender': 'Select gender',
      'errUserNotFound': 'Account not found',
      'errWrongPass': 'Incorrect email or password',
      'errEmailInUse': 'This email is already registered',
      'errWeakPass': 'Password is too weak',
      'errNetwork': 'Check your internet connection',
      'errTooMany': 'Too many attempts, try later',
      'errGeneric': 'Something went wrong, try again',
    },
  };

  static final List<Map<String, Map<String, String>>> _sources = [
    _data,
    homeStrings,
    plansStrings,
    staffStrings,
    childrenStrings,
    scheduleStrings,
    profileStrings,
    bookingsStrings,
    eventsStrings,
    freezeStrings,
  ];

  static String of(BuildContext context, String key) {
    final code = Localizations.localeOf(context).languageCode;
    for (final lang in [code, 'ar']) {
      for (final src in _sources) {
        final v = src[lang]?[key];
        if (v != null) return v;
      }
    }
    return key;
  }
}

/// اختصار: context.tr('welcome')
extension TrX on BuildContext {
  String tr(String key) => AppStrings.of(this, key);
}