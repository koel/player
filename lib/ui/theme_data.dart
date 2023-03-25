import 'package:app/constants/constants.dart';
import 'package:app/utils/full_width_slider_track_shape.dart';
import 'package:flutter/material.dart';

ThemeData themeData(BuildContext context) => ThemeData(
      dividerColor: Colors.white30,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: ColorScheme.dark(
        background: AppColors.primaryBgr,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.primaryBgr.withOpacity(.8),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        elevation: 2,
        color: Colors.grey.shade900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Colors.white70,
        inactiveTrackColor: Colors.white30,
        thumbColor: Colors.white,
        trackHeight: 3,
        overlayColor: Colors.white30,
        trackShape: FullWidthSliderTrackShape(),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
      ),

      /// Text with a color that contrasts with the card and canvas colors.
      textTheme: Theme.of(context)
          .textTheme
          .copyWith(
            displayLarge: const TextStyle(
              fontWeight: FontWeight.w100,
              fontSize: 96,
            ),
            displayMedium: const TextStyle(
              fontWeight: FontWeight.w100,
              fontSize: 60,
            ),
            displaySmall: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 48,
            ),
            headlineMedium: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 34,
            ),
            headlineSmall: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 24,
            ),
            titleLarge: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 20,
            ),
            titleMedium: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
            titleSmall: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            bodyLarge: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 16,
            ),
            bodyMedium: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Colors.white24,
            ),
            bodySmall: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 12,
            ),
            labelLarge: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            labelSmall: const TextStyle(
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
          )
          .apply(
            displayColor: AppColors.primaryText,
            bodyColor: AppColors.primaryText,
          ),

      // The default theme for ElevatedButton widgets.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              side: const BorderSide(color: Colors.white24),
              borderRadius: AppDimensions.inputBorderRadius,
            ),
          ),
          textStyle: MaterialStateProperty.all(
            const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w500),
          ),
          backgroundColor: MaterialStateProperty.all(Colors.white12),
          foregroundColor: MaterialStateProperty.all(AppColors.primaryText),
          overlayColor: MaterialStateProperty.all(Colors.white12),
          elevation: MaterialStateProperty.all(0),
          padding: MaterialStateProperty.all(AppDimensions.inputPadding),
        ),
      ),

      // The default theme for OutlinedButton widgets.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryText,
          side: const BorderSide(color: Colors.white54),
          textStyle: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: AppDimensions.inputBorderRadius,
          ),
          padding: AppDimensions.inputPadding,
        ),
      ),
      inputDecorationTheme: Theme.of(context).inputDecorationTheme.copyWith(
            labelStyle: const TextStyle(color: Colors.white70),
            hintStyle: const TextStyle(color: Colors.white24),
            contentPadding: AppDimensions.inputPadding,
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.transparent),
              borderRadius: AppDimensions.inputBorderRadius,
            ),
            fillColor: Colors.white12,
            filled: true,
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.white24),
              borderRadius: AppDimensions.inputBorderRadius,
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: AppDimensions.inputBorderRadius,
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: AppDimensions.inputBorderRadius,
            ),
          ),
    );
