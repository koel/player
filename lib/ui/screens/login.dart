import 'package:app/constants/dimensions.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/data_loading.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  static const routeName = '/login';

  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _authenticating = false;
  final formKey = GlobalKey<FormState>();

  String? _email = '';
  String? _password = '';
  String? _hostUrl = '';

  @override
  void initState() {
    super.initState();

    // Try looking for stored values in local storage
    setState(() {
      _hostUrl = preferences.hostUrl;
      _email = preferences.userEmail;
    });
  }

  Future<void> showErrorDialog(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: const Text(
          'There was a problem logging in. Please try again.',
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AuthProvider auth = context.watch();

    Future<void> attemptLogin() async {
      final form = formKey.currentState!;

      if (!form.validate()) return;

      form.save();
      setState(() => _authenticating = true);

      bool result = await auth.login(email: _email!, password: _password!);
      setState(() => _authenticating = false);

      if (result) {
        // Store the email into local storage for easy login next time
        preferences.userEmail = _email;
        await auth.tryGetAuthUser();

        Navigator.of(
          context,
          rootNavigator: true,
        ).pushReplacementNamed(DataLoadingScreen.routeName);
      } else {
        throw Error();
      }
    }

    InputDecoration decoration({String? label, String? hint}) {
      return InputDecoration(
        labelText: label,
        hintText: hint,
      );
    }

    String? requireValue(value) =>
        value == null || value.isEmpty ? 'This field is required' : null;

    Widget hostField = TextFormField(
      keyboardType: TextInputType.url,
      autocorrect: false,
      onSaved: (value) => preferences.hostUrl = value,
      decoration: decoration(
        label: 'Host URL',
        hint: 'https://www.koel.music',
      ),
      controller: TextEditingController(text: _hostUrl),
      validator: requireValue,
    );

    final emailField = TextFormField(
      keyboardType: TextInputType.emailAddress,
      autocorrect: false,
      onSaved: (value) => _email = value ?? '',
      decoration: decoration(label: 'Email', hint: 'you@koel.music'),
      controller: TextEditingController(text: _email),
      validator: requireValue,
    );

    final passwordField = TextFormField(
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      onSaved: (value) => _password = value ?? '',
      decoration: decoration(label: 'Password'),
      validator: requireValue,
    );

    final submitButton = ElevatedButton(
      child: const Text('Log In'),
      onPressed: () async {
        try {
          await attemptLogin();
        } catch (error) {
          await showErrorDialog(context);
        }
      },
    );

    final spinnerWidget = const Center(
      child: const Padding(
        padding: const EdgeInsets.only(top: 12),
        child: const Spinner(size: 16),
      ),
    );

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimensions.horizontalPadding),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ...[
                    Image.asset('assets/images/logo.png', width: 160),
                    hostField,
                    emailField,
                    passwordField,
                    SizedBox(
                      width: double.infinity,
                      child: _authenticating ? spinnerWidget : submitButton,
                    )
                  ].expand((widget) => [widget, const SizedBox(height: 12)]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
