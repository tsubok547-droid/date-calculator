import 'package:flutter/material.dart';

class MessengerService {
  void showSnackBar(GlobalKey<ScaffoldMessengerState> messengerKey, String message) {
    final snackBar = SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          messengerKey.currentState?.hideCurrentSnackBar();
        },
      ),
    );
    
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(snackBar);
  }
}