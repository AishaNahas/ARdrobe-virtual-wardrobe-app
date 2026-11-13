import 'package:flutter/material.dart';
import 'wardrobe_item.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String type;
  final List<WardrobeItem> items;
  final DateTime date;

  CalendarEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.items,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'type': type,
      'items': items.map((item) => item.toMap()).toList(),
      'date': date.toIso8601String(),
    };
  }

  factory CalendarEvent.fromMap(Map<String, dynamic> map) {
    return CalendarEvent(
      id: map['id'] as String,
      title: map['title'] as String,
      type: map['type'] as String,
      items: (map['items'] as List)
          .map((item) => WardrobeItem.fromMap(item))
          .toList(),
      date: DateTime.parse(map['date'] as String),
    );
  }
}
