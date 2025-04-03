import 'package:flutter/material.dart';
import 'package:kalakritiapp/utils/theme.dart';
import 'package:kalakritiapp/widgets/custom_button.dart';
import 'package:table_calendar/table_calendar.dart';

class RentalDatePicker extends StatefulWidget {
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;
  final Function(DateTime? startDate, DateTime? endDate) onConfirm;

  const RentalDatePicker({
    super.key,
    this.initialStartDate,
    this.initialEndDate,
    required this.onConfirm,
  });

  @override
  State<RentalDatePicker> createState() => _RentalDatePickerState();
}

class _RentalDatePickerState extends State<RentalDatePicker> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    
    if (_startDate != null) {
      _focusedDay = _startDate!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const Expanded(
                child: Text(
                  'Select Rental Dates',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: _startDate != null && _endDate != null
                    ? () {
                        widget.onConfirm(_startDate, _endDate);
                        Navigator.of(context).pop();
                      }
                    : null,
                color: _startDate != null && _endDate != null
                    ? kSecondaryColor
                    : Colors.grey,
              ),
            ],
          ),
          
          const Divider(),
          
          // Selected dates display
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _startDate != null
                            ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                            : 'Select start date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _startDate != null ? kTextColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'To',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _endDate != null
                            ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                            : 'Select end date',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _endDate != null ? kTextColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Duration: ${_endDate!.difference(_startDate!).inDays + 1} days',
                style: TextStyle(
                  color: kSecondaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          
          const Divider(),
          
          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) {
              // Check if the day is selected
              if (_startDate != null && _endDate != null) {
                return day.isAtSameMomentAs(_startDate!) || 
                       day.isAtSameMomentAs(_endDate!) || 
                       (day.isAfter(_startDate!) && day.isBefore(_endDate!));
              }
              if (_startDate != null) {
                return day.isAtSameMomentAs(_startDate!);
              }
              return false;
            },
            rangeStartDay: _startDate,
            rangeEndDay: _endDate,
            calendarFormat: _calendarFormat,
            rangeSelectionMode: RangeSelectionMode.enforced,
            onDaySelected: (selectedDay, focusedDay) {
              if (_startDate == null || _endDate != null) {
                setState(() {
                  _startDate = selectedDay;
                  _endDate = null;
                  _focusedDay = focusedDay;
                });
              } else if (selectedDay.isAfter(_startDate!)) {
                setState(() {
                  _endDate = selectedDay;
                });
              } else {
                // Selected day is before start date, update start date
                setState(() {
                  _startDate = selectedDay;
                });
              }
            },
            onRangeSelected: (start, end, focusedDay) {
              setState(() {
                _startDate = start;
                _endDate = end;
                _focusedDay = focusedDay;
              });
            },
            onFormatChanged: (format) {
              if (_calendarFormat != format) {
                setState(() {
                  _calendarFormat = format;
                });
              }
            },
            onPageChanged: (focusedDay) {
              _focusedDay = focusedDay;
            },
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              rangeHighlightColor: kSecondaryColor.withOpacity(0.2),
              todayDecoration: BoxDecoration(
                color: kSlateGray.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
              rangeStartDecoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
              rangeEndDecoration: const BoxDecoration(
                color: kSecondaryColor,
                shape: BoxShape.circle,
              ),
              withinRangeTextStyle: const TextStyle(
                color: Colors.black,
              ),
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: kPrimaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              formatButtonTextStyle: TextStyle(
                color: kPrimaryColor,
              ),
              titleTextStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Confirm button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CustomButton(
              text: 'Confirm Rental Dates',
              onPressed: _startDate != null && _endDate != null
                  ? () {
                      widget.onConfirm(_startDate, _endDate);
                      Navigator.of(context).pop();
                    }
                  : null,
              backgroundColor: _startDate != null && _endDate != null
                  ? kAccentColor
                  : Colors.grey,
              textColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 