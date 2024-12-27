import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:scandocus_app/widgets/language_list.dart';

/// This is a [FilterDialog] Widget with all filter options the user can use
/// It is a stateful widget, meaning the widget can have states that change over time
class FilterDialog extends StatefulWidget {
  /// These are the initial values for the filter options, passed from the parent page
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final TimeOfDay? initialStartTime;
  final TimeOfDay? initialEndTime;
  final String? initialLanguage;
  final int? initialStartPageNumber;
  final int? initialEndPageNumber;

  /// Constructor for the [FilterDialog], allowing initial values to be passed
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
  /// Variables to hold the values for filter options
  /// These values will be manipulated based on user input
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TimeOfDay? startTime;
  late TimeOfDay? endTime;
  late String? selectedLanguage;
  late int? startSelectedPages;
  late int? endSelectedPages;

  /// Controllers to handle text inputs for page numbers and time inputs
  late TextEditingController startPageNumberController =
      TextEditingController(text: "");
  late TextEditingController endPageNumberController =
      TextEditingController(text: "");

  late TextEditingController startTimeController;
  late TextEditingController endTimeController;

  /// Initializes filter options with values passed from the parent page [DocumentsView]
  @override
  void initState() {
    super.initState();

    // Assign initial values for date, time, language, and page filters from the parent page
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    startTime = widget.initialStartTime;
    endTime = widget.initialEndTime;
    selectedLanguage = widget.initialLanguage;
    startSelectedPages = widget.initialStartPageNumber;
    endSelectedPages = widget.initialEndPageNumber;

    // Initialize the controller for start page number with the initial value
    startPageNumberController = TextEditingController(
      text: widget.initialStartPageNumber != null
          ? widget.initialStartPageNumber.toString()
          : "",
    );

    // Add a listener to update 'startSelectedPages' whenever the text changes
    startPageNumberController.addListener(() {
      setState(() {
        startSelectedPages = int.tryParse(startPageNumberController.text);
      });
    });

    // Initialize the controller for end page number with the initial value
    endPageNumberController = TextEditingController(
      text: widget.initialEndPageNumber != null
          ? widget.initialEndPageNumber.toString()
          : "",
    );

    // Add a listener to update 'endSelectedPages' whenever the text changes
    endPageNumberController.addListener(() {
      setState(() {
        endSelectedPages = int.tryParse(endPageNumberController.text);
      });
    });
  }

  /// This method is called when the widget's dependencies change
  /// It initializes the time controllers with the formatted time values
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Initialize the controllers for the start and end time input field
    // If they are not null, format it and set it as the controller's text
    startTimeController = TextEditingController(
      text: startTime != null ? startTime!.format(context) : '',
    );
    endTimeController = TextEditingController(
      text: endTime != null ? endTime!.format(context) : '',
    );
  }

  /// This method is called when the widget is disposed (removed from the widget tree)
  /// It ensures that all controllers are properly disposed to free up resources and prevent memory leaks
  @override
  void dispose() {
    startTimeController.dispose();
    endTimeController.dispose();
    startPageNumberController.dispose();
    endPageNumberController.dispose();

    // Call the 'super.dispose()' to ensure the parent class can clean up its resources
    super.dispose();
  }

  /// Method for opening the calendar input modal with the [showDateRangePicker] function of the flutter material library
  /// This allows the user to select a date range
  Future<void> _selectDateRange(BuildContext context) async {
    // Show the date range picker dialog
    // If both _startDate and _endDate are set, use them as the initial date range
    // Otherwise, no initial range is provided
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
      builder: (BuildContext context, Widget? child) {
        // Customizes the appearance of the date range picker dialog
        return Theme(
          data: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: Color(0xFF202124),
            colorScheme: ColorScheme.dark(
              primary: Color.fromARGB(219, 11, 185, 216),
              onPrimary: Colors.white,
              onSurface: Colors.white,
              surface: Color.fromARGB(219, 11, 185, 216),
            ),
            textTheme: TextTheme(
              bodyMedium: GoogleFonts.quicksand(
                textStyle: TextStyle(color: Colors.white, fontSize: 14),
              ),
              titleLarge: GoogleFonts.quicksand(
                textStyle: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
            dialogBackgroundColor: Color(0xFF202124),
          ),
          child: child!, // The child widget (date picker) is rendered here
        );
      },
    );

    // Update the start and end date with the picked ones from the modal
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  /// Method for opening the language list modal which allows the user to select a language
  /// Only languages used in existing documents are displayed in this modal
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
          height: MediaQuery.of(context).size.height *
              0.7, // Takes up 70% of screen height
          color: Colors.transparent,
          child: LanguageList(
              currentLanguage: " ", // Default value for the current language
              // Updates the selected language when the user selects a new one
              languageSelected: (newLang) {
                setState(() {
                  selectedLanguage = newLang.langCode;
                });
              },
              // Indicates that the filter is active
              activeFilter: true),
        );
      },
    );
  }

  /// Resets all filter values and controllers to their default state when the user clicks the reset button
  void resetFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      startTime = null;
      endTime = null;
      selectedLanguage = null;
      startSelectedPages = null;
      endSelectedPages = null;

      startPageNumberController.text = "";
      endPageNumberController.text = "";
      startTimeController.text = "";
      endTimeController.text = "";
    });
  }

  /// Building the filter dialog widget that provides filter options to the user
  @override
  Widget build(BuildContext context) {
    // Define base TextStyles for consistency across the widget
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
      width: double.infinity, // Make the container as wide as its parent
      height: 600,
      padding: const EdgeInsets.all(20.0),
      // Allow scrolling if content overflows vertically
      child: SingleChildScrollView(
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
            Divider(), // Add a horizontal line to separate sections
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text("Scan-Datum: ", style: quicksandTextStyleTitle),
                  // Input fields for startDate and endDate selection
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              // Format the start date as "dd-mm-yyyy"
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
                      // Add spacing between input fields
                      SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          readOnly: true,
                          controller: TextEditingController(
                              // Format the end date as "dd-mm-yyyy"
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
                  SizedBox(height: 20),
                  Text('Scan-Uhrzeit:', style: quicksandTextStyleTitle),
                  // Input fields for startTime and endTime selection
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
                            // Open the time picker dialog to select the start time
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: startTime ??
                                  TimeOfDay
                                      .now(), // Default to current time if no value is set
                              helpText: "Uhrzeit auswählen",
                              cancelText: "Abbrechen",
                              hourLabelText: "",
                              minuteLabelText: "",
                            );

                            // Update the state and controller if a new time is selected
                            if (pickedTime != null && pickedTime != startTime) {
                              setState(() {
                                startTime = pickedTime;
                                startTimeController.text =
                                    pickedTime.format(context);
                              });
                            }
                          },
                        ),
                      ),
                      SizedBox(
                          width:
                              10), // Add spacing between the start and end time fields
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
                            // Open a time picker dialog to select the end time
                            final TimeOfDay? pickedTime = await showTimePicker(
                              context: context,
                              initialTime: endTime ??
                                  TimeOfDay
                                      .now(), // Default to current time if no value is set
                              helpText: "Uhrzeit auswählen",
                              cancelText: "Abbrechen",
                              hourLabelText: "",
                              minuteLabelText: "",
                            );

                            // Update the state and controller if a new time is selected
                            if (pickedTime != null && pickedTime != endTime) {
                              setState(() {
                                endTime = pickedTime;
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
                  // Input fields for selecting the range of page numbers (start and end)
                  Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            keyboardType: TextInputType
                                .number, // Restrict input to numeric values
                            textAlign: TextAlign.center,
                            controller: startPageNumberController,
                            style: quicksandTextStyleTitle,
                            decoration: InputDecoration(
                                labelText: "Von",
                                labelStyle: quicksandTextStyle),
                          ),
                        ),
                        SizedBox(
                            width:
                                10), // Add spacing between the start and end page number fields
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
                  // Display the language selection option
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text("Sprache:", style: quicksandTextStyleTitle),
                      SizedBox(
                          width:
                              30), // Spacing between the label and the button
                      ElevatedButton.icon(
                        onPressed: () async {
                          // Show the language selection dialog when the button is pressed
                          _showLanguageDialog(context);
                        },
                        // Customize button style
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
                        label: Text(
                            selectedLanguage ??
                                "...", // Display the selected language or a placeholder if no language is selected
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
                // Reset Button
                ElevatedButton(
                  onPressed: () async {
                    resetFilters();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(238, 159, 29, 29),
                    elevation: 15,
                    padding: EdgeInsets.all(12),
                    // Set overlay color when button is pressed
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
                // Button for submitting the selected filters
                ElevatedButton(
                  onPressed: () async {
                    // Create map dynamically to hold the filter values
                    final filters = <String, dynamic>{};

                    // Add each filter conditionally to the map if the value is not null
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

                    // Close the filter dialog and pass the filter map back to the previous screen
                    Navigator.pop(context, filters);
                  },
                  // Customize Submit Button
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 60, 221, 121)
                        .withOpacity(0.7),
                    elevation: 15,
                    padding: EdgeInsets.all(12),
                    // Set overlay color when button is pressed
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
