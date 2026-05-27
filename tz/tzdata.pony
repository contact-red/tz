// Internal IANA tzdata dispatch. Single source of truth for the library.
//
// Per resolutions/1 + /4 (2026-05-24):
// - No `TzProvider` trait; no `BundledTz`/`SystemTzProvider`/`FakeTzProvider`
//   split. There is only the bundled IANA data.
// - Dispatch is string-keyed (zone name → rules), not type-keyed.
//   The codegen tool emits a `match` over all zone name literals into
//   per-zone primitives that each carry their own if/elseif transition
//   ladder.
// - Cross-platform consistent — same data on Linux, macOS, Windows.
// - Pre-1970 transitions are wrapped in `ifdef "HISTORICAL_TZ"` inside
//   each per-zone primitive; default builds report OutOfCoverage for
//   those instants and `-D HISTORICAL_TZ` enables the full historical
//   ladder back through the LMT era.
// - zdump-compatible: the (UTC instant, local Y/M/D/H/M/S, abbreviation,
//   isdst, gmtoff) bundle from `observation_at` matches what zdump emits
//   per transition record.
//
// `_TzData` is a `primitive` because all state is compile-time-baked into
// the dispatch table emitted by codegen. No instance state, no startup
// cost, shareable across all actors automatically.


primitive _TzData
  // String-keyed access to bundled IANA tz rules. Internal — consumers
  // don't call this directly; it's the engine behind `ZonedDateTime`'s
  // zone-aware constructors.

  fun observation_at(zone_name: String val, sec: I64, nsec: I64)
    : (Observation val | TzLookupError)
  =>
    """
    What's the local view of this UTC instant in this zone?
    Returns the observation bundle (local fields + offset + abbreviation
    + isdst), or a TzLookupError if the zone isn't recognized or the
    instant falls outside coverage.

    Delegates to the codegen'd `_TzDataGenerated` dispatch (one
    per-zone primitive plus a top-level name match). Regenerate via:
        ponyc tz_codegen_main/ && ./tz_codegen_main
    """
    _TzDataGenerated.observation_at(zone_name, sec, nsec)

  fun _year_from_utc_sec(sec: I64): I16 =>
    let day_sec: I64 = 86_400
    let sec_of_day = (((sec % day_sec) + day_sec) % day_sec)
    let days_since_epoch = ((sec - sec_of_day) / day_sec).i32()
    (let y, _, _) = _Gregorian.civil_from_days(days_since_epoch)
    y

  // ---------------------------------------------------------------
  // Helpers for codegen'd zone primitives (Phase 4 of the codegen
  // tool). The generated `_Zone_*` primitives call these to
  // compute POSIX-TZ-trailer transition instants without each zone
  // having to inline the math.
  // ---------------------------------------------------------------

  fun mwd_local_to_utc(
    year: I16, month: U8, week: U8, weekday_zero_sun: U8,
    local_time_of_day_sec: I32, offset_for_conversion_sec: I32)
    : I64
  =>
    """
    Compute the UTC POSIX second of an Mm.w.d POSIX-TZ rule for the
    given year. `weekday_zero_sun` is 0=Sunday..6=Saturday (matching
    POSIX-TZ convention). `local_time_of_day_sec` is the rule's local
    time in seconds (typically 7200 for 02:00). `offset_for_conversion_sec`
    is the std offset (for spring-forward) or dst offset (for
    fall-back) used to convert local → UTC.

    Internally uses the same algorithm as
    `posix_tz.pony#_resolve_month_week_day` but lives here so generated
    code in this package can call it without a cross-package dependency.
    """
    let first_dow_zero_sun = _day_of_week_zero_sun(year, month, 1)
    let to_first: U8 = (((weekday_zero_sun + 7) - first_dow_zero_sun) % 7)
    let first_occ_dom: U8 = 1 + to_first
    let occ_dom: U8 =
      if week < 5 then
        first_occ_dom + ((week - 1) * 7)
      else
        let max_day = _Gregorian.days_in_month(year, month)
        var d: U8 = first_occ_dom + 28
        while d > max_day do d = d - 7 end
        d
      end
    let date_days =
      try
        Date(year, month, occ_dom)?.days_since_epoch().i64()
      else
        0
      end
    ((date_days * 86_400) + local_time_of_day_sec.i64()) +
      offset_for_conversion_sec.i64()

  fun _day_of_week_zero_sun(y: I16, m: U8, d: U8): U8 =>
    """Zeller's congruence remapped to 0=Sunday..6=Saturday."""
    match _Gregorian.day_of_week(y, m, d)
    | Sunday => 0
    | Monday => 1
    | Tuesday => 2
    | Wednesday => 3
    | Thursday => 4
    | Friday => 5
    | Saturday => 6
    end

  fun julian_local_to_utc(
    year: I16, ordinal_1_based: U16,
    local_time_of_day_sec: I32, offset_for_conversion_sec: I32)
    : I64
  =>
    """
    Jn POSIX-TZ rule: ordinal day 1..365, with Feb 29 NOT counted.
    In leap years, days after Feb 28 shift forward by 1.
    """
    let n = ordinal_1_based.i32()
    let doy: I32 =
      if _Gregorian.is_leap_year(year) and (n > 59) then n + 1 else n end
    _doy_local_to_utc(year, doy, local_time_of_day_sec, offset_for_conversion_sec)

  fun zero_day_local_to_utc(
    year: I16, ordinal_0_based: U16,
    local_time_of_day_sec: I32, offset_for_conversion_sec: I32)
    : I64
  =>
    """n POSIX-TZ rule: ordinal day 0..365 (Feb 29 counted in leap years)."""
    _doy_local_to_utc(
      year, ordinal_0_based.i32() + 1,
      local_time_of_day_sec, offset_for_conversion_sec)

  fun _doy_local_to_utc(
    year: I16, doy_1_based: I32,
    local_time_of_day_sec: I32, offset_for_conversion_sec: I32)
    : I64
  =>
    let jan1_days =
      try
        Date(year, 1, 1)?.days_since_epoch().i64()
      else
        0
      end
    let date_days = jan1_days + (doy_1_based - 1).i64()
    ((date_days * 86_400) + local_time_of_day_sec.i64()) +
      offset_for_conversion_sec.i64()

  fun observation_for_offset(sec: I64, nsec: I64, offset_sec: I32)
    : Observation val
  =>
    """
    Compute an Observation for the fixed-offset case. No tzdata lookup
    needed; just shift the UTC instant by the offset and decompose into
    local fields. Always succeeds — caller is responsible for the offset
    being reasonable.
    """
    _make_observation(sec, nsec, offset_sec, _offset_string(offset_sec), false)

  fun _make_observation(
    sec: I64, nsec: I64, offset_sec: I32, abbrev: String val, is_dst: Bool)
    : Observation val
  =>
    // Shift UTC into local seconds, then decompose.
    let local_sec_total: I64 = sec + offset_sec.i64()
    let day_sec: I64 = 86_400
    // Floor-mod for day-of-second; same pattern as TimeOfDay.add_nanos.
    // Floor-mod (not rem) so negative local_sec_total wraps correctly when
    // HISTORICAL_TZ is set. Pony's `%` is rem; we compensate.
    let sec_of_day: I64 = (((local_sec_total % day_sec) + day_sec) % day_sec)
    let days_since_epoch: I32 = ((local_sec_total - sec_of_day) / day_sec).i32()
    (let y, let m, let d) = _Gregorian.civil_from_days(days_since_epoch)
    let hour: U8 = (sec_of_day / 3600).u8()
    let mn: U8 = ((sec_of_day - (hour.i64() * 3600)) / 60).u8()
    let s: U8 = (sec_of_day - ((hour.i64() * 3600) + (mn.i64() * 60))).u8()
    let local_date =
      try Date(y, m, d)?
      else
        // TODO: replace with a mort-style panic primitive. Reaching this
        // branch means civil_from_days produced a year outside the
        // supported range, which can happen for extreme offsets paired
        // with epoch-adjacent instants.
        Date.epoch()
      end
    let local_tod =
      try TimeOfDay(hour, mn, s, nsec.i32())?
      else
        TimeOfDay.midnight()
      end
    Observation(local_date, local_tod, offset_sec, abbrev, is_dst)

  fun _offset_string(offset_sec: I32): String val =>
    """
    ISO 8601 zone-offset string for a numeric offset: "Z" for 0,
    "+HH:MM" or "-HH:MM" otherwise. Sub-minute offsets (LMT-era) are
    rounded to whole minutes in the abbreviation; full precision is
    available via the offset_sec accessor.
    """
    if offset_sec == 0 then return "Z" end
    let abs_sec: I32 = if offset_sec < 0 then -offset_sec else offset_sec end
    let hours: I32 = abs_sec / 3600
    let mins: I32 = (abs_sec - (hours * 3600)) / 60
    let h_str = hours.string()
    let m_str = mins.string()
    recover val
      let buf = String(6)
      buf.push(if offset_sec < 0 then '-' else '+' end)
      if hours < 10 then buf.push('0') end
      buf.append(consume h_str)
      buf.push(':')
      if mins < 10 then buf.push('0') end
      buf.append(consume m_str)
      buf
    end

// Lookup-error vocabulary. Smaller than the prior TzLookupError because
// there are no filesystem operations (no SystemTzProvider) and no
// distinct providers to disambiguate.

primitive ZoneNotFound
  """The zone name isn't in the bundled IANA tzdata."""

primitive OutOfCoverage
  """
  The requested UTC instant is outside the bundled data's coverage
  range. Default builds cover post-1970; rebuild with
  `-D HISTORICAL_TZ` for earlier dates.
  """

type TzLookupError is (ZoneNotFound | OutOfCoverage)
