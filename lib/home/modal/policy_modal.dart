import 'package:flutter/material.dart';

class PolicyModal extends StatelessWidget {
  const PolicyModal({super.key});

  static Future<void> open(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PolicyModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height * 0.9;

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: GestureDetector(
          onTap: () {},
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Color(0xffe6e6ef),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 14),

                  // drag indicator
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // LOGO
                  Image.asset(
                    'assets/images/iumrah_logo.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Privacy And Policy',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // SCROLLABLE CONTENT
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      child: const Text(
                        '''
Developer: Aziz Kodirov / iumrah project
Contact: iumrahproject@gmail.com
Country: Saudi Arabia

1. General Information
This application iumrah project (“App”) respects your privacy.
This Privacy Policy explains what data we collect, how we use it, and how we protect it.
By using the App, you agree to this Privacy Policy.

2. Data Collection and Use
The App may collect and process the following information:
 • Name, email address, phone number (for communication or registration);
 • Geolocation (if navigation or SOS features are used);
 • Technical data (device type, OS version, language, country);
 • Data provided via Google Sheets (e.g., feedback forms or usage statistics).

Note: All bookings and payments are processed through embedded WebView services:
Aviasales (flights) and Agoda (hotels).
The App does not store or process any payment card data — all transactions occur directly on those third-party platforms.

3. Purpose of Data Processing
Collected data is used for:
 • providing App services;
 • operating the voice guide and customizing user experience;
 • user support and app improvement;
 • ensuring user safety during pilgrimage;
 • managing paid subscriptions and donation records.

4. Subscriptions and Donations
The App offers an annual voice guide subscription and allows donations through the App Store or Google Play.
All donations are used solely for server maintenance, operational costs, and the development of global pilgrimage technologies.

5. Third-Party Services
The App may use the following external services:
 • Aviasales and Agoda – for bookings and payments;
 • Google Sheets – for data management;
 • Google Maps – for navigation;
 • AI Voice Engine – for the voice guide.

Each third-party service has its own privacy policy that applies to its data handling.

6. Data Storage and Protection
We take all reasonable measures to protect user data from loss, unauthorized access, or alteration.
All data is stored securely and never shared with third parties unless required for service functionality.

7. User Rights
Users have the right to:
 • request deletion or modification of their data;
 • cancel subscriptions and delete the App;
 • contact us for any privacy-related questions at iumrahproject@gmail.com.

8. Policy Updates
We may update this Policy from time to time. Any changes will be posted in the App and on our official website.

9. Contact
For questions regarding privacy, please contact us at:
📧 iumrahproject@gmail.com

Разработчик: Aziz Kodirov / iumrah project
Контакт: iumrahproject@gmail.com
Страна: Саудовская Аравия | Узбекистан

1. Общие положения
Данное приложение iumrah project (далее — «Приложение») уважает право пользователей на конфиденциальность. Настоящая Политика описывает, какие данные мы собираем, как их используем и как обеспечиваем их защиту.

Используя Приложение, вы соглашаетесь с условиями данной Политики.

2. Сбор и использование данных
Приложение может собирать и обрабатывать следующие данные:
 • Имя, адрес электронной почты, номер телефона (при регистрации или обратной связи);
 • Геолокация (если пользователь активирует навигационные функции или SOS-сервис);
 • Техническая информация о устройстве (тип устройства, версия ОС, язык, страна);
 • Данные, предоставляемые через Google Sheets (например, форма обратной связи или статистика).

Важно: все бронирования и оплаты происходят через встроенные вебвью-сервисы —
Aviasales (авиабилеты) и Agoda (отели).
Приложение не хранит и не обрабатывает данные платежных карт — они обрабатываются только на стороне указанных сервисов.

3. Цель обработки данных
Собранные данные используются исключительно для:
 • предоставления сервисов Приложения;
 • работы голосового гида и персонализации контента;
 • поддержки пользователей и улучшения функциональности;
 • обеспечения безопасности пользователей во время паломничества;
 • администрирования платной подписки и учёта донатов.

4. Подписки и донаты
Приложение предлагает годовую подписку на голосовой гид и возможность делать донаты через App Store / Google Play.
Донаты используются исключительно для покрытия расходов на серверы, техническое обслуживание и развитие технологий паломничества.

5. Передача данных третьим лицам
Приложение может использовать сторонние сервисы:
 • Aviasales и Agoda — для бронирований и оплаты;
 • Google Sheets — для хранения базовых данных;
 • Google Maps — для карт и навигации;
 • ИИ-озвучка (AI Voice) — для работы голосового гида.

Эти сервисы могут обрабатывать данные в соответствии со своими собственными политиками конфиденциальности.

6. Хранение и защита данных
Мы принимаем все разумные меры для защиты данных пользователей от утраты, несанкционированного доступа и изменения.
Данные хранятся только на защищённых серверах сторонних поставщиков и не передаются третьим лицам без необходимости.

7. Права пользователей
Пользователь имеет право:
 • запросить удаление или изменение своих данных;
 • отказаться от подписки и удалить приложение;
 • связаться с нами для любых вопросов по адресу: iumrahproject@gmail.com

8. Изменения политики
Мы можем обновлять данную Политику. Новая версия будет опубликована в приложении и на сайте.

9. Контактная информация
По вопросам конфиденциальности обращайтесь на email:
📧 iumrahproject@gmail.com
                        ''',
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
