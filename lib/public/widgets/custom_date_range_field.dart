import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDateRangeField extends StatefulWidget {
  final String startLabel;
  final String endLabel;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime?) onStartDateChanged;
  final Function(DateTime?) onEndDateChanged;
  final Color primaryColor;
  final bool showClearButtons;
  final bool showDatePickerIcons;
  final String dateFormat;
  final String? hintText;
  final bool required;
  final String? Function(DateTime?)? validator;

  const CustomDateRangeField({
    Key? key,
    required this.startLabel,
    required this.endLabel,
    this.initialStartDate,
    this.initialEndDate,
    required this.onStartDateChanged,
    required this.onEndDateChanged,
    this.primaryColor = const Color(0xff142831),
    this.showClearButtons = true,
    this.showDatePickerIcons = true,
    this.dateFormat = 'dd/MM/yyyy',
    this.hintText,
    this.required = false,
    this.validator,
  }) : super(key: key);

  @override
  _CustomDateRangeFieldState createState() => _CustomDateRangeFieldState();
}

class _CustomDateRangeFieldState extends State<CustomDateRangeField> {
  late TextEditingController _startDateController;
  late TextEditingController _endDateController;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _startDateController = TextEditingController(
      text: _startDate != null ? DateFormat(widget.dateFormat).format(_startDate!) : '',
    );
    _endDateController = TextEditingController(
      text: _endDate != null ? DateFormat(widget.dateFormat).format(_endDate!) : '',
    );
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: isStartDate ? DateTime(1900) : _startDate ?? DateTime(1900),
      lastDate: isStartDate ? _endDate ?? DateTime(2100) : DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          _startDateController.text = DateFormat(widget.dateFormat).format(picked);
          widget.onStartDateChanged(picked);
        } else {
          _endDate = picked;
          _endDateController.text = DateFormat(widget.dateFormat).format(picked);
          widget.onEndDateChanged(picked);
        }
      });
    }
  }

  void _clearDate(bool isStartDate) {
    setState(() {
      if (isStartDate) {
        _startDate = null;
        _startDateController.clear();
        widget.onStartDateChanged(null);
      } else {
        _endDate = null;
        _endDateController.clear();
        widget.onEndDateChanged(null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildDateField(
            context: context,
            label: widget.startLabel,
            controller: _startDateController,
            isStartDate: true,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildDateField(
            context: context,
            label: widget.endLabel,
            controller: _endDateController,
            isStartDate: false,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required bool isStartDate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: widget.primaryColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.centerRight,
          children: [
            TextFormField(
              controller: controller,
              readOnly: true,
              decoration: InputDecoration(
                hintText: widget.hintText ?? widget.dateFormat.toLowerCase(),
                suffixIcon: widget.showDatePickerIcons
                    ? IconButton(
                  icon: Icon(Icons.calendar_today, color: widget.primaryColor),
                  onPressed: () => _selectDate(context, isStartDate),
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: widget.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
              ),
              onTap: () => _selectDate(context, isStartDate),
              validator: (value) {
                if (widget.required && (value == null || value.isEmpty)) {
                  return '$label is required';
                }
                if (widget.validator != null) {
                  return widget.validator!(isStartDate ? _startDate : _endDate);
                }
                return null;
              },
            ),
            if (widget.showClearButtons && controller.text.isNotEmpty)
              Positioned(
                right: widget.showDatePickerIcons ? 48 : 12,
                child: IconButton(
                  icon: Icon(Icons.clear, color: Colors.grey.shade500, size: 20),
                  onPressed: () => _clearDate(isStartDate),
                ),
              ),
          ],
        ),
      ],
    );
  }
}