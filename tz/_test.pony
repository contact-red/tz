use "pony_test"


actor \nodoc\ Main is TestList
  new create(env: Env) =>
    PonyTest(env, this)

  new make() =>
    None

  fun tag tests(test: PonyTest) =>
    test(_TestDateLeapYear)
    test(_TestDateDaysInMonth)
    test(_TestDateDayOfWeek)
    test(_TestDateDayOfYear)
    test(_TestDateDaysSinceEpoch)
    test(_TestDateAddDays)
    test(_TestDateAddMonthsClamp)
    test(_TestDateAddMonthsReject)
    test(_TestDateAddMonthsNegative)
    test(_TestDateCompare)
    test(_TestDateString)
    test(_TestDateInvalid)
    test(_TestTodConstants)
    test(_TestTodInvalid)
    test(_TestTodTotalNanosRoundTrip)
    test(_TestTodCompare)
    test(_TestTodAddNanos)
    test(_TestTodString)
    test(_TestPeriodConstructors)
    test(_TestPeriodZero)
    test(_TestPeriodEq)
    test(_TestPeriodNeg)
    test(_TestPeriodAdd)
    test(_TestPeriodSub)
    test(_TestPeriodMul)
    test(_TestPeriodString)
    test(_TestZdtFromPosix)
    test(_TestZdtFromPosixAtOffsetSameDay)
    test(_TestZdtFromPosixAtOffsetCrossDay)
    test(_TestZdtFromPosixAtOffsetSubHour)
    test(_TestZdtOffsetAbbreviation)
    test(_TestZdtToTimezoneUtc)
    test(_TestZdtToTimezoneError)
    test(_TestZdtToTimezoneInPlace)
    test(_TestZdtClone)
    test(_TestZdtResetTo)
    test(_TestZdtKindAndZoneName)
    test(_TestZdtString)
    test(_TestZdtStringSubSecond)
    test(_TestRfc3339ParseBasic)
    test(_TestRfc3339ParseSubSecond)
    test(_TestRfc3339RoundTrip)
    test(_TestRfc3339ParseInvalid)
    test(_TestRfc3339ParseInPlace)
    test(_TestIso8601Lenient)
    test(_TestRfc2822ParseBasic)
    test(_TestRfc2822ParseVariants)
    test(_TestRfc2822ParseObsoleteZones)
    test(_TestRfc2822Format)
    test(_TestRfc2822RoundTrip)
    test(_TestRfc2822ParseInvalid)
    test(_TestCronWeekdaySameDayAhead)
    test(_TestCronWeekdaySameDayPast)
    test(_TestCronWeekdayAcrossWeek)
    test(_TestCronWeekdayWeekdaySet)
    test(_TestCronWeekdayEmpty)
    test(_TestCronMonthlyDayOfMonth)
    test(_TestCronMonthlyClamp)
    test(_TestCronMonthlyLastDay)
    test(_TestCronMonthlyLastWeekday)
    test(_TestCronIntervalIntraday)
    test(_TestCronIntervalCalendarUnsupported)
    test(_TestCronUnknownZone)
    test(_TestMonthlyIterPreferredDay)
    test(_TestMonthlyIterStickyError)
    test(_TestMonthlyIterFreshSeries)
    test(_TestWeekdayIterSuccessive)
    test(_TestWeekdayIterSkipsWeekends)
    test(_TestWeekdayIterStickyError)
    test(_TestIntervalIterSuccessive)
    test(_TestIntervalIterStickyCalendar)
    test(_TestIntervalIterStickyZone)
    test(_TestZoneNyWinter)
    test(_TestZoneNySummer)
    test(_TestZoneNyTransitions)
    test(_TestZoneLaSummerWinter)
    test(_TestZoneToTimezone)
    test(_TestDateHistoricalRange)
    test(_TestZdtFloorModHistorical)
    test(_TestZdtStringHistorical)
    test(_TestZdumpDifferentialUtc)
    test(_TestZdumpDifferentialNy)
    test(_TestZdumpDifferentialLa)
    test(_TestZdumpDifferentialLondon)
    test(_TestZdumpDifferentialPosixFallback)
    test(_TestZdumpDifferentialUnknownZone)
    test(_TestZdumpDifferentialTokyoNoDst)
    test(_TestZdumpDifferentialKolkataHalfHour)
    test(_TestZdumpDifferentialAucklandSouthernHemi)
    test(_TestZdumpDifferentialHistoricalGate)
    test(_TestZdumpDifferentialLordHowe30Min)
    test(_TestZdumpDifferentialChatham)
    test(_TestZdumpDifferentialIndianapolis2006Switch)
    test(_TestZdumpDifferentialPyongyangSameNameOffsetShift)
    test(_TestZdumpDifferentialAliasRoutesToCanonical)


class iso _TestDateLeapYear is UnitTest
  fun name(): String => "Date/is_leap_year"
  fun apply(h: TestHelper) ? =>
    // Divisible by 4 but not 100 → leap.
    h.assert_true(Date(2024, 1, 1)?.is_leap_year(), "2024")
    // Divisible by 400 → leap (century exception's exception).
    h.assert_true(Date(2000, 1, 1)?.is_leap_year(), "2000")
    // Divisible by 100 but not 400 → not leap.
    h.assert_false(Date(2100, 1, 1)?.is_leap_year(), "2100")
    h.assert_false(Date(2200, 1, 1)?.is_leap_year(), "2200")
    h.assert_false(Date(2300, 1, 1)?.is_leap_year(), "2300")
    h.assert_true(Date(2400, 1, 1)?.is_leap_year(), "2400")
    // Not divisible by 4 → not leap.
    h.assert_false(Date(2026, 1, 1)?.is_leap_year(), "2026")
    h.assert_false(Date(1970, 1, 1)?.is_leap_year(), "1970")


class iso _TestDateDaysInMonth is UnitTest
  fun name(): String => "Date/days_in_month"
  fun apply(h: TestHelper) ? =>
    // 31-day months.
    h.assert_eq[U8](31, Date(2026, 1, 1)?.days_in_month(), "Jan")
    h.assert_eq[U8](31, Date(2026, 3, 1)?.days_in_month(), "Mar")
    h.assert_eq[U8](31, Date(2026, 12, 1)?.days_in_month(), "Dec")
    // 30-day months.
    h.assert_eq[U8](30, Date(2026, 4, 1)?.days_in_month(), "Apr")
    h.assert_eq[U8](30, Date(2026, 11, 1)?.days_in_month(), "Nov")
    // February varies with leap year.
    h.assert_eq[U8](28, Date(2026, 2, 1)?.days_in_month(), "Feb 2026")
    h.assert_eq[U8](29, Date(2024, 2, 1)?.days_in_month(), "Feb 2024")
    h.assert_eq[U8](29, Date(2000, 2, 1)?.days_in_month(), "Feb 2000")
    h.assert_eq[U8](28, Date(2100, 2, 1)?.days_in_month(), "Feb 2100")


class iso _TestDateDayOfWeek is UnitTest
  fun name(): String => "Date/day_of_week"
  fun apply(h: TestHelper) ? =>
    // Unix epoch is a Thursday — universally known.
    h.assert_true(Date(1970, 1, 1)?.day_of_week() is Thursday, "epoch")
    // 2000-01-01 was a Saturday.
    h.assert_true(Date(2000, 1, 1)?.day_of_week() is Saturday, "Y2K")
    // 2024-01-01 was a Monday.
    h.assert_true(Date(2024, 1, 1)?.day_of_week() is Monday, "2024 New Year")
    // 2026-05-24 — Sunday per the system date earlier in this session.
    h.assert_true(Date(2026, 5, 24)?.day_of_week() is Sunday, "today")


class iso _TestDateDayOfYear is UnitTest
  fun name(): String => "Date/day_of_year"
  fun apply(h: TestHelper) ? =>
    h.assert_eq[U16](1, Date(2026, 1, 1)?.day_of_year(), "Jan 1")
    h.assert_eq[U16](32, Date(2026, 2, 1)?.day_of_year(), "Feb 1 non-leap")
    h.assert_eq[U16](60, Date(2026, 3, 1)?.day_of_year(), "Mar 1 non-leap")
    h.assert_eq[U16](60, Date(2024, 2, 29)?.day_of_year(), "Feb 29 leap")
    h.assert_eq[U16](61, Date(2024, 3, 1)?.day_of_year(), "Mar 1 leap")
    h.assert_eq[U16](365, Date(2026, 12, 31)?.day_of_year(), "Dec 31 non-leap")
    h.assert_eq[U16](366, Date(2024, 12, 31)?.day_of_year(), "Dec 31 leap")


class iso _TestDateDaysSinceEpoch is UnitTest
  fun name(): String => "Date/days_since_epoch"
  fun apply(h: TestHelper) ? =>
    h.assert_eq[I32](0, Date(1970, 1, 1)?.days_since_epoch(), "epoch")
    h.assert_eq[I32](1, Date(1970, 1, 2)?.days_since_epoch(), "epoch+1")
    h.assert_eq[I32](31, Date(1970, 2, 1)?.days_since_epoch(), "epoch+Jan")
    h.assert_eq[I32](365, Date(1971, 1, 1)?.days_since_epoch(), "+1y non-leap")
    // 1972 was a leap year, so 1970→1972 is 365+365 = 730 days.
    h.assert_eq[I32](730, Date(1972, 1, 1)?.days_since_epoch(), "+2y")


class iso _TestDateAddDays is UnitTest
  fun name(): String => "Date/add_days"
  fun apply(h: TestHelper) ? =>
    let epoch = Date(1970, 1, 1)?
    h.assert_true((epoch.add_days(0) as Date).eq(epoch), "no-op")
    h.assert_true((epoch.add_days(1) as Date).eq(Date(1970, 1, 2)?), "+1")
    h.assert_true((epoch.add_days(365) as Date).eq(Date(1971, 1, 1)?), "+365")
    // Crossing Feb 28 in a leap year.
    h.assert_true(
      (Date(2024, 2, 28)?.add_days(1) as Date).eq(Date(2024, 2, 29)?),
      "Feb 28 → Feb 29 leap")
    h.assert_true(
      (Date(2024, 2, 28)?.add_days(2) as Date).eq(Date(2024, 3, 1)?),
      "Feb 28 → Mar 1 leap")
    // Crossing Feb 28 in a non-leap year — no Feb 29.
    h.assert_true(
      (Date(2026, 2, 28)?.add_days(1) as Date).eq(Date(2026, 3, 1)?),
      "Feb 28 → Mar 1 non-leap")
    // Negative.
    h.assert_true(
      (Date(2026, 5, 24)?.add_days(-1) as Date).eq(Date(2026, 5, 23)?),
      "−1")
    h.assert_true(
      (Date(1970, 1, 2)?.add_days(-1) as Date).eq(epoch),
      "back to epoch")


class iso _TestDateAddMonthsClamp is UnitTest
  fun name(): String => "Date/add_months OverflowClamp"
  fun apply(h: TestHelper) ? =>
    // Jan 31 + 1 month: Feb 28 (or 29 in leap year).
    h.assert_true(
      (Date(2026, 1, 31)?.add_months(1, OverflowClamp) as Date).eq(Date(2026, 2, 28)?),
      "Jan 31 → Feb 28 non-leap")
    h.assert_true(
      (Date(2024, 1, 31)?.add_months(1, OverflowClamp) as Date).eq(Date(2024, 2, 29)?),
      "Jan 31 → Feb 29 leap")
    // Mar 31 + 1 month: Apr 30 (only 30 days).
    h.assert_true(
      (Date(2026, 3, 31)?.add_months(1, OverflowClamp) as Date).eq(Date(2026, 4, 30)?),
      "Mar 31 → Apr 30")
    // Year boundary.
    h.assert_true(
      (Date(2026, 12, 31)?.add_months(1, OverflowClamp) as Date).eq(Date(2027, 1, 31)?),
      "Dec 31 + 1 → next Jan 31")
    // No clamping needed.
    h.assert_true(
      (Date(2026, 5, 15)?.add_months(1, OverflowClamp) as Date).eq(Date(2026, 6, 15)?),
      "May 15 → Jun 15")


class iso _TestDateAddMonthsReject is UnitTest
  fun name(): String => "Date/add_months OverflowReject"
  fun apply(h: TestHelper) ? =>
    // Jan 31 + 1 month with reject policy: error variant.
    match Date(2026, 1, 31)?.add_months(1, OverflowReject)
    | ArithmeticPolicyReject => None  // Expected.
    | let d: Date val =>
      h.fail("Expected ArithmeticPolicyReject, got " + d.string())
    | let e: ArithmeticError =>
      h.fail("Expected ArithmeticPolicyReject, got other ArithmeticError")
    end
    // Non-clamping case still succeeds with reject policy.
    h.assert_true(
      (Date(2026, 5, 15)?.add_months(1, OverflowReject) as Date).eq(Date(2026, 6, 15)?),
      "May 15 → Jun 15 doesn't trip reject")


class iso _TestDateAddMonthsNegative is UnitTest
  fun name(): String => "Date/add_months with negative n"
  fun apply(h: TestHelper) ? =>
    h.assert_true(
      (Date(2026, 5, 24)?.add_months(-1, OverflowClamp) as Date).eq(Date(2026, 4, 24)?),
      "−1 same year")
    h.assert_true(
      (Date(2026, 1, 24)?.add_months(-1, OverflowClamp) as Date).eq(Date(2025, 12, 24)?),
      "−1 across year")
    h.assert_true(
      (Date(2026, 1, 24)?.add_months(-13, OverflowClamp) as Date).eq(Date(2024, 12, 24)?),
      "−13 spans 2 years")
    // Negative clamping: Mar 31 − 1 month → Feb 28 (or 29).
    h.assert_true(
      (Date(2026, 3, 31)?.add_months(-1, OverflowClamp) as Date).eq(Date(2026, 2, 28)?),
      "Mar 31 → Feb 28 non-leap")


class iso _TestDateCompare is UnitTest
  fun name(): String => "Date/compare"
  fun apply(h: TestHelper) ? =>
    let a = Date(2026, 5, 24)?
    let b = Date(2026, 5, 24)?
    let earlier = Date(2026, 5, 23)?
    let next_month = Date(2026, 6, 1)?
    let next_year = Date(2027, 1, 1)?

    h.assert_true(a.eq(b), "eq same")
    h.assert_false(a.ne(b), "ne same")
    h.assert_true(earlier.lt(a), "earlier < a")
    h.assert_true(a.gt(earlier), "a > earlier")
    h.assert_true(a.le(b), "a ≤ b (equal)")
    h.assert_true(a.ge(b), "a ≥ b (equal)")
    h.assert_true(a.lt(next_month), "a < next month")
    h.assert_true(a.lt(next_year), "a < next year")
    h.assert_true(a.compare(b) is Equal, "compare Equal")
    h.assert_true(earlier.compare(a) is Less, "compare Less")
    h.assert_true(next_month.compare(a) is Greater, "compare Greater")


class iso _TestDateString is UnitTest
  fun name(): String => "Date/string"
  fun apply(h: TestHelper) ? =>
    h.assert_eq[String]("2026-05-24", Date(2026, 5, 24)?.string())
    h.assert_eq[String]("1970-01-01", Date(1970, 1, 1)?.string())
    h.assert_eq[String]("9999-12-31", Date(9999, 12, 31)?.string())
    h.assert_eq[String]("2024-02-29", Date(2024, 2, 29)?.string())


class iso _TestDateInvalid is UnitTest
  fun name(): String => "Date/create rejects invalid dates"
  fun apply(h: TestHelper) =>
    // Lower year bound depends on -D HISTORICAL_TZ.
    ifdef "HISTORICAL_TZ" then
      h.assert_error({() ? => Date(0, 1, 1)? }, "year 0 below historical min")
    else
      h.assert_error({() ? => Date(1969, 1, 1)? }, "1969 below default min")
    end
    // Year too high (same in both modes).
    h.assert_error({() ? => Date(10000, 1, 1)? }, "10000 above max")
    // Month out of range.
    h.assert_error({() ? => Date(2026, 0, 1)? }, "month 0")
    h.assert_error({() ? => Date(2026, 13, 1)? }, "month 13")
    // Day out of range for month.
    h.assert_error({() ? => Date(2026, 2, 30)? }, "Feb 30")
    h.assert_error({() ? => Date(2026, 2, 29)? }, "Feb 29 non-leap")
    h.assert_error({() ? => Date(2026, 4, 31)? }, "Apr 31")
    h.assert_error({() ? => Date(2026, 1, 32)? }, "Jan 32")
    h.assert_error({() ? => Date(2026, 1, 0)? }, "Jan 0")


// ----- TimeOfDay -----


class iso _TestTodConstants is UnitTest
  fun name(): String => "TimeOfDay/midnight + noon"
  fun apply(h: TestHelper) =>
    let mn = TimeOfDay.midnight()
    h.assert_eq[U8](0, mn.hour())
    h.assert_eq[U8](0, mn.minute())
    h.assert_eq[U8](0, mn.second())
    h.assert_eq[I32](0, mn.nano())
    h.assert_eq[I64](0, mn.total_nanos())

    let n = TimeOfDay.noon()
    h.assert_eq[U8](12, n.hour())
    h.assert_eq[U8](0, n.minute())
    h.assert_eq[U8](0, n.second())
    h.assert_eq[I32](0, n.nano())
    h.assert_eq[I64](43_200_000_000_000, n.total_nanos())


class iso _TestTodInvalid is UnitTest
  fun name(): String => "TimeOfDay/create rejects invalid"
  fun apply(h: TestHelper) =>
    h.assert_error({() ? => TimeOfDay(24, 0, 0)? }, "hour 24")
    h.assert_error({() ? => TimeOfDay(0, 60, 0)? }, "minute 60")
    h.assert_error({() ? => TimeOfDay(0, 0, 60)? }, "second 60")
    h.assert_error({() ? => TimeOfDay(0, 0, 0, -1)? }, "negative nano")
    h.assert_error({() ? => TimeOfDay(0, 0, 0, 1_000_000_000)? }, "nano overflow")

    h.assert_error({() ? => TimeOfDay.from_total_nanos(-1)? }, "negative total")
    h.assert_error(
      {() ? => TimeOfDay.from_total_nanos(86_400_000_000_000)? },
      "total == day boundary")


class iso _TestTodTotalNanosRoundTrip is UnitTest
  fun name(): String => "TimeOfDay/total_nanos round-trip"
  fun apply(h: TestHelper) ? =>
    // A few representative times.
    let cases: Array[TimeOfDay val] val = recover val
      [
        TimeOfDay(0, 0, 0)?
        TimeOfDay(0, 0, 0, 1)?
        TimeOfDay(0, 0, 1)?
        TimeOfDay(0, 1, 0)?
        TimeOfDay(1, 0, 0)?
        TimeOfDay(12, 0, 0)?
        TimeOfDay(23, 59, 59, 999_999_999)?
        TimeOfDay(9, 30, 15, 250_000_000)?
      ]
    end
    for tod in cases.values() do
      let n = tod.total_nanos()
      let round_tripped = TimeOfDay.from_total_nanos(n)?
      h.assert_true(tod.eq(round_tripped),
        "round-trip " + tod.string() + " via " + n.string())
    end


class iso _TestTodCompare is UnitTest
  fun name(): String => "TimeOfDay/compare"
  fun apply(h: TestHelper) ? =>
    let a = TimeOfDay(9, 30, 0)?
    let b = TimeOfDay(9, 30, 0)?
    let earlier = TimeOfDay(9, 29, 59)?
    let later_nano = TimeOfDay(9, 30, 0, 1)?
    let next_hour = TimeOfDay(10, 0, 0)?

    h.assert_true(a.eq(b), "eq")
    h.assert_true(a.compare(b) is Equal, "compare Equal")
    h.assert_true(earlier.lt(a), "earlier < a")
    h.assert_true(a.lt(later_nano), "sub-second resolution")
    h.assert_true(a.lt(next_hour), "a < next hour")
    h.assert_true(a.ge(b), "ge equal")
    h.assert_true(a.le(b), "le equal")
    h.assert_true(next_hour.gt(a), "next hour > a")


class iso _TestTodAddNanos is UnitTest
  fun name(): String => "TimeOfDay/add_nanos"
  fun apply(h: TestHelper) ? =>
    let nine = TimeOfDay(9, 0, 0)?

    // No wrap.
    (let r1, let d1) = nine.add_nanos(60 * 1_000_000_000)
    h.assert_true(r1.eq(TimeOfDay(9, 1, 0)?), "+1 min: time")
    h.assert_eq[I32](0, d1, "+1 min: no overflow")

    // Forward across midnight: 23:00 + 2h → 01:00, +1 day.
    let eleven_pm = TimeOfDay(23, 0, 0)?
    (let r2, let d2) = eleven_pm.add_nanos(2 * 3_600_000_000_000)
    h.assert_true(r2.eq(TimeOfDay(1, 0, 0)?), "23:00 + 2h: time")
    h.assert_eq[I32](1, d2, "23:00 + 2h: +1 day")

    // Backward across midnight: 01:00 + (−2h) → 23:00, −1 day.
    let one_am = TimeOfDay(1, 0, 0)?
    (let r3, let d3) = one_am.add_nanos(-(2 * 3_600_000_000_000))
    h.assert_true(r3.eq(TimeOfDay(23, 0, 0)?), "01:00 − 2h: time")
    h.assert_eq[I32](-1, d3, "01:00 − 2h: −1 day")

    // Multi-day forward: midnight + 50 hours → 02:00, +2 days.
    let mn = TimeOfDay.midnight()
    (let r4, let d4) = mn.add_nanos(50 * 3_600_000_000_000)
    h.assert_true(r4.eq(TimeOfDay(2, 0, 0)?), "+50h: time")
    h.assert_eq[I32](2, d4, "+50h: +2 days")

    // Exact day boundary: midnight + 24h → midnight, +1 day.
    (let r5, let d5) = mn.add_nanos(24 * 3_600_000_000_000)
    h.assert_true(r5.eq(mn), "+24h: time wraps to midnight")
    h.assert_eq[I32](1, d5, "+24h: +1 day")

    // Sub-second precision survives wrap.
    let almost_end = TimeOfDay(23, 59, 59, 999_999_999)?
    (let r6, let d6) = almost_end.add_nanos(1)
    h.assert_true(r6.eq(mn), "23:59:59.999999999 + 1ns: midnight")
    h.assert_eq[I32](1, d6, "23:59:59.999999999 + 1ns: +1 day")


class iso _TestTodString is UnitTest
  fun name(): String => "TimeOfDay/string"
  fun apply(h: TestHelper) ? =>
    // No fractional → HH:MM:SS only.
    h.assert_eq[String]("00:00:00", TimeOfDay.midnight().string())
    h.assert_eq[String]("12:00:00", TimeOfDay.noon().string())
    h.assert_eq[String]("09:30:00", TimeOfDay(9, 30, 0)?.string())
    h.assert_eq[String]("23:59:59", TimeOfDay(23, 59, 59)?.string())
    // With fractional → HH:MM:SS.nnnnnnnnn (9-digit zero-padded).
    h.assert_eq[String]("09:30:00.000000001", TimeOfDay(9, 30, 0, 1)?.string())
    h.assert_eq[String]("12:00:00.500000000", TimeOfDay(12, 0, 0, 500_000_000)?.string())
    h.assert_eq[String]("23:59:59.999999999",
      TimeOfDay(23, 59, 59, 999_999_999)?.string())


// ----- Period -----


class iso _TestPeriodConstructors is UnitTest
  fun name(): String => "Period/constructors"
  fun apply(h: TestHelper) =>
    let z = Period.zero()
    h.assert_eq[I32](0, z.months())
    h.assert_eq[I32](0, z.days())
    h.assert_eq[I64](0, z.nanos())

    let one_month = Period.of_months(1)
    h.assert_eq[I32](1, one_month.months())
    h.assert_eq[I32](0, one_month.days())
    h.assert_eq[I64](0, one_month.nanos())

    let three_days = Period.of_days(3)
    h.assert_eq[I32](3, three_days.days())

    let two_hours = Period.of_hours(2)
    h.assert_eq[I64](2 * 3_600_000_000_000, two_hours.nanos())

    let ninety_minutes = Period.of_minutes(90)
    h.assert_eq[I64](90 * 60_000_000_000, ninety_minutes.nanos())

    let half_sec = Period.of_seconds(1)
    h.assert_eq[I64](1_000_000_000, half_sec.nanos())

    let one_ns = Period.of_nanos(1)
    h.assert_eq[I64](1, one_ns.nanos())

    let composite = Period(1, 2, 3_000_000_000)
    h.assert_eq[I32](1, composite.months())
    h.assert_eq[I32](2, composite.days())
    h.assert_eq[I64](3_000_000_000, composite.nanos())


class iso _TestPeriodZero is UnitTest
  fun name(): String => "Period/is_zero"
  fun apply(h: TestHelper) =>
    h.assert_true(Period.zero().is_zero(), "zero")
    h.assert_true(Period(0, 0, 0).is_zero(), "explicit zero")
    h.assert_false(Period.of_months(1).is_zero(), "1 month")
    h.assert_false(Period.of_days(1).is_zero(), "1 day")
    h.assert_false(Period.of_nanos(1).is_zero(), "1 ns")
    h.assert_false(Period(-1, 0, 0).is_zero(), "negative month")


class iso _TestPeriodEq is UnitTest
  fun name(): String => "Period/eq + ne"
  fun apply(h: TestHelper) =>
    let p1 = Period(1, 2, 3_000_000_000)
    let p2 = Period(1, 2, 3_000_000_000)
    let p3 = Period(1, 2, 3_000_000_001)   // different by 1 ns

    h.assert_true(p1.eq(p2), "identical")
    h.assert_false(p1.ne(p2), "ne identical")
    h.assert_false(p1.eq(p3), "differ by ns")
    h.assert_true(p1.ne(p3), "ne differ")

    // Reflexivity.
    h.assert_true(Period.zero().eq(Period.zero()), "zero == zero")
    h.assert_true(Period.zero().eq(Period(0, 0, 0)), "zero == explicit")


class iso _TestPeriodNeg is UnitTest
  fun name(): String => "Period/neg"
  fun apply(h: TestHelper) =>
    h.assert_true(Period.zero().neg().is_zero(), "−zero = zero")

    let p = Period(1, -2, 3)
    let n = p.neg()
    h.assert_eq[I32](-1, n.months())
    h.assert_eq[I32](2, n.days())
    h.assert_eq[I64](-3, n.nanos())

    // Double-negate is identity.
    h.assert_true(p.eq(p.neg().neg()), "neg.neg = id")


class iso _TestPeriodAdd is UnitTest
  fun name(): String => "Period/add"
  fun apply(h: TestHelper) =>
    let a = Period(1, 2, 3_000_000_000)
    let b = Period(10, 20, 30_000_000_000)
    let sum = a.add(b)
    h.assert_eq[I32](11, sum.months())
    h.assert_eq[I32](22, sum.days())
    h.assert_eq[I64](33_000_000_000, sum.nanos())

    // Identity: + zero.
    h.assert_true(a.add(Period.zero()).eq(a), "a + 0 = a")
    h.assert_true(Period.zero().add(a).eq(a), "0 + a = a")

    // Mixed signs.
    let c = Period(-1, 2, 0)
    let d = Period(1, -2, 0)
    h.assert_true(c.add(d).is_zero(), "c + (−c) = 0")


class iso _TestPeriodSub is UnitTest
  fun name(): String => "Period/sub"
  fun apply(h: TestHelper) =>
    let a = Period(10, 20, 30_000_000_000)
    let b = Period(1, 2, 3_000_000_000)
    let diff = a.sub(b)
    h.assert_eq[I32](9, diff.months())
    h.assert_eq[I32](18, diff.days())
    h.assert_eq[I64](27_000_000_000, diff.nanos())

    // Subtracting self yields zero.
    h.assert_true(a.sub(a).is_zero(), "a − a = 0")

    // sub via add+neg agreement.
    h.assert_true(a.sub(b).eq(a.add(b.neg())), "a − b = a + (−b)")


class iso _TestPeriodMul is UnitTest
  fun name(): String => "Period/mul"
  fun apply(h: TestHelper) =>
    let p = Period(1, 2, 3_000_000_000)

    h.assert_true(p.mul(0).is_zero(), "p × 0 = 0")
    h.assert_true(p.mul(1).eq(p), "p × 1 = p")

    let triple = p.mul(3)
    h.assert_eq[I32](3, triple.months())
    h.assert_eq[I32](6, triple.days())
    h.assert_eq[I64](9_000_000_000, triple.nanos())

    let neg = p.mul(-1)
    h.assert_true(neg.eq(p.neg()), "× −1 = neg")

    let neg_two = p.mul(-2)
    h.assert_eq[I32](-2, neg_two.months())
    h.assert_eq[I32](-4, neg_two.days())
    h.assert_eq[I64](-6_000_000_000, neg_two.nanos())


class iso _TestPeriodString is UnitTest
  fun name(): String => "Period/string"
  fun apply(h: TestHelper) =>
    h.assert_eq[String](
      "Period(months=0, days=0, nanos=0)",
      Period.zero().string())
    h.assert_eq[String](
      "Period(months=1, days=2, nanos=3000000000)",
      Period(1, 2, 3_000_000_000).string())
    h.assert_eq[String](
      "Period(months=-1, days=0, nanos=0)",
      Period.of_months(-1).string())


// ----- ZonedDateTime -----


primitive _DateTimeMath
  // Test helper: build a POSIX seconds value from civil fields, in UTC.
  fun utc_posix_sec(y: I16, mo: U8, d: U8, h: U8, mi: U8, s: U8): I64 ? =>
    let days = Date(y, mo, d)?.days_since_epoch().i64()
    let secs_of_day: I64 = ((h.i64() * 3600) + (mi.i64() * 60)) + s.i64()
    (days * 86400) + secs_of_day


class iso _TestZdtFromPosix is UnitTest
  fun name(): String => "ZonedDateTime/from_posix UTC"
  fun apply(h: TestHelper) ? =>
    // Epoch.
    let epoch = ZonedDateTime.from_posix((0, 0))
    h.assert_true(epoch.local_date().eq(Date(1970, 1, 1)?), "epoch date")
    h.assert_true(epoch.local_tod().eq(TimeOfDay.midnight()), "epoch tod")
    h.assert_eq[I32](0, epoch.offset_sec(), "epoch offset")
    h.assert_eq[String]("UTC", epoch.abbreviation(), "epoch abbrev")
    h.assert_eq[String]("UTC", epoch.zone_name(), "epoch zone_name")
    h.assert_false(epoch.is_dst(), "epoch is_dst")

    // 2026-05-25T12:00:00 UTC.
    let p = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?
    let zdt = ZonedDateTime.from_posix((p, 0))
    h.assert_true(zdt.local_date().eq(Date(2026, 5, 25)?), "noon date")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(12, 0, 0)?), "noon tod")
    h.assert_eq[I64](p, zdt.to_posix()._1, "to_posix roundtrip sec")


class iso _TestZdtFromPosixAtOffsetSameDay is UnitTest
  fun name(): String => "ZonedDateTime/from_posix_at_offset same-day cases"
  fun apply(h: TestHelper) ? =>
    let noon = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?

    // Offset 0 (UTC, but Offset mode) — local 12:00, abbrev "Z".
    let z0 = ZonedDateTime.from_posix_at_offset((noon, 0), 0)
    h.assert_true(z0.local_date().eq(Date(2026, 5, 25)?), "Z date")
    h.assert_true(z0.local_tod().eq(TimeOfDay(12, 0, 0)?), "Z tod")
    h.assert_eq[String]("Z", z0.abbreviation(), "Z abbrev")
    h.assert_eq[I32](0, z0.offset_sec(), "Z offset")

    // +05:00 — local 17:00.
    let zp5 = ZonedDateTime.from_posix_at_offset((noon, 0), 5 * 3600)
    h.assert_true(zp5.local_date().eq(Date(2026, 5, 25)?), "+5h date")
    h.assert_true(zp5.local_tod().eq(TimeOfDay(17, 0, 0)?), "+5h tod")
    h.assert_eq[String]("+05:00", zp5.abbreviation(), "+5h abbrev")

    // -07:00 — local 05:00.
    let zm7 = ZonedDateTime.from_posix_at_offset((noon, 0), -(7 * 3600))
    h.assert_true(zm7.local_date().eq(Date(2026, 5, 25)?), "-7h date")
    h.assert_true(zm7.local_tod().eq(TimeOfDay(5, 0, 0)?), "-7h tod")
    h.assert_eq[String]("-07:00", zm7.abbreviation(), "-7h abbrev")


class iso _TestZdtFromPosixAtOffsetCrossDay is UnitTest
  fun name(): String => "ZonedDateTime/from_posix_at_offset day crossings"
  fun apply(h: TestHelper) ? =>
    // 01:00 UTC, offset -03:00 → 22:00 previous day.
    let one_am = _DateTimeMath.utc_posix_sec(2026, 5, 25, 1, 0, 0)?
    let back = ZonedDateTime.from_posix_at_offset((one_am, 0), -(3 * 3600))
    h.assert_true(back.local_date().eq(Date(2026, 5, 24)?), "back: prev day")
    h.assert_true(back.local_tod().eq(TimeOfDay(22, 0, 0)?), "back: 22:00")

    // 22:00 UTC, offset +05:00 → 03:00 next day.
    let ten_pm = _DateTimeMath.utc_posix_sec(2026, 5, 25, 22, 0, 0)?
    let fwd = ZonedDateTime.from_posix_at_offset((ten_pm, 0), 5 * 3600)
    h.assert_true(fwd.local_date().eq(Date(2026, 5, 26)?), "fwd: next day")
    h.assert_true(fwd.local_tod().eq(TimeOfDay(3, 0, 0)?), "fwd: 03:00")


class iso _TestZdtFromPosixAtOffsetSubHour is UnitTest
  fun name(): String => "ZonedDateTime/from_posix_at_offset sub-hour offsets"
  fun apply(h: TestHelper) ? =>
    let noon = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?

    // India: +05:30.
    let india = ZonedDateTime.from_posix_at_offset(
      (noon, 0), (5 * 3600) + (30 * 60))
    h.assert_true(india.local_tod().eq(TimeOfDay(17, 30, 0)?), "India tod")
    h.assert_eq[String]("+05:30", india.abbreviation(), "India abbrev")

    // Newfoundland: -03:30.
    let nf = ZonedDateTime.from_posix_at_offset(
      (noon, 0), -((3 * 3600) + (30 * 60)))
    h.assert_true(nf.local_tod().eq(TimeOfDay(8, 30, 0)?), "Nfld tod")
    h.assert_eq[String]("-03:30", nf.abbreviation(), "Nfld abbrev")


class iso _TestZdtOffsetAbbreviation is UnitTest
  fun name(): String => "ZonedDateTime/offset abbreviation format"
  fun apply(h: TestHelper) =>
    h.assert_eq[String]("Z",
      ZonedDateTime.from_posix_at_offset((0, 0), 0).abbreviation())
    h.assert_eq[String]("+01:00",
      ZonedDateTime.from_posix_at_offset((0, 0), 3600).abbreviation())
    h.assert_eq[String]("+14:00",
      ZonedDateTime.from_posix_at_offset((0, 0), 14 * 3600).abbreviation())
    h.assert_eq[String]("-12:00",
      ZonedDateTime.from_posix_at_offset((0, 0), -(12 * 3600)).abbreviation())
    // Sub-minute offsets get rounded for the abbreviation; precise
    // value still available via offset_sec().
    let lmt = ZonedDateTime.from_posix_at_offset((0, 0), -17762)
    h.assert_eq[I32](-17762, lmt.offset_sec(), "lmt offset")
    h.assert_eq[String]("-04:56", lmt.abbreviation(), "lmt abbrev rounded")


class iso _TestZdtToTimezoneUtc is UnitTest
  fun name(): String => "ZonedDateTime/to_timezone UTC round-trip"
  fun apply(h: TestHelper) ? =>
    let base = ZonedDateTime.from_posix((0, 0))
    match base.to_timezone("UTC")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(1970, 1, 1)?), "date kept")
      h.assert_eq[I32](0, kept.offset_sec(), "offset 0")
      h.assert_eq[String]("UTC", kept.zone_name(), "name kept")
    | let _: TzLookupError =>
      h.fail("Expected UTC to be a known zone")
    end


class iso _TestZdtToTimezoneError is UnitTest
  fun name(): String => "ZonedDateTime/to_timezone unknown zone"
  fun apply(h: TestHelper) =>
    let base = ZonedDateTime.from_posix((0, 0))
    match base.to_timezone("Atlantis/Lost_City")
    | let _: ZonedDateTime iso => h.fail("Expected ZoneNotFound")
    | ZoneNotFound => None  // Expected.
    | OutOfCoverage =>
      h.fail("Expected ZoneNotFound, got OutOfCoverage")
    end


class iso _TestZdtToTimezoneInPlace is UnitTest
  fun name(): String => "ZonedDateTime/to_timezone_in_place"
  fun apply(h: TestHelper) =>
    let zdt = ZonedDateTime.from_posix((0, 0))
    // Switch to a fake zone → fails; state unchanged.
    match zdt.to_timezone_in_place("Nowhere")
    | None => h.fail("Expected error on Nowhere")
    | ZoneNotFound => None  // Expected.
    | OutOfCoverage => h.fail("Expected ZoneNotFound, got OutOfCoverage")
    end
    h.assert_eq[String]("UTC", zdt.zone_name(), "state preserved after error")

    // Switch UTC → UTC succeeds.
    match zdt.to_timezone_in_place("UTC")
    | None => None  // Expected.
    | let _: TzLookupError => h.fail("Expected UTC to succeed")
    end


class iso _TestZdtClone is UnitTest
  fun name(): String => "ZonedDateTime/clone preserves state and is independent"
  fun apply(h: TestHelper) ? =>
    // Zone mode (UTC): every accessor matches the source.
    let utc_sec = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?
    let utc = ZonedDateTime.from_posix((utc_sec, I64(123_456)))
    let utc_clone: ZonedDateTime iso = utc.clone()
    h.assert_eq[I64](utc_sec, utc_clone.to_posix()._1, "utc: sec")
    h.assert_eq[I64](I64(123_456), utc_clone.to_posix()._2, "utc: nsec")
    h.assert_true(utc_clone.kind() is Zone, "utc: kind preserved")
    h.assert_eq[String]("UTC", utc_clone.zone_name(), "utc: name preserved")
    h.assert_true(utc_clone.local_date().eq(Date(2026, 5, 25)?), "utc: date")
    h.assert_true(utc_clone.local_tod().eq(TimeOfDay(12, 0, 0, 123_456)?),
      "utc: tod (nsec carried into local_tod)")
    h.assert_eq[I32](0, utc_clone.offset_sec(), "utc: offset 0")
    h.assert_eq[String]("UTC", utc_clone.abbreviation(), "utc: abbrev")
    h.assert_eq[Bool](false, utc_clone.is_dst(), "utc: not DST")

    // Offset mode: kind and offset survive; tzdata isn't consulted.
    let off = ZonedDateTime.from_posix_at_offset((utc_sec, 0), 5 * 3600)
    let off_clone: ZonedDateTime iso = off.clone()
    h.assert_true(off_clone.kind() is Offset, "offset: kind preserved")
    h.assert_eq[String]("", off_clone.zone_name(), "offset: empty name")
    h.assert_eq[I32](5 * 3600, off_clone.offset_sec(), "offset: +5h preserved")
    h.assert_true(off_clone.local_tod().eq(TimeOfDay(17, 0, 0)?),
      "offset: noon + 5h")

    // IANA zone in summer: clone preserves DST flag and abbreviation.
    let ny_sec = _DateTimeMath.utc_posix_sec(2026, 7, 4, 16, 0, 0)?
    let ny =
      try
        ZonedDateTime.from_posix_in_zone((ny_sec, 0), "America/New_York")?
      else
        h.fail("America/New_York should resolve")
        return
      end
    let ny_clone: ZonedDateTime iso = ny.clone()
    h.assert_eq[String]("America/New_York", ny_clone.zone_name(),
      "iana: name preserved")
    h.assert_eq[I32](ny.offset_sec(), ny_clone.offset_sec(), "iana: offset")
    h.assert_eq[String](ny.abbreviation(), ny_clone.abbreviation(),
      "iana: abbreviation preserved")
    h.assert_eq[Bool](ny.is_dst(), ny_clone.is_dst(), "iana: DST flag")

    // Independence: mutating the source via reset_to leaves the clone alone.
    let base = ZonedDateTime.from_posix((utc_sec, 0))
    let snapshot: ZonedDateTime iso = base.clone()
    match base.reset_to(
      (_DateTimeMath.utc_posix_sec(2027, 1, 1, 0, 0, 0)?, 0))
    | None => None
    | let _: TzLookupError => h.fail("UTC reset shouldn't fail")
    end
    h.assert_eq[I64](utc_sec, snapshot.to_posix()._1,
      "snapshot sec unchanged after base reset")
    h.assert_true(snapshot.local_date().eq(Date(2026, 5, 25)?),
      "snapshot date still 2026-05-25")
    h.assert_true(base.local_date().eq(Date(2027, 1, 1)?),
      "base advanced to 2027-01-01")


class iso _TestZdtResetTo is UnitTest
  fun name(): String => "ZonedDateTime/reset_to"
  fun apply(h: TestHelper) ? =>
    let zdt = ZonedDateTime.from_posix((0, 0))
    // Advance to noon 2026-05-25.
    let noon = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?
    match zdt.reset_to((noon, 0))
    | None => None
    | let _: TzLookupError => h.fail("UTC reset shouldn't fail")
    end
    h.assert_true(zdt.local_date().eq(Date(2026, 5, 25)?), "date updated")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(12, 0, 0)?), "tod updated")
    h.assert_eq[I64](noon, zdt.to_posix()._1, "posix updated")

    // Offset-mode reset: local fields recompute, offset stays put.
    let off = ZonedDateTime.from_posix_at_offset((0, 0), 5 * 3600)
    match off.reset_to((noon, 0))
    | None => None
    | let _: TzLookupError =>
      h.fail("Offset-mode reset never queries tzdata")
    end
    h.assert_true(off.local_tod().eq(TimeOfDay(17, 0, 0)?), "off: noon + 5h")
    h.assert_eq[I32](5 * 3600, off.offset_sec(), "offset preserved")


class iso _TestZdtKindAndZoneName is UnitTest
  fun name(): String => "ZonedDateTime/kind + zone_name"
  fun apply(h: TestHelper) =>
    let utc = ZonedDateTime.now()
    h.assert_true(utc.kind() is Zone, "now → Zone kind")
    h.assert_eq[String]("UTC", utc.zone_name(), "now → UTC")

    let off = ZonedDateTime.now_at_offset(0)
    h.assert_true(off.kind() is Offset, "now_at_offset → Offset kind")
    h.assert_eq[String]("", off.zone_name(), "offset mode has empty name")


class iso _TestZdtString is UnitTest
  fun name(): String => "ZonedDateTime/string RFC 3339 format"
  fun apply(h: TestHelper) ? =>
    // UTC: trailing Z.
    h.assert_eq[String](
      "1970-01-01T00:00:00Z",
      ZonedDateTime.from_posix((0, 0)).string())
    h.assert_eq[String](
      "2026-05-25T12:00:00Z",
      ZonedDateTime.from_posix(
        (_DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?, 0)).string())

    // Offset modes: ±HH:MM suffix.
    let noon = _DateTimeMath.utc_posix_sec(2026, 5, 25, 12, 0, 0)?
    h.assert_eq[String](
      "2026-05-25T17:00:00+05:00",
      ZonedDateTime.from_posix_at_offset((noon, 0), 5 * 3600).string())
    h.assert_eq[String](
      "2026-05-25T05:00:00-07:00",
      ZonedDateTime.from_posix_at_offset(
        (noon, 0), -(7 * 3600)).string())

    // Sub-minute offsets in the time/sec but rounded for the suffix.
    h.assert_eq[String](
      "2026-05-25T17:30:00+05:30",
      ZonedDateTime.from_posix_at_offset(
        (noon, 0), (5 * 3600) + (30 * 60)).string())

    // Day-crossing backward.
    let one_am = _DateTimeMath.utc_posix_sec(2026, 5, 25, 1, 0, 0)?
    h.assert_eq[String](
      "2026-05-24T22:00:00-03:00",
      ZonedDateTime.from_posix_at_offset(
        (one_am, 0), -(3 * 3600)).string())

    // Day-crossing forward.
    let ten_pm = _DateTimeMath.utc_posix_sec(2026, 5, 25, 22, 0, 0)?
    h.assert_eq[String](
      "2026-05-26T03:00:00+05:00",
      ZonedDateTime.from_posix_at_offset(
        (ten_pm, 0), 5 * 3600).string())

    // Offset 0 always renders as Z, regardless of Zone vs Offset mode.
    h.assert_eq[String](
      "1970-01-01T00:00:00Z",
      ZonedDateTime.from_posix_at_offset((0, 0), 0).string())


class iso _TestZdtStringSubSecond is UnitTest
  fun name(): String => "ZonedDateTime/string preserves sub-second"
  fun apply(h: TestHelper) =>
    // Half-second.
    h.assert_eq[String](
      "1970-01-01T00:00:00.500000000Z",
      ZonedDateTime.from_posix((0, 500_000_000)).string())
    // One nanosecond.
    h.assert_eq[String](
      "1970-01-01T00:00:00.000000001Z",
      ZonedDateTime.from_posix((0, 1)).string())
    // Sub-second with offset.
    h.assert_eq[String](
      "1970-01-01T01:00:00.123456789+01:00",
      ZonedDateTime.from_posix_at_offset(
        (0, 123_456_789), 3600).string())


// ----- Rfc3339 parser -----


class iso _TestRfc3339ParseBasic is UnitTest
  fun name(): String => "Rfc3339/parse basic shapes"
  fun apply(h: TestHelper) ? =>
    // Epoch UTC.
    match Rfc3339.parse("1970-01-01T00:00:00Z")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_eq[I64](0, kept.to_posix()._1, "epoch UTC sec")
      h.assert_eq[I64](0, kept.to_posix()._2, "epoch UTC nsec")
      h.assert_eq[I32](0, kept.offset_sec(), "epoch offset")
      h.assert_true(kept.kind() is Offset, "kind = Offset")
    | let _: ParseMalformed => h.fail("epoch parse")
    end

    // Positive offset.
    match Rfc3339.parse("2026-05-25T17:00:00+05:00")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "+5h date")
      h.assert_true(kept.local_tod().eq(TimeOfDay(17, 0, 0)?), "+5h tod")
      h.assert_eq[I32](5 * 3600, kept.offset_sec(), "+5h offset")
    | let _: ParseMalformed => h.fail("+5h parse")
    end

    // Negative offset.
    match Rfc3339.parse("2026-05-25T05:00:00-07:00")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "-7h date")
      h.assert_true(kept.local_tod().eq(TimeOfDay(5, 0, 0)?), "-7h tod")
      h.assert_eq[I32](-(7 * 3600), kept.offset_sec(), "-7h offset")
    | let _: ParseMalformed => h.fail("-7h parse")
    end

    // Sub-hour offset (India).
    match Rfc3339.parse("2026-05-25T17:30:00+05:30")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_tod().eq(TimeOfDay(17, 30, 0)?), "IST tod")
      h.assert_eq[I32]((5 * 3600) + (30 * 60), kept.offset_sec(), "IST offset")
    | let _: ParseMalformed => h.fail("IST parse")
    end


class iso _TestRfc3339ParseSubSecond is UnitTest
  fun name(): String => "Rfc3339/parse sub-second precision"
  fun apply(h: TestHelper) =>
    // Full 9 digits.
    match Rfc3339.parse("1970-01-01T00:00:00.500000000Z")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_eq[I64](500_000_000, kept.to_posix()._2, "half-second nsec")
    | let _: ParseMalformed => h.fail("full-9 parse")
    end

    // One digit — padded to full nanos.
    match Rfc3339.parse("1970-01-01T00:00:00.5Z")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_eq[I64](500_000_000, kept.to_posix()._2, "one-digit padded")
    | let _: ParseMalformed => h.fail(".5 parse")
    end

    // Three digits (milliseconds).
    match Rfc3339.parse("1970-01-01T00:00:00.123Z")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_eq[I64](123_000_000, kept.to_posix()._2, "ms padded")
    | let _: ParseMalformed => h.fail(".123 parse")
    end

    // Single nanosecond.
    match Rfc3339.parse("1970-01-01T00:00:00.000000001Z")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_eq[I64](1, kept.to_posix()._2, "1 nsec")
    | let _: ParseMalformed => h.fail("1 nsec parse")
    end


class iso _TestRfc3339RoundTrip is UnitTest
  fun name(): String => "Rfc3339/parse-then-format round-trip"
  fun apply(h: TestHelper) =>
    let inputs: Array[String val] val = recover val
      [
        "1970-01-01T00:00:00Z"
        "2026-05-25T17:00:00+05:00"
        "2026-05-25T05:00:00-07:00"
        "2026-05-25T17:30:00+05:30"
        "2026-05-26T03:00:00+05:00"
        "2026-05-24T22:00:00-03:00"
        "1970-01-01T00:00:00.500000000Z"
        "1970-01-01T01:00:00.123456789+01:00"
      ]
    end
    for s in inputs.values() do
      match Rfc3339.parse(s)
      | let zdt: ZonedDateTime iso =>
        let out = (consume zdt).string()
        h.assert_eq[String](s, consume out, "round-trip: " + s)
      | let _: ParseMalformed =>
        h.fail("Failed to parse: " + s)
      end
    end


class iso _TestRfc3339ParseInvalid is UnitTest
  fun name(): String => "Rfc3339/parse rejects malformed input"
  fun apply(h: TestHelper) =>
    let bad_inputs: Array[String val] val = recover val
      [
        ""                                  // empty
        "garbage"                           // not a date
        "2026-05-25"                        // missing time
        "2026-13-01T00:00:00Z"              // invalid month
        "2026-05-32T00:00:00Z"              // invalid day
        "2026-02-30T00:00:00Z"              // Feb 30
        "2026-05-25T25:00:00Z"              // hour out of range
        "2026-05-25T17:60:00Z"              // minute out of range
        "2026-05-25 17:00:00Z"              // space separator (strict rejects)
        "2026-05-25t17:00:00Z"              // lowercase t
        "2026-05-25T17:00:00z"              // lowercase z
        "2026-05-25T17:00:00"               // missing offset
        "2026-05-25T17:00:00+05"            // offset missing minutes
        "2026-05-25T17:00:00+05:00garbage"  // trailing garbage
      ]
    end
    for s in bad_inputs.values() do
      match Rfc3339.parse(s)
      | let _: ZonedDateTime iso =>
        h.fail("Should have rejected: '" + s + "'")
      | let _: ParseMalformed => None  // Expected.
      end
    end


class iso _TestRfc3339ParseInPlace is UnitTest
  fun name(): String => "Rfc3339/parse_in_place"
  fun apply(h: TestHelper) ? =>
    // Start with a Zone-mode (UTC) ZDT; parse should switch it to Offset
    // mode at the parsed offset.
    let zdt = ZonedDateTime.from_posix((0, 0))
    h.assert_true(zdt.kind() is Zone, "starts Zone mode")
    h.assert_eq[String]("UTC", zdt.zone_name(), "starts UTC name")

    match Rfc3339.parse_in_place("2026-05-25T17:00:00+05:00", zdt)
    | None => None
    | let _: ParseMalformed => h.fail("Unexpected parse error")
    end

    h.assert_true(zdt.kind() is Offset, "switched to Offset mode")
    h.assert_eq[String]("", zdt.zone_name(), "zone_name cleared")
    h.assert_eq[I32](5 * 3600, zdt.offset_sec(), "offset set")
    h.assert_true(zdt.local_date().eq(Date(2026, 5, 25)?), "local date")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(17, 0, 0)?), "local tod")

    // Bad input: zdt should be unchanged.
    match Rfc3339.parse_in_place("garbage", zdt)
    | None => h.fail("Should have errored on 'garbage'")
    | let _: ParseMalformed => None  // Expected.
    end
    h.assert_eq[I32](5 * 3600, zdt.offset_sec(), "offset preserved on error")


// ----- Iso8601 parser (lenient) -----


class iso _TestIso8601Lenient is UnitTest
  fun name(): String => "Iso8601/parse accepts lenient dialects"
  fun apply(h: TestHelper) ? =>
    let lenient_inputs: Array[String val] val = recover val
      [
        "2026-05-25T17:00:00+05:00"   // RFC 3339 strict (still accepted)
        "2026-05-25t17:00:00+05:00"   // lowercase t
        "2026-05-25 17:00:00+05:00"   // space separator
        "2026-05-25T17:00:00z"        // lowercase z
        "2026-05-25t17:00:00z"        // both lower
        "2026-05-25 17:00:00Z"        // space + Z
      ]
    end
    for s in lenient_inputs.values() do
      match Iso8601.parse(s, "UTC")
      | let zdt: ZonedDateTime iso =>
        let kept = consume zdt
        h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?),
          "date: " + s)
        h.assert_true(kept.local_tod().eq(TimeOfDay(17, 0, 0)?),
          "tod: " + s)
      | let _: ParseMalformed =>
        h.fail("Iso8601 rejected lenient input: '" + s + "'")
      end
    end

    // Iso8601 should also reject things RFC 3339 rejects.
    match Iso8601.parse("2026-13-01T00:00:00Z", "UTC")
    | let _: ZonedDateTime iso =>
      h.fail("Should have rejected invalid month")
    | let _: ParseMalformed => None
    end


// ----- Rfc2822 parser -----


class iso _TestRfc2822ParseBasic is UnitTest
  fun name(): String => "Rfc2822/parse standard form"
  fun apply(h: TestHelper) ? =>
    // Canonical: day-of-week, 2-digit day, capital month, full time, ±HHMM.
    match Rfc2822.parse("Mon, 25 May 2026 12:00:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "date")
      h.assert_true(kept.local_tod().eq(TimeOfDay(12, 0, 0)?), "tod")
      h.assert_eq[I32](0, kept.offset_sec(), "offset 0")
    | let _: ParseMalformed => h.fail("basic parse")
    end

    // Offset -0700.
    match Rfc2822.parse("Mon, 25 May 2026 05:00:00 -0700")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "PDT date")
      h.assert_true(kept.local_tod().eq(TimeOfDay(5, 0, 0)?), "PDT tod")
      h.assert_eq[I32](-(7 * 3600), kept.offset_sec(), "PDT offset")
    | let _: ParseMalformed => h.fail("offset parse")
    end


class iso _TestRfc2822ParseVariants is UnitTest
  fun name(): String => "Rfc2822/parse optional fields and case-folding"
  fun apply(h: TestHelper) ? =>
    // No day-of-week prefix.
    match Rfc2822.parse("25 May 2026 12:00:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "no-dow date")
    | let _: ParseMalformed => h.fail("no-dow parse")
    end

    // Single-digit day-of-month.
    match Rfc2822.parse("5 May 2026 09:00:00 +0500")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 5)?), "1-digit day")
      h.assert_eq[I32](5 * 3600, kept.offset_sec(), "+0500")
    | let _: ParseMalformed => h.fail("1-digit day parse")
    end

    // No seconds — defaults to :00.
    match Rfc2822.parse("Mon, 25 May 2026 12:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_tod().eq(TimeOfDay(12, 0, 0)?), "no-sec tod")
    | let _: ParseMalformed => h.fail("no-seconds parse")
    end

    // Case-insensitive month.
    match Rfc2822.parse("Mon, 25 may 2026 12:00:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "lower may")
    | let _: ParseMalformed => h.fail("lowercase month parse")
    end

    match Rfc2822.parse("Mon, 25 MAY 2026 12:00:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "upper MAY")
    | let _: ParseMalformed => h.fail("uppercase month parse")
    end

    // Day-of-week prefix is parsed but not validated against the date.
    // We label May 25 as "Fri" (wrong) and still accept it.
    match Rfc2822.parse("Fri, 25 May 2026 12:00:00 +0000")
    | let zdt: ZonedDateTime iso =>
      let kept = consume zdt
      h.assert_true(kept.local_date().eq(Date(2026, 5, 25)?), "wrong dow accepted")
    | let _: ParseMalformed => h.fail("wrong-dow parse")
    end


class iso _TestRfc2822ParseObsoleteZones is UnitTest
  fun name(): String => "Rfc2822/parse obsolete zone names"
  fun apply(h: TestHelper) =>
    let cases: Array[(String val, I32)] val = recover val
      [
        ("Mon, 25 May 2026 12:00:00 GMT", I32(0))
        ("Mon, 25 May 2026 12:00:00 UT", I32(0))
        ("Mon, 25 May 2026 12:00:00 UTC", I32(0))
        ("Mon, 25 May 2026 12:00:00 EST", -(5 * 3600))
        ("Mon, 25 May 2026 12:00:00 EDT", -(4 * 3600))
        ("Mon, 25 May 2026 12:00:00 CST", -(6 * 3600))
        ("Mon, 25 May 2026 12:00:00 CDT", -(5 * 3600))
        ("Mon, 25 May 2026 12:00:00 MST", -(7 * 3600))
        ("Mon, 25 May 2026 12:00:00 MDT", -(6 * 3600))
        ("Mon, 25 May 2026 12:00:00 PST", -(8 * 3600))
        ("Mon, 25 May 2026 12:00:00 PDT", -(7 * 3600))
        ("Mon, 25 May 2026 12:00:00 XYZ", I32(0))  // unknown → +0000 per RFC 5322
      ]
    end
    for c in cases.values() do
      (let s, let expected) = c
      match Rfc2822.parse(s)
      | let zdt: ZonedDateTime iso =>
        let kept = consume zdt
        h.assert_eq[I32](expected, kept.offset_sec(),
          "zone offset for: " + s)
      | let _: ParseMalformed =>
        h.fail("Failed to parse: " + s)
      end
    end


class iso _TestRfc2822Format is UnitTest
  fun name(): String => "Rfc2822/format canonical output"
  fun apply(h: TestHelper) =>
    // Epoch UTC.
    h.assert_eq[String](
      "Thu, 01 Jan 1970 00:00:00 +0000",
      Rfc2822.format(ZonedDateTime.from_posix((0, 0))))

    // 2026-05-25 at +0500.
    let posix_noon = try Date(2026, 5, 25)?.days_since_epoch().i64() * 86400
      else I64(0) end + (12 * 3600)
    h.assert_eq[String](
      "Mon, 25 May 2026 17:00:00 +0500",
      Rfc2822.format(
        ZonedDateTime.from_posix_at_offset((posix_noon, 0), 5 * 3600)))

    // -0730 (sub-hour negative offset, also RFC 2822-emittable).
    h.assert_eq[String](
      "Mon, 25 May 2026 04:30:00 -0730",
      Rfc2822.format(
        ZonedDateTime.from_posix_at_offset(
          (posix_noon, 0),
          -((7 * 3600) + (30 * 60)))))


class iso _TestRfc2822RoundTrip is UnitTest
  fun name(): String => "Rfc2822/round-trip from canonical form"
  fun apply(h: TestHelper) =>
    let inputs: Array[String val] val = recover val
      [
        "Thu, 01 Jan 1970 00:00:00 +0000"
        "Mon, 25 May 2026 12:00:00 +0000"
        "Mon, 25 May 2026 17:00:00 +0500"
        "Mon, 25 May 2026 05:00:00 -0700"
        "Mon, 25 May 2026 17:30:00 +0530"
        "Sun, 24 May 2026 22:00:00 -0300"  // day-cross backward
      ]
    end
    for s in inputs.values() do
      match Rfc2822.parse(s)
      | let zdt: ZonedDateTime iso =>
        let formatted = Rfc2822.format(consume zdt)
        h.assert_eq[String](s, consume formatted, "round-trip: " + s)
      | let _: ParseMalformed =>
        h.fail("Failed to parse: " + s)
      end
    end


class iso _TestRfc2822ParseInvalid is UnitTest
  fun name(): String => "Rfc2822/parse rejects malformed input"
  fun apply(h: TestHelper) =>
    let bad_inputs: Array[String val] val = recover val
      [
        ""                                              // empty
        "garbage"                                       // not a date
        "Mon, 25 Foo 2026 12:00:00 +0000"               // invalid month
        "Mon, 32 May 2026 12:00:00 +0000"               // invalid day
        "Mon, 25 May 2026 25:00:00 +0000"               // hour out of range
        "Mon, 25 May 2026 12:00:00 +05:00"              // colon in offset (RFC 3339 style)
        "Mon, 25 May 2026 12:00:00"                     // missing offset
        "Mon, 25 May 2026 12:00:00 +0000 extra"         // trailing garbage
        "25  May 2026 12:00:00 +0000"                   // double space
      ]
    end
    for s in bad_inputs.values() do
      match Rfc2822.parse(s)
      | let _: ZonedDateTime iso =>
        h.fail("Should have rejected: '" + s + "'")
      | let _: ParseMalformed => None  // Expected.
      end
    end


// ----- Cron / Recurrence -----
//
// Calendar anchors for these tests:
//   2026-05-22 Friday
//   2026-05-25 Monday
//   2026-05-29 Friday (the last Friday of May 2026)
//   2026-06-01 Monday


class iso _TestCronWeekdaySameDayAhead is UnitTest
  fun name(): String => "Cron/weekday: fires today when ahead of after"
  fun apply(h: TestHelper) ? =>
    // Every Monday at 09:00 UTC; after Mon 08:00 → today 09:00.
    let r = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    let after = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 25, 8, 0, 0)?, 0))
    let expected = _DateTimeMath.utc_posix_sec(2026, 5, 25, 9, 0, 0)?
    match r.iter_after(after).next()
    | let zdt: ZonedDateTime =>
      (let s: I64, let n: I64) = zdt.to_posix()
      h.assert_eq[I64](expected, s, "same-day fire sec")
      h.assert_eq[I64](0, n, "no nsec")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronWeekdaySameDayPast is UnitTest
  fun name(): String => "Cron/weekday: rolls forward when today is past"
  fun apply(h: TestHelper) ? =>
    // Every Monday at 09:00 UTC; after Mon 10:00 → next Mon (Jun 1).
    let r = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    let after = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 25, 10, 0, 0)?, 0))
    let expected = _DateTimeMath.utc_posix_sec(2026, 6, 1, 9, 0, 0)?
    match r.iter_after(after).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected, zdt.to_posix()._1, "next-Mon sec")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronWeekdayAcrossWeek is UnitTest
  fun name(): String => "Cron/weekday: jumps from Fri to next Mon"
  fun apply(h: TestHelper) ? =>
    // Every Monday at 09:00 UTC; after Fri (May 22) noon → May 25 09:00.
    let r = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    let after = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 22, 12, 0, 0)?, 0))
    let expected = _DateTimeMath.utc_posix_sec(2026, 5, 25, 9, 0, 0)?
    match r.iter_after(after).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected, zdt.to_posix()._1, "Mon after Fri")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronWeekdayWeekdaySet is UnitTest
  fun name(): String => "Cron/weekday: weekday-set (Mon-Fri) skips weekend"
  fun apply(h: TestHelper) ? =>
    let r = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday; Tuesday; Wednesday; Thursday; Friday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    // After Sat 10:00 → Mon 09:00 (skips Sun).
    let after_sat = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 23, 10, 0, 0)?, 0))
    let expected_mon = _DateTimeMath.utc_posix_sec(2026, 5, 25, 9, 0, 0)?
    match r.iter_after(after_sat).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_mon, zdt.to_posix()._1, "Sat → Mon")
    | NextFireError => h.fail("expected fire")
    end

    // After Fri 08:00 → Fri 09:00 (same day, ahead of fire).
    let after_fri_morn = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 22, 8, 0, 0)?, 0))
    let expected_fri = _DateTimeMath.utc_posix_sec(2026, 5, 22, 9, 0, 0)?
    match r.iter_after(after_fri_morn).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_fri, zdt.to_posix()._1, "Fri 08 → Fri 09")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronWeekdayEmpty is UnitTest
  fun name(): String => "Cron/weekday: empty set errors out"
  fun apply(h: TestHelper) ? =>
    let r = WeekdayRecurrence(
      recover val Array[DayOfWeek] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    match r.iter_after(ZonedDateTime.from_posix((0, 0))).next()
    | let _: ZonedDateTime => h.fail("expected NextFireError")
    | NextFireError => None  // Expected.
    end


class iso _TestCronMonthlyDayOfMonth is UnitTest
  fun name(): String => "Cron/monthly: DayOfMonth(15)"
  fun apply(h: TestHelper) ? =>
    let r = MonthlyRecurrence(DayOfMonth(15)?, TimeOfDay.midnight(), "UTC")
    // After May 10 → May 15.
    let after_may10 = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 10, 0, 0, 0)?, 0))
    let expected_may15 = _DateTimeMath.utc_posix_sec(2026, 5, 15, 0, 0, 0)?
    match r.iter_after(after_may10).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_may15, zdt.to_posix()._1, "May 15")
    | NextFireError => h.fail("expected fire")
    end

    // After May 16 → Jun 15 (skipped this month's fire).
    let after_may16 = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 16, 0, 0, 0)?, 0))
    let expected_jun15 = _DateTimeMath.utc_posix_sec(2026, 6, 15, 0, 0, 0)?
    match r.iter_after(after_may16).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_jun15, zdt.to_posix()._1, "Jun 15")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronMonthlyClamp is UnitTest
  fun name(): String => "Cron/monthly: DayOfMonth(31) clamps for short months"
  fun apply(h: TestHelper) ? =>
    let r = MonthlyRecurrence(DayOfMonth(31)?, TimeOfDay.midnight(), "UTC")
    // After Apr 10 → Apr 30 (April has 30 days).
    let after_apr = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 4, 10, 0, 0, 0)?, 0))
    let expected_apr30 = _DateTimeMath.utc_posix_sec(2026, 4, 30, 0, 0, 0)?
    match r.iter_after(after_apr).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_apr30, zdt.to_posix()._1, "Apr 30")
    | NextFireError => h.fail("expected fire")
    end

    // After May 10 → May 31 (May has 31 days, preferred-day intact).
    let after_may = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 10, 0, 0, 0)?, 0))
    let expected_may31 = _DateTimeMath.utc_posix_sec(2026, 5, 31, 0, 0, 0)?
    match r.iter_after(after_may).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_may31, zdt.to_posix()._1, "May 31")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronMonthlyLastDay is UnitTest
  fun name(): String => "Cron/monthly: LastDayOfMonth handles leap/non-leap Feb"
  fun apply(h: TestHelper) ? =>
    let r = MonthlyRecurrence(LastDayOfMonth, TimeOfDay.midnight(), "UTC")
    // After Feb 10, 2026 (non-leap) → Feb 28.
    let after_feb26 = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 2, 10, 0, 0, 0)?, 0))
    let expected_feb28 = _DateTimeMath.utc_posix_sec(2026, 2, 28, 0, 0, 0)?
    match r.iter_after(after_feb26).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_feb28, zdt.to_posix()._1, "Feb 28 2026")
    | NextFireError => h.fail("expected fire")
    end

    // After Feb 10, 2024 (leap) → Feb 29.
    let after_feb24 = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2024, 2, 10, 0, 0, 0)?, 0))
    let expected_feb29 = _DateTimeMath.utc_posix_sec(2024, 2, 29, 0, 0, 0)?
    match r.iter_after(after_feb24).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_feb29, zdt.to_posix()._1, "Feb 29 2024")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronMonthlyLastWeekday is UnitTest
  fun name(): String => "Cron/monthly: LastWeekdayOfMonth"
  fun apply(h: TestHelper) ? =>
    let r = MonthlyRecurrence(
      LastWeekdayOfMonth(Friday),
      TimeOfDay.midnight(),
      "UTC")
    // Last Friday of May 2026 is May 29.
    let after_may10 = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 10, 0, 0, 0)?, 0))
    let expected_may29 = _DateTimeMath.utc_posix_sec(2026, 5, 29, 0, 0, 0)?
    match r.iter_after(after_may10).next()
    | let zdt: ZonedDateTime =>
      h.assert_eq[I64](expected_may29, zdt.to_posix()._1, "last Fri May")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronIntervalIntraday is UnitTest
  fun name(): String => "Cron/interval: pure intraday (every 90 min)"
  fun apply(h: TestHelper) =>
    let r = IntervalRecurrence(Period.of_minutes(90), "UTC", OverflowClamp)
    // 90 minutes = 5400 seconds.
    match r.iter_after(ZonedDateTime.from_posix((1000, 0))).next()
    | let zdt: ZonedDateTime =>
      (let s: I64, let n: I64) = zdt.to_posix()
      h.assert_eq[I64](6400, s, "90 min later")
      h.assert_eq[I64](0, n)
    | NextFireError => h.fail("expected fire")
    end

    // 1-second interval.
    let r1 = IntervalRecurrence(Period.of_seconds(1), "UTC", OverflowClamp)
    match r1.iter_after(ZonedDateTime.from_posix((1000, 500_000_000))).next()
    | let zdt: ZonedDateTime =>
      (let s: I64, let n: I64) = zdt.to_posix()
      h.assert_eq[I64](1001, s, "+1s sec")
      h.assert_eq[I64](500_000_000, n, "nsec preserved")
    | NextFireError => h.fail("expected fire")
    end


class iso _TestCronIntervalCalendarUnsupported is UnitTest
  fun name(): String => "Cron/interval: calendar-mixed isn't supported in v1"
  fun apply(h: TestHelper) =>
    let r = IntervalRecurrence(Period.of_months(1), "UTC", OverflowClamp)
    match r.iter_after(ZonedDateTime.from_posix((0, 0))).next()
    | let _: ZonedDateTime =>
      h.fail("expected NextFireError (calendar-mixed not yet supported)")
    | NextFireError => None  // Expected.
    end


class iso _TestCronUnknownZone is UnitTest
  fun name(): String => "Cron/unknown zone returns NextFireError"
  fun apply(h: TestHelper) ? =>
    let weekdays = recover val [as DayOfWeek: Monday] end
    let tod = TimeOfDay(9, 0, 0)?
    let r = WeekdayRecurrence(weekdays, tod, "Atlantis/Lost")
    match r.iter_after(ZonedDateTime.from_posix((0, 0))).next()
    | let _: ZonedDateTime => h.fail("expected NextFireError")
    | NextFireError => None  // Expected.
    end


class iso _TestMonthlyIterPreferredDay is UnitTest
  fun name(): String => "MonthlyIter/preserves preferred day across clamps"
  fun apply(h: TestHelper) ? =>
    // "Bill on the 31st of every month, midnight UTC" — the canonical
    // R4 scenario. Verifies that clamping in Feb / Apr / Jun / Sep / Nov
    // doesn't lose the original preferred day for subsequent months.
    let rec = MonthlyRecurrence(DayOfMonth(31)?, TimeOfDay.midnight(), "UTC")
    let signup = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 1, 15, 0, 0, 0)?, 0))
    let iter = rec.iter_after(signup)
    let expected: Array[I64] val = recover val
      [
        _DateTimeMath.utc_posix_sec(2026, 1, 31, 0, 0, 0)?   // Jan 31
        _DateTimeMath.utc_posix_sec(2026, 2, 28, 0, 0, 0)?   // Feb 28 (clamped)
        _DateTimeMath.utc_posix_sec(2026, 3, 31, 0, 0, 0)?   // Mar 31 (preferred preserved)
        _DateTimeMath.utc_posix_sec(2026, 4, 30, 0, 0, 0)?   // Apr 30 (clamped)
        _DateTimeMath.utc_posix_sec(2026, 5, 31, 0, 0, 0)?   // May 31 (preferred preserved)
        _DateTimeMath.utc_posix_sec(2026, 6, 30, 0, 0, 0)?   // Jun 30 (clamped)
        _DateTimeMath.utc_posix_sec(2026, 7, 31, 0, 0, 0)?   // Jul 31 (preferred preserved)
      ]
    end
    var i: USize = 0
    for exp in expected.values() do
      match iter.next()
      | let zdt: ZonedDateTime =>
        h.assert_eq[I64](exp, zdt.to_posix()._1, "iter fire #" + i.string())
      | NextFireError =>
        h.fail("iter errored at #" + i.string())
        return
      end
      i = i + 1
    end


class iso _TestMonthlyIterStickyError is UnitTest
  fun name(): String => "MonthlyIter/sticky error on zone lookup"
  fun apply(h: TestHelper) ? =>
    // Unknown zone → first call returns NextFireError; second and
    // subsequent calls return the same sticky error.
    let rec = MonthlyRecurrence(
      DayOfMonth(15)?, TimeOfDay.midnight(), "Atlantis/Lost")
    let iter = rec.iter_after(ZonedDateTime.from_posix((0, 0)))

    // First call: error is emitted directly via the return-side union.
    match iter.next()
    | let _: ZonedDateTime => h.fail("expected NextFireError on first call")
    | NextFireError => None
    end

    // After emitting the error once, the iterator is exhausted.
    h.assert_false(iter.has_next(), "has_next after error emitted")


class iso _TestMonthlyIterFreshSeries is UnitTest
  fun name(): String => "MonthlyIter/separate iterators are independent"
  fun apply(h: TestHelper) ? =>
    // Two iterators built from the same MonthlyRecurrence with different
    // `after_posix` arguments should advance independently. This
    // verifies that state lives on the iterator, not on the (val)
    // recurrence value.
    let rec = MonthlyRecurrence(
      DayOfMonth(15)?, TimeOfDay.midnight(), "UTC")
    let iter_a = rec.iter_after(ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 1, 10, 0, 0, 0)?, 0)))
    let iter_b = rec.iter_after(ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 6, 10, 0, 0, 0)?, 0)))

    let a1 = _next_sec(h, iter_a, "iter_a #1")
    let b1 = _next_sec(h, iter_b, "iter_b #1")
    let a2 = _next_sec(h, iter_a, "iter_a #2")
    let b2 = _next_sec(h, iter_b, "iter_b #2")

    h.assert_eq[I64](
      _DateTimeMath.utc_posix_sec(2026, 1, 15, 0, 0, 0)?, a1, "a1")
    h.assert_eq[I64](
      _DateTimeMath.utc_posix_sec(2026, 6, 15, 0, 0, 0)?, b1, "b1")
    h.assert_eq[I64](
      _DateTimeMath.utc_posix_sec(2026, 2, 15, 0, 0, 0)?, a2, "a2")
    h.assert_eq[I64](
      _DateTimeMath.utc_posix_sec(2026, 7, 15, 0, 0, 0)?, b2, "b2")

  fun _next_sec(h: TestHelper, iter: MonthlyIter, label: String): I64 =>
    match iter.next()
    | let zdt: ZonedDateTime => zdt.to_posix()._1
    | NextFireError =>
      h.fail("Expected fire at " + label)
      I64(0)
    end


class iso _TestWeekdayIterSuccessive is UnitTest
  fun name(): String => "WeekdayIter/successive weekly fires"
  fun apply(h: TestHelper) ? =>
    // "Every Monday at 09:00 UTC" — five consecutive Mondays.
    let rec = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    // Start: 2026-05-22 (Fri); first fire is 2026-05-25 (Mon).
    let after = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 22, 0, 0, 0)?, 0))
    let iter = rec.iter_after(after)
    let expected: Array[I64] val = recover val
      [
        _DateTimeMath.utc_posix_sec(2026, 5, 25, 9, 0, 0)?   // Mon
        _DateTimeMath.utc_posix_sec(2026, 6, 1,  9, 0, 0)?   // Mon
        _DateTimeMath.utc_posix_sec(2026, 6, 8,  9, 0, 0)?   // Mon
        _DateTimeMath.utc_posix_sec(2026, 6, 15, 9, 0, 0)?   // Mon
        _DateTimeMath.utc_posix_sec(2026, 6, 22, 9, 0, 0)?   // Mon
      ]
    end
    var i: USize = 0
    for exp in expected.values() do
      match iter.next()
      | let zdt: ZonedDateTime =>
        h.assert_eq[I64](exp, zdt.to_posix()._1, "Mon #" + i.string())
      | NextFireError =>
        h.fail("iter errored at #" + i.string())
        return
      end
      i = i + 1
    end


class iso _TestWeekdayIterSkipsWeekends is UnitTest
  fun name(): String => "WeekdayIter/weekday set skips weekend days"
  fun apply(h: TestHelper) ? =>
    // "Every weekday at 09:00 UTC" — should produce Mon-Tue-Wed-Thu-Fri
    // then jump to next Mon.
    let rec = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday; Tuesday; Wednesday; Thursday; Friday] end,
      TimeOfDay(9, 0, 0)?,
      "UTC")
    // Start: 2026-05-24 (Sun) — first fire is Mon May 25.
    let after = ZonedDateTime.from_posix(
      (_DateTimeMath.utc_posix_sec(2026, 5, 24, 0, 0, 0)?, 0))
    let iter = rec.iter_after(after)
    let expected: Array[I64] val = recover val
      [
        _DateTimeMath.utc_posix_sec(2026, 5, 25, 9, 0, 0)?   // Mon
        _DateTimeMath.utc_posix_sec(2026, 5, 26, 9, 0, 0)?   // Tue
        _DateTimeMath.utc_posix_sec(2026, 5, 27, 9, 0, 0)?   // Wed
        _DateTimeMath.utc_posix_sec(2026, 5, 28, 9, 0, 0)?   // Thu
        _DateTimeMath.utc_posix_sec(2026, 5, 29, 9, 0, 0)?   // Fri
        // weekend skipped
        _DateTimeMath.utc_posix_sec(2026, 6, 1,  9, 0, 0)?   // next Mon
        _DateTimeMath.utc_posix_sec(2026, 6, 2,  9, 0, 0)?   // next Tue
      ]
    end
    var i: USize = 0
    for exp in expected.values() do
      match iter.next()
      | let zdt: ZonedDateTime =>
        h.assert_eq[I64](exp, zdt.to_posix()._1, "weekday #" + i.string())
      | NextFireError =>
        h.fail("iter errored at #" + i.string())
        return
      end
      i = i + 1
    end


class iso _TestWeekdayIterStickyError is UnitTest
  fun name(): String => "WeekdayIter/sticky error on zone lookup"
  fun apply(h: TestHelper) ? =>
    let rec = WeekdayRecurrence(
      recover val [as DayOfWeek: Monday] end,
      TimeOfDay(9, 0, 0)?,
      "Atlantis/Lost")
    let iter = rec.iter_after(ZonedDateTime.from_posix((0, 0)))

    match iter.next()
    | let _: ZonedDateTime => h.fail("expected NextFireError on first call")
    | NextFireError => None
    end

    h.assert_false(iter.has_next(), "has_next after error emitted")


class iso _TestIntervalIterSuccessive is UnitTest
  fun name(): String => "IntervalIter/successive intraday fires"
  fun apply(h: TestHelper) =>
    // "Every 90 minutes" — five consecutive fires.
    let rec = IntervalRecurrence(Period.of_minutes(90), "UTC", OverflowClamp)
    let iter = rec.iter_after(ZonedDateTime.from_posix((1000, 0)))
    // 90 minutes = 5400 seconds.
    let expected: Array[I64] val = recover val
      [1000 + 5400; 1000 + 10800; 1000 + 16200; 1000 + 21600; 1000 + 27000]
    end
    var i: USize = 0
    for exp in expected.values() do
      match iter.next()
      | let zdt: ZonedDateTime =>
        (let s: I64, let nsec: I64) = zdt.to_posix()
        h.assert_eq[I64](exp, s, "fire #" + i.string())
        h.assert_eq[I64](0, nsec, "no nsec drift")
      | NextFireError =>
        h.fail("iter errored at #" + i.string())
        return
      end
      i = i + 1
    end


class iso _TestIntervalIterStickyCalendar is UnitTest
  fun name(): String => "IntervalIter/calendar-mixed period sticks once"
  fun apply(h: TestHelper) =>
    let rec = IntervalRecurrence(Period.of_months(1), "UTC", OverflowClamp)
    let iter = rec.iter_after(ZonedDateTime.from_posix((0, 0)))
    // First call: not supported → emits NextFireError.
    match iter.next()
    | let _: ZonedDateTime => h.fail("expected NextFireError")
    | NextFireError => None
    end
    // Iterator is exhausted after emitting the error.
    h.assert_false(iter.has_next(), "has_next after error emitted")


class iso _TestIntervalIterStickyZone is UnitTest
  fun name(): String => "IntervalIter/unknown zone sticks once"
  fun apply(h: TestHelper) =>
    let rec = IntervalRecurrence(
      Period.of_minutes(30), "Atlantis/Lost", OverflowClamp)
    let iter = rec.iter_after(ZonedDateTime.from_posix((0, 0)))
    match iter.next()
    | let _: ZonedDateTime => h.fail("expected NextFireError")
    | NextFireError => None
    end
    h.assert_false(iter.has_next(), "has_next after error emitted")


// ----- Real IANA zones: America/New_York, America/Los_Angeles -----
//
// These zones are hand-coded with the post-2007 US DST rule. Pre-2007
// instants are silently treated as if the current rule had always
// applied — that's wrong (the rule changed in 1987, 2007) but the
// tests here use 2026+ exclusively to stay within the rule's domain.


class iso _TestZoneNyWinter is UnitTest
  fun name(): String => "Zone/America/New_York winter is EST"
  fun apply(h: TestHelper) ? =>
    // 2026-01-15 12:00 UTC → local 07:00 EST.
    let sec = _DateTimeMath.utc_posix_sec(2026, 1, 15, 12, 0, 0)?
    let zdt = ZonedDateTime.from_posix_in_zone((sec, 0), "America/New_York")?
    h.assert_true(zdt.local_date().eq(Date(2026, 1, 15)?), "date")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(7, 0, 0)?), "07:00 local")
    h.assert_eq[I32](-(5 * 3600), zdt.offset_sec(), "EST offset")
    h.assert_eq[String]("EST", zdt.abbreviation(), "EST abbrev")
    h.assert_false(zdt.is_dst(), "not DST")


class iso _TestZoneNySummer is UnitTest
  fun name(): String => "Zone/America/New_York summer is EDT"
  fun apply(h: TestHelper) ? =>
    // 2026-07-15 12:00 UTC → local 08:00 EDT.
    let sec = _DateTimeMath.utc_posix_sec(2026, 7, 15, 12, 0, 0)?
    let zdt = ZonedDateTime.from_posix_in_zone((sec, 0), "America/New_York")?
    h.assert_true(zdt.local_date().eq(Date(2026, 7, 15)?), "date")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(8, 0, 0)?), "08:00 local")
    h.assert_eq[I32](-(4 * 3600), zdt.offset_sec(), "EDT offset")
    h.assert_eq[String]("EDT", zdt.abbreviation(), "EDT abbrev")
    h.assert_true(zdt.is_dst(), "is DST")


class iso _TestZoneNyTransitions is UnitTest
  fun name(): String => "Zone/America/New_York DST transition boundaries"
  fun apply(h: TestHelper) ? =>
    // 2026 spring forward: 2nd Sunday March = March 8, at 07:00 UTC.
    let spring = _DateTimeMath.utc_posix_sec(2026, 3, 8, 7, 0, 0)?
    let before = _DateTimeMath.utc_posix_sec(2026, 3, 8, 6, 59, 59)?
    let just_before = ZonedDateTime.from_posix_in_zone(
      (before, 0), "America/New_York")?
    h.assert_eq[String]("EST", just_before.abbreviation(),
      "1s before spring → still EST")
    let just_after = ZonedDateTime.from_posix_in_zone(
      (spring, 0), "America/New_York")?
    h.assert_eq[String]("EDT", just_after.abbreviation(),
      "at spring → EDT")

    // 2026 fall back: 1st Sunday November = Nov 1, at 06:00 UTC.
    let fall = _DateTimeMath.utc_posix_sec(2026, 11, 1, 6, 0, 0)?
    let before_fall = _DateTimeMath.utc_posix_sec(2026, 11, 1, 5, 59, 59)?
    let just_before_fall = ZonedDateTime.from_posix_in_zone(
      (before_fall, 0), "America/New_York")?
    h.assert_eq[String]("EDT", just_before_fall.abbreviation(),
      "1s before fall → still EDT")
    let just_after_fall = ZonedDateTime.from_posix_in_zone(
      (fall, 0), "America/New_York")?
    h.assert_eq[String]("EST", just_after_fall.abbreviation(),
      "at fall → EST")


class iso _TestZoneLaSummerWinter is UnitTest
  fun name(): String => "Zone/America/Los_Angeles seasons"
  fun apply(h: TestHelper) ? =>
    // Winter: PST (-8). January 15 2026 12:00 UTC → 04:00 PST.
    let win = _DateTimeMath.utc_posix_sec(2026, 1, 15, 12, 0, 0)?
    let zdt_win = ZonedDateTime.from_posix_in_zone(
      (win, 0), "America/Los_Angeles")?
    h.assert_true(zdt_win.local_tod().eq(TimeOfDay(4, 0, 0)?), "04:00 PST")
    h.assert_eq[I32](-(8 * 3600), zdt_win.offset_sec(), "PST offset")
    h.assert_eq[String]("PST", zdt_win.abbreviation())
    h.assert_false(zdt_win.is_dst())

    // Summer: PDT (-7). July 15 2026 12:00 UTC → 05:00 PDT.
    let sum = _DateTimeMath.utc_posix_sec(2026, 7, 15, 12, 0, 0)?
    let zdt_sum = ZonedDateTime.from_posix_in_zone(
      (sum, 0), "America/Los_Angeles")?
    h.assert_true(zdt_sum.local_tod().eq(TimeOfDay(5, 0, 0)?), "05:00 PDT")
    h.assert_eq[I32](-(7 * 3600), zdt_sum.offset_sec(), "PDT offset")
    h.assert_eq[String]("PDT", zdt_sum.abbreviation())
    h.assert_true(zdt_sum.is_dst())


class iso _TestZoneToTimezone is UnitTest
  fun name(): String => "Zone/to_timezone switches between IANA zones"
  fun apply(h: TestHelper) ? =>
    // Start UTC, switch to NY summer, verify local fields update.
    let sec = _DateTimeMath.utc_posix_sec(2026, 7, 15, 12, 0, 0)?
    let zdt = ZonedDateTime.from_posix((sec, 0))
    h.assert_eq[String]("UTC", zdt.zone_name(), "starts UTC")

    match zdt.to_timezone_in_place("America/New_York")
    | None => None
    | let _: TzLookupError => h.fail("NY should be known")
    end
    h.assert_eq[String]("America/New_York", zdt.zone_name(), "name updated")
    h.assert_true(zdt.local_tod().eq(TimeOfDay(8, 0, 0)?), "08:00 EDT")
    h.assert_eq[String]("EDT", zdt.abbreviation())

    // Switch again to LA.
    match zdt.to_timezone_in_place("America/Los_Angeles")
    | None => None
    | let _: TzLookupError => h.fail("LA should be known")
    end
    h.assert_true(zdt.local_tod().eq(TimeOfDay(5, 0, 0)?), "05:00 PDT")
    h.assert_eq[String]("PDT", zdt.abbreviation())

    // Unknown zone still fails cleanly.
    match zdt.to_timezone_in_place("Atlantis/Lost")
    | None => h.fail("Atlantis should be unknown")
    | ZoneNotFound => None
    | OutOfCoverage => h.fail("wrong variant")
    end


// ----- HISTORICAL_TZ-conditional tests -----
//
// These exercise paths that only become reachable when the year range
// is widened backward (default: 1970..=9999 → HISTORICAL_TZ: 1..=9999).
// In default builds they log-and-pass; in `-D HISTORICAL_TZ` builds they
// actually run their assertions.
//
// The floor-mod in `_TzData._make_observation` is the headline reason
// for these — within default scope, `local_sec_total` can't reach
// negative values because any pre-epoch local date fails Date.create.
// Widen the range and the branch becomes live.


class iso _TestDateHistoricalRange is UnitTest
  fun name(): String => "Date/HISTORICAL_TZ extends min year"
  fun apply(h: TestHelper) ? =>
    ifdef "HISTORICAL_TZ" then
      // Pre-1970 dates accepted.
      let dec31_1969 = Date(1969, 12, 31)?
      h.assert_eq[I32](-1, dec31_1969.days_since_epoch(),
        "Dec 31 1969 is one day before epoch")
      let jan1_1969 = Date(1969, 1, 1)?
      h.assert_eq[I32](-365, jan1_1969.days_since_epoch(),
        "Jan 1 1969 is 365 days before epoch")
      // Far-back date round-trips through Hinnant correctly.
      let mid_1844 = Date(1844, 6, 15)?
      let n = mid_1844.days_since_epoch()
      h.assert_true(n < 0, "1844 is pre-epoch")
      // Year 1 is allowed; year 0 is not (proleptic Gregorian has no year 0).
      h.assert_true((Date(1, 1, 1)?.year() == 1), "year 1 is the min")
      h.assert_error({() ? => Date(0, 1, 1)? }, "year 0 still rejected")
    else
      h.log("Skipped: needs -D HISTORICAL_TZ")
    end


class iso _TestZdtFloorModHistorical is UnitTest
  fun name(): String => "ZonedDateTime/floor-mod with HISTORICAL_TZ"
  fun apply(h: TestHelper) ? =>
    ifdef "HISTORICAL_TZ" then
      // 1970-01-01T01:00:00 UTC at offset -03:00 → 1969-12-31T22:00:00.
      // Without the floor-mod, `local_sec_total = -7200` would silently
      // produce 1970-01-01T00:00:00 instead.
      let z1 = ZonedDateTime.from_posix_at_offset((3600, 0), -(3 * 3600))
      h.assert_true(z1.local_date().eq(Date(1969, 12, 31)?),
        "01:00 UTC -3h: prev day")
      h.assert_true(z1.local_tod().eq(TimeOfDay(22, 0, 0)?),
        "01:00 UTC -3h: 22:00")

      // Epoch at offset -01:00 → 1969-12-31T23:00:00.
      let z2 = ZonedDateTime.from_posix_at_offset((0, 0), -3600)
      h.assert_true(z2.local_date().eq(Date(1969, 12, 31)?),
        "epoch -1h: prev day")
      h.assert_true(z2.local_tod().eq(TimeOfDay(23, 0, 0)?),
        "epoch -1h: 23:00")

      // Pre-epoch UTC (sec = -3600) at offset 0 → 1969-12-31T23:00:00.
      let z3 = ZonedDateTime.from_posix_at_offset((-3600, 0), 0)
      h.assert_true(z3.local_date().eq(Date(1969, 12, 31)?),
        "pre-epoch UTC: date")
      h.assert_true(z3.local_tod().eq(TimeOfDay(23, 0, 0)?),
        "pre-epoch UTC: tod")

      // Pre-epoch UTC + negative offset (compound backward shift).
      let z4 = ZonedDateTime.from_posix_at_offset((-3600, 0), -(2 * 3600))
      h.assert_true(z4.local_date().eq(Date(1969, 12, 31)?),
        "compound back: date")
      h.assert_true(z4.local_tod().eq(TimeOfDay(21, 0, 0)?),
        "compound back: 21:00")

      // Forward across a pre-epoch year boundary. 1968-12-31T23:00 UTC +
      // 2h offset → 1969-01-01T01:00.
      let days_dec31_1968 = Date(1968, 12, 31)?.days_since_epoch().i64()
      let posix_23 = (days_dec31_1968 * 86400) + (23 * 3600)
      let z5 = ZonedDateTime.from_posix_at_offset((posix_23, 0), 2 * 3600)
      h.assert_true(z5.local_date().eq(Date(1969, 1, 1)?),
        "1968-12-31 + 2h: rolled to 1969")
      h.assert_true(z5.local_tod().eq(TimeOfDay(1, 0, 0)?),
        "1968-12-31 + 2h: 01:00")
    else
      h.log("Skipped: needs -D HISTORICAL_TZ")
    end


class iso _TestZdtStringHistorical is UnitTest
  fun name(): String => "ZonedDateTime/string with HISTORICAL_TZ pre-epoch"
  fun apply(h: TestHelper) =>
    ifdef "HISTORICAL_TZ" then
      // Pre-epoch UTC.
      h.assert_eq[String](
        "1969-12-31T23:00:00Z",
        ZonedDateTime.from_posix((-3600, 0)).string())
      // Day-crossing with negative offset producing pre-epoch local.
      h.assert_eq[String](
        "1969-12-31T22:00:00-03:00",
        ZonedDateTime.from_posix_at_offset(
          (3600, 0), -(3 * 3600)).string())
    else
      h.log("Skipped: needs -D HISTORICAL_TZ")
    end


// ---- Phase 6: differential test against zdump ----
//
// Each row is a (zone, UTC instant) → expected Observation pair
// captured verbatim from `zdump -v`. We compute the UTC POSIX
// second from (y,m,d,hh,mn,ss) and ask `_TzData.observation_at`
// for the observation, then assert every field matches what zdump
// reported.
//
// Coverage spans:
//   - UTC (trivial: zero offset, no DST, no transitions)
//   - America/New_York 2025-2027 spring/fall boundaries (off-by-one
//     at the transition second matters here — the table dispatch
//     uses `sec < t`, so `t` itself is the new offset)
//   - America/Los_Angeles 2025/2026 (different offset to surface
//     bugs in the per-zone primitive selection)
//   - Europe/London 2026 (different DST grammar: M3.5.0/1 +
//     M10.5.0; the "last Sunday" disambiguation and the /1 time)
//   - America/Los_Angeles 2080: past LA's explicit transition
//     table (~2067), so the POSIX-TZ-trailer extrapolation kicks
//     in. Same shape as the table entries — proves the fallback
//     evaluator agrees with what zic would have produced.
//   - Unknown zone: ZoneNotFound.


primitive _Zdump
  fun apply(
    h: TestHelper, zone: String val,
    utc_y: I16, utc_m: U8, utc_d: U8,
    utc_hh: U8, utc_mn: U8, utc_ss: U8,
    loc_y: I16, loc_m: U8, loc_d: U8,
    loc_hh: U8, loc_mn: U8, loc_ss: U8,
    expected_offset_sec: I32, expected_abbrev: String val,
    expected_isdst: Bool)
    ?
  =>
    """
    Compute the UTC POSIX second for the given UTC moment, look up
    the observation, and assert each field. Partial because Date
    construction is partial.
    """
    let utc_sec: I64 =
      (Date(utc_y, utc_m, utc_d)?.days_since_epoch().i64() * 86_400)
        + (utc_hh.i64() * 3600)
        + (utc_mn.i64() * 60)
        + utc_ss.i64()
    let label: String val = recover val
      let s = String(48)
      s.append(zone)
      s.append(" @ ")
      s.append(utc_y.string())
      s.append("-")
      s.append(utc_m.string())
      s.append("-")
      s.append(utc_d.string())
      s.append("T")
      s.append(utc_hh.string())
      s.append(":")
      s.append(utc_mn.string())
      s.append(":")
      s.append(utc_ss.string())
      s.append("Z")
      s
    end
    match _TzData.observation_at(zone, utc_sec, 0)
    | let o: Observation val =>
      h.assert_eq[I16](loc_y, o.local_date().year(), label + " local year")
      h.assert_eq[U8](loc_m, o.local_date().month(), label + " local month")
      h.assert_eq[U8](loc_d, o.local_date().day(), label + " local day")
      h.assert_eq[U8](loc_hh, o.local_tod().hour(), label + " local hour")
      h.assert_eq[U8](loc_mn, o.local_tod().minute(), label + " local minute")
      h.assert_eq[U8](loc_ss, o.local_tod().second(), label + " local second")
      h.assert_eq[I32](expected_offset_sec, o.offset_sec(), label + " offset")
      h.assert_eq[String](expected_abbrev, o.abbreviation(), label + " abbrev")
      h.assert_eq[Bool](expected_isdst, o.is_dst(), label + " isdst")
    | let _: TzLookupError => h.fail(label + " lookup failed")
    end


class iso _TestZdumpDifferentialUtc is UnitTest
  fun name(): String => "tzdata/zdump diff: UTC"
  fun apply(h: TestHelper) ? =>
    // UTC has one type, no transitions — every instant maps to (0, "UTC", false).
    _Zdump(h, "UTC", 2026, 5, 22, 12, 0, 0,
              2026, 5, 22, 12, 0, 0,
              0, "UTC", false)?
    _Zdump(h, "UTC", 1970, 1, 1, 0, 0, 0,
              1970, 1, 1, 0, 0, 0,
              0, "UTC", false)?
    _Zdump(h, "UTC", 2080, 12, 31, 23, 59, 59,
              2080, 12, 31, 23, 59, 59,
              0, "UTC", false)?


class iso _TestZdumpDifferentialNy is UnitTest
  fun name(): String => "tzdata/zdump diff: America/New_York 2025-2027"
  fun apply(h: TestHelper) ? =>
    // 2025 spring: Mar 9.
    _Zdump(h, "America/New_York", 2025, 3, 9, 6, 59, 59,
              2025, 3, 9, 1, 59, 59, -18000, "EST", false)?
    _Zdump(h, "America/New_York", 2025, 3, 9, 7, 0, 0,
              2025, 3, 9, 3, 0, 0, -14400, "EDT", true)?
    // 2025 fall: Nov 2.
    _Zdump(h, "America/New_York", 2025, 11, 2, 5, 59, 59,
              2025, 11, 2, 1, 59, 59, -14400, "EDT", true)?
    _Zdump(h, "America/New_York", 2025, 11, 2, 6, 0, 0,
              2025, 11, 2, 1, 0, 0, -18000, "EST", false)?
    // 2026 spring: Mar 8.
    _Zdump(h, "America/New_York", 2026, 3, 8, 6, 59, 59,
              2026, 3, 8, 1, 59, 59, -18000, "EST", false)?
    _Zdump(h, "America/New_York", 2026, 3, 8, 7, 0, 0,
              2026, 3, 8, 3, 0, 0, -14400, "EDT", true)?
    // 2026 fall: Nov 1.
    _Zdump(h, "America/New_York", 2026, 11, 1, 5, 59, 59,
              2026, 11, 1, 1, 59, 59, -14400, "EDT", true)?
    _Zdump(h, "America/New_York", 2026, 11, 1, 6, 0, 0,
              2026, 11, 1, 1, 0, 0, -18000, "EST", false)?
    // 2027 spring: Mar 14.
    _Zdump(h, "America/New_York", 2027, 3, 14, 6, 59, 59,
              2027, 3, 14, 1, 59, 59, -18000, "EST", false)?
    _Zdump(h, "America/New_York", 2027, 3, 14, 7, 0, 0,
              2027, 3, 14, 3, 0, 0, -14400, "EDT", true)?


class iso _TestZdumpDifferentialLa is UnitTest
  fun name(): String => "tzdata/zdump diff: America/Los_Angeles 2025-2026"
  fun apply(h: TestHelper) ? =>
    // 2025 spring: Mar 9.
    _Zdump(h, "America/Los_Angeles", 2025, 3, 9, 9, 59, 59,
              2025, 3, 9, 1, 59, 59, -28800, "PST", false)?
    _Zdump(h, "America/Los_Angeles", 2025, 3, 9, 10, 0, 0,
              2025, 3, 9, 3, 0, 0, -25200, "PDT", true)?
    // 2025 fall: Nov 2.
    _Zdump(h, "America/Los_Angeles", 2025, 11, 2, 8, 59, 59,
              2025, 11, 2, 1, 59, 59, -25200, "PDT", true)?
    _Zdump(h, "America/Los_Angeles", 2025, 11, 2, 9, 0, 0,
              2025, 11, 2, 1, 0, 0, -28800, "PST", false)?
    // 2026 spring + fall.
    _Zdump(h, "America/Los_Angeles", 2026, 3, 8, 9, 59, 59,
              2026, 3, 8, 1, 59, 59, -28800, "PST", false)?
    _Zdump(h, "America/Los_Angeles", 2026, 3, 8, 10, 0, 0,
              2026, 3, 8, 3, 0, 0, -25200, "PDT", true)?
    _Zdump(h, "America/Los_Angeles", 2026, 11, 1, 8, 59, 59,
              2026, 11, 1, 1, 59, 59, -25200, "PDT", true)?
    _Zdump(h, "America/Los_Angeles", 2026, 11, 1, 9, 0, 0,
              2026, 11, 1, 1, 0, 0, -28800, "PST", false)?


class iso _TestZdumpDifferentialLondon is UnitTest
  fun name(): String => "tzdata/zdump diff: Europe/London 2025-2026"
  fun apply(h: TestHelper) ? =>
    // 2025 BST start (M3.5.0/1): Mar 30 01:00 UTC → 02:00 BST.
    _Zdump(h, "Europe/London", 2025, 3, 30, 0, 59, 59,
              2025, 3, 30, 0, 59, 59, 0, "GMT", false)?
    _Zdump(h, "Europe/London", 2025, 3, 30, 1, 0, 0,
              2025, 3, 30, 2, 0, 0, 3600, "BST", true)?
    // 2025 BST end (M10.5.0/2 default): Oct 26 01:00 UTC → 01:00 GMT.
    _Zdump(h, "Europe/London", 2025, 10, 26, 0, 59, 59,
              2025, 10, 26, 1, 59, 59, 3600, "BST", true)?
    _Zdump(h, "Europe/London", 2025, 10, 26, 1, 0, 0,
              2025, 10, 26, 1, 0, 0, 0, "GMT", false)?
    // 2026.
    _Zdump(h, "Europe/London", 2026, 3, 29, 0, 59, 59,
              2026, 3, 29, 0, 59, 59, 0, "GMT", false)?
    _Zdump(h, "Europe/London", 2026, 3, 29, 1, 0, 0,
              2026, 3, 29, 2, 0, 0, 3600, "BST", true)?
    _Zdump(h, "Europe/London", 2026, 10, 25, 0, 59, 59,
              2026, 10, 25, 1, 59, 59, 3600, "BST", true)?
    _Zdump(h, "Europe/London", 2026, 10, 25, 1, 0, 0,
              2026, 10, 25, 1, 0, 0, 0, "GMT", false)?


class iso _TestZdumpDifferentialPosixFallback is UnitTest
  fun name(): String => "tzdata/zdump diff: POSIX-TZ fallback (LA 2080, London 2038)"
  fun apply(h: TestHelper) ? =>
    """
    Past the explicit transition table, the generated dispatch falls
    through to the POSIX-TZ-trailer-driven branch. These instants
    sit beyond the last `elseif sec <` entry for their zone and so
    are computed via `_TzData.mwd_local_to_utc(...)` at runtime.
    """
    // LA 2080-03-10 10:00 UTC = 2080-03-10 03:00 PDT.
    _Zdump(h, "America/Los_Angeles", 2080, 3, 10, 9, 59, 59,
              2080, 3, 10, 1, 59, 59, -28800, "PST", false)?
    _Zdump(h, "America/Los_Angeles", 2080, 3, 10, 10, 0, 0,
              2080, 3, 10, 3, 0, 0, -25200, "PDT", true)?
    _Zdump(h, "America/Los_Angeles", 2080, 11, 3, 8, 59, 59,
              2080, 11, 3, 1, 59, 59, -25200, "PDT", true)?
    _Zdump(h, "America/Los_Angeles", 2080, 11, 3, 9, 0, 0,
              2080, 11, 3, 1, 0, 0, -28800, "PST", false)?
    // London 2038-03-28 01:00 UTC = 2038-03-28 02:00 BST.
    _Zdump(h, "Europe/London", 2038, 3, 28, 0, 59, 59,
              2038, 3, 28, 0, 59, 59, 0, "GMT", false)?
    _Zdump(h, "Europe/London", 2038, 3, 28, 1, 0, 0,
              2038, 3, 28, 2, 0, 0, 3600, "BST", true)?
    _Zdump(h, "Europe/London", 2038, 10, 31, 0, 59, 59,
              2038, 10, 31, 1, 59, 59, 3600, "BST", true)?
    _Zdump(h, "Europe/London", 2038, 10, 31, 1, 0, 0,
              2038, 10, 31, 1, 0, 0, 0, "GMT", false)?


class iso _TestZdumpDifferentialUnknownZone is UnitTest
  fun name(): String => "tzdata/zdump diff: unknown zone → ZoneNotFound"
  fun apply(h: TestHelper) =>
    // Not in any IANA distribution. The generated dispatch's
    // else-arm returns ZoneNotFound; library MUST NOT silently
    // fall back to UTC.
    match _TzData.observation_at("Mars/Olympus_Mons", 0, 0)
    | let _: Observation val => h.fail("expected ZoneNotFound")
    | ZoneNotFound => None
    | OutOfCoverage => h.fail("expected ZoneNotFound, got OutOfCoverage")
    end


class iso _TestZdumpDifferentialTokyoNoDst is UnitTest
  fun name(): String => "tzdata/zdump diff: Asia/Tokyo (no DST, +9h)"
  fun apply(h: TestHelper) ? =>
    // Japan dropped DST in 1951. The modern entry is JST = UTC+9
    // with no transitions in the table after that. Both instants
    // below should report JST.
    _Zdump(h, "Asia/Tokyo", 2025, 1, 15, 3, 0, 0,
              2025, 1, 15, 12, 0, 0, 32400, "JST", false)?
    _Zdump(h, "Asia/Tokyo", 2026, 7, 4, 15, 0, 0,
              2026, 7, 5, 0, 0, 0, 32400, "JST", false)?


class iso _TestZdumpDifferentialKolkataHalfHour is UnitTest
  fun name(): String => "tzdata/zdump diff: Asia/Kolkata (+5:30, half-hour offset)"
  fun apply(h: TestHelper) ? =>
    // IST = UTC+5:30, no DST. Half-hour offset exercises the
    // `offset_sec` field; 19800 = 5*3600 + 30*60.
    _Zdump(h, "Asia/Kolkata", 2026, 5, 25, 18, 30, 0,
              2026, 5, 26, 0, 0, 0, 19800, "IST", false)?
    // Cross-midnight wrap: 18:29:59 UTC = 23:59:59 local same day.
    _Zdump(h, "Asia/Kolkata", 2026, 5, 25, 18, 29, 59,
              2026, 5, 25, 23, 59, 59, 19800, "IST", false)?


class iso _TestZdumpDifferentialAucklandSouthernHemi is UnitTest
  fun name(): String => "tzdata/zdump diff: Pacific/Auckland (southern hemi DST)"
  fun apply(h: TestHelper) ? =>
    // NZ DST runs the opposite calendar of the northern hemisphere:
    // NZDT ends April 6 2025 at 14:00 UTC (03:00 local NZDT → 02:00
    // local NZST), NZDT starts Sept 28 2025 at 14:00 UTC.
    _Zdump(h, "Pacific/Auckland", 2025, 4, 5, 13, 59, 59,
              2025, 4, 6, 2, 59, 59, 46800, "NZDT", true)?
    _Zdump(h, "Pacific/Auckland", 2025, 4, 5, 14, 0, 0,
              2025, 4, 6, 2, 0, 0, 43200, "NZST", false)?
    _Zdump(h, "Pacific/Auckland", 2025, 9, 27, 13, 59, 59,
              2025, 9, 28, 1, 59, 59, 43200, "NZST", false)?
    _Zdump(h, "Pacific/Auckland", 2025, 9, 27, 14, 0, 0,
              2025, 9, 28, 3, 0, 0, 46800, "NZDT", true)?


class iso _TestZdumpDifferentialHistoricalGate is UnitTest
  fun name(): String => "tzdata/zdump diff: pre-1970 gated by HISTORICAL_TZ"
  fun apply(h: TestHelper) =>
    """
    The first NY transition is 1883-11-18 17:00 UTC = sec
    -2717650800. One second earlier (sec -2717650801) is the LMT
    era. The library's behavior at that instant depends on the
    compile mode:

    - Default build: pre-1970 instants are gated out, so the
      observation lookup returns OutOfCoverage.
    - `-D HISTORICAL_TZ` build: the historical ladder is in scope
      and produces the LMT observation that zdump reports as
      offset -17762 sec ("LMT", isdst=0).
    """
    let lmt_era_utc: I64 = -2_717_650_801

    ifdef "HISTORICAL_TZ" then
      match _TzData.observation_at("America/New_York", lmt_era_utc, 0)
      | let o: Observation val =>
        h.assert_eq[I16](1883, o.local_date().year(), "LMT year")
        h.assert_eq[U8](11, o.local_date().month(), "LMT month")
        h.assert_eq[U8](18, o.local_date().day(), "LMT day")
        h.assert_eq[U8](12, o.local_tod().hour(), "LMT hour")
        h.assert_eq[U8](3, o.local_tod().minute(), "LMT minute")
        h.assert_eq[U8](57, o.local_tod().second(), "LMT second")
        h.assert_eq[I32](-17762, o.offset_sec(), "LMT offset")
        h.assert_eq[String]("LMT", o.abbreviation(), "LMT abbreviation")
        h.assert_eq[Bool](false, o.is_dst(), "LMT isdst")
      | OutOfCoverage =>
        h.fail("HISTORICAL_TZ build: expected LMT, got OutOfCoverage")
      | ZoneNotFound => h.fail("expected LMT, got ZoneNotFound")
      end
    else
      match _TzData.observation_at("America/New_York", lmt_era_utc, 0)
      | let _: Observation val =>
        h.fail("default build: expected OutOfCoverage for pre-1970 NY")
      | OutOfCoverage => None
      | ZoneNotFound => h.fail("expected OutOfCoverage, got ZoneNotFound")
      end
    end


class iso _TestZdumpDifferentialLordHowe30Min is UnitTest
  fun name(): String => "tzdata/zdump diff: Australia/Lord_Howe (30-min DST)"
  fun apply(h: TestHelper) ? =>
    """
    Lord_Howe is the only IANA zone with a 30-minute DST step
    (rather than the usual 60). Spring-forward jumps clocks 30
    minutes ahead; fall-back rewinds 30 minutes. Abbreviations are
    the numeric forms "+11" and "+1030".
    """
    // 2025 fall-back (Apr 6): +11 → +1030, 30-minute rewind.
    _Zdump(h, "Australia/Lord_Howe", 2025, 4, 5, 14, 59, 59,
              2025, 4, 6, 1, 59, 59, 39600, "+11", true)?
    _Zdump(h, "Australia/Lord_Howe", 2025, 4, 5, 15, 0, 0,
              2025, 4, 6, 1, 30, 0, 37800, "+1030", false)?
    // 2025 spring-forward (Oct 5): +1030 → +11, 30-minute jump.
    _Zdump(h, "Australia/Lord_Howe", 2025, 10, 4, 15, 29, 59,
              2025, 10, 5, 1, 59, 59, 37800, "+1030", false)?
    _Zdump(h, "Australia/Lord_Howe", 2025, 10, 4, 15, 30, 0,
              2025, 10, 5, 2, 30, 0, 39600, "+11", true)?


class iso _TestZdumpDifferentialChatham is UnitTest
  fun name(): String => "tzdata/zdump diff: Pacific/Chatham (+12:45 offset)"
  fun apply(h: TestHelper) ? =>
    """
    Chatham Islands sit 45 minutes east of NZ proper, giving the
    only :45 offset still in use: +12:45 STD, +13:45 DST.
    Exercises the offset_sec field at sub-half-hour granularity.
    """
    // 2025 fall-back: +1345 → +1245.
    _Zdump(h, "Pacific/Chatham", 2025, 4, 5, 13, 59, 59,
              2025, 4, 6, 3, 44, 59, 49500, "+1345", true)?
    _Zdump(h, "Pacific/Chatham", 2025, 4, 5, 14, 0, 0,
              2025, 4, 6, 2, 45, 0, 45900, "+1245", false)?
    // 2025 spring-forward: +1245 → +1345.
    _Zdump(h, "Pacific/Chatham", 2025, 9, 27, 13, 59, 59,
              2025, 9, 28, 2, 44, 59, 45900, "+1245", false)?
    _Zdump(h, "Pacific/Chatham", 2025, 9, 27, 14, 0, 0,
              2025, 9, 28, 3, 45, 0, 49500, "+1345", true)?


class iso _TestZdumpDifferentialIndianapolis2006Switch is UnitTest
  fun name(): String => "tzdata/zdump diff: Indianapolis 2006 DST adoption"
  fun apply(h: TestHelper) ? =>
    """
    Indiana switched from year-round EST to observing DST in 2006.
    The very first Indianapolis EDT transition (Apr 2 2006) is in
    the post-1970 explicit table — verifies dispatch picks up the
    new rule rather than continuing the prior EST-always behavior.
    """
    _Zdump(h, "America/Indiana/Indianapolis", 2006, 4, 2, 6, 59, 59,
              2006, 4, 2, 1, 59, 59, -18000, "EST", false)?
    _Zdump(h, "America/Indiana/Indianapolis", 2006, 4, 2, 7, 0, 0,
              2006, 4, 2, 3, 0, 0, -14400, "EDT", true)?
    // And a recent transition for sanity:
    _Zdump(h, "America/Indiana/Indianapolis", 2026, 3, 8, 7, 0, 0,
              2026, 3, 8, 3, 0, 0, -14400, "EDT", true)?


class iso _TestZdumpDifferentialPyongyangSameNameOffsetShift is UnitTest
  fun name(): String => "tzdata/zdump diff: Pyongyang abbrev steady, offset shifts"
  fun apply(h: TestHelper) ? =>
    """
    North Korea shifted from KST UTC+9 to KST UTC+8:30 on 2015-08-15,
    then back to KST UTC+9 on 2018-05-05. The abbreviation string
    "KST" is unchanged across both transitions while the offset
    actually changes — exercises the (abbrev, offset) pair as
    independent observation fields, not a single conflated label.
    """
    // 2015-Aug-14 15:00 UTC: offset drops from +9h to +8:30.
    _Zdump(h, "Asia/Pyongyang", 2015, 8, 14, 14, 59, 59,
              2015, 8, 14, 23, 59, 59, 32400, "KST", false)?
    _Zdump(h, "Asia/Pyongyang", 2015, 8, 14, 15, 0, 0,
              2015, 8, 14, 23, 30, 0, 30600, "KST", false)?
    // 2018-May-04 15:00 UTC: offset shifts back to +9h.
    _Zdump(h, "Asia/Pyongyang", 2018, 5, 4, 14, 59, 59,
              2018, 5, 4, 23, 29, 59, 30600, "KST", false)?
    _Zdump(h, "Asia/Pyongyang", 2018, 5, 4, 15, 0, 0,
              2018, 5, 5, 0, 0, 0, 32400, "KST", false)?


class iso _TestZdumpDifferentialAliasRoutesToCanonical is UnitTest
  fun name(): String => "tzdata/zdump diff: alias routes to canonical"
  fun apply(h: TestHelper) =>
    """
    The codegen tool dedupes content-identical tzfiles into a single
    primitive. On most distros `UTC` is a symlink to `Etc/UTC`, so
    `_TzData.observation_at("UTC", ...)` dispatches into the
    canonical `_ZoneEtcUTC.observation_at`. Look up the same UTC
    second through both names; the Observations must be field-for-
    field identical. If the dedup ever wired an alias to the wrong
    canonical, this test catches the divergence.
    """
    let probe_utc: I64 = 1748278800  // arbitrary 2026 instant
    let via_alias = _TzData.observation_at("UTC", probe_utc, 0)
    let via_canonical = _TzData.observation_at("Etc/UTC", probe_utc, 0)
    match (via_alias, via_canonical)
    | (let a: Observation val, let c: Observation val) =>
      h.assert_eq[I16](c.local_date().year(), a.local_date().year(),
        "year matches")
      h.assert_eq[U8](c.local_date().month(), a.local_date().month(),
        "month matches")
      h.assert_eq[U8](c.local_date().day(), a.local_date().day(),
        "day matches")
      h.assert_eq[U8](c.local_tod().hour(), a.local_tod().hour(),
        "hour matches")
      h.assert_eq[U8](c.local_tod().minute(), a.local_tod().minute(),
        "minute matches")
      h.assert_eq[U8](c.local_tod().second(), a.local_tod().second(),
        "second matches")
      h.assert_eq[I32](c.offset_sec(), a.offset_sec(), "offset matches")
      h.assert_eq[String](c.abbreviation(), a.abbreviation(),
        "abbreviation matches")
      h.assert_eq[Bool](c.is_dst(), a.is_dst(), "isdst matches")
    else
      h.fail("expected Observation for both UTC and Etc/UTC")
    end
