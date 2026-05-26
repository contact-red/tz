// Calendar primitives: Date, TimeOfDay, Period, plus the policy types
// for calendar arithmetic.
//
// These types know nothing about zones — they're zone-naive wall-clock
// components. Pairing them with a Zone happens via Zone.resolve_local or
// similar.


class val Date
  """
  A proleptic Gregorian calendar date: year, month, day.

  Year range:
  - Default: 1970..=9999 (matches default tzdata coverage).
  - With `-D HISTORICAL_TZ`: 1..=9999 (matches widened tzdata coverage
    back through pre-1900 LMT-era zones).

  Calendar math (leap years, day-of-week, days-in-month, day-of-year,
  arithmetic) uses the proleptic Gregorian rule for all years in range,
  even those preceding regional Gregorian adoption (1582 onward).
  """
  let _year: I16
  let _month: U8
  let _day: U8

  new val create(year': I16, month': U8, day': U8) ? =>
    """
    Construct a date. Errors if year is outside the supported range, or
    if (month, day) is not a real calendar date (e.g. Feb 30, Apr 31,
    Feb 29 of a non-leap year).
    """
    if (year' < _DateLimits.min_year()) or (year' > _DateLimits.max_year()) then
      error
    end
    if (month' < 1) or (month' > 12) then error end
    if day' < 1 then error end
    if day' > _Gregorian.days_in_month(year', month') then error end
    _year = year'
    _month = month'
    _day = day'

  new val epoch() =>
    """
    1970-01-01 — non-partial because the epoch date is always valid in
    every supported configuration. Used for stubs and as a safe default.
    """
    _year = 1970
    _month = 1
    _day = 1

  // Accessors

  fun val year(): I16 => _year
  fun val month(): U8 => _month
  fun val day(): U8 => _day

  // Calendar facts

  fun val is_leap_year(): Bool =>
    """True if this date's year is leap under the proleptic Gregorian rule."""
    _Gregorian.is_leap_year(_year)

  fun val days_in_month(): U8 =>
    """Number of days in this date's month (28..=31), accounting for leap year."""
    _Gregorian.days_in_month(_year, _month)

  fun val day_of_week(): DayOfWeek =>
    """Day-of-week via Zeller's congruence (proleptic Gregorian)."""
    _Gregorian.day_of_week(_year, _month, _day)

  fun val day_of_year(): U16 =>
    """Ordinal day within the year: 1 for Jan 1, up to 365 or 366."""
    var total: U16 = _day.u16()
    var m: U8 = 1
    while m < _month do
      total = total + _Gregorian.days_in_month(_year, m).u16()
      m = m + 1
    end
    total

  fun val days_since_epoch(): I32 =>
    """Days from 1970-01-01. Negative for pre-epoch dates."""
    _Gregorian.days_from_civil(_year, _month, _day)

  // Comparison

  fun val compare(other: Date val): Compare =>
    if _year < other._year then Less
    elseif _year > other._year then Greater
    elseif _month < other._month then Less
    elseif _month > other._month then Greater
    elseif _day < other._day then Less
    elseif _day > other._day then Greater
    else Equal
    end

  fun val eq(other: Date val): Bool =>
    (_year == other._year) and (_month == other._month) and (_day == other._day)

  fun val ne(other: Date val): Bool => not eq(other)

  fun val lt(other: Date val): Bool =>
    match compare(other) | Less => true else false end

  fun val le(other: Date val): Bool =>
    match compare(other) | Greater => false else true end

  fun val gt(other: Date val): Bool =>
    match compare(other) | Greater => true else false end

  fun val ge(other: Date val): Bool =>
    match compare(other) | Less => false else true end

  // Arithmetic

  fun val add_days(n: I32): (Date val | ArithmeticError) =>
    """
    Return a new Date `n` days after this one (negative for past).
    Errors if the result is outside the supported year range.
    """
    let target = days_since_epoch() + n
    (let y, let m, let d) = _Gregorian.civil_from_days(target)
    try Date(y, m, d)? else ArithmeticOutOfRange end

  fun val add_months(n: I32, policy: OverflowPolicy): (Date val | ArithmeticError) =>
    """
    Return a new Date `n` months after this one (negative for past).
    On month-shift overflow (e.g. Jan 31 + 1 month), `policy` decides
    between clamping (Feb 28/29) and rejecting (ArithmeticPolicyReject).
    """
    // total_months counts from year 0, month 1 (index 0). Pony / and %
    // truncate toward zero, so we compensate for negative results.
    let total: I32 = (_year.i32() * 12) + (_month.i32() - 1) + n
    let m_index: I32 = ((total % 12) + 12) % 12  // [0, 11]
    let y_new: I32 = (total - m_index) / 12
    let m_new: U8 = (m_index + 1).u8()
    let max_day = _Gregorian.days_in_month(y_new.i16(), m_new)
    let d_new: U8 =
      if _day > max_day then
        match policy
        | OverflowClamp => max_day
        | OverflowReject => return ArithmeticPolicyReject
        end
      else
        _day
      end
    try Date(y_new.i16(), m_new, d_new)? else ArithmeticOutOfRange end

  fun val add_period(p: Period val, policy: OverflowPolicy): (Date val | ArithmeticError) =>
    """
    Apply months and days from `p`. The `nanos` component is ignored
    because Date has no time-of-day to apply it to (pair with TimeOfDay
    or use ZonedDateTime for sub-day arithmetic).
    """
    match add_months(p.months(), policy)
    | let after_months: Date val =>
      after_months.add_days(p.days())
    | let e: ArithmeticError => e
    end

  // Formatting

  fun val string(): String iso^ =>
    """ISO 8601 date format: YYYY-MM-DD. Negative years prefixed with '-'."""
    let y_part = (if _year < 0 then -_year.i32() else _year.i32() end).string()
    let m_part = _month.string()
    let d_part = _day.string()
    recover iso
      let s = String(11)
      if _year < 0 then s.push('-') end
      var pad = (4 - y_part.size().i32()).max(0).usize()
      while pad > 0 do s.push('0'); pad = pad - 1 end
      s.append(consume y_part)
      s.push('-')
      if m_part.size() < 2 then s.push('0') end
      s.append(consume m_part)
      s.push('-')
      if d_part.size() < 2 then s.push('0') end
      s.append(consume d_part)
      s
    end


class val TimeOfDay
  """
  An hour:minute:second.nanosecond within a day, with no date and no zone.
  Range: 00:00:00.000_000_000 .. 23:59:59.999_999_999.
  No leap-second representation (POSIX model).
  """
  let _hour: U8
  let _minute: U8
  let _second: U8
  let _nano: I32

  new val create(hour': U8, minute': U8, second': U8, nano': I32 = 0) ? =>
    """
    Construct from hour/minute/second/nanosecond. Errors if any field is
    out of range.
    """
    if (hour' > 23) or (minute' > 59) or (second' > 59)
       or (nano' < 0) or (nano' > 999_999_999)
    then error end
    _hour = hour'
    _minute = minute'
    _second = second'
    _nano = nano'

  new val midnight() =>
    """
    00:00:00.000_000_000 — non-partial because midnight is always valid.
    Used for stubs and as a safe default.
    """
    _hour = 0
    _minute = 0
    _second = 0
    _nano = 0

  new val noon() =>
    """12:00:00.000_000_000 — non-partial; always valid."""
    _hour = 12
    _minute = 0
    _second = 0
    _nano = 0

  new val from_total_nanos(n: I64) ? =>
    """
    Construct from nanoseconds since midnight (0 .. 86_399_999_999_999).
    Errors if `n` is out of range. Inverse of `total_nanos()`.
    """
    if (n < 0) or (n >= 86_400_000_000_000) then error end
    _nano = (n % 1_000_000_000).i32()
    let total_sec = n / 1_000_000_000             // [0, 86399]
    _second = (total_sec % 60).u8()
    let total_min = total_sec / 60                // [0, 1439]
    _minute = (total_min % 60).u8()
    _hour = (total_min / 60).u8()                 // [0, 23]

  // Accessors

  fun val hour(): U8 => _hour
  fun val minute(): U8 => _minute
  fun val second(): U8 => _second
  fun val nano(): I32 => _nano

  fun val total_nanos(): I64 =>
    """Nanoseconds since midnight: 0 .. 86_399_999_999_999."""
    ((((_hour.i64() * 3_600_000_000_000)
      + (_minute.i64() * 60_000_000_000))
      + (_second.i64() * 1_000_000_000))
      + _nano.i64())

  // Comparison

  fun val compare(other: TimeOfDay val): Compare =>
    if _hour < other._hour then Less
    elseif _hour > other._hour then Greater
    elseif _minute < other._minute then Less
    elseif _minute > other._minute then Greater
    elseif _second < other._second then Less
    elseif _second > other._second then Greater
    elseif _nano < other._nano then Less
    elseif _nano > other._nano then Greater
    else Equal
    end

  fun val eq(other: TimeOfDay val): Bool =>
    (_hour == other._hour) and (_minute == other._minute)
      and (_second == other._second) and (_nano == other._nano)

  fun val ne(other: TimeOfDay val): Bool => not eq(other)

  fun val lt(other: TimeOfDay val): Bool =>
    match compare(other) | Less => true else false end

  fun val le(other: TimeOfDay val): Bool =>
    match compare(other) | Greater => false else true end

  fun val gt(other: TimeOfDay val): Bool =>
    match compare(other) | Greater => true else false end

  fun val ge(other: TimeOfDay val): Bool =>
    match compare(other) | Less => false else true end

  // Arithmetic

  fun val add_nanos(n: I64): (TimeOfDay val, I32) =>
    """
    Return (new TimeOfDay, days-overflow). Adds `n` nanoseconds, wrapping
    within the day; overflow days are reported so the caller can apply
    them to a Date or ZonedDateTime.

    `n` may be negative, in which case days-overflow can be negative.
    Example: 23:00 + 2h yields (01:00, +1); 01:00 + (-2h) yields (23:00, -1).
    """
    let day_nanos: I64 = 86_400_000_000_000
    let total_new = total_nanos() + n
    // Floor-mod to get wrapped in [0, day_nanos), and floor-div for overflow.
    // Pony `%` is rem (matches dividend sign); we compensate.
    let wrapped = ((total_new % day_nanos) + day_nanos) % day_nanos
    let day_overflow = ((total_new - wrapped) / day_nanos).i32()
    let tod =
      try
        from_total_nanos(wrapped)?
      else
        // Unreachable: wrapped is in [0, day_nanos) by construction.
        midnight()
      end
    (tod, day_overflow)

  // Formatting

  fun val string(): String iso^ =>
    """
    ISO 8601 time format. Emits "HH:MM:SS" when nanoseconds are zero,
    or "HH:MM:SS.nnnnnnnnn" (zero-padded to 9 digits) otherwise.
    """
    let h_part = _hour.string()
    let m_part = _minute.string()
    let s_part = _second.string()
    recover iso
      let buf = String(20)
      if h_part.size() < 2 then buf.push('0') end
      buf.append(consume h_part)
      buf.push(':')
      if m_part.size() < 2 then buf.push('0') end
      buf.append(consume m_part)
      buf.push(':')
      if s_part.size() < 2 then buf.push('0') end
      buf.append(consume s_part)
      if _nano > 0 then
        buf.push('.')
        let frac = _nano.string()
        var pad: USize = (9 - frac.size().i32()).max(0).usize()
        while pad > 0 do buf.push('0'); pad = pad - 1 end
        buf.append(consume frac)
      end
      buf
    end


class val Period
  """
  A calendar interval: months + days + nanoseconds.

  Per T7, Period carries intraday units (nanoseconds) so a single type
  covers "every 1 month" and "every 90 minutes" alike. Application to a
  date or zoned date-time goes through an OverflowPolicy.

  Two Periods are equal when all three components match. Periods do NOT
  support compare/lt/gt — "1 month vs 30 days" has no answer without a
  date to apply both against, so semantic ordering is intentionally
  absent. Apply both to a date and compare the results if you need it.
  """
  let _months: I32
  let _days: I32
  let _nanos: I64

  new val create(months': I32 = 0, days': I32 = 0, nanos': I64 = 0) =>
    _months = months'
    _days = days'
    _nanos = nanos'

  new val zero() =>
    """The zero period: every component is zero."""
    _months = 0
    _days = 0
    _nanos = 0

  new val of_months(m: I32) =>
    _months = m
    _days = 0
    _nanos = 0

  new val of_days(d: I32) =>
    _months = 0
    _days = d
    _nanos = 0

  new val of_hours(h: I64) =>
    _months = 0
    _days = 0
    _nanos = h * 3_600_000_000_000

  new val of_minutes(m: I64) =>
    _months = 0
    _days = 0
    _nanos = m * 60_000_000_000

  new val of_seconds(s: I64) =>
    _months = 0
    _days = 0
    _nanos = s * 1_000_000_000

  new val of_nanos(n: I64) =>
    _months = 0
    _days = 0
    _nanos = n

  // Accessors

  fun val months(): I32 => _months
  fun val days(): I32 => _days
  fun val nanos(): I64 => _nanos

  // Predicates

  fun val is_zero(): Bool =>
    """True if every component is zero."""
    (_months == 0) and (_days == 0) and (_nanos == 0)

  // Equality (component-wise; no ordering — see class docstring).

  fun val eq(other: Period val): Bool =>
    (_months == other._months) and (_days == other._days) and (_nanos == other._nanos)

  fun val ne(other: Period val): Bool => not eq(other)

  // Arithmetic (component-wise, wrapping on overflow).

  fun val neg(): Period val =>
    """Return -this: every component negated."""
    Period(-_months, -_days, -_nanos)

  fun val add(other: Period val): Period val =>
    """Component-wise addition. Overflow wraps (Pony default `+`)."""
    Period(
      _months + other._months,
      _days + other._days,
      _nanos + other._nanos)

  fun val sub(other: Period val): Period val =>
    """Component-wise subtraction."""
    Period(
      _months - other._months,
      _days - other._days,
      _nanos - other._nanos)

  fun val mul(n: I32): Period val =>
    """Multiply every component by scalar `n`. Overflow wraps."""
    Period(_months * n, _days * n, _nanos * n.i64())

  // Formatting

  fun val string(): String iso^ =>
    """
    Debug-style representation: "Period(months=N, days=N, nanos=N)".
    Not ISO 8601 Duration format — that's a TODO; the negative-with-
    fractional-seconds case is fiddly enough to want its own design pass.
    """
    let m_str = _months.string()
    let d_str = _days.string()
    let n_str = _nanos.string()
    recover iso
      let buf = String(64)
      buf.append("Period(months=")
      buf.append(consume m_str)
      buf.append(", days=")
      buf.append(consume d_str)
      buf.append(", nanos=")
      buf.append(consume n_str)
      buf.push(')')
      buf
    end


primitive OverflowReject
  """
  Period arithmetic that overflows the target (e.g. Jan 31 + 1 month)
  is an error.
  """

primitive OverflowClamp
  """
  Period arithmetic that overflows clamps to the nearest representable
  result (Jan 31 + 1 month → Feb 28/29).
  """

type OverflowPolicy is (OverflowReject | OverflowClamp)


primitive Sunday
primitive Monday
primitive Tuesday
primitive Wednesday
primitive Thursday
primitive Friday
primitive Saturday

type DayOfWeek is
  (Sunday | Monday | Tuesday | Wednesday | Thursday | Friday | Saturday)


primitive ArithmeticOutOfRange
  """Result of calendar arithmetic falls outside the supported year range."""

primitive ArithmeticPolicyReject
  """
  OverflowReject policy refused to clamp (e.g. Jan 31 + 1 month with
  OverflowReject).
  """

type ArithmeticError is (ArithmeticOutOfRange | ArithmeticPolicyReject)


// Internal calendar math, factored out so Date methods stay thin.
// All math is proleptic Gregorian; same rule for every supported year.

primitive _Gregorian
  fun is_leap_year(y: I16): Bool =>
    """Standard Gregorian rule: divisible by 4, except by 100, except by 400."""
    let y32 = y.i32()
    ((y32 % 4) == 0) and (((y32 % 100) != 0) or ((y32 % 400) == 0))

  fun days_in_month(y: I16, m: U8): U8 =>
    """Days in month `m` of year `y` (28..=31)."""
    match m
    | 4 | 6 | 9 | 11 => 30
    | 2 => if is_leap_year(y) then 29 else 28 end
    else 31
    end

  fun day_of_week(y: I16, m: U8, d: U8): DayOfWeek =>
    """Zeller's congruence for the Gregorian calendar."""
    var year_z = y.i32()
    var month_z = m.i32()
    let day_z = d.i32()
    if month_z < 3 then
      month_z = month_z + 12
      year_z = year_z - 1
    end
    let k = year_z % 100
    let j = year_z / 100
    let h_raw =
      (((((day_z + ((13 * (month_z + 1)) / 5)) + k) + (k / 4)) + (j / 4)) - (2 * j))
    let h = ((h_raw % 7) + 7) % 7   // Normalize to [0, 6].
    match h
    | 0 => Saturday
    | 1 => Sunday
    | 2 => Monday
    | 3 => Tuesday
    | 4 => Wednesday
    | 5 => Thursday
    | 6 => Friday
    else Saturday  // Unreachable: h is in [0, 6].
    end

  fun days_from_civil(y: I16, m: U8, d: U8): I32 =>
    """
    Howard Hinnant's proleptic Gregorian algorithm. Returns days since
    1970-01-01 (negative for pre-epoch dates).
    See: http://howardhinnant.github.io/date_algorithms.html
    """
    var y2 = y.i32()
    let m2 = m.i32()
    if m2 <= 2 then y2 = y2 - 1 end
    let era: I32 = if y2 >= 0 then y2 / 400 else (y2 - 399) / 400 end
    let yoe = y2 - (era * 400)
    let doy = ((((153 * (m2 + (if m2 > 2 then -3 else 9 end))) + 2) / 5) + d.i32()) - 1
    let doe = (((yoe * 365) + (yoe / 4)) - (yoe / 100)) + doy
    ((era * 146097) + doe) - 719468

  fun civil_from_days(z: I32): (I16, U8, U8) =>
    """
    Inverse of days_from_civil. Returns (year, month, day) for the
    given days-since-epoch count.
    """
    let z2 = z + 719468
    let era: I32 = if z2 >= 0 then z2 / 146097 else (z2 - 146096) / 146097 end
    let doe = z2 - (era * 146097)
    let yoe = ((((doe - (doe / 1460)) + (doe / 36524)) - (doe / 146096)) / 365)
    var y = yoe + (era * 400)
    let doy = doe - (((365 * yoe) + (yoe / 4)) - (yoe / 100))
    let mp = ((5 * doy) + 2) / 153
    let d = (((doy - (((153 * mp) + 2) / 5)) + 1)).u8()
    let m = (mp + (if mp < 10 then 3 else -9 end)).u8()
    if m <= 2 then y = y + 1 end
    (y.i16(), m, d)


// Year-range limits, switchable at compile time via HISTORICAL_TZ.
// The Date constructor enforces these; arithmetic operations error
// with ArithmeticOutOfRange when results fall outside.

primitive _DateLimits
  fun min_year(): I16 =>
    ifdef "HISTORICAL_TZ" then 1
    else 1970
    end

  fun max_year(): I16 => 9999
