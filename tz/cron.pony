// Cron — primitive with free functions that compute "next fire after T".
// Plus the NextFireError vocabulary the iterators and Cron share.
//
// Per resolutions/1 (2026-05-24), no provider parameter on Cron —
// `_TzData` is the only data source.

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
    the Recurrence variant.
    """
    match r
    | let w: WeekdayRecurrence => next_weekday(w, after)
    | let m: MonthlyRecurrence => next_monthly(m, after)
    | let i: IntervalRecurrence => next_interval(i, after)
    end

  fun next_weekday(r: WeekdayRecurrence, after: ZonedDateTime box)
    : (ZonedDateTime iso^ | NextFireError)
  =>
    """
    One-shot wrapper that pulls the first fire from the iterator. For
    multi-fire iteration use `r.iter_after(after)` directly.
    """
    r.iter_after(after).next()

  fun next_monthly(r: MonthlyRecurrence, after: ZonedDateTime box)
    : (ZonedDateTime iso^ | NextFireError)
  =>
    """
    One-shot wrapper that pulls the first fire from the iterator. For
    multi-fire iteration (e.g., projecting 12 months of billing dates)
    use `r.iter_after(after)` directly — the iterator preserves cursor
    state across `next()` calls.
    """
    r.iter_after(after).next()

  fun next_interval(r: IntervalRecurrence, after: ZonedDateTime box)
    : (ZonedDateTime iso^ | NextFireError)
  =>
    """
    One-shot wrapper that pulls the first fire from the iterator. For
    multi-fire iteration use `r.iter_after(after)` directly.
    """
    r.iter_after(after).next()

  // ----- internal helpers -----

  fun _resolve_anchor(anchor: MonthlyAnchor, year: I16, month: U8): Date val ? =>
    """
    Compute the actual calendar date for a MonthlyAnchor in the given
    year/month. Clamps DayOfMonth to month length; walks backward from
    end-of-month for LastWeekdayOfMonth.
    """
    match anchor
    | let dom: DayOfMonth =>
      let max_day = _Gregorian.days_in_month(year, month)
      let day = if dom.preferred() > max_day then max_day else dom.preferred() end
      Date(year, month, day)?
    | LastDayOfMonth =>
      Date(year, month, _Gregorian.days_in_month(year, month))?
    | let lwd: LastWeekdayOfMonth =>
      let target = lwd.weekday()
      var day: U8 = _Gregorian.days_in_month(year, month)
      while day >= 1 do
        let d = Date(year, month, day)?
        if d.day_of_week() is target then return d end
        day = day - 1
      end
      // Unreachable: every month has at least one of each weekday.
      error
    end

  fun _is_weekday_in_set(d: DayOfWeek, set: Array[DayOfWeek] val): Bool =>
    for entry in set.values() do
      if d is entry then return true end
    end
    false

  fun _local_to_utc_in_zone(
    date: Date val, tod: TimeOfDay val, zone_name: String val)
    : ((I64, I64) | NextFireError)
  =>
    """
    Convert local fields in `zone_name` to a UTC POSIX tuple.
    Currently only "UTC" is supported (no tzdata); other zone names
    return NextFireZoneNotFound. Real IANA zones land here once the
    codegen story is built out.
    """
    if zone_name == "UTC" then
      let days = date.days_since_epoch().i64()
      let sec = (days * 86400) +
        (((tod.hour().i64() * 3600) + (tod.minute().i64() * 60)) + tod.second().i64())
      (sec, tod.nano().i64())
    else
      NextFireZoneNotFound
    end

  fun _posix_gt(a: (I64, I64), b: (I64, I64)): Bool =>
    if a._1 > b._1 then true
    elseif a._1 < b._1 then false
    else a._2 > b._2 end


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
