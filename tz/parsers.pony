// Wire-format parsers and formatters: Rfc3339, Iso8601 (lenient), Rfc2822.
//
// Per resolutions/1 (2026-05-24), no provider parameter — `_TzData` is the
// single data source. Parsers that produce a ZonedDateTime in a real IANA
// zone (or for the fixed-offset case) go through `_TzData` internally
// when zone-aware resolution is needed.
//
// Each parser/formatter is a primitive with the `X` + `X_in_place` pattern
// (mimicking stdlib `String`):
//
//   - `parse(s)`: returns fresh `ZonedDateTime iso^`.
//   - `parse_in_place(s, zdt)`: mutates caller's `ZonedDateTime ref`.
//   - `format(zdt)`: returns fresh `String iso^`.
//   - `format_in_place(zdt, buf)`: appends to caller's `String ref`.
//
// RFC 3339 carries an offset (not a zone), so its parser produces a
// ZonedDateTime in Offset mode (zone_name == "", kind == Offset). The
// formatter is shared with `ZonedDateTime.string()` since the format
// is identical.
//
// ISO 8601 (lenient) accepts dialects RFC 3339 rejects: `T`/`t`/space
// for the date-time separator, `Z`/`z` for zulu. Inputs lacking an
// offset require a fallback zone name to resolve against (currently
// only "UTC" is recognized; full IANA zones come with the codegen
// story).
//
// RFC 2822 (email date) parsing/formatting is stubbed pending demand.


primitive Rfc3339
  """
  Strict RFC 3339 parsing and formatting.
  See: https://datatracker.ietf.org/doc/html/rfc3339
  """

  fun parse(s: String val): (ZonedDateTime iso^ | ParseError) =>
    """
    Parse an RFC 3339 timestamp into a fresh ZonedDateTime in Offset
    mode (RFC 3339 carries offset, not zone). Returns ParseError on
    malformed input.
    """
    match _parse_components(s, false)
    | let e: ParseError => e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      recover iso ZonedDateTime.from_posix_at_offset((sec, nsec), off) end
    end

  fun parse_in_place(s: String val, zdt: ZonedDateTime)
    : (None | ParseError)
  =>
    """
    Parse an RFC 3339 timestamp, mutating `zdt` to represent the
    result. Zero allocation on the happy path. Self is left unchanged
    on error.
    """
    match _parse_components(s, false)
    | let e: ParseError => e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      zdt.reset_at_offset((sec, nsec), off)
      None
    end

  fun format(zdt: ZonedDateTime box): String iso^ =>
    """RFC 3339 representation. Delegates to `ZonedDateTime.string()`."""
    zdt.string()

  fun format_in_place(zdt: ZonedDateTime box, buf: String ref) =>
    """Append the RFC 3339 representation to `buf`."""
    let s = zdt.string()
    buf.append(consume s)

  fun _parse_components(s: String val, lenient: Bool)
    : ((I64, I64, I32) | ParseError)
  =>
    """
    Internal: parse to (utc_sec, nsec, offset_sec). When `lenient` is
    true, accept the Iso8601 dialects (lowercase 't'/'z', space
    separator). Otherwise strict RFC 3339.
    """
    let p = _ParseState(s)
    try
      let year = p.read_digits(4)?.i16()
      p.expect('-')?
      let month = p.read_digits(2)?.u8()
      p.expect('-')?
      let day = p.read_digits(2)?.u8()
      // Date-time separator.
      let sep = p.byte()?
      if lenient then
        if (sep != 'T') and (sep != 't') and (sep != ' ') then error end
      else
        if sep != 'T' then error end
      end
      let hour = p.read_digits(2)?.u8()
      p.expect(':')?
      let minute = p.read_digits(2)?.u8()
      p.expect(':')?
      let second = p.read_digits(2)?.u8()
      // Optional fractional seconds.
      var nano: I32 = 0
      if (not p.eof()) and (p.peek()? == '.') then
        p.byte()?  // consume '.'
        nano = _read_fractional(p)?
      end
      // Offset.
      let offset_sec = _read_offset(p, lenient)?
      if not p.eof() then error end  // trailing garbage
      // Validate semantic correctness via Date/TimeOfDay constructors.
      let date = Date(year, month, day)?
      let tod = TimeOfDay(hour, minute, second, nano)?
      // Compute UTC POSIX seconds from local fields and offset.
      let days = date.days_since_epoch().i64()
      let local_sec = (days * 86400) +
        (((hour.i64() * 3600) + (minute.i64() * 60)) + second.i64())
      let utc_sec = local_sec - offset_sec.i64()
      (utc_sec, nano.i64(), offset_sec)
    else
      ParseMalformed
    end

  fun _read_fractional(p: _ParseState): I32 ? =>
    var digits_read: USize = 0
    var value: I64 = 0
    while (not p.eof()) and is_digit(p.peek()?) do
      let c = p.byte()?
      if digits_read < 9 then
        value = (value * 10) + (c - '0').i64()
      end
      digits_read = digits_read + 1
    end
    if digits_read == 0 then error end
    // Scale to nanoseconds: pad on the right if fewer than 9 digits.
    var i: USize = digits_read.min(9)
    while i < 9 do
      value = value * 10
      i = i + 1
    end
    value.i32()

  fun _read_offset(p: _ParseState, lenient: Bool): I32 ? =>
    if p.eof() then error end
    let c = p.peek()?
    if (c == 'Z') or (lenient and (c == 'z')) then
      p.byte()?
      0
    elseif (c == '+') or (c == '-') then
      p.byte()?  // consume sign
      let h = p.read_digits(2)?.i32()
      p.expect(':')?
      let m = p.read_digits(2)?.i32()
      if (h > 23) or (m > 59) then error end
      let sign: I32 = if c == '-' then -1 else 1 end
      sign * ((h * 3600) + (m * 60))
    else
      error
    end

  fun is_digit(c: U8): Bool => (c >= '0') and (c <= '9')


primitive Iso8601
  """
  Lenient ISO 8601 parsing/formatting. Accepts the dialects RFC 3339
  rejects: `T`/`t`/space for the date-time separator, `Z`/`z` for
  zulu. Inputs without an offset require a fallback zone name,
  resolved via `_TzData`.
  """

  fun parse(s: String val, fallback_zone_name: String val)
    : (ZonedDateTime iso^ | ParseError)
  =>
    """
    Parse an ISO 8601 timestamp. If the input carries an offset,
    `fallback_zone_name` is ignored and the result is in Offset mode.
    If the input lacks an offset (TODO: not yet supported in v1; see
    `_parse_or_fallback`), `fallback_zone_name` is used as the IANA
    zone via `_TzData`.
    """
    match _parse_or_fallback(s, fallback_zone_name)
    | let e: ParseError => e
    | let zdt: ZonedDateTime iso => consume zdt
    end

  fun parse_in_place(
    s: String val, fallback_zone_name: String val, zdt: ZonedDateTime)
    : (None | ParseError)
  =>
    """
    Lenient parse, mutating `zdt`. See `parse` for semantics.
    """
    // The lenient grammar still has an offset in the common case
    // (any consumer of ISO 8601 we care about emits one). When it
    // doesn't, that's the fallback-zone path which is currently
    // restricted to "UTC" until codegen lands.
    match Rfc3339._parse_components(s, true)
    | let e: ParseError =>
      // TODO: offset-less inputs aren't supported in v1; they'd need
      // a separate grammar branch + _TzData resolution via
      // fallback_zone_name. Surface as ParseMalformed for now.
      e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      zdt.reset_at_offset((sec, nsec), off)
      None
    end

  fun format(zdt: ZonedDateTime box): String iso^ =>
    """Same canonical format as RFC 3339."""
    zdt.string()

  fun format_in_place(zdt: ZonedDateTime box, buf: String ref) =>
    let s = zdt.string()
    buf.append(consume s)

  fun _parse_or_fallback(s: String val, fallback_zone_name: String val)
    : (ZonedDateTime iso^ | ParseError)
  =>
    match Rfc3339._parse_components(s, true)
    | let e: ParseError => e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      recover iso ZonedDateTime.from_posix_at_offset((sec, nsec), off) end
    end


primitive Rfc2822
  """
  RFC 2822 / 5322 (email date) parsing and formatting.
  See: https://datatracker.ietf.org/doc/html/rfc5322 (§3.3)

  Example: `Sun, 25 May 2026 12:00:00 -0700`

  Accepted on parse:
  - Optional day-of-week prefix (3-letter + comma + space); not
    validated against the computed day-of-week.
  - 1- or 2-digit day-of-month.
  - Case-insensitive 3-letter month name.
  - 4-digit year.
  - HH:MM or HH:MM:SS time.
  - Numeric offset `+HHMM` / `-HHMM`, or the legacy zone names
    `UT`/`GMT`/`EST`/`EDT`/`CST`/`CDT`/`MST`/`MDT`/`PST`/`PDT`.
  - Single space as field separator (FWS / CFWS folding rules from
    RFC 5322 §3.2.2 are not implemented in v1).

  Emitted on format: the canonical form with day-of-week, 2-digit
  day, capital-case 3-letter month, 4-digit year, HH:MM:SS, numeric
  offset (`+0000` for UTC, never `GMT`/`UT`).
  """

  fun parse(s: String val): (ZonedDateTime iso^ | ParseError) =>
    match _parse_components(s)
    | let e: ParseError => e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      recover iso ZonedDateTime.from_posix_at_offset((sec, nsec), off) end
    end

  fun parse_in_place(s: String val, zdt: ZonedDateTime)
    : (None | ParseError)
  =>
    match _parse_components(s)
    | let e: ParseError => e
    | (let sec: I64, let nsec: I64, let off: I32) =>
      zdt.reset_at_offset((sec, nsec), off)
      None
    end

  fun format(zdt: ZonedDateTime box): String iso^ =>
    let date = zdt.local_date()
    let tod = zdt.local_tod()
    let dow_str = _dow_abbrev(date.day_of_week())
    let month_str = _month_abbrev(date.month())
    let day = date.day()
    let year = date.year()
    let hour = tod.hour()
    let minute = tod.minute()
    let second = tod.second()
    let off_str = _format_offset_4digit(zdt.offset_sec())
    recover iso
      let buf = String(40)
      buf.append(dow_str)
      buf.append(", ")
      if day < 10 then buf.push('0') end
      let d_str = day.string()
      buf.append(consume d_str)
      buf.push(' ')
      buf.append(month_str)
      buf.push(' ')
      // Year, padded to 4 digits (assume non-negative for the supported range).
      let y_str = year.string()
      var pad: USize = (4 - y_str.size().i32()).max(0).usize()
      while pad > 0 do buf.push('0'); pad = pad - 1 end
      buf.append(consume y_str)
      buf.push(' ')
      if hour < 10 then buf.push('0') end
      let h_str = hour.string()
      buf.append(consume h_str)
      buf.push(':')
      if minute < 10 then buf.push('0') end
      let m_str = minute.string()
      buf.append(consume m_str)
      buf.push(':')
      if second < 10 then buf.push('0') end
      let s_str = second.string()
      buf.append(consume s_str)
      buf.push(' ')
      buf.append(off_str)
      buf
    end

  fun format_in_place(zdt: ZonedDateTime box, buf: String ref) =>
    let s = format(zdt)
    buf.append(consume s)

  fun _parse_components(s: String val): ((I64, I64, I32) | ParseError) =>
    let p = _ParseState(s)
    try
      _maybe_consume_dow(p)?
      let day = _read_1_or_2_digits(p)?
      p.expect(' ')?
      let month = _read_month(p)?
      p.expect(' ')?
      let year = p.read_digits(4)?.i16()
      p.expect(' ')?
      let hour = p.read_digits(2)?.u8()
      p.expect(':')?
      let minute = p.read_digits(2)?.u8()
      var second: U8 = 0
      if (not p.eof()) and (p.peek()? == ':') then
        p.byte()?  // consume ':'
        second = p.read_digits(2)?.u8()
      end
      p.expect(' ')?
      let offset_sec = _read_offset_or_zone(p)?
      if not p.eof() then error end
      // Validate via Date/TimeOfDay constructors.
      let date = Date(year, month, day)?
      let tod = TimeOfDay(hour, minute, second)?
      let days = date.days_since_epoch().i64()
      let local_sec = (days * 86400) +
        (((hour.i64() * 3600) + (minute.i64() * 60)) + second.i64())
      let utc_sec = local_sec - offset_sec.i64()
      (utc_sec, I64(0), offset_sec)
    else
      ParseMalformed
    end

  fun _maybe_consume_dow(p: _ParseState) ? =>
    // If the first character is a letter, treat it as a day-of-week
    // prefix: "XYZ, ". Otherwise no-op (leave position at the day-of-month).
    if p.eof() then error end
    if _is_letter(p.peek()?) then
      // Three letters, then comma, then space.
      p.byte()?
      if not _is_letter(p.byte()?) then error end
      if not _is_letter(p.byte()?) then error end
      p.expect(',')?
      p.expect(' ')?
    end

  fun _read_1_or_2_digits(p: _ParseState): U8 ? =>
    let first = p.byte()?
    if (first < '0') or (first > '9') then error end
    let v1: U8 = (first - '0').u8()
    if (not p.eof()) and is_digit(p.peek()?) then
      let second = p.byte()?
      ((v1 * 10) + (second - '0').u8())
    else
      v1
    end

  fun _read_month(p: _ParseState): U8 ? =>
    let c1 = _to_lower(p.byte()?)
    let c2 = _to_lower(p.byte()?)
    let c3 = _to_lower(p.byte()?)
    if (c1 == 'j') and (c2 == 'a') and (c3 == 'n') then 1
    elseif (c1 == 'f') and (c2 == 'e') and (c3 == 'b') then 2
    elseif (c1 == 'm') and (c2 == 'a') and (c3 == 'r') then 3
    elseif (c1 == 'a') and (c2 == 'p') and (c3 == 'r') then 4
    elseif (c1 == 'm') and (c2 == 'a') and (c3 == 'y') then 5
    elseif (c1 == 'j') and (c2 == 'u') and (c3 == 'n') then 6
    elseif (c1 == 'j') and (c2 == 'u') and (c3 == 'l') then 7
    elseif (c1 == 'a') and (c2 == 'u') and (c3 == 'g') then 8
    elseif (c1 == 's') and (c2 == 'e') and (c3 == 'p') then 9
    elseif (c1 == 'o') and (c2 == 'c') and (c3 == 't') then 10
    elseif (c1 == 'n') and (c2 == 'o') and (c3 == 'v') then 11
    elseif (c1 == 'd') and (c2 == 'e') and (c3 == 'c') then 12
    else error
    end

  fun _read_offset_or_zone(p: _ParseState): I32 ? =>
    if p.eof() then error end
    let first = p.peek()?
    if (first == '+') or (first == '-') then
      p.byte()?  // consume sign
      // RFC 2822 offset is 4 digits with no colon: HHMM.
      let h = p.read_digits(2)?.i32()
      let m = p.read_digits(2)?.i32()
      if (h > 23) or (m > 59) then error end
      let sign: I32 = if first == '-' then -1 else 1 end
      sign * ((h * 3600) + (m * 60))
    elseif _is_letter(first) then
      _read_obs_zone(p)?
    else
      error
    end

  fun _read_obs_zone(p: _ParseState): I32 ? =>
    // Collect 1-4 contiguous letters and match against the documented
    // obsolete zone names. Anything we don't recognize is treated as
    // +0000 per RFC 5322 §4.3 (alphabetic obs-zone of unknown meaning
    // SHOULD be interpreted as 0000).
    let c1 = _to_lower(p.byte()?)
    if p.eof() or (not _is_letter(p.peek()?)) then return 0 end
    let c2 = _to_lower(p.byte()?)
    if p.eof() or (not _is_letter(p.peek()?)) then
      // 2-letter: only "UT" is known.
      if (c1 == 'u') and (c2 == 't') then return 0 end
      return 0
    end
    let c3 = _to_lower(p.byte()?)
    // Drain any further letters; they don't affect interpretation.
    while (not p.eof()) and _is_letter(p.peek()?) do
      p.byte()?
    end
    // 3-letter zones.
    if (c1 == 'g') and (c2 == 'm') and (c3 == 't') then return 0 end
    if (c1 == 'u') and (c2 == 't') and (c3 == 'c') then return 0 end
    if (c1 == 'e') and (c2 == 's') and (c3 == 't') then return -(5 * 3600) end
    if (c1 == 'e') and (c2 == 'd') and (c3 == 't') then return -(4 * 3600) end
    if (c1 == 'c') and (c2 == 's') and (c3 == 't') then return -(6 * 3600) end
    if (c1 == 'c') and (c2 == 'd') and (c3 == 't') then return -(5 * 3600) end
    if (c1 == 'm') and (c2 == 's') and (c3 == 't') then return -(7 * 3600) end
    if (c1 == 'm') and (c2 == 'd') and (c3 == 't') then return -(6 * 3600) end
    if (c1 == 'p') and (c2 == 's') and (c3 == 't') then return -(8 * 3600) end
    if (c1 == 'p') and (c2 == 'd') and (c3 == 't') then return -(7 * 3600) end
    0  // Unknown alphabetic obs-zone → +0000 per RFC 5322 §4.3.

  fun _dow_abbrev(d: DayOfWeek): String val =>
    match d
    | Sunday => "Sun"
    | Monday => "Mon"
    | Tuesday => "Tue"
    | Wednesday => "Wed"
    | Thursday => "Thu"
    | Friday => "Fri"
    | Saturday => "Sat"
    end

  fun _month_abbrev(m: U8): String val =>
    match m
    | 1 => "Jan"
    | 2 => "Feb"
    | 3 => "Mar"
    | 4 => "Apr"
    | 5 => "May"
    | 6 => "Jun"
    | 7 => "Jul"
    | 8 => "Aug"
    | 9 => "Sep"
    | 10 => "Oct"
    | 11 => "Nov"
    | 12 => "Dec"
    else "???"  // Unreachable for any Date that survived validation.
    end

  fun _format_offset_4digit(offset_sec: I32): String val =>
    let abs_sec: I32 = if offset_sec < 0 then -offset_sec else offset_sec end
    let hours: I32 = abs_sec / 3600
    let mins: I32 = (abs_sec - (hours * 3600)) / 60
    let h_str = hours.string()
    let m_str = mins.string()
    recover val
      let buf = String(5)
      buf.push(if offset_sec < 0 then '-' else '+' end)
      if hours < 10 then buf.push('0') end
      buf.append(consume h_str)
      if mins < 10 then buf.push('0') end
      buf.append(consume m_str)
      buf
    end

  fun _is_letter(c: U8): Bool =>
    ((c >= 'A') and (c <= 'Z')) or ((c >= 'a') and (c <= 'z'))

  fun _to_lower(c: U8): U8 =>
    if (c >= 'A') and (c <= 'Z') then
      c + 32
    else
      c
    end

  fun is_digit(c: U8): Bool => (c >= '0') and (c <= '9')


// Internal byte-by-byte parser state shared by Rfc3339 and Iso8601.

class ref _ParseState
  let _s: String val
  var _i: USize

  new ref create(s: String val) =>
    _s = s
    _i = 0

  fun box eof(): Bool => _i >= _s.size()

  fun box peek(): U8 ? =>
    _s(_i)?

  fun ref byte(): U8 ? =>
    let b = _s(_i)?
    _i = _i + 1
    b

  fun ref expect(b: U8) ? =>
    if byte()? != b then error end

  fun ref read_digits(n: USize): I64 ? =>
    if (_i + n) > _s.size() then error end
    var v: I64 = 0
    var k: USize = 0
    while k < n do
      let c = _s(_i)?
      if (c < '0') or (c > '9') then error end
      v = (v * 10) + (c - '0').i64()
      _i = _i + 1
      k = k + 1
    end
    v


// Parse error vocabulary.

primitive ParseMalformed
  """Input doesn't match the expected grammar at all."""

class val ParseInvalidDate
  """Right shape but Y/M/D values aren't a valid date (e.g. Feb 30)."""
  let _at_byte: USize
  new val create(at_byte': USize) => _at_byte = at_byte'
  fun val at_byte(): USize => _at_byte

class val ParseInvalidTime
  """Right shape but H/M/S values out of range."""
  let _at_byte: USize
  new val create(at_byte': USize) => _at_byte = at_byte'
  fun val at_byte(): USize => _at_byte

class val ParseInvalidOffset
  """Offset suffix malformed or out of -23:59..+23:59."""
  let _at_byte: USize
  new val create(at_byte': USize) => _at_byte = at_byte'
  fun val at_byte(): USize => _at_byte

class val ParseInvalidFractional
  """Fractional-seconds part malformed."""
  let _at_byte: USize
  new val create(at_byte': USize) => _at_byte = at_byte'
  fun val at_byte(): USize => _at_byte

primitive ParseUnexpectedEnd
  """Input ended before parser had what it needed."""

primitive ParseTrailingGarbage
  """Extra data after a valid timestamp."""

primitive ParseZoneNotFound
  """ISO 8601 lenient: fallback zone name isn't in the bundled tzdata."""

type ParseError is
  ( ParseMalformed
  | ParseInvalidDate
  | ParseInvalidTime
  | ParseInvalidOffset
  | ParseInvalidFractional
  | ParseUnexpectedEnd
  | ParseTrailingGarbage
  | ParseZoneNotFound
  )
