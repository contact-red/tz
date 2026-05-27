// Cron — primitive with free functions that compute "next fire after T".
// Plus the `Recurrence` union and the `NextFireError` vocabulary the
// iterators and Cron share.
//
// Per resolutions/1 (2026-05-24), no provider parameter on Cron —
// `_TzData` is the only data source.


type Recurrence is (WeekdayRecurrence | MonthlyRecurrence | IntervalRecurrence)


// Cron: free-function namespace that computes next-fire instants.
// No provider parameter — _TzData is the single source.

primitive Cron
  """
  Compute "next fire" instants from Recurrence rules. Zone lookups
  go through `_TzData`; no provider parameter.

  Each one-shot wrapper returns `(ZonedDateTime iso^ | NextFireError)`
  — the success path yields a fresh ZDT; the error path yields the
  reason no next fire could be computed. Call `.to_posix()` on the
  ZDT branch when you need a POSIX `(sec, nsec)` tuple for e.g.
  `time.Timer.abs(...)`.
  """

  fun next(r: Recurrence, after: ZonedDateTime box)
    : (ZonedDateTime iso^ | NextFireError)
  =>
    """
    Find the next fire instant strictly after `after`. Dispatches on
    the Recurrence variant. For multi-fire iteration, call
    `r.iter_after(after)` directly and pull from the resulting
    iterator.
    """
    match r
    | let w: WeekdayRecurrence => w.iter_after(after).next()
    | let m: MonthlyRecurrence => m.iter_after(after).next()
    | let i: IntervalRecurrence => i.iter_after(after).next()
    end


primitive NextFireBudgetExhausted
  """
  Cron searched for too many iterations without finding a valid next
  fire (corrupt tzdata, empty weekday set, recurring DST gap with
  strict policy, etc.).
  """

primitive NextFireOutOfRange
  """Computed next-fire instant is outside the supported date range."""

primitive NextFireZoneNotFound
  """The recurrence's zone name isn't in the bundled tzdata."""

type NextFireError is
  (NextFireBudgetExhausted | NextFireOutOfRange | NextFireZoneNotFound)
