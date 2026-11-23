import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Error with a message that is safe to show to the user.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

const _offlineMessage = 'No internet connection. Please check your network.';

/// Runs [action] and converts every Supabase / network error into an
/// [AppException] with a friendly message. Used by all backend services.
Future<T> guardBackend<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on AppException {
    rethrow;
  } on AuthRetryableFetchException {
    throw const AppException(_offlineMessage);
  } on AuthException catch (e) {
    throw AppException(_authMessage(e));
  } on PostgrestException catch (e) {
    throw AppException(switch (e.code) {
      '42501' => 'You are not allowed to do that.',
      '23505' => 'This item already exists.',
      '23514' => 'Some values are not valid.',
      _ => 'Database error: ${e.message}',
    });
  } on StorageException catch (e) {
    throw AppException('Image upload failed: ${e.message}');
  } on SocketException {
    throw const AppException(_offlineMessage);
  } on http.ClientException {
    throw const AppException(_offlineMessage);
  } on TimeoutException {
    throw const AppException(
        'The server took too long to answer. Please try again.');
  } on Exception catch (e) {
    // Last safety net: a screen must never stay stuck on a spinner.
    throw AppException('Something went wrong: $e');
  }
}

String _authMessage(AuthException e) {
  final text = e.message.toLowerCase();
  if (text.contains('invalid login credentials')) {
    return 'Wrong email or password.';
  }
  if (text.contains('already registered') || e.code == 'user_already_exists') {
    return 'An account with this email already exists.';
  }
  if (text.contains('email not confirmed')) {
    return 'Please confirm your email first (check your inbox).';
  }
  if (text.contains('rate limit') ||
      e.code == 'over_email_send_rate_limit' ||
      e.statusCode == '429') {
    return 'Too many emails were sent recently. Wait a few minutes, or ask '
        'the project owner to turn off "Confirm email" in Supabase.';
  }
  if (text.contains('database error')) {
    return 'The database could not create your profile. Run '
        'supabase/fix_signup.sql in the Supabase SQL Editor.';
  }
  if (text.contains('password should be at least')) {
    return 'The password is too short (minimum 6 characters).';
  }
  if (text.contains('different from the old password')) {
    return 'The new password must be different from the old one.';
  }
  return e.message;
}
