// IntervalRecurrence: "every Period after the start instant, in this
// IANA zone." Period carries intraday units (T7), so "every 90 minutes"
// works. Paired with IntervalIter, which yields successive fire
// instants by adding `every()` to the previous one.

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

  fun val iter_after(after: ZonedDateTime box): IntervalIter =>
    """
    Build an iterator that yields successive fire instants. Each call
    advances by `every()`. Pure-intraday Periods (months == 0 &&
    days == 0) work today; calendar-mixed Periods produce a sticky
    `NextFireBudgetExhausted` until local-time arithmetic lands.
    """
    IntervalIter(this, after)


class ref IntervalIter is Iterator[(ZonedDateTime iso^ | NextFireError)]
  """
  Iterator over the fire instants of an `IntervalRecurrence`. Each
  call to `next()` yields either a fresh `ZonedDateTime iso^` or a
  `NextFireError`. The error is emitted exactly once, after which
  `has_next()` returns `false`.
  """
  let _period: Period val
  let _zone_name: String val
  var _state: _IntervalIterState

  new ref create(r: IntervalRecurrence, after: ZonedDateTime box) =>
    _period = r.every()
    _zone_name = r.zone_name()
    _state = _IntervalIterStart(after.to_posix())

  fun ref has_next(): Bool =>
    match _state
    | _IntervalIterDone => false
    else true
    end

  fun ref next(): (ZonedDateTime iso^ | NextFireError) =>
    match _state
    | let s: _IntervalIterStart => _emit(_begin(s.after_posix()))
    | let c: _IntervalIterCursor => _emit(_step(c.last_fire()))
    | let stuck: _IntervalIterStuck =>
      let e = stuck.err()
      _state = _IntervalIterDone
      e
    | _IntervalIterDone => NextFireBudgetExhausted
    end

  fun ref _emit(posix: ((I64, I64) | NextFireError))
    : (ZonedDateTime iso^ | NextFireError)
  =>
    match posix
    | (let sec: I64, let nsec: I64) =>
      try
        recover iso ZonedDateTime.from_posix_in_zone((sec, nsec), _zone_name)? end
      else
        _state = _IntervalIterDone
        NextFireOutOfRange
      end
    | let err: NextFireError =>
      _state = _IntervalIterDone
      err
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
  """Internal: error queued, to be emitted on the next `next()` call."""
  let _err: NextFireError
  new val create(e: NextFireError) => _err = e
  fun val err(): NextFireError => _err

primitive _IntervalIterDone
  """Internal: error has been emitted; the iterator is exhausted."""

type _IntervalIterState is
  ( _IntervalIterStart
  | _IntervalIterCursor
  | _IntervalIterStuck
  | _IntervalIterDone )
