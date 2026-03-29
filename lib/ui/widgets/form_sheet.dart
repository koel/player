import 'package:app/constants/constants.dart';
import 'package:app/ui/widgets/widgets.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// A reusable bottom sheet with a title, form fields, and action buttons.
/// Used for creating/editing playlists, folders, radio stations, etc.
Future<void> showFormSheet(
  BuildContext context, {
  required String title,
  required Widget Function(BuildContext context, StateSetter setState) builder,
  required String submitLabel,
  required Future<void> Function() onSubmit,
  bool Function()? canSubmit,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: _FormSheet(
          title: title,
          builder: builder,
          submitLabel: submitLabel,
          onSubmit: onSubmit,
          canSubmit: canSubmit,
        ),
      );
    },
  );
}

class _FormSheet extends StatefulWidget {
  final String title;
  final Widget Function(BuildContext context, StateSetter setState) builder;
  final String submitLabel;
  final Future<void> Function() onSubmit;
  final bool Function()? canSubmit;

  const _FormSheet({
    required this.title,
    required this.builder,
    required this.submitLabel,
    required this.onSubmit,
    this.canSubmit,
  });

  @override
  State<_FormSheet> createState() => _FormSheetState();
}

class _FormSheetState extends State<_FormSheet> {
  var _submitting = false;

  @override
  Widget build(BuildContext context) {
    return GradientDecoratedContainer(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 28),
                Flexible(
                  child: SingleChildScrollView(
                    child: widget.builder(context, setState),
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: _submitting
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: _submitting ? Colors.white24 : Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        color: highlightColor,
                        borderRadius: BorderRadius.circular(8),
                        onPressed: _submitting ||
                                (widget.canSubmit != null &&
                                    !widget.canSubmit!())
                            ? null
                            : () async {
                                setState(() => _submitting = true);
                                try {
                                  await widget.onSubmit();
                                } finally {
                                  if (mounted) {
                                    setState(() => _submitting = false);
                                  }
                                }
                              },
                        child: _submitting
                            ? const CupertinoActivityIndicator()
                            : Text(
                                widget.submitLabel,
                                style: const TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A styled text field for use in form sheets. Shows a hint when unfocused,
/// and a floating label above the field when focused.
class FormTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? placeholder;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;

  const FormTextField({
    Key? key,
    required this.controller,
    this.placeholder,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
  }) : super(key: key);

  @override
  State<FormTextField> createState() => _FormTextFieldState();
}

class _FormTextFieldState extends State<FormTextField> {
  late final FocusNode _focusNode;
  var _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  bool get _showLabel => _focused;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      maxLines: widget.maxLines,
      keyboardType: widget.keyboardType,
      onChanged: (value) {
        setState(() {});
        widget.onChanged?.call(value);
      },
      style: const TextStyle(color: Colors.white, fontSize: 14),
      cursorColor: highlightColor,
      decoration: InputDecoration(
        hintText: _showLabel ? null : widget.placeholder,
        hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
        labelText: _showLabel ? widget.placeholder : null,
        labelStyle: const TextStyle(color: Colors.white),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        filled: true,
        fillColor: CupertinoColors.tertiarySystemFill,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white54, width: 1),
        ),
      ),
    );
  }
}

/// A styled dropdown for use in form sheets, matching the FormTextField style.
class FormDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) labelBuilder;
  final String placeholder;
  final ValueChanged<T?> onChanged;
  final IconData icon;

  const FormDropdown({
    Key? key,
    required this.value,
    required this.items,
    required this.labelBuilder,
    required this.onChanged,
    this.placeholder = 'Select',
    this.icon = CupertinoIcons.chevron_down,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.circular(8),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          icon: Icon(icon, size: 12, color: CupertinoColors.systemGrey),
          hint: Text(
            placeholder,
            style: const TextStyle(
              fontSize: 14,
              color: CupertinoColors.placeholderText,
            ),
          ),
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                labelBuilder(item),
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
