import 'package:flutter/material.dart';

class FilterDatePicker extends StatefulWidget {
  const FilterDatePicker({super.key});

  @override
  State<FilterDatePicker> createState() => _FilterDatePickerState();
}

class _FilterDatePickerState extends State<FilterDatePicker> {
  DateTime? _startDate;
  DateTime? _endDate;

  /// Methode zum Öffnen des Kalenders und Aktualisieren der Felder
  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2021),
      lastDate: DateTime(2025),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Eingabefelder für Start- und Enddatum
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
              text: _startDate != null
                  ? "${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}"
                  : ''),
          decoration: const InputDecoration(
            labelText: "Startdatum",
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () => _selectDateRange(context),
        ),
        const SizedBox(height: 16),
        TextFormField(
          readOnly: true,
          controller: TextEditingController(
              text: _endDate != null
                  ? "${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}"
                  : ''),
          decoration: const InputDecoration(
            labelText: "Enddatum",
            suffixIcon: Icon(Icons.calendar_today),
          ),
          onTap: () => _selectDateRange(context),
        ),
        const SizedBox(height: 16),
        // Button zum Öffnen des Kalenders
        Center(
          child: ElevatedButton(
            onPressed: () => _selectDateRange(context),
            child: const Text("Kalender öffnen"),
          ),
        ),
      ],
    );
  }
}
