// Recurrence — the typed rule values for "fire every X" scheduling.
// MonthlyAnchor — the billing-intent sum union (DayOfMonth /
// LastDayOfMonth / LastWeekdayOfMonth).
// Cron — primitive with free functions that compute "next fire after T".
//
// Per resolutions/1 (2026-05-24), no provider parameter on Cron — `_TzData`
// is the only data source.
//
// Per T6, Recurrence is a typed value wrapping the underlying free
// functions. Per T7, Period (with intraday units) handles fine-grained
// recurrences.


// MonthlyAnchor: billing-intent type that resolves R4.

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


// Recurrence: typed rule values, as a closed union.

class val WeekdayRecurrence
  """
  "Every weekday-in-set at TimeOfDay, in this IANA zone."
  """
  let _weekdays: Array[DayOfWeek] val
  let _at: TimeOfDay val
  let _zone_name: String val

  new val create(
    weekdays': Array[DayOfWeek] val,
    at': TimeOfDay val,
    zone_name': String val)
  =>
    _weekdays = weekdays'
    _at = at'
    _zone_name = zone_name'

  fun val weekdays(): Array[DayOfWeek] val => _weekdays
  fun val at(): TimeOfDay val => _at
  fun val zone_name(): String val => _zone_name

  fun val iter_after(after_posix: (I64, I64)): WeekdayIter =>
    """
    Build an iterator that yields successive fire instants strictly
    after `after_posix`. Each call to `next_fire()` advances at least
    one day; consecutive calls within the same week may advance only
    one day (across weekdays in the set) or skip several (across
    excluded weekend days).
    """
    WeekdayIter(this, after_posix)


class ref WeekdayIter
  """
  Iterator over the fire instants of a `WeekdayRecurrence`. Same
  state-machine and sticky-error model as `MonthlyIter`.
  """
  let _weekdays: Array[DayOfWeek] val
  let _target_tod: TimeOfDay val
  let _zone_name: String val
  var _state: _WeekdayIterState

  new ref create(r: WeekdayRecurrence, after_posix: (I64, I64)) =>
    _weekdays = r.weekdays()
    _target_tod = r.at()
    _zone_name = r.zone_name()
    _state = _WeekdayIterStart(after_posix)

  fun ref next_fire(): ((I64, I64) | NextFireError) =>
    match _state
    | let s: _WeekdayIterStart => _begin(s.after_posix())
    | let c: _WeekdayIterCursor => _advance(c.cursor_date(), c.lower())
    | let stuck: _WeekdayIterStuck => stuck.err()
    end

  fun ref _begin(after_posix: (I64, I64)): ((I64, I64) | NextFireError) =>
    if _weekdays.size() == 0 then
      _state = _WeekdayIterStuck(NextFireBudgetExhausted)
      return NextFireBudgetExhausted
    end
    let zdt =
      try
        ZonedDateTime.from_posix_in_zone(after_posix, _zone_name)?
      else
        _state = _WeekdayIterStuck(NextFireZoneNotFound)
        return NextFireZoneNotFound
      end
    _advance(zdt.local_date(), after_posix)

  fun ref _advance(start_date: Date val, lower: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    var cur = start_date
    var i: USize = 0
    while i < 8 do
      if Cron._is_weekday_in_set(cur.day_of_week(), _weekdays) then
        match Cron._local_to_utc_in_zone(cur, _target_tod, _zone_name)
        | (let s: I64, let n: I64) =>
          let fire = (s, n)
          if Cron._posix_gt(fire, lower) then
            let next_cur =
              match cur.add_days(1)
              | let d: Date val => d
              | let _: ArithmeticError =>
                _state = _WeekdayIterStuck(NextFireOutOfRange)
                return fire   // emit this, stick on next call
              end
            _state = _WeekdayIterCursor(next_cur, fire)
            return fire
          end
        | let e: NextFireError =>
          _state = _WeekdayIterStuck(e)
          return e
        end
      end
      match cur.add_days(1)
      | let d: Date val => cur = d
      | let _: ArithmeticError =>
        _state = _WeekdayIterStuck(NextFireOutOfRange)
        return NextFireOutOfRange
      end
      i = i + 1
    end
    _state = _WeekdayIterStuck(NextFireBudgetExhausted)
    NextFireBudgetExhausted


class val _WeekdayIterStart
  let _after_posix: (I64, I64)
  new val create(p: (I64, I64)) => _after_posix = p
  fun val after_posix(): (I64, I64) => _after_posix

class val _WeekdayIterCursor
  let _cursor_date: Date val
  let _lower: (I64, I64)
  new val create(d: Date val, l: (I64, I64)) =>
    _cursor_date = d
    _lower = l
  fun val cursor_date(): Date val => _cursor_date
  fun val lower(): (I64, I64) => _lower

class val _WeekdayIterStuck
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

type _WeekdayIterState is
  (_WeekdayIterStart | _WeekdayIterCursor | _WeekdayIterStuck)


class val MonthlyRecurrence
  """
  "On MonthlyAnchor of every month, at TimeOfDay, in this IANA zone."
  """
  let _anchor: MonthlyAnchor
  let _at: TimeOfDay val
  let _zone_name: String val

  new val create(anchor': MonthlyAnchor, at': TimeOfDay val, zone_name': String val) =>
    _anchor = anchor'
    _at = at'
    _zone_name = zone_name'

  fun val anchor(): MonthlyAnchor => _anchor
  fun val at(): TimeOfDay val => _at
  fun val zone_name(): String val => _zone_name

  fun val iter_after(after_posix: (I64, I64)): MonthlyIter =>
    """
    Build an iterator that yields successive fire instants strictly
    after `after_posix`. Each call to `next_fire()` advances by one
    month. Preserves the preferred-day behavior of `DayOfMonth(N)`
    across clamping months (Jan 31 → Feb 28 → Mar 31 → Apr 30 → ...).
    """
    MonthlyIter(this, after_posix)


class ref MonthlyIter
  """
  Iterator over the fire instants of a `MonthlyRecurrence`. Each
  call to `next_fire()` returns the next instant strictly after the
  previous one — or, on the first call, strictly after the
  `after_posix` passed at construction.

  Sticky error model: once any call returns a `NextFireError`, every
  subsequent call returns the same error. This lets a consumer loop
  on `next_fire()` without re-checking conditions, knowing that
  forward progress has stopped.
  """
  let _anchor: MonthlyAnchor
  let _target_tod: TimeOfDay val
  let _zone_name: String val
  var _state: _MonthlyIterState

  new ref create(r: MonthlyRecurrence, after_posix: (I64, I64)) =>
    _anchor = r.anchor()
    _target_tod = r.at()
    _zone_name = r.zone_name()
    _state = _MonthlyIterStart(after_posix)

  fun ref next_fire(): ((I64, I64) | NextFireError) =>
    match _state
    | let s: _MonthlyIterStart => _begin(s.after_posix())
    | let c: _MonthlyIterCursor => _advance(c.cursor(), c.lower())
    | let stuck: _MonthlyIterStuck => stuck.err()
    end

  fun ref _begin(after_posix: (I64, I64)): ((I64, I64) | NextFireError) =>
    let zdt =
      try
        ZonedDateTime.from_posix_in_zone(after_posix, _zone_name)?
      else
        _state = _MonthlyIterStuck(NextFireZoneNotFound)
        return NextFireZoneNotFound
      end
    _advance(zdt.local_date(), after_posix)

  fun ref _advance(start_cursor: Date val, lower: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    """
    Search forward from `start_cursor` for a fire instant strictly
    after `lower`. Bounded at 13 iterations per call (covers a full
    year plus the current-month case). On success, updates `_state`
    to a cursor that's one month past the fire; on any structural
    failure, transitions to `_MonthlyIterStuck`.
    """
    var cur = start_cursor
    var i: USize = 0
    while i < 13 do
      let candidate_date =
        try Cron._resolve_anchor(_anchor, cur.year(), cur.month())?
        else
          _state = _MonthlyIterStuck(NextFireOutOfRange)
          return NextFireOutOfRange
        end
      match Cron._local_to_utc_in_zone(candidate_date, _target_tod, _zone_name)
      | (let s: I64, let n: I64) =>
        let fire = (s, n)
        if Cron._posix_gt(fire, lower) then
          // Advance cursor one month past so the next call starts
          // resolving the following month.
          let next_cur =
            match cur.add_months(1, OverflowClamp)
            | let d: Date val => d
            | let _: ArithmeticError =>
              _state = _MonthlyIterStuck(NextFireOutOfRange)
              return fire   // emit this fire, then stick on the next call
            end
          _state = _MonthlyIterCursor(next_cur, fire)
          return fire
        end
      | let e: NextFireError =>
        _state = _MonthlyIterStuck(e)
        return e
      end
      // This month's anchor was at or before `lower`; try the next month.
      match cur.add_months(1, OverflowClamp)
      | let d: Date val => cur = d
      | let _: ArithmeticError =>
        _state = _MonthlyIterStuck(NextFireOutOfRange)
        return NextFireOutOfRange
      end
      i = i + 1
    end
    _state = _MonthlyIterStuck(NextFireBudgetExhausted)
    NextFireBudgetExhausted


class val _MonthlyIterStart
  let _after_posix: (I64, I64)
  new val create(p: (I64, I64)) => _after_posix = p
  fun val after_posix(): (I64, I64) => _after_posix

class val _MonthlyIterCursor
  let _cursor: Date val
  let _lower: (I64, I64)
  new val create(c: Date val, l: (I64, I64)) =>
    _cursor = c
    _lower = l
  fun val cursor(): Date val => _cursor
  fun val lower(): (I64, I64) => _lower

class val _MonthlyIterStuck
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

type _MonthlyIterState is
  (_MonthlyIterStart | _MonthlyIterCursor | _MonthlyIterStuck)


class val IntervalRecurrence
  """
  "Every Period after the start instant, in this IANA zone."
  Period carries intraday units (T7), so "every 90 minutes" works.
  """
  let _every: Period val
  let _zone_name: String val
  let _policy: OverflowPolicy

  new val create(every': Period val, zone_name': String val, policy': OverflowPolicy) =>
    _every = every'
    _zone_name = zone_name'
    _policy = policy'

  fun val every(): Period val => _every
  fun val zone_name(): String val => _zone_name
  fun val policy(): OverflowPolicy => _policy

  fun val iter_after(after_posix: (I64, I64)): IntervalIter =>
    """
    Build an iterator that yields successive fire instants. Each call
    advances by `every()`. Pure-intraday Periods (months == 0 &&
    days == 0) work today; calendar-mixed Periods produce a sticky
    `NextFireBudgetExhausted` until local-time arithmetic lands.
    """
    IntervalIter(this, after_posix)


class ref IntervalIter
  """
  Iterator over the fire instants of an `IntervalRecurrence`. Same
  state-machine and sticky-error model as the other iterators.
  """
  let _period: Period val
  let _zone_name: String val
  var _state: _IntervalIterState

  new ref create(r: IntervalRecurrence, after_posix: (I64, I64)) =>
    _period = r.every()
    _zone_name = r.zone_name()
    _state = _IntervalIterStart(after_posix)

  fun ref next_fire(): ((I64, I64) | NextFireError) =>
    match _state
    | let s: _IntervalIterStart => _begin(s.after_posix())
    | let c: _IntervalIterCursor => _step(c.last_fire())
    | let stuck: _IntervalIterStuck => stuck.err()
    end

  fun ref _begin(after_posix: (I64, I64)): ((I64, I64) | NextFireError) =>
    // Validate zone (even though pure-intraday math doesn't actually
    // use it — consistency with the other iterators).
    try
      ZonedDateTime.from_posix_in_zone(after_posix, _zone_name)?
    else
      _state = _IntervalIterStuck(NextFireZoneNotFound)
      return NextFireZoneNotFound
    end
    if (_period.months() != 0) or (_period.days() != 0) then
      // TODO: calendar-mixed intervals need local-time arithmetic.
      _state = _IntervalIterStuck(NextFireBudgetExhausted)
      return NextFireBudgetExhausted
    end
    if _period.nanos() <= 0 then
      _state = _IntervalIterStuck(NextFireBudgetExhausted)
      return NextFireBudgetExhausted
    end
    _step(after_posix)

  fun ref _step(from: (I64, I64)): ((I64, I64) | NextFireError) =>
    """
    Add `_period.nanos()` to `from`. Validation in `_begin` already
    confirmed the period is pure-intraday and positive.
    """
    let total_nanos = _period.nanos()
    let new_sec_raw = from._1 + (total_nanos / 1_000_000_000)
    let new_nsec_raw = from._2 + (total_nanos % 1_000_000_000)
    let carry = new_nsec_raw / 1_000_000_000
    let new_sec = new_sec_raw + carry
    let new_nsec = new_nsec_raw % 1_000_000_000
    let fire = (new_sec, new_nsec)
    _state = _IntervalIterCursor(fire)
    fire


class val _IntervalIterStart
  let _after_posix: (I64, I64)
  new val create(p: (I64, I64)) => _after_posix = p
  fun val after_posix(): (I64, I64) => _after_posix

class val _IntervalIterCursor
  let _last_fire: (I64, I64)
  new val create(p: (I64, I64)) => _last_fire = p
  fun val last_fire(): (I64, I64) => _last_fire

class val _IntervalIterStuck
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

type _IntervalIterState is
  (_IntervalIterStart | _IntervalIterCursor | _IntervalIterStuck)


type Recurrence is (WeekdayRecurrence | MonthlyRecurrence | IntervalRecurrence)


// Cron: free-function namespace that computes next-fire timestamps.
// No provider parameter — _TzData is the single source.
// Returns POSIX (I64, I64) suitable for stdlib time.Timer.abs.

primitive Cron
  """
  Compute "next fire" timestamps from Recurrence rules. Zone lookups
  go through `_TzData`; no provider parameter.

  All returned tuples are POSIX `(I64 sec, I64 nsec)` shape — feed
  directly to `time.Timer.abs(...)`.
  """

  fun next(r: Recurrence, after_posix: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    """
    Find the next fire instant strictly after `after_posix`. Dispatches
    on the Recurrence variant.
    """
    match r
    | let w: WeekdayRecurrence => next_weekday(w, after_posix)
    | let m: MonthlyRecurrence => next_monthly(m, after_posix)
    | let i: IntervalRecurrence => next_interval(i, after_posix)
    end

  fun next_weekday(r: WeekdayRecurrence, after_posix: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    """
    One-shot wrapper around `WeekdayIter.next_fire`. For multi-fire
    iteration use `r.iter_after(after_posix)` and call `.next_fire()`
    repeatedly.
    """
    r.iter_after(after_posix).next_fire()

  fun next_monthly(r: MonthlyRecurrence, after_posix: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    """
    One-shot wrapper around `MonthlyIter.next_fire`. For multi-fire
    iteration (e.g., projecting 12 months of billing dates) use
    `r.iter_after(after_posix)` directly and call `.next_fire()`
    repeatedly — the iterator preserves cursor state across calls.
    """
    r.iter_after(after_posix).next_fire()

  fun next_interval(r: IntervalRecurrence, after_posix: (I64, I64))
    : ((I64, I64) | NextFireError)
  =>
    """
    One-shot wrapper around `IntervalIter.next_fire`. For multi-fire
    iteration use `r.iter_after(after_posix)` and call `.next_fire()`
    repeatedly.
    """
    r.iter_after(after_posix).next_fire()

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
