import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class LauncherHelper {
  static Future<void> openMap(num lat, num lng) async {
    final googleUrl =
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not open the map.';
    }
  }

  static Future<void> openPage(String url) async {
    final googleUrl = Uri.parse(url);
    await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
  }

  static Future<void> callPhone({String? phone}) async {
    await launchUrl(Uri.parse("tel://$phone"));
  }

  static Future<void> sendWhatsApp({String? phone, String? text}) async {
    var contact = phone ?? '';
    var androidUrl = "whatsapp://send?phone=$contact&text=$text";
    var iosUrl = "https://wa.me/$contact?text=${Uri.parse(text ?? '')}";

    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    await launchUrl(Uri.parse(isIOS ? iosUrl : (kIsWeb ? iosUrl : androidUrl)));
  }
}
