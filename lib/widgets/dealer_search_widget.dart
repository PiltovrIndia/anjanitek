import 'package:anjanitek/modals/users.dart';
import 'package:anjanitek/utils/divider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class DealerSearchWidget extends StatelessWidget {
  const DealerSearchWidget({
    super.key,
    required this.controller,
    required this.dealers,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
    required this.onDealerTap,
    this.hintText = 'Type dealer name to Search',
    this.emptyStateText,
    this.readOnlyWhenFilled = true,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final List<Users> dealers;
  final bool isLoading;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;
  final ValueChanged<Users> onDealerTap;
  final String hintText;
  final String? emptyStateText;
  final bool readOnlyWhenFilled;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          autofocus: autofocus,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          controller: controller,
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14.0),
          decoration: InputDecoration(
            fillColor: Colors.white,
            filled: true,
            contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            suffixIcon: controller.text.isNotEmpty
                ? TextButton(
                    onPressed: onClear,
                    child: const Text(
                      'Clear',
                      style: TextStyle(color: Color(0xFF008160)),
                    ),
                  )
                : const Icon(
                    PhosphorIconsRegular.magnifyingGlass,
                    color: Color(0xFF008160),
                  ),
            hintText: hintText,
            hintStyle: const TextStyle(fontSize: 14.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16.0),
              borderSide: const BorderSide(
                color: Color(0xFF008160),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: const BorderSide(
                color: Color(0xFF008160),
                width: 1.5,
              ),
            ),
          ),
          readOnly: readOnlyWhenFilled && controller.text.isNotEmpty,
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (dealers.isNotEmpty)
          Material(
            elevation: 8.0,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                border: Border.all(
                  color: Colors.black12,
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    offset: Offset(0.0, 0.0),
                    blurRadius: 24.0,
                    spreadRadius: 0.3,
                  ),
                ],
              ),
              height: 180,
              child: Scrollbar(
                thumbVisibility: true,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: dealers.length,
                  itemBuilder: (context, index) {
                    final dealer = dealers[index];

                    return ListTile(
                      dense: true,
                      visualDensity:
                          const VisualDensity(horizontal: 0, vertical: -4),
                      isThreeLine: false,
                      title: Text(
                        dealer.name ?? '',
                        style: GoogleFonts.inter(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        dealer.id ?? '',
                        style: GoogleFonts.inter(
                          textStyle: Theme.of(context).textTheme.bodySmall,
                          color: Colors.black54,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () => onDealerTap(dealer),
                    );
                  },
                  separatorBuilder: (context, index) => divider(Colors.black12),
                ),
              ),
            ),
          )
        else if (emptyStateText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAF9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD7E7E1)),
            ),
            child: Row(
              children: [
                const Icon(
                  PhosphorIconsRegular.info,
                  color: Color(0xFF5A6B66),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    emptyStateText!,
                    style: GoogleFonts.inter(
                      textStyle: Theme.of(context).textTheme.bodySmall,
                      color: const Color(0xFF5A6B66),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
