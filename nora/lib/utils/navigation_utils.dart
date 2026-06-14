import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavigationUtils {
  // Méthode de retour sécurisée
  static void safePop(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }
}

// Extension pour faciliter l'utilisation
extension SafePopExtension on BuildContext {
  void safePop() {
    if (Navigator.of(this).canPop()) {
      pop();  // pop() directement, pas goRouter.pop()
    } else {
      go('/home');  // go() directement
    }
  }
  
  void goBack() {
    safePop();
  }
}