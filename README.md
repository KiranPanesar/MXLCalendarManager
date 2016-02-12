MXLCalendarManager
==================

A set of classes to parse and handle iCalendar (.ICS) files. The framework can parse through an iCalendar file and extract all VEVENT objects into MXLCalendarEvent items. Then, by running the [checkDate:](https://github.com/KiranPanesar/MXLCalendarManager/blob/master/MXLCalendarManager/MXLCalendarEvent.h#L99) or [checkDay:month:year](https://github.com/KiranPanesar/MXLCalendarManager/blob/master/MXLCalendarManager/MXLCalendarEvent.h#L98) you can see if the event occurs on a certain day.

Installation
---
The recommended installation is via CocoaPods.

```
pod 'MXLCalendarManager'
```

Any questions or comments? Feel free to [email me](mailto:kiransinghpanesar@googlemail.com) or send me a [tweet](http://www.twitter.com/k_panesar).
