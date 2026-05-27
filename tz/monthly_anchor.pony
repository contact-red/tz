// MonthlyAnchor: billing-intent type that resolves R4. The closed union
// of DayOfMonth (Nth of every month), LastDayOfMonth (end of every
// month), and LastWeekdayOfMonth (e.g. "last Friday of every month").

class val DayOfMonth
  """
  "The Nth of every month" — clamped to month length if N exceeds it,
  but the preferred N is remembered. Distinguishable at the type level
  from LastDayOfMonth.
  """
  let _preferred: U8

  new val create(d: U8) ? =>
    if (d < 1) or (d > 31) then error end
    _preferred = d

  fun val preferred(): U8 => _preferred


primitive LastDayOfMonth
  """
  "End of every month" — Jan 31, Feb 28/29, Mar 31, ... Always the
  actual last day, varying with month length and leap years.
  """


class val LastWeekdayOfMonth
  """
  "The last Friday of every month", etc.
  """
  let _weekday: DayOfWeek

  new val create(w: DayOfWeek) =>
    _weekday = w

  fun val weekday(): DayOfWeek => _weekday


type MonthlyAnchor is (DayOfMonth | LastDayOfMonth | LastWeekdayOfMonth)
