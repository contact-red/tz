// MonthlyRecurrence: "on MonthlyAnchor of every month, at TimeOfDay, in
// this IANA zone." Paired with MonthlyIter, which yields successive
// fire instants and preserves DayOfMonth(N)'s preferred-day behavior
// across clamping months.

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

  fun val iter_after(after: ZonedDateTime box): MonthlyIter =>
    """
    Build an iterator that yields successive fire instants strictly
    after `after`. Each call to `next()` advances by one month.
    Preserves the preferred-day behavior of `DayOfMonth(N)` across
    clamping months (Jan 31 → Feb 28 → Mar 31 → Apr 30 → ...).
    """
    MonthlyIter(this, after)


class ref MonthlyIter is Iterator[(ZonedDateTime iso^ | NextFireError)]
  """
  Iterator over the fire instants of a `MonthlyRecurrence`. Each call
  to `next()` yields either a fresh `ZonedDateTime iso^` or a
  `NextFireError`. The error is emitted exactly once, after which
  `has_next()` returns `false`.
  """
  let _anchor: MonthlyAnchor
  let _target_tod: TimeOfDay val
  let _zone_name: String val
  var _state: _MonthlyIterState

  new ref create(r: MonthlyRecurrence, after: ZonedDateTime box) =>
    _anchor = r.anchor()
    _target_tod = r.at()
    _zone_name = r.zone_name()
    _state = _MonthlyIterStart(after.to_posix())

  fun ref has_next(): Bool =>
    match _state
    | _MonthlyIterDone => false
    else true
    end

  fun ref next(): (ZonedDateTime iso^ | NextFireError) =>
    match _state
    | let s: _MonthlyIterStart => _emit(_begin(s.after_posix()))
    | let c: _MonthlyIterCursor => _emit(_advance(c.cursor(), c.lower()))
    | let stuck: _MonthlyIterStuck =>
      let e = stuck.err()
      _state = _MonthlyIterDone
      e
    | _MonthlyIterDone => NextFireBudgetExhausted
    end

  fun ref _emit(posix: ((I64, I64) | NextFireError))
    : (ZonedDateTime iso^ | NextFireError)
  =>
    match posix
    | (let sec: I64, let nsec: I64) =>
      try
        recover iso ZonedDateTime.from_posix_in_zone((sec, nsec), _zone_name)? end
      else
        _state = _MonthlyIterDone
        NextFireOutOfRange
      end
    | let err: NextFireError =>
      _state = _MonthlyIterDone
      err
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
    failure, queues the error in `_MonthlyIterStuck`.
    """
    var cur = start_cursor
    var i: USize = 0
    while i < 13 do
      let candidate_date =
        try _resolve_anchor(cur.year(), cur.month())?
        else
          _state = _MonthlyIterStuck(NextFireOutOfRange)
          return NextFireOutOfRange
        end
      match _RecurrenceMath.local_to_utc_in_zone(
        candidate_date, _target_tod, _zone_name)
      | (let s: I64, let n: I64) =>
        let fire = (s, n)
        if _RecurrenceMath.posix_gt(fire, lower) then
          // Advance cursor one month past so the next call starts
          // resolving the following month.
          let next_cur =
            match cur.add_months(1, OverflowClamp)
            | let d: Date val => d
            | let _: ArithmeticError =>
              _state = _MonthlyIterStuck(NextFireOutOfRange)
              return fire   // emit this fire; error queued for next call
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

  fun box _resolve_anchor(year: I16, month: U8): Date val ? =>
    """
    Compute the actual calendar date for this iterator's anchor in
    the given year/month. Clamps `DayOfMonth(N)` to month length;
    walks backward from end-of-month for `LastWeekdayOfMonth`.
    """
    match _anchor
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
  """Internal: error queued, to be emitted on the next `next()` call."""
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

primitive _MonthlyIterDone
  """Internal: error has been emitted; the iterator is exhausted."""

type _MonthlyIterState is
  ( _MonthlyIterStart
  | _MonthlyIterCursor
  | _MonthlyIterStuck
  | _MonthlyIterDone )
