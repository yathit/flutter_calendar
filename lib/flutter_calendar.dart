import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_calendar/calendar_tile.dart';
import 'package:tuple/tuple.dart';
import 'package:ydn/date_utils.dart';

typedef DayBuilder(BuildContext context, DateTime day);

class Calendar extends StatefulWidget {
  final ValueChanged<DateTime> onDateSelected;
  final ValueChanged<Tuple2<DateTime, DateTime>> onSelectedRangeChange;
  final bool isExpandable;
  final bool isExpanded;
  final DayBuilder dayBuilder;
  final bool showChevronsToChangeRange;
  final bool showTodayAction;
  final bool showCalendarPickerIcon;

  Calendar({
    this.onDateSelected,
    this.onSelectedRangeChange,
    this.isExpandable: false,
    this.isExpanded: false,
    this.dayBuilder,
    this.showTodayAction: true,
    this.showChevronsToChangeRange: true,
    this.showCalendarPickerIcon: true,
  });

  @override
  _CalendarState createState() => new _CalendarState();
}

class _CalendarState extends State<Calendar> {
  DateTime today = new DateTime.now();
  List<DateTime> selectedMonthsDays;
  Iterable<DateTime> selectedWeeksDays;
  DateTime _selectedDate;
  Tuple2<DateTime, DateTime> selectedRange;
  String currentMonth;
  bool isExpanded;
  String displayMonth;

  DateTime get selectedDate => _selectedDate;

  void initState() {
    super.initState();
    isExpanded = widget.isExpanded == true;
    selectedMonthsDays = DateUtils.daysInMonth(today);
    var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(today);
    var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(today);
    selectedWeeksDays =
        DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
            .toList()
            .sublist(0, 7);
    _selectedDate = today;
    displayMonth = DateUtils.formatMonth(DateUtils.firstDayOfWeek(today));
  }

  Widget get nameAndIconRow {
    var leftInnerIcon;
    var rightInnerIcon;
    var leftOuterIcon;
    var rightOuterIcon;

    if (widget.showCalendarPickerIcon) {
      rightInnerIcon = new IconButton(
        onPressed: () => selectDateFromPicker(),
        icon: new Icon(Icons.calendar_today),
      );
    } else {
      rightInnerIcon = new Container();
    }

    if (widget.showChevronsToChangeRange) {
      leftOuterIcon = new IconButton(
        onPressed: isExpanded ? previousMonth : previousWeek,
        icon: new Icon(Icons.chevron_left),
      );
      rightOuterIcon = new IconButton(
        onPressed: isExpanded ? nextMonth : nextWeek,
        icon: new Icon(Icons.chevron_right),
      );
    } else {
      leftOuterIcon = new Container();
      rightOuterIcon = new Container();
    }

    if (widget.showTodayAction) {
      leftInnerIcon = new IconButton(
        icon: Icon(Icons.today),
        onPressed: resetToToday,
      );
    } else {
      leftInnerIcon = new Container();
    }

    return new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        leftOuterIcon ?? new Container(),
        leftInnerIcon ?? new Container(),
        Expanded(
          child: new Text(
            displayMonth,
            style: new TextStyle(
              fontSize: 20.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.clip,
            textAlign: TextAlign.center,
          ),
        ),
        rightInnerIcon ?? new Container(),
        rightOuterIcon ?? new Container(),
      ],
    );
  }

  Widget get calendarGridView {
    return new Container(
      child: new GestureDetector(
        onHorizontalDragStart: (gestureDetails) => beginSwipe(gestureDetails),
        onHorizontalDragUpdate: (gestureDetails) =>
            getDirection(gestureDetails),
        onHorizontalDragEnd: (gestureDetails) => endSwipe(gestureDetails),
        child: new GridView.count(
          shrinkWrap: true,
          crossAxisCount: 7,
          padding: new EdgeInsets.only(bottom: 0.0),
          children: calendarBuilder(),
        ),
      ),
    );
  }

  List<Widget> calendarBuilder() {
    List<Widget> dayWidgets = [];
    List<DateTime> calendarDays =
        isExpanded ? selectedMonthsDays : selectedWeeksDays;

    DateUtils.weekdays.forEach(
      (day) {
        dayWidgets.add(
          new CalendarTile(
            isDayOfWeek: true,
            dayOfWeek: day,
          ),
        );
      },
    );

    bool monthStarted = false;
    bool monthEnded = false;

    calendarDays.forEach(
      (day) {
        if (monthStarted && day.day == 01) {
          monthEnded = true;
        }

        if (DateUtils.isFirstDayOfMonth(day)) {
          monthStarted = true;
        }

        final tile = new CalendarTile(
          onDateSelected: () => handleSelectedDateAndUserCallback(day),
          date: day,
          dateStyles: configureDateStyle(monthStarted, monthEnded),
          isSelected: DateUtils.isSameDay(selectedDate, day),
        );

        if (this.widget.dayBuilder != null) {
          dayWidgets.add(
            new Stack(
              children: <Widget>[
                widget.dayBuilder(context, day),
                tile,
              ],
            ),
          );
        } else {
          dayWidgets.add(new Container(
            decoration: new BoxDecoration(
              color: Colors.white,
            ),
            child: tile,
          ));
        }
      },
    );
    return dayWidgets;
  }

  TextStyle configureDateStyle(monthStarted, monthEnded) {
    TextStyle dateStyles;
    if (isExpanded) {
      dateStyles = monthStarted && !monthEnded
          ? new TextStyle(color: Colors.black)
          : new TextStyle(color: Colors.black38);
    } else {
      dateStyles = new TextStyle(color: Colors.black);
    }
    return dateStyles;
  }

  Widget get expansionButtonRow {
    if (widget.isExpandable) {
      return new Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          new Text(DateUtils.fullDayFormat(selectedDate)),
          new IconButton(
            iconSize: 20.0,
            padding: new EdgeInsets.all(0.0),
            onPressed: toggleExpanded,
            icon: isExpanded
                ? new Icon(Icons.arrow_drop_up)
                : new Icon(Icons.arrow_drop_down),
          ),
        ],
      );
    } else {
      return new Container();
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          nameAndIconRow,
          new ExpansionCrossFade(
            collapsed: calendarGridView,
            expanded: calendarGridView,
            isExpanded: isExpanded,
          ),
          expansionButtonRow
        ],
      ),
    );
  }

  void resetToToday() {
    today = new DateTime.now();
    var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(today);
    var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(today);

    setState(() {
      _selectedDate = today;
      selectedWeeksDays =
          DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList();
      displayMonth = DateUtils.formatMonth(DateUtils.firstDayOfWeek(today));
    });
    _updateSelectedRange();
    if (widget.onDateSelected != null) widget.onDateSelected(_selectedDate);
  }

  void nextMonth() {
    setState(() {
      today = DateUtils.nextMonth(today);
      var firstDateOfNewMonth = DateUtils.firstDayOfMonth(today);
      var lastDateOfNewMonth = DateUtils.lastDayOfMonth(today);
      updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
      selectedMonthsDays = DateUtils.daysInMonth(today);
      displayMonth = DateUtils.formatMonth(today);
    });
  }

  void previousMonth() {
    setState(() {
      today = DateUtils.previousMonth(today);
      var firstDateOfNewMonth = DateUtils.firstDayOfMonth(today);
      var lastDateOfNewMonth = DateUtils.lastDayOfMonth(today);
      updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
      selectedMonthsDays = DateUtils.daysInMonth(today);
      displayMonth = DateUtils.formatMonth(today);
    });
  }

  void nextWeek() {
    setState(() {
      today = DateUtils.nextWeek(today);
      var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(today);
      var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(today);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeeksDays =
          DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList()
              .sublist(0, 7);
      displayMonth = DateUtils.formatMonth(DateUtils.firstDayOfWeek(today));
    });
  }

  void previousWeek() {
    setState(() {
      today = DateUtils.previousWeek(today);
      var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(today);
      var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(today);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
      selectedWeeksDays =
          DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList()
              .sublist(0, 7);
      displayMonth = DateUtils.formatMonth(DateUtils.firstDayOfWeek(today));
    });
  }

  void updateSelectedRange(DateTime start, DateTime end) {
    selectedRange = new Tuple2<DateTime, DateTime>(start, end);
    if (widget.onSelectedRangeChange != null) {
      widget.onSelectedRangeChange(selectedRange);
    }
  }

  Future<Null> selectDateFromPicker() async {
    DateTime selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? new DateTime.now(),
      firstDate: new DateTime(1960),
      lastDate: new DateTime(2050),
    );

    if (selected != null) {
      var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(selected);
      var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(selected);

      setState(() {
        _selectedDate = selected;
        selectedWeeksDays =
            DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
                .toList();
        displayMonth =
            DateUtils.formatMonth(DateUtils.firstDayOfWeek(selected));
        _updateSelectedRange();
      });
      if (widget.onDateSelected != null) {
        widget.onDateSelected(_selectedDate);
      }
    }
  }

  var gestureStart;
  var gestureDirection;
  void beginSwipe(DragStartDetails gestureDetails) {
    gestureStart = gestureDetails.globalPosition.dx;
  }

  void getDirection(DragUpdateDetails gestureDetails) {
    if (gestureDetails.globalPosition.dx < gestureStart) {
      gestureDirection = 'rightToLeft';
    } else {
      gestureDirection = 'leftToRight';
    }
  }

  void endSwipe(DragEndDetails gestureDetails) {
    if (gestureDirection == 'rightToLeft') {
      if (isExpanded) {
        nextMonth();
      } else {
        nextWeek();
      }
    } else {
      if (isExpanded) {
        previousMonth();
      } else {
        previousWeek();
      }
    }
  }

  void _updateSelectedRange() {
    if (isExpanded) {
      var firstDateOfNewMonth = DateUtils.firstDayOfMonth(today);
      var lastDateOfNewMonth = DateUtils.lastDayOfMonth(today);
      updateSelectedRange(firstDateOfNewMonth, lastDateOfNewMonth);
    } else {
      var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(today);
      var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(today);
      updateSelectedRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek);
    }
  }

  void toggleExpanded() {
    if (widget.isExpandable) {
      setState(() => isExpanded = !isExpanded);
      _updateSelectedRange();
    }
  }

  void handleSelectedDateAndUserCallback(DateTime day) {
    var firstDayOfCurrentWeek = DateUtils.firstDayOfWeek(day);
    var lastDayOfCurrentWeek = DateUtils.lastDayOfWeek(day);
    setState(() {
      _selectedDate = day;
      selectedWeeksDays =
          DateUtils.daysInRange(firstDayOfCurrentWeek, lastDayOfCurrentWeek)
              .toList();
    });
    if (widget.onDateSelected != null) {
      widget.onDateSelected(day);
    }
  }
}

class ExpansionCrossFade extends StatelessWidget {
  final Widget collapsed;
  final Widget expanded;
  final bool isExpanded;

  ExpansionCrossFade({this.collapsed, this.expanded, this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return new Flexible(
      flex: 1,
      child: new AnimatedCrossFade(
        firstChild: collapsed,
        secondChild: expanded,
        firstCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        secondCurve: const Interval(0.0, 1.0, curve: Curves.fastOutSlowIn),
        sizeCurve: Curves.decelerate,
        crossFadeState:
            isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
      ),
    );
  }
}
