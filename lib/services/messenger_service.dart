import 'package:flutter/material.dart';

class MessengerService {
  // BuildContextの代わりにGlobalKey<ScaffoldMessengerState>を受け取る
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
    
    // GlobalKeyを使ってSnackBarを表示する
    messengerKey.currentState?.hideCurrentSnackBar();
    messengerKey.currentState?.showSnackBar(snackBar);
  }
}