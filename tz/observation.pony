// Observation: resolved local fields for a (zone, instant) pair. The
// canonical return value of every tzdata lookup; cached on ZonedDateTime
// so accessors read from it directly rather than re-querying tzdata.
// Consumers rarely see it directly — they go through ZonedDateTime.

class val Observation
  """
  Resolved local fields for a `(zone, instant)` pair: local date and
  time-of-day, offset from UTC, zone abbreviation, and DST flag.

  Produced by every `_TzData.observation_at(...)` call and cached on
  `ZonedDateTime` so its accessors don't re-query tzdata. The shape was
  chosen to match what `zdump` emits per transition record, which makes
  it convenient as the comparison surface in our differential tests
  against `zdump`.
  """
  let _local_date: Date val
  let _local_tod: TimeOfDay val
  let _offset_sec: I32
  let _abbreviation: String val
  let _is_dst: Bool

  new val create(
    local_date': Date val,
    local_tod': TimeOfDay val,
    offset_sec': I32,
    abbreviation': String val,
    is_dst': Bool)
  =>
    _local_date = local_date'
    _local_tod = local_tod'
    _offset_sec = offset_sec'
    _abbreviation = abbreviation'
    _is_dst = is_dst'

  fun val local_date(): Date val => _local_date
  fun val local_tod(): TimeOfDay val => _local_tod
  fun val offset_sec(): I32 => _offset_sec
  fun val abbreviation(): String val => _abbreviation
  fun val is_dst(): Bool => _is_dst
