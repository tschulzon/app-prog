import 'dart:io';

import 'package:clay_containers/clay_containers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: Color.fromARGB(219, 11, 185, 216),
              onPrimary: Colors.white,
              onSurface: Colors.white,
              surface: Color.fromARGB(219, 11, 185, 216),
            ),
            textTheme: TextTheme(
              bodyMedium: GoogleFonts.quicksand(
                textStyle: TextStyle(color: Colors.white, fontSize: 14),
              ), // Schriftart für die normalen Tage
              titleLarge: GoogleFonts.quicksand(
                textStyle: TextStyle(color: Colors.white, fontSize: 18),
              ), // Schriftart für den Monatstitel
            ),
            dialogBackgroundColor: Color(0xFF202124),
          ),
          child: child!,
        );
      },
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF202124),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(16.0),
        ),
      ),
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          color: Colors.transparent,
          child: LanguageList(
              currentLanguage: " ",
              languageSelected: (newLang) {
                setState(() {
                  selectedLanguage = newLang.langCode;
                });
              },
              activeFilter: true),
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
    Color baseColor = Color(0xFF202124);

    final TextStyle quicksandTextStyle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Color.fromARGB(219, 11, 185, 216),
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleTitle = GoogleFonts.quicksand(
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14.0,
        fontWeight: FontWeight.w400,
      ),
    );

    final TextStyle quicksandTextStyleButton = GoogleFonts.quicksand(
      textStyle: TextStyle(
        color: Color(0xFF202124),
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
      ),
    );

    return Container(
      width: double.infinity,
      height: 600,
      padding: const EdgeInsets.all(20.0),
      child: SingleChildScrollView(
        // padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(3.0),
              child: Text("Filter-Optionen",
                  style: GoogleFonts.quicksand(
                    textStyle: TextStyle(
                      color: Color.fromARGB(219, 11, 185, 216),
                      fontSize: 16.0,
                      fontWeight: FontWeight.w700,
                    ),
                  )),
            ),
            Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Scan-Datum: ", style: quicksandTextStyleTitle),
                  // FilterDatePicker(),
                  // Eingabefelder für Start- und Enddatum
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _startDate != null
                                  ? "${_startDate!.day.toString().padLeft(2, '0')}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.year}"
                                  : ''),
                          style: quicksandTextStyleTitle,
                          decoration: InputDecoration(
                            labelText: "Start",
                            labelStyle: quicksandTextStyle,
                            suffixIcon: Icon(Icons.calendar_today),
                            suffixIconColor: Color.fromARGB(219, 11, 185, 216),
                          ),
                          onTap: () => _selectDateRange(context),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              text: _endDate != null
                                  ? "${_endDate!.day.toString().padLeft(2, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.year}"
                                  : ''),
                          style: quicksandTextStyleTitle,
                          decoration: InputDecoration(
                            labelText: "Ende",
                            labelStyle: quicksandTextStyle,
                            suffixIcon: Icon(Icons.calendar_today),
                            suffixIconColor: Color.fromARGB(219, 11, 185, 216),
                          ),
                          onTap: () => _selectDateRange(context),
                        ),
                      ),
                    ],
                  ),
                  // Divider(),
                  SizedBox(height: 20),
                  // Zeigt die aktuell ausgewählte Zeit an
                  Text('Scan-Uhrzeit:', style: quicksandTextStyleTitle),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: startTimeController,
                          style: quicksandTextStyleTitle,
                          decoration: InputDecoration(
                            labelText: "Start",
                            labelStyle: quicksandTextStyle,
                            suffixIcon: Icon(Icons.schedule),
                            suffixIconColor: Color.fromARGB(219, 11, 185, 216),
                          ),
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: startTime ?? TimeOfDay.now(),
                            );

                            if (pickedTime != null && pickedTime != startTime) {
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
                          style: quicksandTextStyleTitle,
                          decoration: InputDecoration(
                            labelText: "Ende",
                            labelStyle: quicksandTextStyle,
                            suffixIcon: Icon(Icons.schedule),
                            suffixIconColor: Color.fromARGB(219, 11, 185, 216),
                          ),
                          onTap: () async {
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: endTime ?? TimeOfDay.now(),
                              helpText: "Uhrzeit auswählen",
                              cancelText: "Abbrechen",
                              hourLabelText: "",
                              minuteLabelText: "",
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
                  SizedBox(height: 20),
                  Text("Seitenzahl:", style: quicksandTextStyleTitle),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            controller: startPageNumberController,
                            style: quicksandTextStyleTitle,
                            decoration: InputDecoration(
                                labelText: "Von",
                                labelStyle: quicksandTextStyle),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            controller: endPageNumberController,
                            style: quicksandTextStyleTitle,
                            decoration: InputDecoration(
                                labelText: "Bis",
                                labelStyle: quicksandTextStyle),
                          ),
                        ),
                      ]),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Sprache:", style: quicksandTextStyleTitle),
                      SizedBox(width: 30),
                      ElevatedButton.icon(
                        onPressed: () async {
                          print("Sprachbutton gedrückt");
                          _showLanguageDialog(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(219, 11, 185, 216),
                          elevation: 30,
                          shadowColor: Color(0xFF202124),
                          padding: EdgeInsets.all(10),
                          overlayColor: const Color.fromARGB(255, 26, 255, 114)
                              .withOpacity(0.7),
                        ),
                        icon: Icon(
                          Icons.language,
                          color: Color(0xFF202124),
                          size: 25.0,
                        ),
                        label: Text(selectedLanguage ?? "...",
                            style: quicksandTextStyleButton),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    print("ResetButton gedrückt");
                    resetFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(238, 159, 29, 29),
                    elevation: 15,
                    padding: EdgeInsets.all(12),
                    overlayColor: const Color.fromARGB(255, 255, 26, 133)
                        .withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () async {
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 60, 221, 121)
                        .withOpacity(0.7),
                    elevation: 15,
                    padding: EdgeInsets.all(12),
                    overlayColor:
                        const Color.fromARGB(255, 26, 255, 60).withOpacity(0.7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 20.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
