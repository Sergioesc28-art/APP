import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:url_launcher/url_launcher.dart';

class PaymentController {
  Future<void> subscribeToPremium(String userId) async {
    final url = Uri.parse('http://localhost:3000/create-checkout-session');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final checkoutUrl = data['url'];

      // Abre la URL de Stripe Checkout
      if (await canLaunch(checkoutUrl)) {
        await launch(checkoutUrl);
      } else {
        throw 'No se pudo abrir la URL de Stripe Checkout';
      }
    } else {
      print('Error al crear la sesión de pago: ${response.body}');
    }
  }
}