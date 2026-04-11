import 'package:app/constants/constants.dart';
import 'package:app/providers/providers.dart';
import 'package:app/ui/screens/screens.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class GoogleConsentScreen extends StatefulWidget {
  static const routeName = '/google-consent';

  final Map<String, dynamic> ssoUser;
  final Map<String, dynamic> legalUrls;

  const GoogleConsentScreen({
    Key? key,
    required this.ssoUser,
    required this.legalUrls,
  }) : super(key: key);

  @override
  State<GoogleConsentScreen> createState() => _GoogleConsentScreenState();
}

class _GoogleConsentScreenState extends State<GoogleConsentScreen> {
  var _termsAccepted = false;
  var _privacyAccepted = false;
  var _ageVerified = false;
  var _submitting = false;

  bool get _allAccepted => _termsAccepted && _privacyAccepted && _ageVerified;

  Future<void> _submit() async {
    setState(() => _submitting = true);

    try {
      final auth = context.read<AuthProvider>();
      await auth.completeGoogleConsent(ssoUser: widget.ssoUser);
      await auth.tryGetAuthUser();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pushNamedAndRemoveUntil(
          DataLoadingScreen.routeName,
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    }
  }

  bool _isValidHttpUrl(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      return false;
    }
    return uri.host.isNotEmpty;
  }

  Future<void> _openUrl(String? url) async {
    if (url == null) return;
    final trimmed = url.trim();
    if (trimmed.isEmpty) return;

    final uri = Uri.tryParse(trimmed);
    if (uri == null || !_isValidHttpUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open this link.')),
        );
      }
      return;
    }

    final launched =
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open this link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.ssoUser['name'] ?? '';
    final email = widget.ssoUser['email'] ?? '';
    final termsUrl = widget.legalUrls['terms_url'];
    final privacyUrl = widget.legalUrls['privacy_url'];

    return Scaffold(
      body: GradientDecoratedContainer(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.hPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 160),
                const SizedBox(height: 24),
                Text(
                  'Welcome, $name',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),
                _ConsentCheckbox(
                  value: _termsAccepted,
                  onChanged: (v) => setState(() => _termsAccepted = v ?? false),
                  label: 'I accept the ',
                  linkText: 'Terms and Conditions',
                  onTapLink: () => _openUrl(termsUrl),
                ),
                _ConsentCheckbox(
                  value: _privacyAccepted,
                  onChanged: (v) =>
                      setState(() => _privacyAccepted = v ?? false),
                  label: 'I accept the ',
                  linkText: 'Privacy Policy',
                  onTapLink: () => _openUrl(privacyUrl),
                ),
                _ConsentCheckbox(
                  value: _ageVerified,
                  onChanged: (v) => setState(() => _ageVerified = v ?? false),
                  label: 'I confirm I am 13 years or older',
                  linkText: null,
                  onTapLink: null,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _allAccepted && !_submitting ? _submit : null,
                    child: _submitting
                        ? const SpinKitThreeBounce(
                            color: Colors.white, size: 16)
                        : const Text('Continue'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _submitting
                      ? null
                      : () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsentCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final String? linkText;
  final VoidCallback? onTapLink;

  const _ConsentCheckbox({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.linkText,
    required this.onTapLink,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.highlight,
          checkColor: Colors.black,
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => onChanged(!value),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                children: [
                  TextSpan(text: label),
                  if (linkText != null)
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: onTapLink,
                        child: Text(
                          linkText!,
                          style: TextStyle(
                            color: AppColors.highlight,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.highlight,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
