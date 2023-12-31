import 'dart:convert';

import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../strings/enum_manager.dart';
import 'dart:convert';

import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/chat/my_room_object.dart';
import '../strings/enum_manager.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart' as firebase;

class AppSharedPreference {
  static const _token = '1';
  static const _phoneNumber = '3';
  static const _toScreen = '4';
  static const _policy = '5';
  static const _user = '6';
  static const _forgetEmail = '7';
  static const _fireToken = '8';
  static const _notificationCount = '9';
  static const _social = '10';
  static const _activeNoti = '11';
  static const _myId = '12';
  static const _cart = '13';
  static const _lang = '14';

  static late SharedPreferences _prefs;

  static init(SharedPreferences preferences) async {
    _prefs = preferences;
  }

  static cashToken(String? token) {
    if (token == null) return;

    _prefs.setString(_token, token);
  }

  static String getToken() {
    return _prefs.getString(_token) ?? '';
  }





  static cashPhoneOrEmail(String? phone) async {
    if (phone == null) return;

    loggerObject.v(phone);
    await _prefs.setString(_phoneNumber, phone);
  }

  static String get  getPhoneOrEmail {
    return _prefs.getString(_phoneNumber) ?? '';
  }

  static void removePhoneOrEmail() {
    _prefs.remove(_phoneNumber);
  }

  static cashToScreen(ToScreen appState) {
    _prefs.setInt(_toScreen, appState.index);
  }

  static ToScreen toScreen() {
    final index = _prefs.getInt(_toScreen) ?? 0;
    return ToScreen.values[index];
  }

  static cashAcceptPolicy(bool isAccept) {
    if (isAccept == false) cashToScreen(ToScreen.policy);

    _prefs.setBool(_policy, isAccept);
  }

  static bool isAcceptPolicy() {
    return _prefs.getBool(_policy) ?? false;
  }

  static void clear() {
    _prefs.clear();
  }

  static void logout() {
    _prefs.clear();
  }


  static bool get isLogin => getToken().isNotEmpty;

  static void cashFireToken(String token) {
    _prefs.setString(_fireToken, token);
  }

  static String getFireToken() {
    return _prefs.getString(_fireToken) ?? '';
  }

  static void addNotificationCount() {
    var count = getNotificationCount() + 1;
    _prefs.setInt(_notificationCount, count);
  }

  static int getNotificationCount() {
    return _prefs.getInt(_notificationCount) ?? 0;
  }

  static void clearNotificationCount() {
    _prefs.setInt(_notificationCount, 0);
  }

  static bool isCachedSocial() {
    return (_prefs.getString(_social) ?? '').length > 10;
  }

  static void cashActiveNotification(bool val) {
    _prefs.setBool(_activeNoti, val);
  }

  static bool getActiveNotification() {
    return _prefs.getBool(_activeNoti) ?? true;
  }

  static void cashMyId(int id) {
    _prefs.setInt(_myId, id);
  }

  static void updateCart(List<String> jsonCart) {
    _prefs.setStringList(_cart, jsonCart);
  }

  static List<String> getJsonListCart() => _prefs.getStringList(_cart) ?? <String>[];

  static int get getMyId => _prefs.getInt(_myId) ?? 0;

  static void cashLocal(String langCode) {
    _prefs.setString(_lang, langCode);
  }

  static String get getLocal => _prefs.getString(_lang) ?? 'en';
}
