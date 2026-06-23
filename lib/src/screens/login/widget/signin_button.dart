import 'package:flutter/material.dart';
import 'package:amaguexpress/src/screens/admin/order_monitor/admin_order_monitor_screen.dart';
import 'package:amaguexpress/constants/types_constant.dart';
import 'package:amaguexpress/generated/l10n.dart';
import 'package:amaguexpress/src/models/user_model.dart';
import 'package:amaguexpress/src/screens/deliveryman/petitions/petitions_screen.dart';
import 'package:amaguexpress/src/screens/login/access_controller.dart';
import 'package:amaguexpress/src/screens/main/tab_main_screen.dart';
import 'package:amaguexpress/src/screens/manager/requests/requests_screen.dart';
import 'package:amaguexpress/src/screens/recover/recover_screen.dart';
import 'package:amaguexpress/src/widgets/primary_button.dart';

class SigninButton extends StatelessWidget {
  const SigninButton(
    this.accessController, {
    super.key,
    required GlobalKey<FormState> formKey,
  }) : _formKey = formKey;
  final AccessController accessController;
  final GlobalKey<FormState> _formKey;

  @override
  Widget build(BuildContext context) {
    return PrimaryButton(
      text: S.of(context).bSignin,
      onPressed: () async {
        FocusScope.of(context).requestFocus(FocusNode());
        _formKey.currentState!.save();
        if (!_formKey.currentState!.validate()) return;

        final navigator = Navigator.of(context);
        final scaffoldMessenger = ScaffoldMessenger.of(context);
        final s = S.of(context);

        UserModel? userLogin = await accessController.signin();

        if (userLogin != null) {
          // ✅ Login OK: reset counter
          accessController.resetFailedSigninAttempts();

          MaterialPageRoute route;
          if (userLogin.roles.contains(TypesRol.admin)) {
            route = MaterialPageRoute(
                builder: (context) => const AdminOrderMonitorScreen());
          } else if (userLogin.roles.contains(TypesRol.deliveryman)) {
            route = MaterialPageRoute(
                builder: (context) => const PetitionsScreen());
          } else if (userLogin.roles.contains(TypesRol.manager)) {
            route =
                MaterialPageRoute(builder: (context) => const RequestsScreen());
          } else {
            route =
                MaterialPageRoute(builder: (context) => const TabMainScreen());
          }
          navigator.pushAndRemoveUntil(route, (Route<dynamic> route) {
            return false;
          });
        } else {
          // ❌ Login fail: increment counter
          final attempts = accessController.registerFailedSigninAttempt();

          scaffoldMessenger.clearSnackBars();

          scaffoldMessenger.showSnackBar(SnackBar(
            duration: const Duration(milliseconds: 4500),
            content: Text('${s.mIncorrectLogin} ($attempts/5)'),
            action: SnackBarAction(
              label: s.bRecoverAccount,
              textColor: Colors.red,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RecoverScreen()),
              ),
            ),
          ));

          // ✅ At 5 attempts: show blocking dialog and send to recover
          if (attempts >= 5) {
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (_) => AlertDialog(
                backgroundColor: Colors.grey.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: Colors.black87, width: 1.2),
                ),
                titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                title: const Text(
                  'CUENTA BLOQUEADA',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color.fromARGB(255, 54, 0, 0),
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                content: const Text(
                  'Has excedido el número de intentos. Recupera tu cuenta para continuar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.25),
                ),
                actions: [
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => RecoverScreen()),
                        );
                      },
                      child: const Text(
                        'Recuperar cuenta',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            );

            // UI only: reset after lock message
            accessController.resetFailedSigninAttempts();
          }
        }
      },
    );
  }
}
