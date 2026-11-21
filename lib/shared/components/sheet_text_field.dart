import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Campo di testo che possiede il proprio controller: il testo digitato
/// sopravvive a ogni rebuild (anche con errori), l'aspetto viene dal tema.
class SheetTextField extends StatefulWidget {
  const SheetTextField({
    super.key,
    required this.initialValue,
    required this.onChanged,
    this.label,
    this.errorText,
    this.helperText,
    this.hintText,
    this.enabled = true,
    this.minLines = 1,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
  });

  final String initialValue;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? errorText;
  final String? helperText;
  final String? hintText;
  final bool enabled;
  final int minLines;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SheetTextField> createState() => _SheetTextFieldState();
}

class _SheetTextFieldState extends State<SheetTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialValue,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: _controller,
    onChanged: widget.onChanged,
    enabled: widget.enabled,
    minLines: widget.minLines,
    maxLines: widget.maxLines,
    maxLength: widget.maxLength,
    maxLengthEnforcement: MaxLengthEnforcement.none,
    keyboardType: widget.keyboardType,
    inputFormatters: widget.inputFormatters,
    decoration: InputDecoration(
      labelText: widget.label,
      errorText: widget.errorText,
      helperText: widget.helperText,
      hintText: widget.hintText,
    ),
  );
}
