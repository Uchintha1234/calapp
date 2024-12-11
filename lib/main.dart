// Import necessary libraries
import 'package:flutter/material.dart'; // For designing the app's interface
import 'package:math_expressions/math_expressions.dart'; // For evaluating mathematical expressions

// The main function is the starting point of every Flutter app
void main() {
  runApp(
      const CalculatorApp()); // Runs the app and shows the CalculatorApp widget
}

// The main widget of the app
class CalculatorApp extends StatelessWidget {
  const CalculatorApp(
      {super.key}); // A constructor with a key for identifying this widget

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calculator App', // Sets the title of the app
      debugShowCheckedModeBanner: false, // Hides the "Debug" banner on the app
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.grey[850], // Sets the primary color of the theme
        scaffoldBackgroundColor: Colors.grey[900], // Sets the background color
      ),
      home: const CalculatorScreen(), // The main screen of the app
    );
  }
}

// The screen where the calculator interface is displayed
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState(); // Links the widget to its state
}

// The state class for managing user input and display
class _CalculatorScreenState extends State<CalculatorScreen> {
  String _displayText = ''; // The text shown on the calculator screen

  // Handles button presses
void _onButtonPressed(String buttonText, Function? action) {
  setState(() {
    if (action != null) {
      action(); // Executes the action for special buttons (e.g., "C")
    } else {
      // Prevent invalid input or special logic for the buttons
      if (['Undefined', "Can't divide by zero", 'Error'].contains(_displayText)) {
        if (RegExp(r'\d|-|\(|\)').hasMatch(buttonText)) {
          _displayText = buttonText; // Resets the display if it shows an error
        }
        return;
      }

      // Prevent consecutive operators
      if (RegExp(r'[+\-x/%]').hasMatch(buttonText) &&
          _displayText.isNotEmpty &&
          RegExp(r'[+\-x/%()]$').hasMatch(_displayText)) {
        return;
      }

      if (buttonText == '.') {
        List<String> parts = _displayText.split(RegExp(r'[+\-x/%()]'));
        if (parts.isNotEmpty && parts.last.contains('.')) return;

        if (_displayText.isEmpty ||
            RegExp(r'[+\-x/%()]$').hasMatch(_displayText)) {
          _displayText += '0'; // Adds a zero before the dot if needed
        }
      }

      if (buttonText == '%') {
        // Only allows percentage after a valid number
        if (_displayText.isNotEmpty &&
            RegExp(r'\d').hasMatch(_displayText[_displayText.length - 1])) {
          _displayText += '%';
        }
        return;
      }

      if (_displayText == '' && RegExp(r'[+\x/%]').hasMatch(buttonText)) {
        return;
      }

      if (_displayText.endsWith('.') &&
          RegExp(r'[+\-x/%]').hasMatch(buttonText)) return;

      if (_displayText.endsWith('.') && !RegExp(r'\d').hasMatch(buttonText)) {
        return;
      }

      if (_displayText == '0') {
        if (buttonText == '0') return;

        if (RegExp(r'[+\-x/%().]').hasMatch(buttonText)) {
          _displayText += buttonText; // Allows only valid operations after "0"
        } else {
          _displayText = buttonText; // Replaces "0" with a valid number
        }
      } else if (buttonText == '(') {
        // Handles logic for opening parentheses
        if (_displayText.isNotEmpty &&
            (RegExp(r'\d|\)')
                .hasMatch(_displayText[_displayText.length - 1]))) {
          _displayText += 'x('; // Adds a multiplication if needed
        } else {
          _displayText += '(';
        }
      } else if (buttonText == ')') {
        // Adds closing parentheses only if valid
        int openCount = _displayText.split('(').length - 1;
        int closeCount = _displayText.split(')').length - 1;

        if (openCount > closeCount) {
          _displayText += ')';
        }
      } else {
        // Adds the button text to the display
        _displayText += buttonText;
      }
    }
  });
}


  // Evaluates the entered expression
  String _evaluateExpression(String expression) {
    try {
      expression = expression.replaceAll(
          'x', '*'); // Replaces 'x' with '*' for multiplication
      expression = expression.replaceAllMapped(
        RegExp(r'(\d+)%'), // Handles percentages
        (match) => '(${match.group(1)}/100)',
      );
      expression = expression.replaceAllMapped(
        RegExp(r'(\d)(\()'), // Adds multiplication before opening parentheses
        (match) => '${match.group(1)}*(',
      );
      expression = expression.replaceAllMapped(
        RegExp(r'(\))(\d|\()'), // Adds multiplication after closing parentheses
        (match) => ')*${match.group(2)}',
      );

      if (expression.contains('/0')) {
        // Checks for division by zero
        return expression == '0/0' ? 'Undefined' : "Can't divide by zero";
      }

      Parser parser = Parser(); // Initializes the math parser
      Expression exp = parser.parse(expression); // Parses the expression
      ContextModel contextModel = ContextModel(); // Provides variable context
      double result = exp.evaluate(
          EvaluationType.REAL, contextModel); // Evaluates the expression

      return result
          .toString()
          .replaceAll(RegExp(r'\.0$'), ''); // Removes unnecessary ".0"
    } catch (e) {
      return 'Error'; // Shows "Error" for invalid expressions
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculator'), // Displays the title
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0), // Adds space around the screen
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.end, // Aligns content to the bottom
          crossAxisAlignment:
              CrossAxisAlignment.end, // Aligns text to the right
          children: [
            Text(
              _displayText, // Shows the entered text and result
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold),
              textAlign: TextAlign.end,
            ),
            const SizedBox(height: 20.0), // Adds spacing
            ..._buildButtonRows(), // Adds the calculator buttons
          ],
        ),
      ),
    );
  }

  // Creates rows of buttons for the calculator
  List<Widget> _buildButtonRows() {
    final List<List<Map<String, dynamic>>> buttonRows = [
      [
        {'label': 'C','color': Colors.grey,'fontColor': Colors.black,'action': () => _displayText = ''},
        {'label': '←','color': Colors.grey,'fontColor': Colors.black,'action': () {
            if (!['Undefined', "Can't divide by zero", 'Error']
                .contains(_displayText)) {
              if (_displayText.length > 1) {
                _displayText =
                    _displayText.substring(0, _displayText.length - 1);
              } else {
                _displayText = '';
              }
            } else {
              _displayText = ''; // Clears the error message if it's displayed
            }
          }
        },
        {'label': '%','color': Colors.grey,'fontColor': Colors.black,'action': null},
        {'label': '/','color': Colors.orange,'fontColor': Colors.white,'action': null},
      ],
      [
        {'label': '7','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '8','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '9','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': 'x','color': Colors.orange,'fontColor': Colors.white,'action': null},
      ],
      [
        {'label': '4','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '5','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '6','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '-','color': Colors.orange,'fontColor': Colors.white,'action': null},
      ],
      [
        {'label': '1','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '2','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '3','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '+','color': Colors.orange,'fontColor': Colors.white,'action': null},
      ],
      [
        {'label': '0','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '.','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': null},
        {'label': '()','color': const Color.fromARGB(255, 67, 65, 65),'fontColor': Colors.white,'action': () {
            if (_displayText.contains('(') && !_displayText.contains(')')) {
              _displayText += ')';
            } else {
              _displayText += '(';
            }
          }
        },
        {'label': '=','color': Colors.orange,'fontColor': Colors.white,'action': () => _displayText = _evaluateExpression(_displayText),},
      ],
    ];
// Map over each row of buttons to create a list of Columns
    return buttonRows.map((row) {
      return Column(
        children: [
          // For each row, create a Row widget to hold the buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,// Distribute buttons evenly across the row
            children: row.map((button) {
               // Map over each button in the row to create CalculatorButton widgets
              return CalculatorButton(
                text: button['label'], // The text displayed on the button
                onPressed: () =>
                    _onButtonPressed(button['label'], button['action']),// The callback executed when the button is pressed
                color: button['color'],// Background color of the button
                fontColor: button['fontColor'],// Font color of the button text
              );
            }).toList(),// Convert the mapped buttons into a list
          ),
          const SizedBox(height: 10.0),// Add some vertical spacing between rows
        ],
      );
    }).toList(); // Convert the mapped rows into a list
  }
}

// A reusable widget for a single calculator button
class CalculatorButton extends StatelessWidget {
  final String text; // The text shown on the button
  final VoidCallback onPressed; // The action performed when pressed
  final Color color; // The background color of the button
  final Color fontColor; // The text color

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.color,
    required this.fontColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80.0, // Width of the button
      height: 80.0, // Height of the button
      child: ElevatedButton(
        onPressed: onPressed, // The button's action
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(), // Makes the button circular
          backgroundColor: color, // Sets the button's color
          textStyle: const TextStyle(
              fontSize: 30, fontWeight: FontWeight.bold), // Sets the text style
        ),
        child: Text(
          text,
          style: TextStyle(color: fontColor), // Sets the text color
        ),
      ),
    );
  }
}
