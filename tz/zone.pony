"""
# tz

## I M P O R T A N T 

_Timezone is NOT the same as an offset. A regional Timezone doesn't always
map to a canonical Timezone_

If you want historical data (pre-1970), compile with -D HISTORICAL_TZ

Since "Illegal States must not be representable", there is no "DateTime"
class (which canonically in almost every language represents a Date/Time
in UTC).  We have only ZonedDateTime which defaults to UTC.

## High Level (Separate Date / Times)

* [Date class](https://tz.contact.red/tz-Date/) for date math, leap year
  checks, day of week, etc…
* [Time class](https://tz.contact.red/tz-TimeOfDay/) for time math within
  a single day.

## High Level (Dates / Times / TimeZones)

* [ZonedDateTime class](https://tz.contact.red/tz-ZonedDateTime/) contains
  a POSIX (sec, nanosec) UTC timestamp and associated TimeZone / Offset.
    * Constructors for .now(), and .from_posix(), and timezone'd versions
      such as .from_posix_in_zone(), .now_at_offset() etc…
    * Ability to "cast" time between timezones (`to_timezone` /
      `to_timezone_in_place`) — same UTC instant, re-resolved local
      fields for the new zone.
    * Comparisons across zones are DST-safe because every ZDT carries
      a UTC POSIX instant; compare via `to_posix()` and the local
      DST quirks of either side don't enter the comparison.

* Parsers and Formatters for various date ISO/RFC formats:
  * [rfc2822/rfc5322](https://tz.contact.red/tz-Rfc2822/)
    Example:
      * Sun, 25 May 2026 12:00:00 -0700
  * [rfc3339 / iso8601](https://tz.contact.red/tz-Rfc3339/)
    Examples:
      * 1985-04-12T23:20:50.52Z
      * 1996-12-19T16:39:57-08:00
      * 1990-12-31T23:59:59Z
      * 1937-01-01T12:00:27.87+00:20

## High Level (Calendaring Functions):

* [WeekdayIter](https://tz.contact.red/tz-WeekdayIter/) "Every weekday
  in Array[DayOfWeek] at the same time in the same Zone".
* [MonthlyIter](https://tz.contact.red/tz-MonthlyIter/) "Every (DayOfMonth | LastDayOfMonth | LastWeekdayOfMonth) of the month".
* [IntervalIter](https://tz.contact.red/tz-IntervalIter/) "Every N
  minutes / hours" — pure-intraday Periods today; calendar-mixed
  Periods (months / days) are planned.

... and much much more.


"""


// Tag primitives. No instance data; discriminate the ZonedDateTime kind.

primitive Zone
  """
  Tag: this ZonedDateTime is in an IANA-named zone (DST rules apply,
  abbreviation comes from tzdata).
  """

primitive Offset
  """
  Tag: this ZonedDateTime is at a fixed numeric offset, no zone
  identity, no DST.
  """

type ZonedKind is (Zone | Offset)
