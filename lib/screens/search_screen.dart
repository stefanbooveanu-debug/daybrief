import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event.dart';

class SearchScreen extends StatefulWidget {
  final List<Event> events;
  final Function(Event) onEventTap;

  const SearchScreen({
    super.key,
    required this.events,
    required this.onEventTap,
  });

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Event> _filteredEvents = [];
  String _selectedFilter = 'All';
  bool _showResults = false;

  final List<String> _filters = ['All', 'Today', 'This Week', 'This Month', 'Upcoming'];

  @override
  void initState() {
    super.initState();
    _filteredEvents = widget.events;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterEvents();
  }

  void _filterEvents() {
    final query = _searchController.text.toLowerCase();
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);

    setState(() {
      _filteredEvents = widget.events.where((event) {
        final matchesQuery = query.isEmpty || 
            event.title.toLowerCase().contains(query) ||
            (event.description?.toLowerCase().contains(query) ?? false);
        
        bool matchesFilter = true;
        switch (_selectedFilter) {
          case 'Today':
            matchesFilter = _isSameDay(event.dateTime, now);
            break;
          case 'This Week':
            matchesFilter = event.dateTime.isAfter(startOfWeek) && event.dateTime.isBefore(endOfWeek);
            break;
          case 'This Month':
            matchesFilter = event.dateTime.isAfter(startOfMonth) && event.dateTime.isBefore(endOfMonth.add(const Duration(days: 1)));
            break;
          case 'Upcoming':
            matchesFilter = event.dateTime.isAfter(now);
            break;
        }
        
        return matchesQuery && matchesFilter;
      }).toList();
      
      _showResults = _searchController.text.isNotEmpty || _selectedFilter != 'All';
    });
  }

  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : const Color(0xFF5F6368)),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF202124)),
          decoration: InputDecoration(
            hintText: 'Search events...',
            hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400]),
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _showResults = false);
                    },
                  )
                : null,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              itemBuilder: (context, index) {
                final filter = _filters[index];
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() => _selectedFilter = selected ? filter : 'All');
                      _filterEvents();
                    },
                    backgroundColor: isDark ? const Color(0xFF2D2D2D) : Colors.white,
                    selectedColor: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                    labelStyle: TextStyle(
                      color: isSelected 
                          ? (isDark ? Colors.black : Colors.white)
                          : (isDark ? Colors.white70 : const Color(0xFF5F6368)),
                    ),
                    checkmarkColor: isDark ? Colors.black : Colors.white,
                  ),
                );
              },
            ),
          ),
          if (_showResults || _filteredEvents.isNotEmpty)
            Expanded(
              child: _filteredEvents.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text('No events found', style: TextStyle(fontSize: 18, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                        ],
                      ),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredEvents.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              '${_filteredEvents.length} result${_filteredEvents.length > 1 ? 's' : ''} found',
                              style: TextStyle(fontSize: 14, color: isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          );
                        }
                        final event = _filteredEvents[index - 1];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                widget.onEventTap(event);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48, height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF1A73E8).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.event, color: Color(0xFF1A73E8)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF202124))),
                                          const SizedBox(height: 4),
                                          Text(DateFormat('EEE, MMM d • h:mm a').format(event.dateTime),
                                            style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                                        ],
                                      ),
                                    ),
                                    Icon(Icons.chevron_right, color: isDark ? Colors.grey[600] : Colors.grey[400]),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            )
          else
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search, size: 80, color: isDark ? Colors.grey[700] : Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('Search for events', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.grey[400] : Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Type to search or use filters', style: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[500])),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
