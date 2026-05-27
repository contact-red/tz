// Demonstrates the three recurrence iterators in the `tz` package:
// WeekdayIter, MonthlyIter, and IntervalIter.
//
// Build and run from the repo root:
//
//     make build-examples
//     ./build/debug/iterators
//
// All three iterators conform to Pony's standard `Iterator[A]` interface
// with `A = (ZonedDateTime iso^ | NextFireError)` — the error is part
// of the value type, not a side channel. They compose with `for result
// in iter do ... end`:
//
//   1. Construct a `*Recurrence` value describing the rule (which days,
//      what time, what zone, what period, ...).
//   2. Call `rec.iter_after(after_zdt)` (where `after_zdt` is a
//      `ZonedDateTime box`) to get a mutable iterator that yields fires
//      strictly after that instant.
//   3. Iterate with a `for` loop; match each result to handle the ZDT
//      and error cases inline.
//   4. The iterator emits any `NextFireError` exactly once, then
//      `has_next()` returns `false` — the `for` loop terminates
//      naturally on the next check.
//
// Note: the recurrence layer currently only resolves the zone name
// "UTC" — full IANA-zone resolution for WeekdayRecurrence and
// MonthlyRecurrence is a follow-up. IntervalRecurrence with a pure
// intraday `Period` (months == 0 && days == 0) already works against
// any zone for validation purposes.

use "../../tz"

actor Main
  new create(env: Env) =>
    let now_zdt = ZonedDateTime.now()
    let now = now_zdt.to_posix()
    env.out.print("Now (POSIX): " + now._1.string() + "s " +
      now._2.string() + "ns")
    env.out.print("Now (UTC):   " + now_zdt.string())
    env.out.print("")

    _demo_weekday(env, now_zdt)
    env.out.print("")
    _demo_monthly(env, now_zdt)
    env.out.print("")
    _demo_interval(env, now_zdt)

  fun _demo_weekday(env: Env, after: ZonedDateTime box) =>
    """
    Project the next five "Mon/Wed/Fri at 09:00 UTC" fires.
    """
    env.out.print("== WeekdayIter: every Mon/Wed/Fri @ 09:00 UTC ==")
    let tod =
      try
        TimeOfDay(9, 0, 0)?
      else
        env.err.print("unreachable: 09:00:00 is a valid TimeOfDay")
        return
      end
    let rec = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday; Wednesday; Friday] end,
      tod,
      "UTC")
    _print_n(env, rec.iter_after(after), 5)

  fun _demo_monthly(env: Env, after: ZonedDateTime box) =>
    """
    Three monthly rules off the same start instant:
      * "the 15th of every month"   (DayOfMonth)
      * "the last day of every month"   (LastDayOfMonth)
      * "the last Friday of every month"   (LastWeekdayOfMonth)
    """
    env.out.print("== MonthlyIter: three anchor types ==")

    let mid_month =
      try
        MonthlyRecurrence(DayOfMonth(15)?, TimeOfDay.midnight(), "UTC")
      else
        env.err.print("unreachable: 15 is a valid DayOfMonth")
        return
      end
    env.out.print("- 15th of the month @ 00:00 UTC")
    _print_n(env, mid_month.iter_after(after), 3)

    let eom = MonthlyRecurrence(LastDayOfMonth, TimeOfDay.midnight(), "UTC")
    env.out.print("- last day of the month @ 00:00 UTC")
    _print_n(env, eom.iter_after(after), 3)

    let last_friday = MonthlyRecurrence(
      LastWeekdayOfMonth(Friday), TimeOfDay.midnight(), "UTC")
    env.out.print("- last Friday of the month @ 00:00 UTC")
    _print_n(env, last_friday.iter_after(after), 3)

  fun _demo_interval(env: Env, after: ZonedDateTime box) =>
    """
    Project the next five "every 90 minutes" fires.

    IntervalRecurrence currently requires a pure-intraday Period
    (no months or days). A calendar-mixed Period sticks immediately
    on `NextFireBudgetExhausted` — we demonstrate that error path
    afterward so the sticky-error shape is visible.
    """
    env.out.print("== IntervalIter: every 90 minutes ==")
    let rec = IntervalRecurrence(
      Period.of_minutes(90), "UTC", OverflowClamp)
    _print_n(env, rec.iter_after(after), 5)

    env.out.print("")
    env.out.print("== IntervalIter: every 1 month (currently unsupported) ==")
    let cal = IntervalRecurrence(
      Period.of_months(1), "UTC", OverflowClamp)
    _print_n(env, cal.iter_after(after), 3)

  fun _print_n(env: Env, iter: (WeekdayIter | MonthlyIter | IntervalIter),
    n: USize)
  =>
    """
    Pull up to `n` fires from `iter` and print them.

    `next()` yields `(ZonedDateTime iso^ | NextFireError)` — the error
    is part of the value type, matched inline alongside the success
    case. No `try`/`else`, no `error_state()` accessor: each call
    carries everything we need. The iterator is unbounded so we
    `break` once we've printed `n` items.
    """
    var i: USize = 0
    for result in iter do
      if (i >= n) then break end
      match consume result
      | let zdt: ZonedDateTime iso =>
        env.out.print("  " + (i + 1).string() + ". " + zdt.string())
        i = i + 1
      | NextFireBudgetExhausted =>
        env.out.print("  stopped: budget exhausted")
      | NextFireOutOfRange =>
        env.out.print("  stopped: out of representable date range")
      | NextFireZoneNotFound =>
        env.out.print("  stopped: zone not found")
      end
    end
