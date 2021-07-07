import 'package:app/constants/dimens.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/ui/screens/start.dart';
import 'package:app/ui/widgets/spinner.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
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
    preferences.hostUrl.then((value) => setState(() => _hostUrl = value));
    preferences.userEmail.then((value) => setState(() => _email = value));
  }

  showErrorDialog(BuildContext context) {
    showDialog(
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
            onPressed: () => Navigator.of(context).pop(),
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
        await preferences.setUserEmail(_email!);
        await auth.tryGetAuthUser();

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const StartScreen()),
        );
      } else {
        showErrorDialog(context);
      }
    }

    InputDecoration decoration({String? label, String? hint}) {
      return InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white),
        contentPadding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.transparent),
          borderRadius: BorderRadius.circular(6),
        ),
        fillColor: Colors.white12,
        filled: true,
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white24),
          borderRadius: BorderRadius.circular(6),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(6),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.red),
          borderRadius: BorderRadius.circular(6),
        ),
      );
    }

    String? requireValue(value) =>
        value == null || value.isEmpty ? 'This field is required' : null;

    Widget hostField = TextFormField(
      keyboardType: TextInputType.url,
      autocorrect: false,
      onSaved: (value) => preferences.setHostUrl(value!),
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
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
        primary: Colors.grey.shade900,
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: const Text('Log In'),
      onPressed: attemptLogin,
    );

    final spinnerWidget = Center(
      child: Padding(
        padding: EdgeInsets.only(top: 12),
        child: const Spinner(size: 16),
      ),
    );

    return SafeArea(
      child: Scaffold(
        body: Container(
          padding: const EdgeInsets.all(AppDimens.horizontalPadding),
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
                ].expand(
                  (element) => [element, const SizedBox(height: 12)],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
