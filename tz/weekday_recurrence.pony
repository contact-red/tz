// WeekdayRecurrence: "every weekday-in-set at TimeOfDay, in this IANA
// zone". Paired with WeekdayIter, which yields successive fire instants.

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

  fun val iter_after(after: ZonedDateTime box): WeekdayIter =>
    """
    Build an iterator that yields successive fire instants strictly
    after `after`. Each call to `next()` advances at least one day;
    consecutive calls within the same week may advance only one day
    (across weekdays in the set) or skip several (across excluded
    weekend days).
    """
    WeekdayIter(this, after)


class ref WeekdayIter is Iterator[(ZonedDateTime iso^ | NextFireError)]
  """
  Iterator over the fire instants of a `WeekdayRecurrence`. Each call
  to `next()` yields either a fresh `ZonedDateTime iso^` or a
  `NextFireError` — the error is part of the value type, not a side
  channel.

  Termination: when the iterator can't progress, the next call emits
  the relevant `NextFireError` exactly once, then `has_next()` returns
  `false` forever after. A `for` loop sees the error in the body via
  match, then terminates naturally on the following `has_next()` check.
  """
  let _weekdays: Array[DayOfWeek] val
  let _target_tod: TimeOfDay val
  let _zone_name: String val
  var _state: _WeekdayIterState

  new ref create(r: WeekdayRecurrence, after: ZonedDateTime box) =>
    _weekdays = r.weekdays()
    _target_tod = r.at()
    _zone_name = r.zone_name()
    _state = _WeekdayIterStart(after.to_posix())

  fun ref has_next(): Bool =>
    match _state
    | _WeekdayIterDone => false
    else true
    end

  fun ref next(): (ZonedDateTime iso^ | NextFireError) =>
    match _state
    | let s: _WeekdayIterStart => _emit(_begin(s.after_posix()))
    | let c: _WeekdayIterCursor => _emit(_advance(c.cursor_date(), c.lower()))
    | let stuck: _WeekdayIterStuck =>
      let e = stuck.err()
      _state = _WeekdayIterDone
      e
    | _WeekdayIterDone =>
      // Caller didn't honor the has_next() contract. Degrade
      // gracefully rather than crash.
      NextFireBudgetExhausted
    end

  fun ref _emit(posix: ((I64, I64) | NextFireError))
    : (ZonedDateTime iso^ | NextFireError)
  =>
    """
    Lift the internal POSIX-or-error result into the public ZDT-or-
    error shape. Handles two state-transition cases:

    - POSIX returned: build the ZDT. If construction fails (tzdata
      coverage edge), transition to Done and emit OutOfRange.
    - Error returned: `_begin`/`_advance` already set `_state` to
      `_Stuck`. We surface that error now and move to `_Done`.
    """
    match posix
    | (let sec: I64, let nsec: I64) =>
      try
        recover iso ZonedDateTime.from_posix_in_zone((sec, nsec), _zone_name)? end
      else
        _state = _WeekdayIterDone
        NextFireOutOfRange
      end
    | let err: NextFireError =>
      _state = _WeekdayIterDone
      err
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
                return fire   // emit this fire; error queued for next call
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
  """Internal: error queued, to be emitted on the next `next()` call."""
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

primitive _WeekdayIterDone
  """Internal: error has been emitted; the iterator is exhausted."""

type _WeekdayIterState is
  ( _WeekdayIterStart
  | _WeekdayIterCursor
  | _WeekdayIterStuck
  | _WeekdayIterDone )
