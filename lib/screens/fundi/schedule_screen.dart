import 'package:flutter/material.dart';

class FundiScheduleScreen extends StatefulWidget {
  const FundiScheduleScreen({super.key});

  @override
  State<FundiScheduleScreen> createState() => _FundiScheduleScreenState();
}

class _FundiScheduleScreenState extends State<FundiScheduleScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static final List<_ScheduleItem> _schedule = [
    _ScheduleItem(title: 'Plumbing Repair', client: 'John M.', time: '9:00 AM', duration: '2 hrs', location: 'Nairobi CBD'),
    _ScheduleItem(title: 'Electrical Fix', client: 'Sarah W.', time: '2:00 PM', duration: '1.5 hrs', location: 'Westlands'),
  ];

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: Column(
        children: [
          _buildCalendarHeader(color, now),
          _buildWeekRow(color, now),
          const Divider(height: 1),
          Expanded(
            child: _schedule.isEmpty
                ? const Center(child: Text('No jobs scheduled today.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _schedule.length,
                    itemBuilder: (context, i) => _ScheduleCard(item: _schedule[i], color: color),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarHeader(Color color, DateTime now) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_monthName(_focusedDay.month)} ${_focusedDay.year}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1))),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeekRow(Color color, DateTime now) {
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    return SizedBox(
      height: 72,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, i) {
          final day = startOfWeek.add(Duration(days: i));
          final isToday = day.day == now.day && day.month == now.month;
          final isSelected = _selectedDay?.day == day.day;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day),
            child: Container(
              width: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : (isToday ? color.withValues(alpha: 0.1) : Colors.transparent),
                borderRadius: BorderRadius.circular(12),
                border: isToday && !isSelected ? Border.all(color: color) : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_dayName(day.weekday), style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.grey[600])),
                  const SizedBox(height: 4),
                  Text('${day.day}', style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : null)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _monthName(int m) => ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m];
  String _dayName(int d) => ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d];
}

class _ScheduleCard extends StatelessWidget {
  final _ScheduleItem item;
  final Color color;
  const _ScheduleCard({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(width: 4, height: 60, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Client: ${item.client}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('${item.time} • ${item.duration}', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(item.location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleItem {
  final String title, client, time, duration, location;
  const _ScheduleItem({required this.title, required this.client, required this.time, required this.duration, required this.location});
}
