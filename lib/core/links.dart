import 'package:url_launcher/url_launcher.dart';

class Links {
  static const instagram = 'https://www.instagram.com/aljafensportsacademy';
  static const facebook =
      'https://www.facebook.com/profile.php?id=100024045846944';
  static const snapchat = 'https://snapchat.com/t/0DHTikvc';
  static const map = 'https://maps.app.goo.gl/p12ZPHRq32hWSqnr9';
  static const whatsapp = 'https://wa.me/966552006531';
  static const phone = 'tel:+966552006531';
}

Future<void> openUrl(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {}
}