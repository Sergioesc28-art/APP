import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5EEDC), // Fondo beige
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'dogzline',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.brown,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Términos y Condiciones de Dogzline',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
              SizedBox(height: 10),
              Text(
                '''1. Introducción
Bienvenido a Dogzline, una innovadora aplicación móvil diseñada para facilitar la conexión y socialización de perros y sus dueños. Al acceder o utilizar nuestra aplicación, aceptas estos Términos y Condiciones. Si no estás de acuerdo con alguna parte de estos términos, te recomendamos que no utilices nuestra plataforma. Estos términos pueden ser actualizados periódicamente, y te notificaremos sobre cambios significativos.

2. Uso de la Aplicación
2.1. Acceso y Registro:
Para acceder a las funcionalidades de Dogzline, es necesario registrarse en la aplicación con información veraz y actualizada. Esto incluye datos como la información de contacto del dueño, detalles sobre el perro (raza, edad, tamaño, etc.), y cualquier otro dato relevante para la plataforma.
2.2. Edad mínima:
Debes ser mayor de 18 años para crear una cuenta y utilizar la aplicación. Si eres menor de edad, necesitarás el consentimiento de un padre o tutor para registrarte y utilizar Dogzline.
2.3. Propósito de la aplicación:
Dogzline tiene como propósito conectar a dueños de perros con otros dueños para actividades recreativas, paseos y eventos sociales, así como para fines de socialización y reproducción responsable. Cualquier uso de la aplicación fuera de estos fines está prohibido.

3. Registro y Seguridad de la Cuenta
3.1. Responsabilidad de la cuenta:
El usuario es el único responsable de mantener la confidencialidad de su cuenta y sus credenciales. No debes compartir tu cuenta o permitir que otras personas utilicen tu perfil.
3.2. Seguridad de la cuenta:
Dogzline toma medidas para proteger la seguridad de la aplicación y las cuentas de los usuarios, pero no podemos garantizar la seguridad absoluta. Si sospechas que tu cuenta ha sido comprometida, es tu responsabilidad cambiar la contraseña y notificar a soporte.
3.3. Información de contacto:
Es importante mantener actualizada tu información de contacto. Dogzline se reserva el derecho de suspender temporalmente o eliminar cuentas con información errónea o incompleta.

4. Contenido y Conducta del Usuario
4.1. Responsabilidad del contenido:
El usuario es responsable de todo el contenido que publique en la plataforma, incluidos perfiles, fotos, comentarios y cualquier otra forma de interacción. No se permite contenido ofensivo, ilegal, difamatorio o que viole los derechos de terceros.
4.2. Interacciones entre usuarios:
Dogzline proporciona una plataforma para facilitar la conexión entre usuarios, pero no interviene directamente en las interacciones. Se espera que los usuarios mantengan una conducta respetuosa, ética y responsable en todo momento.
4.3. Incumplimiento de los términos:
Dogzline se reserva el derecho de eliminar cualquier perfil o contenido que infrinja estos Términos y Condiciones, y de suspender o terminar cuentas en caso de violaciones graves.

5. Responsabilidad y Riesgos
5.1. Conexión entre usuarios:
Dogzline actúa únicamente como un intermediario para conectar a los dueños de mascotas, pero no se hace responsable de la compatibilidad o el bienestar de las interacciones entre perros ni entre sus dueños.
5.2. Riesgos inherentes:
Al utilizar la aplicación, los usuarios comprenden que existen riesgos inherentes, tales como accidentes, enfermedades u otros problemas relacionados con los perros y las interacciones entre ellos. Cada usuario es responsable de garantizar la seguridad de sus perros y de tomar medidas adecuadas para prevenir incidentes.
5.3. Responsabilidad del usuario:
El usuario es el único responsable de verificar las credenciales de otros usuarios antes de acordar cualquier encuentro o actividad. Dogzline no verifica la autenticidad de los perfiles o la información proporcionada por los usuarios.
5.4. No responsabilidad por daños o pérdidas:
Dogzline no es responsable de ningún daño, pérdida, robo o lesión que ocurra como resultado de la utilización de la aplicación, incluidos daños a la propiedad, pérdidas financieras, daños físicos o emocionales derivados de encuentros o interacciones.

6. Privacidad y Datos Personales
6.1. Recopilación de datos:
Dogzline recopila datos personales y de los perros de los usuarios con el fin de proporcionar el servicio adecuado. Esto incluye, pero no se limita a, nombres, direcciones de correo electrónico, datos de pago, preferencias y fotos de los perros.
6.2. Uso de los datos:
Los datos personales serán utilizados únicamente para los fines establecidos en la Política de Privacidad de Dogzline. No compartiremos tus datos con terceros sin tu consentimiento expreso, excepto cuando sea necesario para cumplir con requisitos legales o de seguridad.
6.3. Eliminación de datos:
Tienes el derecho de solicitar la eliminación de tus datos personales en cualquier momento. Para hacerlo, puedes contactar con el soporte de Dogzline.
6.4. Protección de datos:
Dogzline toma medidas razonables para proteger tus datos personales. Sin embargo, debes ser consciente de que no podemos garantizar la seguridad absoluta contra accesos no autorizados.

7. Modificaciones y Terminación
7.1. Modificación de los Términos:
Dogzline se reserva el derecho de modificar estos Términos y Condiciones en cualquier momento. Las modificaciones serán publicadas en la aplicación y entrarán en vigor de inmediato. Se recomienda a los usuarios revisar regularmente estos términos para estar al tanto de cualquier cambio.
7.2. Terminación de la cuenta:
Dogzline puede suspender o eliminar cuentas en caso de violaciones de estos Términos y Condiciones. El usuario puede cancelar su cuenta en cualquier momento a través de la configuración de la aplicación.

8. Política de Reembolsos y Cancelaciones
8.1. Compra de servicios y suscripciones:
Dogzline ofrece suscripciones y servicios adicionales dentro de la aplicación. Estas compras son finales y no se emitirán reembolsos bajo ninguna circunstancia.
8.2. Problemas técnicos:
En caso de que la aplicación no funcione correctamente debido a fallos técnicos o errores, Dogzline proporcionará soporte para resolver el inconveniente, pero no se ofrecerán reembolsos.
8.3. Cancelar suscripciones:
Si decides cancelar tu suscripción, podrás hacerlo en cualquier momento, pero no se realizarán reembolsos por períodos no utilizados.

9. Legislación Aplicable
9.1. Jurisdicción:
Estos Términos y Condiciones se rigen por las leyes del país en el que Dogzline opera. Cualquier disputa derivada del uso de la aplicación será resuelta bajo las leyes aplicables en esa jurisdicción.
9.2. Resolución de disputas:
Cualquier controversia o disputa será resuelta de forma amigable, y en caso de no llegar a un acuerdo, las partes se someterán a los tribunales competentes.

10. Propiedad Intelectual
10.1. Derechos de autor y propiedad:
Todos los derechos de propiedad intelectual relacionados con la aplicación Dogzline, incluido el diseño, logotipos, gráficos, software y contenido, son propiedad exclusiva de Dogzline o de sus licenciantes.
10.2. Uso de la propiedad intelectual:
El usuario no tiene derecho a copiar, modificar, distribuir, transmitir ni usar ningún contenido de la aplicación sin autorización previa y expresa de Dogzline.

11. Suspensión de Cuenta
11.1. Razones para la suspensión:
Dogzline podrá suspender o eliminar cuentas por violación de los términos, comportamiento inapropiado, uso fraudulento o por cualquier otra razón que ponga en peligro la seguridad o la integridad de la plataforma.
11.2. Proceso de apelación:
Los usuarios que consideren que su cuenta fue suspendida injustamente pueden apelar dicha suspensión contactando con el equipo de soporte de Dogzline.

12. Indemnización
12.1. Responsabilidad del usuario:
Aceptas indemnizar y mantener indemne a Dogzline, sus empleados, directores, agentes y socios por cualquier reclamación, pérdida, daño o gasto que surja del uso de la aplicación o de la violación de estos Términos y Condiciones.

13. Limitación de Responsabilidad
13.1. Exención de responsabilidad:
En la máxima medida permitida por la ley, Dogzline no será responsable de daños directos, indirectos, incidentales, especiales o consecuentes derivados del uso de la aplicación, ni de la pérdida de datos o interrupciones en el servicio.
13.2. Garantías:
Dogzline no garantiza que la aplicación estará libre de errores o interrupciones, ni que cumplirá todas las expectativas de los usuarios.

14. Derecho a Modificar los Términos
14.1. Cambios en los términos:
Dogzline puede modificar estos Términos y Condiciones en cualquier momento. Los usuarios serán notificados de dichos cambios y deberán aceptar los nuevos términos para continuar usando la aplicación.

15. Información de Contacto
Si tienes preguntas sobre estos Términos y Condiciones, por favor contacta con el soporte de Dogzline a través de la sección de ayuda en la aplicación.

Fecha de última actualización: [Fecha]
                ''',
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
            ],
          ),
        ),
      ),
    );
  }
}