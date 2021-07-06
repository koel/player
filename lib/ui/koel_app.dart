import 'package:app/constants/colors.dart';
import 'package:app/constants/strings.dart';
import 'package:app/models/user.dart';
import 'package:app/providers/user_provider.dart';
import 'package:app/ui/screens/login.dart';
import 'package:app/ui/screens/start.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/utils/full_width_slider_track_shape.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class KoelApp extends StatefulWidget {
  KoelApp({Key? key}) : super(key: key);

  @override
  _KoelAppState createState() => _KoelAppState();
}

class _KoelAppState extends State<KoelApp> {
  late Future<User?> futureUser;

  @override
  void initState() {
    super.initState();
    futureUser = context.read<UserProvider>().tryGetAuthUser();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppStrings.appName,
        theme: ThemeData(
          brightness: Brightness.dark,
          dividerColor: Colors.white.withOpacity(.3),
          scaffoldBackgroundColor: Colors.black,
          backgroundColor: AppColors.primaryBgr,
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
            activeTrackColor: Colors.white.withOpacity(.8),
            inactiveTrackColor: Colors.white.withOpacity(.3),
            thumbColor: Colors.white,
            trackHeight: 3,
            overlayColor: Colors.white.withAlpha(32),
            trackShape: FullWidthSliderTrackShape(),
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 8,
            ),
          ),
          textTheme: Theme.of(context).textTheme.apply(
                bodyColor: Colors.white.withOpacity(.9),
                displayColor: Colors.white.withOpacity(.6),
              ),
        ),
        home: FutureBuilder(
          future: futureUser,
          builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.none:
              case ConnectionState.waiting:
                return ContainerWithSpinner();
              default:
                return snapshot.data == null ? LoginScreen() : StartScreen();
            }
          },
        ),
      ),
    );
  }
}
