"""
Zone and Offset (tag primitives), Observation, LocalResolution,
ResolveError, ZonedDateTime.

Per resolutions/4 (2026-05-24), Zone and Offset are tag primitives
with no instance data — they discriminate whether a ZonedDateTime's
internal representation refers to an IANA-named zone (DST rules apply)
or a fixed numeric offset (no DST). The actual data (name string or
offset int) lives on the ZonedDateTime itself.

Per resolutions/1, the IANA-bundled tzdata (via `_TzData`) is the only
data source. No TzProvider abstraction.

Per resolutions/2, ZonedDateTime is the only "moment in time" type —
no separate Instant. Construction via `now()` (UTC), `now_in_zone(name)`,
or `now_at_offset(sec)`. Stdlib bridge via `to_posix(): (I64, I64)`.

ZonedDateTime is REF — designed for in-place mutation in tight loops.
"""

use "time"


// Tag primitives. No instance data; discriminate the ZonedDateTime kind.

primitive Zone
  """
  Tag: this ZonedDateTime is in an IANA-named zone (DST rules apply,
  abbreviation comes from tzdata).
  """

primitive Offset
  """
  Tag: this ZonedDateTime is at a fixed numeric offset, no zone
  identity, no DST.
  """

type ZonedKind is (Zone | Offset)


// Observation: the zdump-comparable observable bundle for a (zone, instant)
// pair. Internal type used by ZonedDateTime; rarely seen by consumers
// directly (ZonedDateTime delegates accessors to it).

class val Observation
  """
  Local fields + offset + abbreviation + isdst flag for a (zone, instant)
  pair. Matches what zdump emits per transition record (used as the
  comparison surface for differential testing against zdump).
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


// DST resolution policy and error variants.

primitive ResolveStrict
  """DST gaps and overlaps are errors (LocalGap, LocalAmbiguous)."""
primitive ResolveEarliest
  """On overlap, pick the earlier UTC instant (pre-transition offset)."""
primitive ResolveLatest
  """On overlap, pick the later UTC instant (post-transition offset)."""
primitive ResolveNextValid
  """On gap, advance to the first valid local instant after the gap."""

type LocalResolution is
  (ResolveStrict | ResolveEarliest | ResolveLatest | ResolveNextValid)


primitive LocalGap
  """Spring-forward gap and policy refused to advance."""
primitive LocalAmbiguous
  """Fall-back overlap and policy refused to pick."""

type ResolveError is (LocalGap | LocalAmbiguous)


// ZonedDateTime: the primary moment-in-time type.

class ZonedDateTime
  """
  A UTC moment plus zone context (an IANA zone OR a fixed offset).

  Storage: POSIX (sec, nsec) UTC + zone name (or "" for Offset mode) +
  resolved Observation (local fields, offset, abbrev, isdst).

  REF capability. Allocate once and reuse via `reset_to`,
  `to_timezone_in_place`, etc. For cross-actor sharing, convert via
  `to_posix()` + `zone_name()` (or `offset_sec()` when in Offset mode)
  and reconstruct in the receiver actor.

  ## Construction patterns

      ZonedDateTime.now()                                   // UTC
      ZonedDateTime.now_in_zone("America/Los_Angeles")?     // IANA
      ZonedDateTime.now_at_offset(-7 * 3600)                // fixed offset
      ZonedDateTime.from_posix((sec, nsec))                 // reconstruct UTC
      ZonedDateTime.from_posix_in_zone((sec, nsec), name)?
      ZonedDateTime.from_posix_at_offset((sec, nsec), offset_sec)
  """
  var _sec: I64
  var _nsec: I64
  var _kind: ZonedKind
  var _zone_name: String val
  var _observation: Observation val

  new now() =>
    """Wall-clock now, in UTC."""
    (_sec, _nsec) = Time.now()
    _kind = Zone
    _zone_name = "UTC"
    _observation = _resolve_utc(_sec, _nsec)

  new now_in_zone(name: String val) ? =>
    """
    Wall-clock now, in the specified IANA zone. Errors if the zone
    isn't in the bundled tzdata (use `try_zone(name)` on an existing
    ZDT for richer error info).
    """
    (_sec, _nsec) = Time.now()
    _kind = Zone
    _zone_name = name
    _observation =
      match _TzData.observation_at(name, _sec, _nsec)
      | let o: Observation val => o
      | let _: TzLookupError => error
      end

  new now_at_offset(offset_sec': I32) =>
    """Wall-clock now, at a fixed numeric offset (not an IANA zone)."""
    (_sec, _nsec) = Time.now()
    _kind = Offset
    _zone_name = ""
    _observation = _TzData.observation_for_offset(_sec, _nsec, offset_sec')

  new from_posix(p: (I64, I64)) =>
    """Reconstruct a UTC ZonedDateTime from a POSIX tuple."""
    (_sec, _nsec) = p
    _kind = Zone
    _zone_name = "UTC"
    _observation = _resolve_utc(_sec, _nsec)

  new from_posix_in_zone(p: (I64, I64), name: String val) ? =>
    """Construct a ZonedDateTime in an IANA zone from a POSIX tuple."""
    (_sec, _nsec) = p
    _kind = Zone
    _zone_name = name
    _observation =
      match _TzData.observation_at(name, _sec, _nsec)
      | let o: Observation val => o
      | let _: TzLookupError => error
      end

  new from_posix_at_offset(p: (I64, I64), offset_sec': I32) =>
    """Construct a ZonedDateTime at a fixed offset from a POSIX tuple."""
    (_sec, _nsec) = p
    _kind = Offset
    _zone_name = ""
    _observation = _TzData.observation_for_offset(_sec, _nsec, offset_sec')

  new _unchecked(
    sec': I64, nsec': I64, kind': ZonedKind, zone_name': String val,
    obs': Observation val)
  =>
    """
    Package-private constructor that bypasses validation. Used by
    methods like `to_timezone` that have already done their own
    consistency checks. Not callable from outside the package.
    """
    _sec = sec'
    _nsec = nsec'
    _kind = kind'
    _zone_name = zone_name'
    _observation = obs'

  // Mutation methods (in-place; no allocation).

  fun ref reset_to(p: (I64, I64)): (None | TzLookupError) =>
    """
    Mutate to represent a different UTC instant in the same zone (or
    offset). For Zone mode, re-resolves against the bundled tzdata —
    may fail if the new instant falls outside coverage, in which case
    self is left unchanged.
    """
    let new_sec = p._1
    let new_nsec = p._2
    match _kind
    | Zone =>
      match _TzData.observation_at(_zone_name, new_sec, new_nsec)
      | let o: Observation val =>
        _sec = new_sec
        _nsec = new_nsec
        _observation = o
        None
      | let e: TzLookupError => e
      end
    | Offset =>
      _sec = new_sec
      _nsec = new_nsec
      _observation =
        _TzData.observation_for_offset(_sec, _nsec, _observation.offset_sec())
      None
    end

  fun ref to_timezone_in_place(name: String val): (None | TzLookupError) =>
    """
    Mutate to represent the same UTC instant in a different IANA zone.
    Returns ZoneNotFound or OutOfCoverage on failure; self is left
    unchanged on error.
    """
    match _TzData.observation_at(name, _sec, _nsec)
    | let o: Observation val =>
      _zone_name = name
      _kind = Zone
      _observation = o
      None
    | let e: TzLookupError => e
    end

  fun ref reset_at_offset(p: (I64, I64), offset_sec': I32) =>
    """
    Mutate to a UTC instant at a fixed offset, switching this ZDT to
    Offset mode. Symmetric with `from_posix_at_offset` but reuses
    self — no allocation.
    """
    _sec = p._1
    _nsec = p._2
    _kind = Offset
    _zone_name = ""
    _observation = _TzData.observation_for_offset(_sec, _nsec, offset_sec')

  fun ref reset_in_zone(p: (I64, I64), name: String val)
    : (None | TzLookupError)
  =>
    """
    Mutate to a UTC instant in an IANA zone, switching this ZDT to
    Zone mode. Symmetric with `from_posix_in_zone`; self is left
    unchanged on error.
    """
    match _TzData.observation_at(name, p._1, p._2)
    | let o: Observation val =>
      _sec = p._1
      _nsec = p._2
      _kind = Zone
      _zone_name = name
      _observation = o
      None
    | let e: TzLookupError => e
    end

  fun box to_timezone(name: String val): (ZonedDateTime iso^ | TzLookupError) =>
    """
    Return a NEW ZonedDateTime representing the same UTC instant in a
    different IANA zone. Allocates one heap object on success.
    """
    match _TzData.observation_at(name, _sec, _nsec)
    | let o: Observation val =>
      let sec' = _sec
      let nsec' = _nsec
      recover iso ZonedDateTime._unchecked(sec', nsec', Zone, name, o) end
    | let e: TzLookupError => e
    end

  // Accessors.

  fun box to_posix(): (I64, I64) => (_sec, _nsec)
  fun box kind(): ZonedKind => _kind
  fun box zone_name(): String val => _zone_name
  fun box local_date(): Date val => _observation.local_date()
  fun box local_tod(): TimeOfDay val => _observation.local_tod()
  fun box offset_sec(): I32 => _observation.offset_sec()
  fun box abbreviation(): String val => _observation.abbreviation()
  fun box is_dst(): Bool => _observation.is_dst()

  // Formatting.

  fun box string(): String iso^ =>
    """
    RFC 3339 / ISO 8601 representation of this ZonedDateTime.
    Format: `YYYY-MM-DDTHH:MM:SS[.nnnnnnnnn][Z|±HH:MM]`

    - Date part comes from `local_date().string()` (YYYY-MM-DD,
      negative years prefixed with '-').
    - Time part comes from `local_tod().string()` (HH:MM:SS, or
      HH:MM:SS.nnnnnnnnn when sub-second precision is non-zero).
    - Offset is `Z` for zero offset, or `±HH:MM` otherwise (sub-minute
      offsets — LMT-era — are rounded for the suffix; precise value
      remains available via `offset_sec()`).

    The IANA zone name is NOT in the output — RFC 3339 carries an
    offset, not a zone. Use `zone_name()` separately if you need it.
    """
    let date_str = local_date().string()
    let tod_str = local_tod().string()
    let off_str = _TzData._offset_string(offset_sec())
    recover iso
      let buf = String(40)
      buf.append(consume date_str)
      buf.push('T')
      buf.append(consume tod_str)
      buf.append(consume off_str)
      buf
    end

  // UTC is the one zone we know always resolves cleanly — extract the
  // try/else for the (currently impossible) error path so the public
  // UTC constructors stay non-partial.
  fun tag _resolve_utc(sec: I64, nsec: I64): Observation val =>
    match _TzData.observation_at("UTC", sec, nsec)
    | let o: Observation val => o
    | let _: TzLookupError =>
      // Unreachable: _TzData hard-codes UTC.
      Observation(Date.epoch(), TimeOfDay.midnight(), 0, "UTC", false)
    end


// fun _observation_for_offset(sec: I64, nsec: I64, offset_sec: I32): Observation val =>
//   """Compute a local Observation for a fixed-offset case (no tzdata
//   lookup needed). Used by now_at_offset and reset_to (Offset case)."""
//   // TODO: split (sec + offset_sec) back into Y/M/D H:M:S, format
//   // abbreviation as the offset string ("-07:00" etc.)
//   Observation(Date(1970,1,1)?, TimeOfDay(0,0,0)?, offset_sec, "", false)
