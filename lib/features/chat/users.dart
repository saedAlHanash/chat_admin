import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/api_manager/api_service.dart';
import 'package:fitness_admin_chat/core/extensions/extensions.dart';
import 'package:fitness_admin_chat/core/util/my_style.dart';
import 'package:fitness_admin_chat/features/chat/userss_bloc/users_bloc.dart';
import 'package:fitness_admin_chat/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive/hive.dart';
import 'package:image_multi_type/circle_image_widget.dart';

import '../../generated/assets.dart';
import '../../router/app_router.dart';
import 'util.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<UsersCubit, UsersInitial>(
        builder: (context, state) {
          return Placeholder();
        },
      ),
    );
  }
}
