import 'package:shared_preferences/shared_preferences.dart';

class SharedPreferencesHelper {
  ///
  /// Instantiation of the SharedPreferences library
  ///
  static const String _password = "password";
  static const String _userID = "user_id";
  static const String _token = "token";
  static const String _login = "login";
  static const String _isHasCheckDomain = 'check-domain';

  /// ------------------------------------------------------------
  /// Method that returns the user password
  /// ------------------------------------------------------------
  static Future<String?> getPassword() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(_password) ?? null;
  }
  /// ------------------------------------------------------------
  /// Method that returns the user token
  /// ------------------------------------------------------------
  static Future<String?> getToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(_token) ?? null;
  }
  /// ------------------------------------------------------------
  /// Method that returns the user login
  /// ------------------------------------------------------------
  static Future<String?> getLogin() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getString(_login) ?? null;
  }

    /// ------------------------------------------------------------
  /// Method that returns the user check domain
  /// ------------------------------------------------------------
  static Future<bool?> getCheckDomain() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_isHasCheckDomain) ?? null;
  }

  static Future<bool?> getUserID() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.getBool(_userID) ?? null;
  }

  static Future<bool> setUserID(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(_userID, value);
  }



  /// ----------------------------------------------------------
  /// Method that saves the user password
  /// ----------------------------------------------------------
  static Future<bool> setPassword(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(_password, value);
  }

    /// ----------------------------------------------------------
  /// Method that saves the user token
  /// ----------------------------------------------------------
  static Future<bool> setToken(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(_token, value);
  }

    /// ----------------------------------------------------------
  /// Method that saves the user login
  /// ----------------------------------------------------------
  static Future<bool> setLogin(String value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setString(_login, value);
  }
    /// ----------------------------------------------------------
  /// Method that saves the user check-domain
  /// ----------------------------------------------------------
  static Future<bool> setCheckDomain(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    return prefs.setBool(_isHasCheckDomain, value);
  }



}