import 'package:app/constants/constants.dart';
import 'package:app/exceptions/exceptions.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:app/utils/preferences.dart' as preferences;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class TwoFactorChallengeScreen extends StatefulWidget {
  static const routeName = '/two-factor-challenge';

  final String host;
  final String email;
  final String loginToken;

  const TwoFactorChallengeScreen({
    Key? key,
    required this.host,
    required this.email,
    required this.loginToken,
  }) : super(key: key);

  @override
  _TwoFactorChallengeScreenState createState() =>
      _TwoFactorChallengeScreenState();
}

class _TwoFactorChallengeScreenState extends State<TwoFactorChallengeScreen> {
  final formKey = GlobalKey<FormState>();
  late final AuthProvider _auth;
  var _verifying = false;
  var _code = '';

  @override
  void initState() {
    super.initState();
    _auth = context.read();
  }

  Future<void> showErrorDialog(BuildContext context, {String? message}) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Error'),
        content: Text(
          message ?? 'There was a problem verifying the code. Please try again.',
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> verify() async {
    final form = formKey.currentState!;
    var successful = false;

    if (!form.validate()) return;

    form.save();
    setState(() => _verifying = true);

    try {
      await _auth.completeTwoFactorChallenge(
        loginToken: widget.loginToken,
        code: _code.trim(),
      );
      await _auth.tryGetAuthUser();
      successful = true;
    } on HttpResponseException catch (error) {
      await showErrorDialog(
        context,
        message: error.response.statusCode == 401
            ? 'Invalid authentication code.'
            : null,
      );
    } catch (error) {
      await showErrorDialog(context);
    } finally {
      setState(() => _verifying = false);
    }

    if (successful) {
      preferences.host = widget.host;
      preferences.userEmail = widget.email;
      Navigator.of(context, rootNavigator: true)
          .pushReplacementNamed(DataLoadingScreen.routeName);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientDecoratedContainer(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.hPadding,
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ...[
                    Text(
                      'Two-Factor Authentication',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const Text(
                      'Enter the code from your authenticator app, or one of '
                      'your recovery codes.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70),
                    ),
                    TextFormField(
                      autofocus: true,
                      autocorrect: false,
                      keyboardType: TextInputType.text,
                      textInputAction: TextInputAction.go,
                      onChanged: (value) => _code = value,
                      onSaved: (value) => _code = value ?? '',
                      onFieldSubmitted: (_) => _verifying ? null : verify(),
                      decoration: const InputDecoration(
                        labelText: 'Authentication code',
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'This field is required'
                          : null,
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        child: _verifying
                            ? const SpinKitThreeBounce(
                                color: Colors.white,
                                size: 16,
                              )
                            : const Text('Verify'),
                        onPressed: _verifying ? null : verify,
                      ),
                    ),
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
