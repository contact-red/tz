// The `Recurrence` union and the `NextFireError` sentinel shared by
// the three iterators (WeekdayIter, MonthlyIter, IntervalIter).
//
// Per resolutions/1 (2026-05-24), no provider parameter on the
// iterators — `_TzData` is the only data source.


type Recurrence is (WeekdayRecurrence | MonthlyRecurrence | IntervalRecurrence)


primitive NextFireError
  """
  Signal that an iterator can't produce its next fire. Possible causes
  include: unknown zone name, out-of-range arithmetic, iteration
  budget exhausted (corrupt tzdata, empty weekday set, recurring DST
  gap with strict policy), or an unsupported recurrence (e.g.
  calendar-mixed `IntervalRecurrence`).

  The iterator emits one of these exactly once, after which
  `has_next()` returns `false` and no further fires can be produced.
  """
