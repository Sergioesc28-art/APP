import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentController {
  Future<void> createPaymentIntent() async {
    try {
      // URL de tu backend
      final url = Uri.parse('http://localhost:3000/create-payment-intent');

      // Cuerpo de la solicitud
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 5000, // Monto en centavos (5000 = $50.00)
          'currency': 'usd',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Obtén el clientSecret del backend
        final clientSecret = data['clientSecret'];

        // Confirma el pago con Stripe
        await Stripe.instance.confirmPayment(
          clientSecret,
          PaymentMethodParams.card(
            paymentMethodData: PaymentMethodData(),
          ),
        );

        print('Pago exitoso');
      } else {
        print('Error al crear el Payment Intent: ${response.body}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }
}