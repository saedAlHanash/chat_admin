import 'package:drawable_text/drawable_text.dart';
import 'package:fitness_admin_chat/core/strings/app_color_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_multi_type/image_multi_type.dart';

class MyTextFormWidget extends StatelessWidget {
  const MyTextFormWidget({
    Key? key,
    this.liable = '',
    this.hint = '',
    this.maxLines = 1,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.maxLength = 1000,
    this.onChanged,
    this.controller,
    this.keyBordType,
    this.innerPadding,
    this.icon,
    this.enable,
    this.initialValue,
  }) : super(key: key);

  final String liable;
  final String hint;
  final String? initialValue;
  final String? icon;
  final int maxLines;
  final int maxLength;
  final bool obscureText;
  final bool? enable;
  final TextAlign textAlign;
  final Function(String val)? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyBordType;
  final EdgeInsets? innerPadding;

  @override
  Widget build(BuildContext context) {
    final padding = innerPadding ?? EdgeInsets.symmetric(horizontal: 10.0.w);

    bool obscureText = this.obscureText;
    Widget? suffixIcon;
    VoidCallback? onChangeObscure;

    if (icon != null) {
      suffixIcon = Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w),
        child: ImageMultiType(url: icon!, height: 23.0.h, width: 40.0.w),
      );
    }

    if (obscureText) {
      suffixIcon = StatefulBuilder(builder: (context, state) {
        return IconButton(
            splashRadius: 0.01,
            onPressed: () {
              state(() => obscureText = !obscureText);
              if (onChangeObscure != null) onChangeObscure!();
            },
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off));
      });
    }

    final inputDecoration = InputDecoration(
      contentPadding: padding,
      errorBorder: InputBorder.none,
      counter: const SizedBox(),
      alignLabelWithHint: true,
      labelText: liable,
      suffixIcon: suffixIcon ?? const SizedBox(),
    );

    final textStyle = TextStyle(
      fontFamily: FontManager.cairoSemiBold.name,
      fontSize: 16.0.sp,
      color: AppColorManager.gray,
    );

    return StatefulBuilder(builder: (context, state) {
      onChangeObscure = () => state(() {});
      return TextFormField(
        decoration: inputDecoration,
        maxLines: maxLines,
        obscureText: obscureText,
        textAlign: textAlign,
        onChanged: onChanged,
        textDirection: TextDirection.rtl,
        style: textStyle,
        maxLength: maxLength,
        initialValue: initialValue,
        enabled: enable,
        controller: controller,
        keyboardType: keyBordType,
      );
    });
  }
}

class MyTextFormOutLineWidget extends StatelessWidget {
  const MyTextFormOutLineWidget({
    Key? key,
    this.liable = '',
    this.hint = '',
    this.maxLines = 1,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.maxLength = 1000,
    this.onChanged,
    this.controller,
    this.keyBordType,
    this.innerPadding,
    this.enable,
    this.icon,
    this.initialValue,
  }) : super(key: key);
  final bool? enable;
  final String liable;
  final String hint;
  final dynamic icon;
  final int maxLines;
  final int maxLength;
  final bool obscureText;
  final String? initialValue;
  final TextAlign textAlign;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyBordType;
  final EdgeInsets? innerPadding;

  @override
  Widget build(BuildContext context) {
    final padding = innerPadding ?? EdgeInsets.symmetric(horizontal: 10.0.w);

    bool obscureText = this.obscureText;
    Widget? suffixIcon;
    VoidCallback? onChangeObscure;

    if (icon != null) {
      suffixIcon = Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w),
        child: ImageMultiType(url: icon!, height: 23.0.h, width: 40.0.w),
      );
    }

    if (obscureText) {
      suffixIcon = StatefulBuilder(builder: (context, state) {
        return IconButton(
            splashRadius: 0.01,
            onPressed: () {
              state(() => obscureText = !obscureText);
              if (onChangeObscure != null) onChangeObscure!();
            },
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off));
      });
    }

    final inputDecoration = InputDecoration(
      contentPadding: padding,
      errorBorder: InputBorder.none,
      disabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(
          color: AppColorManager.mainColor,
        ),
      ),
      counter: const SizedBox(),
      alignLabelWithHint: true,
      labelText: liable,
      suffixIcon: suffixIcon ?? const SizedBox(),
      enabled: enable ?? true,
    );

    final textStyle = TextStyle(
      fontFamily: FontManager.cairoSemiBold.name,
      fontSize: 16.0.sp,
      color: AppColorManager.black,
    );

    return StatefulBuilder(builder: (context, state) {
      onChangeObscure = () => state(() {});
      return TextFormField(
        decoration: inputDecoration,
        maxLines: maxLines,
        obscureText: obscureText,
        textAlign: textAlign,
        autofocus: true,
        onChanged: onChanged,
        initialValue: initialValue,
        style: textStyle,
        maxLength: maxLength,
        controller: controller,
        keyboardType: keyBordType,
      );
    });
  }
}

class MyEditTextWidget extends StatelessWidget {
  const MyEditTextWidget({
    Key? key,
    this.hint = '',
    this.maxLines = 1,
    this.textAlign,
    this.maxLength = 1000,
    this.onChanged,
    this.controller,
    this.keyBordType,
    this.innerPadding,
    this.backgroundColor,
    this.focusNode,
    this.obscureText = false,
    this.icon,
    this.enable,
    this.radios,
    this.textInputAction,
    this.onFieldSubmitted,
    this.initialValue,
  }) : super(key: key);

  final String hint;
  final String? initialValue;
  final int maxLines;
  final int maxLength;
  final bool obscureText;
  final bool? enable;
  final TextAlign? textAlign;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyBordType;
  final EdgeInsets? innerPadding;
  final Color? backgroundColor;
  final Widget? icon;
  final FocusNode? focusNode;
  final double? radios;
  final TextInputAction? textInputAction;
  final Function(String)? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    bool obscureText = this.obscureText;
    Widget? suffixIcon;
    late VoidCallback onChangeObscure;

    if (icon != null) suffixIcon = icon;

    if (obscureText) {
      suffixIcon = StatefulBuilder(builder: (context, state) {
        return InkWell(
            splashColor: Colors.transparent,
            onTap: () {
              state(() => obscureText = !obscureText);
              onChangeObscure();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0).r,
              child: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                size: 20.0.spMin,
              ),
            ));
      });
    }

    final border = OutlineInputBorder(
        borderSide: BorderSide(
          color: backgroundColor ?? AppColorManager.offWhit.withOpacity(0.27),
        ),
        borderRadius: BorderRadius.circular(radios ?? 10.0.r));
    final inputDecoration = InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10.0).w,
      counter: const SizedBox(),
      enabledBorder: border,
      focusedErrorBorder: border,
      disabledBorder: border,
      focusedBorder: border,
      border: border,
      fillColor: backgroundColor ?? AppColorManager.offWhit.withOpacity(0.27),
      filled: true,
      enabled: enable ?? true,
      suffix: suffixIcon ?? 0.0.verticalSpace,
      suffixIconConstraints: BoxConstraints(maxWidth: 80.0.spMin, minHeight: 50.0.spMin),
    );

    return StatefulBuilder(
      builder: (context, state) {
        onChangeObscure = () => state(() {});
        return TextFormField(
          onTap: () {
            if (controller != null) {
              if (controller!.selection ==
                  TextSelection.fromPosition(
                      TextPosition(offset: controller!.text.length - 1))) {
                state(() {
                  controller!.selection = TextSelection.fromPosition(
                      TextPosition(offset: controller!.text.length));
                });
              }
            }
          },
          initialValue: initialValue,
          obscureText: obscureText,
          decoration: inputDecoration,
          maxLines: maxLines,
          textAlign: textAlign ?? TextAlign.start,
          onChanged: onChanged,
          focusNode: focusNode,
          maxLength: maxLength,
          controller: controller,
          keyboardType: keyBordType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
        );
      },
    );
  }
}

class MyTextFormNoLabelWidget extends StatelessWidget {
  const MyTextFormNoLabelWidget({
    Key? key,
    this.label = '',
    this.hint = '',
    this.maxLines = 1,
    this.obscureText = false,
    this.textAlign = TextAlign.start,
    this.maxLength = 1000,
    this.onChanged,
    this.controller,
    this.keyBordType,
    this.innerPadding,
    this.enable,
    this.icon,
    this.color,
    this.initialValue,
    this.textDirection,
  }) : super(key: key);
  final bool? enable;
  final String label;
  final String hint;
  final String? icon;
  final Color? color;
  final int maxLines;
  final int maxLength;
  final bool obscureText;
  final TextAlign textAlign;
  final Function(String)? onChanged;
  final TextEditingController? controller;
  final TextInputType? keyBordType;
  final EdgeInsets? innerPadding;
  final String? initialValue;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final padding = innerPadding ?? EdgeInsets.symmetric(horizontal: 10.0.w);

    bool obscureText = this.obscureText;
    Widget? suffixIcon;
    VoidCallback? onChangeObscure;

    if (icon != null) {
      suffixIcon = Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0.w),
        child: ImageMultiType(url: icon!, height: 23.0.h, width: 40.0.w),
      );
    }

    if (obscureText) {
      suffixIcon = StatefulBuilder(builder: (context, state) {
        return IconButton(
            splashRadius: 0.01,
            onPressed: () {
              state(() => obscureText = !obscureText);
              if (onChangeObscure != null) onChangeObscure!();
            },
            icon: Icon(obscureText ? Icons.visibility : Icons.visibility_off));
      });
    }
    final border = OutlineInputBorder(
        borderSide: BorderSide(
          color: color ?? AppColorManager.gray.withOpacity(0.7),
        ),
        borderRadius: BorderRadius.circular(10.0.r));

    final inputDecoration = InputDecoration(
      contentPadding: padding,
      errorBorder: InputBorder.none,
      border: border,
      focusedErrorBorder: border,
      focusedBorder: border,
      enabledBorder: border,
      counter: const SizedBox(),
      alignLabelWithHint: true,
      labelStyle: TextStyle(color: color ?? AppColorManager.mainColor),
      suffixIcon: suffixIcon,
      enabled: enable ?? true,
    );

    final textStyle = TextStyle(
      fontFamily: FontManager.cairoSemiBold.name,
      fontSize: 20.0.sp,
      color: AppColorManager.mainColor,
    );

    return StatefulBuilder(builder: (context, state) {
      onChangeObscure = () => state(() {});
      return Column(
        children: [
          DrawableText(
            text: label,
            matchParent: true,
            color: AppColorManager.black,
            padding: const EdgeInsets.symmetric(horizontal: 10.0).w,
            size: 18.0.sp,
          ),
          3.0.verticalSpace,
          TextFormField(
            decoration: inputDecoration,
            maxLines: maxLines,
            initialValue: initialValue,
            obscureText: obscureText,
            textAlign: textAlign,
            onChanged: onChanged,
            style: textStyle,
            textDirection: textDirection,
            maxLength: maxLength,
            controller: controller,
            keyboardType: keyBordType,
          ),
          5.0.verticalSpace,
        ],
      );
    });
  }
}
