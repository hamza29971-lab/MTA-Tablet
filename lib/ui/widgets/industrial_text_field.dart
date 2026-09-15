import 'package:flutter/material.dart';

class IndustrialTextField extends StatefulWidget {
  final TextEditingController controller;
  final String? hintText;
  final String? label;
  final TextInputType keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;

  const IndustrialTextField({
    Key? key,
    required this.controller,
    this.label,
    this.hintText,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.textInputAction,
  }) : super(key: key);

  @override
  State<IndustrialTextField> createState() => _IndustrialTextFieldState();
}

class _IndustrialTextFieldState extends State<IndustrialTextField> {

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null && widget.label!.isNotEmpty)
          Text(
            widget.label!,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF046464),
            ),
          ),
        if (widget.label != null && widget.label!.isNotEmpty)
          const SizedBox(height: 8),
        TextField(
          controller: widget.controller,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          decoration: InputDecoration(
            hintText: widget.hintText,
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF046464), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
