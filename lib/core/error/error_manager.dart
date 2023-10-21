import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';


import '../injection/injection_container.dart';
import '../util/abstract_cubit_state.dart';
import '../util/shared_preferences.dart';


class ErrorManager {
  static String getApiError(Response response) {
    switch (response.statusCode) {
      case 401:
        return ' المستخدم الحالي لم يسجل الدخول ' '${response.statusCode}';

      case 503:
        return 'حدث تغيير في المخدم رمز الخطأ 503 ' '${response.statusCode}';
      case 481:
        return 'لا يوجد اتصال بالانترنت' '${response.statusCode}';
      case 482:


      case 404:
      case 500:
      default:
        final errorBody = ErrorBody.fromJson(jsonDecode(response.body));

        return '${errorBody.errors.join('\n')}\n ${response.statusCode}';
    }
  }
}

class ErrorBody {
  ErrorBody({
    required this.errors,
  });

  final List<String> errors;

  factory ErrorBody.fromJson(Map<String, dynamic> json) {
    return ErrorBody(
      errors:
          json["errors"] == null ? [] : List<String>.from(json["errors"]!.map((x) => x)),
    );
  }

  Map<String, dynamic> toJson() => {
        "errors": errors.map((x) => x).toList(),
      };
}

showErrorFromApi(AbstractCubit state) {
  final ctx = sl<GlobalKey<NavigatorState>>().currentContext;
  if (ctx == null) return;

}
