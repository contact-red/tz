// Math shared between WeekdayIter, MonthlyIter, and IntervalIter:
// local-to-UTC conversion in a zone, and POSIX-tuple comparison. Lives
// in its own file because both `weekday_recurrence.pony` and
// `monthly_recurrence.pony` call into it, and we don't want either to
// be the "host" file for shared math.

primitive _RecurrenceMath
  fun local_to_utc_in_zone(
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

  fun posix_gt(a: (I64, I64), b: (I64, I64)): Bool =>
    if a._1 > b._1 then true
    elseif a._1 < b._1 then false
    else a._2 > b._2 end
