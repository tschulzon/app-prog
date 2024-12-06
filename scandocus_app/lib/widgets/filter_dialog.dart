import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:scandocus_app/models/document.dart';
import 'package:scandocus_app/widgets/language_list.dart';
import '../screens/doc_page_overview.dart';
import '../services/api_service.dart';
import '../widgets/date_picker.dart';

import 'package:provider/provider.dart';
import '../utils/document_provider.dart';

class FilterDialog extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final String? initialLanguage;
  final int? initialStartPageNumber;
  final int? initialEndPageNumber;

  const FilterDialog(
      {super.key,
      this.initialStartDate,
      this.initialEndDate,
      this.initialStartTime,
      this.initialEndTime,
      this.initialLanguage,
      this.initialStartPageNumber,
      this.initialEndPageNumber});

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TimeOfDay? startTime;
  late TimeOfDay? endTime;
  late String? selectedLanguage;
  late int? startSelectedPages;
  late int? endSelectedPages;

  late TextEditingController startPageNumberController;
  late TextEditingController endPageNumberController;

  late TextEditingController startTimeController;
  late TextEditingController endTimeController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    startTime = widget.initialStartTime;
    endTime = widget.initialEndTime;
    selectedLanguage = widget.initialLanguage;
    startSelectedPages = widget.initialStartPageNumber;
    endSelectedPages = widget.initialEndPageNumber;

    // // Erstelle Controller, lasse sie leer, wenn keine Zeit gesetzt ist
    // startTimeController = TextEditingController(
    //   text: startTime != null ? startTime!.format(context) : '',
    // );
    // endTimeController = TextEditingController(
    //   text: endTime != null ? endTime!.format(context) : '',
    // );

    startPageNumberController = TextEditingController(text: "");

    startPageNumberController.addListener(() {
      setState(() {
        startSelectedPages = int.tryParse(startPageNumberController.text);
      });
    });

    endPageNumberController = TextEditingController(text: "");

    endPageNumberController.addListener(() {
      setState(() {
        endSelectedPages = int.tryParse(endPageNumberController.text);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialisiere die Controller in didChangeDependencies, nachdem der Kontext verfügbar ist
    // Erstelle Controller, lasse sie leer, wenn keine Zeit gesetzt ist
    startTimeController = TextEditingController(
      text: startTime != null ? startTime!.format(context) : '',
    );
    endTimeController = TextEditingController(
      text: endTime != null ? endTime!.format(context) : '',
    );
  }

  @override
  void dispose() {
    // Entsorge den Controller, um Speicherlecks zu vermeiden
    startTimeController.dispose();
    endTimeController.dispose();
    startPageNumberController.dispose();
    endPageNumberController.dispose();
    super.dispose();
  }

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

  String formatScanDate(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('dd-MM-yyyy').format(dateTime);
  }

  String formatScanTime(String isoDate) {
    DateTime dateTime = DateTime.parse(isoDate);
    return DateFormat('HH:mm').format(dateTime);
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: LanguageList(
              currentLanguage: " ",
              languageSelected: (newLang) {
                setState(() {
                  selectedLanguage = newLang.code;
                });
              }),
        );
      },
    );
  }

  void resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      startTime = null;
      endTime = null;
      selectedLanguage = null;
      startSelectedPages = null;
      endSelectedPages = null;

      //Reset the Controller
      startPageNumberController.text = "";
      endPageNumberController.text = "";
      startTimeController.text = "";
      endTimeController.text = "";
    });
  }

  TimeOfDay currentTime = TimeOfDay.now(); // Aktuelle Zeit initialisieren

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetAnimationCurve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        height: 600,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text("Filter-Optionen", style: TextStyle(fontSize: 16)),
              ),
              Divider(),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    const Text("Scan-Datum: "),
                    const SizedBox(height: 10),
                    // FilterDatePicker(),
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
                    Divider(),
                    SizedBox(height: 20),
                    // Zeigt die aktuell ausgewählte Zeit an
                    Text('Scan-Uhrzeit: '),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: startTimeController,
                            decoration: const InputDecoration(
                              labelText: "Start",
                              suffixIcon: Icon(Icons.schedule),
                            ),
                            onTap: () async {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime: startTime ??
                                    TimeOfDay
                                        .now(), // Nutze die zuletzt ausgewählte Zeit
                              );

                              if (pickedTime != null &&
                                  pickedTime != startTime) {
                                setState(() {
                                  startTime = pickedTime;
                                  // Aktualisiere den Controller mit der neuen Zeit
                                  startTimeController.text =
                                      pickedTime.format(context);
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            readOnly: true,
                            controller: endTimeController,
                            decoration: const InputDecoration(
                              labelText: "Ende",
                              suffixIcon: Icon(Icons.schedule),
                            ),
                            onTap: () async {
                              final TimeOfDay? pickedTime =
                                  await showTimePicker(
                                context: context,
                                initialTime: endTime ??
                                    TimeOfDay
                                        .now(), // Nutze die zuletzt ausgewählte Zeit
                              );

                              if (pickedTime != null && pickedTime != endTime) {
                                setState(() {
                                  endTime = pickedTime;
                                  // Aktualisiere den Controller mit der neuen Zeit
                                  endTimeController.text =
                                      pickedTime.format(context);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                    Text("Seitenzahl: "),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              controller: startPageNumberController,
                              decoration: InputDecoration(labelText: "Von"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              controller: endPageNumberController,
                              decoration: InputDecoration(labelText: "Bis"),
                            ),
                          ),
                        ]),
                    Divider(),
                    Text("Sprache: "),
                    ElevatedButton.icon(
                      onPressed: () {
                        print("Sprachbutton gedrückt");
                        _showLanguageDialog(context);
                      },
                      icon: const Icon(Icons.language),
                      label: Text(selectedLanguage ?? "Sprachauswahl"),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print("ResetButton gedrückt");
                        resetFilters();
                      },
                      child: const Icon(Icons.close),
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        print("STARTDATUM:");
                        print(_startDate);
                        print("ENDDATUM:");
                        print(_endDate);
                        print("----------------------");
                        print("STARTZEIT:");
                        print(startTime);
                        print("ENDZEIT:");
                        print(endTime);
                        print("----------------------");
                        print("SPRACHE:");
                        print(selectedLanguage);
                        print("----------------------");
                        print("Seitenzahl Von:");
                        print(startSelectedPages);
                        print("Seitenzahl Bis:");
                        print(endSelectedPages);

                        // Filter-Map dynamisch erstellen
                        final filters = <String, dynamic>{};

                        if (_startDate != null) {
                          filters['startDate'] = _startDate;
                        }
                        if (_endDate != null) {
                          filters['endDate'] = _endDate;
                        }
                        if (startTime != null) {
                          filters['startTime'] = startTime;
                        }
                        if (endTime != null) {
                          filters['endTime'] = endTime;
                        }
                        if (selectedLanguage != null) {
                          filters['selectedLanguage'] = selectedLanguage;
                        }
                        if (startSelectedPages != null) {
                          filters['startSelectedPages'] = startSelectedPages;
                        }
                        if (endSelectedPages != null) {
                          filters['endSelectedPages'] = endSelectedPages;
                        }

                        Navigator.pop(context, filters);
                      },
                      child: const Icon(Icons.check),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
