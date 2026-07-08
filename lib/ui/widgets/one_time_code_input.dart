import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A segmented one-time-code field: [length] single-digit boxes with
/// auto-advance, backspace-to-previous, and paste/autofill distribution.
class OneTimeCodeInput extends StatefulWidget {
  final int length;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onCompleted;

  const OneTimeCodeInput({
    Key? key,
    this.length = 6,
    this.onChanged,
    this.onCompleted,
  }) : super(key: key);

  @override
  State<OneTimeCodeInput> createState() => _OneTimeCodeInputState();
}

class _OneTimeCodeInputState extends State<OneTimeCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (index) {
      return FocusNode()..onKeyEvent = (_, event) => _handleKey(index, event);
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) controller.dispose();
    for (final node in _focusNodes) node.dispose();
    super.dispose();
  }

  String get _code => _controllers.map((controller) => controller.text).join();

  void _setBox(int index, String digit) {
    _controllers[index].value = TextEditingValue(
      text: digit,
      selection: TextSelection.collapsed(offset: digit.length),
    );
  }

  void _emit() {
    final code = _code;
    widget.onChanged?.call(code);
    if (code.length == widget.length) widget.onCompleted?.call(code);
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      for (var offset = 0; index + offset < widget.length; offset++) {
        _setBox(index + offset,
            offset < digits.length ? digits[offset] : '');
      }
      final focusIndex =
          (index + digits.length).clamp(0, widget.length - 1);
      _focusNodes[focusIndex].requestFocus();
    } else {
      _setBox(index, digits);
      if (digits.isNotEmpty && index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      }
    }

    _emit();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    final isBackspace = event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace;

    if (isBackspace && _controllers[index].text.isEmpty && index > 0) {
      _setBox(index - 1, '');
      _focusNodes[index - 1].requestFocus();
      _emit();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final highlight = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: SizedBox(
            width: 44,
            height: 54,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              autofocus: index == 0,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: Colors.white10,
                contentPadding: EdgeInsets.zero,
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: highlight, width: 2),
                ),
              ),
              onChanged: (value) => _handleChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
