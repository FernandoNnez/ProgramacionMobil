import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class Calendar extends StatefulWidget {
  final String titulo;

  const Calendar({super.key, required this.titulo});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime _selectedDate = DateTime.now();
  List<Meeting> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEventsForSelectedDate(); //obtiene data
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titulo)),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SfCalendar(
              view: CalendarView.month,
              onSelectionChanged: (CalendarSelectionDetails details) {
                setState(() {
                  _selectedDate = details.date ?? DateTime.now();
                  _loadEventsForSelectedDate(); //refr
                });
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => _addEventDialog(),
            child: const Text("Agregar Evento"),
          ),
          const Divider(),
          Expanded(
            flex: 1,
            child: _events.isEmpty
                ? const Center(child: Text("No hay eventos para esta fecha"))
                : ListView.builder(
              itemCount: _events.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_events[index].eventName),
                  subtitle: Text(
                    "${_events[index].from} - ${_events[index].to}",
                  ),
                  leading: Icon(Icons.event,
                      color: Color(_events[index].color)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteEvent(_events[index].id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadEventsForSelectedDate() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("data")
        .doc("Calendar")
        .get();

    if (!doc.exists) {
      setState(() {
        _events = [];
      });
      return;
    }

    final List<dynamic> eventsData = doc.data()?["events"] ?? [];
    final selectedStart = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final selectedEnd = selectedStart.add(const Duration(days: 1));

    final filtered = eventsData.where((e) {
      final start = (e["start"] as Timestamp).toDate();
      return start.isAfter(selectedStart.subtract(const Duration(seconds: 1))) &&
          start.isBefore(selectedEnd);
    }).map((e) => Meeting(
      id: e["id"],
      eventName: e["eventName"],
      from: (e["start"] as Timestamp).toDate(),
      to: (e["end"] as Timestamp).toDate(),
      allDay: e["allDay"],
      color: e["color"],
    )).toList();

    setState(() {
      _events = filtered;
    });
  }

  Future<void> _addEvent(String name, DateTime start, DateTime end, bool allDay, int color) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("data")
        .doc("Calendar");

    final doc = await docRef.get();
    final List<dynamic> existingEvents = doc.data()?["events"] ?? [];

    final newEvent = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "eventName": name,
      "start": Timestamp.fromDate(start),
      "end": Timestamp.fromDate(end),
      "allDay": allDay,
      "color": color,
    };

    existingEvents.add(newEvent);

    await docRef.set({
      "events": existingEvents,
    }, SetOptions(merge: true));

    _loadEventsForSelectedDate(); // refresca daaah
  }


  Future<void> _deleteEvent(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("data")
        .doc("Calendar");

    final doc = await docRef.get();
    if (!doc.exists) return;

    final List<dynamic> existingEvents = doc.data()?["events"] ?? [];
    existingEvents.removeWhere((e) => e["id"] == eventId);

    await docRef.set({"events": existingEvents}, SetOptions(merge: true));
    _loadEventsForSelectedDate();// otro refrs
  }



  void _addEventDialog() {
    TextEditingController eventController = TextEditingController();
    DateTime startTime = _selectedDate;
    DateTime endTime = _selectedDate.add(const Duration(hours: 1));
    bool allDay = false;
    int selectedColor = Colors.blue.value;
    Color pickerColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> _selectDateTime(bool isStart) async {
              final DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: isStart ? startTime : endTime,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (pickedDate == null) return;

              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                    isStart ? startTime : endTime),
              );
              if (pickedTime == null) return;

              final combined = DateTime(
                pickedDate.year,
                pickedDate.month,
                pickedDate.day,
                pickedTime.hour,
                pickedTime.minute,
              );

              setState(() {
                if (isStart) {
                  startTime = combined;
                  if (endTime.isBefore(startTime)) {
                    endTime = startTime.add(const Duration(hours: 1));
                  }
                } else {
                  endTime = combined;
                }
              });
            }

            void _openColorPicker() {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Elige un color'),
                    content: SingleChildScrollView(
                      child: ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (color) {
                          setState(() {
                            pickerColor = color;
                          });
                        },
                        showLabel: true,
                        pickerAreaHeightPercent: 0.8,
                      ),
                    ),
                    actions: [
                      TextButton(
                        child: const Text('Cancelar'),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton(
                        child: const Text('Seleccionar'),
                        onPressed: () {
                          setState(() {
                            selectedColor = pickerColor.value;
                          });
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            }

            return AlertDialog(
              title: const Text("Agregar Evento"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: eventController,
                      decoration: const InputDecoration(
                          labelText: "Nombre del evento"),
                    ),
                    CheckboxListTile(
                      title: const Text("Todo el día"),
                      value: allDay,
                      onChanged: (value) {
                        setState(() {
                          allDay = value!;
                        });
                      },
                    ),
                    Row(
                      children: [
                        const Text("Inicio: "),
                        TextButton(
                          onPressed: () => _selectDateTime(true),
                          child: Text("${startTime.toLocal()}".split('.')[0]),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Text("Fin: "),
                        TextButton(
                          onPressed: () => _selectDateTime(false),
                          child: Text("${endTime.toLocal()}".split('.')[0]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Color del evento: "),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _openColorPicker,
                          child: CircleAvatar(
                            backgroundColor: Color(selectedColor),
                            radius: 15,
                            child: const Icon(
                                Icons.edit, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (eventController.text.isNotEmpty) {
                      _addEvent(
                          eventController.text, startTime, endTime, allDay,
                          selectedColor);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class Meeting {
  String id;
  String eventName;
  DateTime from;
  DateTime to;
  bool allDay;
  int color;

  Meeting({
    required this.id,
    required this.eventName,
    required this.from,
    required this.to,
    required this.allDay,
    required this.color,
  });
}
