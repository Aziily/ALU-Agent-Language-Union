flow babel_lib:
  steps:
    - dates_group
    - languages_group
    - lists_group
    - localedata_group
    - localtime__helpers_group
    - localtime__unix_group
    - localtime__win32_group
    - messages_catalog_group
    - messages_checkers_group
    - messages_extract_group
    - messages_frontend_group
    - messages_jslexer_group
    - messages_mofile_group
    - messages_plurals_group
    - messages_pofile_group
    - messages_setuptools_frontend_group
    - numbers_group
    - support_group
    - units_group
    - util_group


flow dates_group:
  steps:
    - _get_dt_and_tzinfo
    - _get_tz_name
    - _get_datetime
    - _ensure_datetime_tzinfo
    - _get_time
    - get_timezone
    - get_period_names
    - get_day_names
    - get_month_names
    - get_quarter_names
    - get_era_names
    - get_date_format
    - get_datetime_format
    - get_time_format
    - get_timezone_gmt
    - get_timezone_location
    - get_timezone_name
    - format_date
    - format_datetime
    - format_time
    - format_skeleton
    - format_timedelta
    - format_interval
    - get_period_id
    - parse_date
    - parse_time
    - DateTimeFormat__format_weekday
    - DateTimeFormat__format_period
    - DateTimeFormat__format_frac_seconds
    - DateTimeFormat__get_week_number
    - parse_pattern
    - tokenize_pattern
    - untokenize_pattern
    - split_interval_pattern
    - match_skeleton


flow languages_group:
  steps:
    - get_official_languages
    - get_territory_language_info


flow lists_group:
  steps:
    - format_list


flow localedata_group:
  steps:
    - normalize_locale
    - resolve_locale_filename
    - exists
    - locale_identifiers
    - load
    - merge
    - Alias__resolve


flow localtime__helpers_group:
  steps:
    - _get_tzinfo


flow localtime__unix_group:
  steps:
    - _get_localzone


flow localtime__win32_group:
  steps:
    - valuestodict


flow messages_catalog_group:
  steps:
    - get_close_matches
    - Message__is_identical
    - Message__check
    - Message__fuzzy
    - Message__pluralizable
    - Message__python_format
    - Catalog__num_plurals
    - Catalog__plural_expr
    - Catalog__plural_forms
    - Catalog__add
    - Catalog__check
    - Catalog__get
    - Catalog__delete
    - Catalog__update
    - Catalog___to_fuzzy_match_key
    - Catalog___key_for
    - Catalog__is_identical


flow messages_checkers_group:
  steps:
    - num_plurals
    - python_format
    - _validate_format


flow messages_extract_group:
  steps:
    - _strip_comment_tags
    - extract_from_dir
    - check_and_call_extract_file
    - extract_from_file
    - extract
    - extract_nothing
    - extract_python
    - extract_javascript
    - parse_template_string


flow messages_frontend_group:
  steps:
    - listify_value
    - _make_directory_filter
    - CommandLineInterface__run
    - CommandLineInterface___configure_command
    - parse_mapping
    - parse_keywords


flow messages_jslexer_group:
  steps:
    - get_rules
    - indicates_division
    - unquote_string
    - tokenize


flow messages_mofile_group:
  steps:
    - read_mo
    - write_mo


flow messages_plurals_group:
  steps:
    - get_plural


flow messages_pofile_group:
  steps:
    - unescape
    - denormalize
    - PoFileParser___add_message
    - PoFileParser__parse
    - read_po
    - escape
    - normalize
    - write_po
    - _sort_messages


flow messages_setuptools_frontend_group:
  steps:
    - check_message_extractors


flow numbers_group:
  steps:
    - list_currencies
    - validate_currency
    - is_currency
    - normalize_currency
    - get_currency_name
    - get_currency_symbol
    - get_currency_precision
    - get_currency_unit_pattern
    - get_territory_currencies
    - get_decimal_symbol
    - get_plus_sign_symbol
    - get_minus_sign_symbol
    - get_exponential_symbol
    - get_group_symbol
    - get_infinity_symbol
    - format_number
    - get_decimal_precision
    - get_decimal_quantum
    - format_decimal
    - format_compact_decimal
    - _get_compact_format
    - format_currency
    - format_compact_currency
    - format_percent
    - format_scientific
    - parse_number
    - parse_decimal
    - _remove_trailing_zeros_after_decimal
    - parse_grouping
    - parse_pattern
    - NumberPattern__compute_scale
    - NumberPattern__scientific_notation_elements
    - NumberPattern__apply


flow support_group:
  steps:
    - Format__date
    - Format__datetime
    - Format__time
    - Format__timedelta
    - Format__number
    - Format__decimal
    - Format__compact_decimal
    - Format__currency
    - Format__compact_currency
    - Format__percent
    - Format__scientific
    - NullTranslations__dgettext
    - NullTranslations__ldgettext
    - NullTranslations__udgettext
    - NullTranslations__dngettext
    - NullTranslations__ldngettext
    - NullTranslations__udngettext
    - NullTranslations__pgettext
    - NullTranslations__lpgettext
    - NullTranslations__npgettext
    - NullTranslations__lnpgettext
    - NullTranslations__upgettext
    - NullTranslations__unpgettext
    - NullTranslations__dpgettext
    - NullTranslations__udpgettext
    - NullTranslations__ldpgettext
    - NullTranslations__dnpgettext
    - NullTranslations__udnpgettext
    - NullTranslations__ldnpgettext
    - Translations__load
    - Translations__add
    - Translations__merge
    - _locales_to_names


flow units_group:
  steps:
    - get_unit_name
    - _find_unit_pattern
    - format_unit
    - _find_compound_unit
    - format_compound_unit


flow util_group:
  steps:
    - distinct
    - parse_encoding
    - parse_future_flags
    - pathmatch
    - wraptext


code _get_dt_and_tzinfo:
  body: |
    def _get_dt_and_tzinfo(dt_or_tzinfo: _DtOrTzinfo):
        """
        Parse a `dt_or_tzinfo` value into a datetime and a tzinfo.
    
        See the docs for this function's callers for semantics.
    
        :rtype: tuple[datetime, tzinfo]
        
        """
        pass


code _get_tz_name:
  body: |
    def _get_tz_name(dt_or_tzinfo: _DtOrTzinfo):
        """
        Get the timezone name out of a time, datetime, or tzinfo object.
    
        :rtype: str
        
        """
        pass


code _get_datetime:
  body: |
    def _get_datetime(instant: _Instant):
        """
        Get a datetime out of an "instant" (date, time, datetime, number).
    
        .. warning:: The return values of this function may depend on the system clock.
    
        If the instant is None, the current moment is used.
        If the instant is a time, it's augmented with today's date.
    
        Dates are converted to naive datetimes with midnight as the time component.
    
        >>> from datetime import date, datetime
        >>> _get_datetime(date(2015, 1, 1))
        datetime.datetime(2015, 1, 1, 0, 0)
    
        UNIX timestamps are converted to datetimes.
    
        >>> _get_datetime(1400000000)
        datetime.datetime(2014, 5, 13, 16, 53, 20)
    
        Other values are passed through as-is.
    
        >>> x = datetime(2015, 1, 1)
        >>> _get_datetime(x) is x
        True
    
        :param instant: date, time, datetime, integer, float or None
        :type instant: date|time|datetime|int|float|None
        :return: a datetime
        :rtype: datetime
        
        """
        pass


code _ensure_datetime_tzinfo:
  body: |
    def _ensure_datetime_tzinfo(dt: datetime.datetime, tzinfo: datetime.tzinfo | None=None):
        """
        Ensure the datetime passed has an attached tzinfo.
    
        If the datetime is tz-naive to begin with, UTC is attached.
    
        If a tzinfo is passed in, the datetime is normalized to that timezone.
    
        >>> from datetime import datetime
        >>> _get_tz_name(_ensure_datetime_tzinfo(datetime(2015, 1, 1)))
        'UTC'
    
        >>> tz = get_timezone("Europe/Stockholm")
        >>> _ensure_datetime_tzinfo(datetime(2015, 1, 1, 13, 15, tzinfo=UTC), tzinfo=tz).hour
        14
    
        :param datetime: Datetime to augment.
        :param tzinfo: optional tzinfo
        :return: datetime with tzinfo
        :rtype: datetime
        
        """
        pass


code _get_time:
  body: |
    def _get_time(time: datetime.time | datetime.datetime | None, tzinfo: datetime.tzinfo | None=None):
        """
        Get a timezoned time from a given instant.
    
        .. warning:: The return values of this function may depend on the system clock.
    
        :param time: time, datetime or None
        :rtype: time
        
        """
        pass


code get_timezone:
  body: |
    def get_timezone(zone: str | datetime.tzinfo | None=None):
        """Looks up a timezone by name and returns it.  The timezone object
        returned comes from ``pytz`` or ``zoneinfo``, whichever is available.
        It corresponds to the `tzinfo` interface and can be used with all of
        the functions of Babel that operate with dates.
    
        If a timezone is not known a :exc:`LookupError` is raised.  If `zone`
        is ``None`` a local zone object is returned.
    
        :param zone: the name of the timezone to look up.  If a timezone object
                     itself is passed in, it's returned unchanged.
        
        """
        pass


code get_period_names:
  body: |
    def get_period_names(width: Literal['abbreviated', 'narrow', 'wide']='wide', context: _Context='stand-alone', locale: Locale | str | None=LC_TIME):
        """Return the names for day periods (AM/PM) used by the locale.
    
        >>> get_period_names(locale='en_US')['am']
        u'AM'
    
        :param width: the width to use, one of "abbreviated", "narrow", or "wide"
        :param context: the context, either "format" or "stand-alone"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_day_names:
  body: |
    def get_day_names(width: Literal['abbreviated', 'narrow', 'short', 'wide']='wide', context: _Context='format', locale: Locale | str | None=LC_TIME):
        """Return the day names used by the locale for the specified format.
    
        >>> get_day_names('wide', locale='en_US')[1]
        u'Tuesday'
        >>> get_day_names('short', locale='en_US')[1]
        u'Tu'
        >>> get_day_names('abbreviated', locale='es')[1]
        u'mar'
        >>> get_day_names('narrow', context='stand-alone', locale='de_DE')[1]
        u'D'
    
        :param width: the width to use, one of "wide", "abbreviated", "short" or "narrow"
        :param context: the context, either "format" or "stand-alone"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_month_names:
  body: |
    def get_month_names(width: Literal['abbreviated', 'narrow', 'wide']='wide', context: _Context='format', locale: Locale | str | None=LC_TIME):
        """Return the month names used by the locale for the specified format.
    
        >>> get_month_names('wide', locale='en_US')[1]
        u'January'
        >>> get_month_names('abbreviated', locale='es')[1]
        u'ene'
        >>> get_month_names('narrow', context='stand-alone', locale='de_DE')[1]
        u'J'
    
        :param width: the width to use, one of "wide", "abbreviated", or "narrow"
        :param context: the context, either "format" or "stand-alone"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_quarter_names:
  body: |
    def get_quarter_names(width: Literal['abbreviated', 'narrow', 'wide']='wide', context: _Context='format', locale: Locale | str | None=LC_TIME):
        """Return the quarter names used by the locale for the specified format.
    
        >>> get_quarter_names('wide', locale='en_US')[1]
        u'1st quarter'
        >>> get_quarter_names('abbreviated', locale='de_DE')[1]
        u'Q1'
        >>> get_quarter_names('narrow', locale='de_DE')[1]
        u'1'
    
        :param width: the width to use, one of "wide", "abbreviated", or "narrow"
        :param context: the context, either "format" or "stand-alone"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_era_names:
  body: |
    def get_era_names(width: Literal['abbreviated', 'narrow', 'wide']='wide', locale: Locale | str | None=LC_TIME):
        """Return the era names used by the locale for the specified format.
    
        >>> get_era_names('wide', locale='en_US')[1]
        u'Anno Domini'
        >>> get_era_names('abbreviated', locale='de_DE')[1]
        u'n. Chr.'
    
        :param width: the width to use, either "wide", "abbreviated", or "narrow"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_date_format:
  body: |
    def get_date_format(format: _PredefinedTimeFormat='medium', locale: Locale | str | None=LC_TIME):
        """Return the date formatting patterns used by the locale for the specified
        format.
    
        >>> get_date_format(locale='en_US')
        <DateTimePattern u'MMM d, y'>
        >>> get_date_format('full', locale='de_DE')
        <DateTimePattern u'EEEE, d. MMMM y'>
    
        :param format: the format to use, one of "full", "long", "medium", or
                       "short"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_datetime_format:
  body: |
    def get_datetime_format(format: _PredefinedTimeFormat='medium', locale: Locale | str | None=LC_TIME):
        """Return the datetime formatting patterns used by the locale for the
        specified format.
    
        >>> get_datetime_format(locale='en_US')
        u'{1}, {0}'
    
        :param format: the format to use, one of "full", "long", "medium", or
                       "short"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_time_format:
  body: |
    def get_time_format(format: _PredefinedTimeFormat='medium', locale: Locale | str | None=LC_TIME):
        """Return the time formatting patterns used by the locale for the specified
        format.
    
        >>> get_time_format(locale='en_US')
        <DateTimePattern u'h:mm:ss a'>
        >>> get_time_format('full', locale='de_DE')
        <DateTimePattern u'HH:mm:ss zzzz'>
    
        :param format: the format to use, one of "full", "long", "medium", or
                       "short"
        :param locale: the `Locale` object, or a locale string
        
        """
        pass


code get_timezone_gmt:
  body: |
    def get_timezone_gmt(datetime: _Instant=None, width: Literal['long', 'short', 'iso8601', 'iso8601_short']='long', locale: Locale | str | None=LC_TIME, return_z: bool=False):
        """Return the timezone associated with the given `datetime` object formatted
        as string indicating the offset from GMT.
    
        >>> from datetime import datetime
        >>> dt = datetime(2007, 4, 1, 15, 30)
        >>> get_timezone_gmt(dt, locale='en')
        u'GMT+00:00'
        >>> get_timezone_gmt(dt, locale='en', return_z=True)
        'Z'
        >>> get_timezone_gmt(dt, locale='en', width='iso8601_short')
        u'+00'
        >>> tz = get_timezone('America/Los_Angeles')
        >>> dt = _localize(tz, datetime(2007, 4, 1, 15, 30))
        >>> get_timezone_gmt(dt, locale='en')
        u'GMT-07:00'
        >>> get_timezone_gmt(dt, 'short', locale='en')
        u'-0700'
        >>> get_timezone_gmt(dt, locale='en', width='iso8601_short')
        u'-07'
    
        The long format depends on the locale, for example in France the acronym
        UTC string is used instead of GMT:
    
        >>> get_timezone_gmt(dt, 'long', locale='fr_FR')
        u'UTC-07:00'
    
        .. versionadded:: 0.9
    
        :param datetime: the ``datetime`` object; if `None`, the current date and
                         time in UTC is used
        :param width: either "long" or "short" or "iso8601" or "iso8601_short"
        :param locale: the `Locale` object, or a locale string
        :param return_z: True or False; Function returns indicator "Z"
                         when local time offset is 0
        
        """
        pass


code get_timezone_location:
  body: |
    def get_timezone_location(dt_or_tzinfo: _DtOrTzinfo=None, locale: Locale | str | None=LC_TIME, return_city: bool=False):
        """Return a representation of the given timezone using "location format".
    
        The result depends on both the local display name of the country and the
        city associated with the time zone:
    
        >>> tz = get_timezone('America/St_Johns')
        >>> print(get_timezone_location(tz, locale='de_DE'))
        Kanada (St. John’s) (Ortszeit)
        >>> print(get_timezone_location(tz, locale='en'))
        Canada (St. John’s) Time
        >>> print(get_timezone_location(tz, locale='en', return_city=True))
        St. John’s
        >>> tz = get_timezone('America/Mexico_City')
        >>> get_timezone_location(tz, locale='de_DE')
        u'Mexiko (Mexiko-Stadt) (Ortszeit)'
    
        If the timezone is associated with a country that uses only a single
        timezone, just the localized country name is returned:
    
        >>> tz = get_timezone('Europe/Berlin')
        >>> get_timezone_name(tz, locale='de_DE')
        u'Mitteleurop\xe4ische Zeit'
    
        .. versionadded:: 0.9
    
        :param dt_or_tzinfo: the ``datetime`` or ``tzinfo`` object that determines
                             the timezone; if `None`, the current date and time in
                             UTC is assumed
        :param locale: the `Locale` object, or a locale string
        :param return_city: True or False, if True then return exemplar city (location)
                            for the time zone
        :return: the localized timezone name using location format
    
        
        """
        pass


code get_timezone_name:
  body: |
    def get_timezone_name(dt_or_tzinfo: _DtOrTzinfo=None, width: Literal['long', 'short']='long', uncommon: bool=False, locale: Locale | str | None=LC_TIME, zone_variant: Literal['generic', 'daylight', 'standard'] | None=None, return_zone: bool=False):
        """Return the localized display name for the given timezone. The timezone
        may be specified using a ``datetime`` or `tzinfo` object.
    
        >>> from datetime import time
        >>> dt = time(15, 30, tzinfo=get_timezone('America/Los_Angeles'))
        >>> get_timezone_name(dt, locale='en_US')  # doctest: +SKIP
        u'Pacific Standard Time'
        >>> get_timezone_name(dt, locale='en_US', return_zone=True)
        'America/Los_Angeles'
        >>> get_timezone_name(dt, width='short', locale='en_US')  # doctest: +SKIP
        u'PST'
    
        If this function gets passed only a `tzinfo` object and no concrete
        `datetime`,  the returned display name is independent of daylight savings
        time. This can be used for example for selecting timezones, or to set the
        time of events that recur across DST changes:
    
        >>> tz = get_timezone('America/Los_Angeles')
        >>> get_timezone_name(tz, locale='en_US')
        u'Pacific Time'
        >>> get_timezone_name(tz, 'short', locale='en_US')
        u'PT'
    
        If no localized display name for the timezone is available, and the timezone
        is associated with a country that uses only a single timezone, the name of
        that country is returned, formatted according to the locale:
    
        >>> tz = get_timezone('Europe/Berlin')
        >>> get_timezone_name(tz, locale='de_DE')
        u'Mitteleurop\xe4ische Zeit'
        >>> get_timezone_name(tz, locale='pt_BR')
        u'Hor\xe1rio da Europa Central'
    
        On the other hand, if the country uses multiple timezones, the city is also
        included in the representation:
    
        >>> tz = get_timezone('America/St_Johns')
        >>> get_timezone_name(tz, locale='de_DE')
        u'Neufundland-Zeit'
    
        Note that short format is currently not supported for all timezones and
        all locales.  This is partially because not every timezone has a short
        code in every locale.  In that case it currently falls back to the long
        format.
    
        For more information see `LDML Appendix J: Time Zone Display Names
        <https://www.unicode.org/reports/tr35/#Time_Zone_Fallback>`_
    
        .. versionadded:: 0.9
    
        .. versionchanged:: 1.0
           Added `zone_variant` support.
    
        :param dt_or_tzinfo: the ``datetime`` or ``tzinfo`` object that determines
                             the timezone; if a ``tzinfo`` object is used, the
                             resulting display name will be generic, i.e.
                             independent of daylight savings time; if `None`, the
                             current date in UTC is assumed
        :param width: either "long" or "short"
        :param uncommon: deprecated and ignored
        :param zone_variant: defines the zone variation to return.  By default the
                               variation is defined from the datetime object
                               passed in.  If no datetime object is passed in, the
                               ``'generic'`` variation is assumed.  The following
                               values are valid: ``'generic'``, ``'daylight'`` and
                               ``'standard'``.
        :param locale: the `Locale` object, or a locale string
        :param return_zone: True or False. If true then function
                            returns long time zone ID
        
        """
        pass


code format_date:
  body: |
    def format_date(date: datetime.date | None=None, format: _PredefinedTimeFormat | str='medium', locale: Locale | str | None=LC_TIME):
        """Return a date formatted according to the given pattern.
    
        >>> from datetime import date
        >>> d = date(2007, 4, 1)
        >>> format_date(d, locale='en_US')
        u'Apr 1, 2007'
        >>> format_date(d, format='full', locale='de_DE')
        u'Sonntag, 1. April 2007'
    
        If you don't want to use the locale default formats, you can specify a
        custom date pattern:
    
        >>> format_date(d, "EEE, MMM d, ''yy", locale='en')
        u"Sun, Apr 1, '07"
    
        :param date: the ``date`` or ``datetime`` object; if `None`, the current
                     date is used
        :param format: one of "full", "long", "medium", or "short", or a custom
                       date/time pattern
        :param locale: a `Locale` object or a locale identifier
        
        """
        pass


code format_datetime:
  body: |
    def format_datetime(datetime: _Instant=None, format: _PredefinedTimeFormat | str='medium', tzinfo: datetime.tzinfo | None=None, locale: Locale | str | None=LC_TIME):
        """Return a date formatted according to the given pattern.
    
        >>> from datetime import datetime
        >>> dt = datetime(2007, 4, 1, 15, 30)
        >>> format_datetime(dt, locale='en_US')
        u'Apr 1, 2007, 3:30:00\u202fPM'
    
        For any pattern requiring the display of the timezone:
    
        >>> format_datetime(dt, 'full', tzinfo=get_timezone('Europe/Paris'),
        ...                 locale='fr_FR')
        'dimanche 1 avril 2007, 17:30:00 heure d’été d’Europe centrale'
        >>> format_datetime(dt, "yyyy.MM.dd G 'at' HH:mm:ss zzz",
        ...                 tzinfo=get_timezone('US/Eastern'), locale='en')
        u'2007.04.01 AD at 11:30:00 EDT'
    
        :param datetime: the `datetime` object; if `None`, the current date and
                         time is used
        :param format: one of "full", "long", "medium", or "short", or a custom
                       date/time pattern
        :param tzinfo: the timezone to apply to the time for display
        :param locale: a `Locale` object or a locale identifier
        
        """
        pass


code format_time:
  body: |
    def format_time(time: datetime.time | datetime.datetime | float | None=None, format: _PredefinedTimeFormat | str='medium', tzinfo: datetime.tzinfo | None=None, locale: Locale | str | None=LC_TIME):
        """Return a time formatted according to the given pattern.
    
        >>> from datetime import datetime, time
        >>> t = time(15, 30)
        >>> format_time(t, locale='en_US')
        u'3:30:00\u202fPM'
        >>> format_time(t, format='short', locale='de_DE')
        u'15:30'
    
        If you don't want to use the locale default formats, you can specify a
        custom time pattern:
    
        >>> format_time(t, "hh 'o''clock' a", locale='en')
        u"03 o'clock PM"
    
        For any pattern requiring the display of the time-zone a
        timezone has to be specified explicitly:
    
        >>> t = datetime(2007, 4, 1, 15, 30)
        >>> tzinfo = get_timezone('Europe/Paris')
        >>> t = _localize(tzinfo, t)
        >>> format_time(t, format='full', tzinfo=tzinfo, locale='fr_FR')
        '15:30:00 heure d’été d’Europe centrale'
        >>> format_time(t, "hh 'o''clock' a, zzzz", tzinfo=get_timezone('US/Eastern'),
        ...             locale='en')
        u"09 o'clock AM, Eastern Daylight Time"
    
        As that example shows, when this function gets passed a
        ``datetime.datetime`` value, the actual time in the formatted string is
        adjusted to the timezone specified by the `tzinfo` parameter. If the
        ``datetime`` is "naive" (i.e. it has no associated timezone information),
        it is assumed to be in UTC.
    
        These timezone calculations are **not** performed if the value is of type
        ``datetime.time``, as without date information there's no way to determine
        what a given time would translate to in a different timezone without
        information about whether daylight savings time is in effect or not. This
        means that time values are left as-is, and the value of the `tzinfo`
        parameter is only used to display the timezone name if needed:
    
        >>> t = time(15, 30)
        >>> format_time(t, format='full', tzinfo=get_timezone('Europe/Paris'),
        ...             locale='fr_FR')  # doctest: +SKIP
        u'15:30:00 heure normale d\u2019Europe centrale'
        >>> format_time(t, format='full', tzinfo=get_timezone('US/Eastern'),
        ...             locale='en_US')  # doctest: +SKIP
        u'3:30:00\u202fPM Eastern Standard Time'
    
        :param time: the ``time`` or ``datetime`` object; if `None`, the current
                     time in UTC is used
        :param format: one of "full", "long", "medium", or "short", or a custom
                       date/time pattern
        :param tzinfo: the time-zone to apply to the time for display
        :param locale: a `Locale` object or a locale identifier
        
        """
        pass


code format_skeleton:
  body: |
    def format_skeleton(skeleton: str, datetime: _Instant=None, tzinfo: datetime.tzinfo | None=None, fuzzy: bool=True, locale: Locale | str | None=LC_TIME):
        """Return a time and/or date formatted according to the given pattern.
    
        The skeletons are defined in the CLDR data and provide more flexibility
        than the simple short/long/medium formats, but are a bit harder to use.
        The are defined using the date/time symbols without order or punctuation
        and map to a suitable format for the given locale.
    
        >>> from datetime import datetime
        >>> t = datetime(2007, 4, 1, 15, 30)
        >>> format_skeleton('MMMEd', t, locale='fr')
        u'dim. 1 avr.'
        >>> format_skeleton('MMMEd', t, locale='en')
        u'Sun, Apr 1'
        >>> format_skeleton('yMMd', t, locale='fi')  # yMMd is not in the Finnish locale; yMd gets used
        u'1.4.2007'
        >>> format_skeleton('yMMd', t, fuzzy=False, locale='fi')  # yMMd is not in the Finnish locale, an error is thrown
        Traceback (most recent call last):
            ...
        KeyError: yMMd
    
        After the skeleton is resolved to a pattern `format_datetime` is called so
        all timezone processing etc is the same as for that.
    
        :param skeleton: A date time skeleton as defined in the cldr data.
        :param datetime: the ``time`` or ``datetime`` object; if `None`, the current
                     time in UTC is used
        :param tzinfo: the time-zone to apply to the time for display
        :param fuzzy: If the skeleton is not found, allow choosing a skeleton that's
                      close enough to it.
        :param locale: a `Locale` object or a locale identifier
        
        """
        pass


code format_timedelta:
  body: |
    def format_timedelta(delta: datetime.timedelta | int, granularity: Literal['year', 'month', 'week', 'day', 'hour', 'minute', 'second']='second', threshold: float=0.85, add_direction: bool=False, format: Literal['narrow', 'short', 'medium', 'long']='long', locale: Locale | str | None=LC_TIME):
        """Return a time delta according to the rules of the given locale.
    
        >>> from datetime import timedelta
        >>> format_timedelta(timedelta(weeks=12), locale='en_US')
        u'3 months'
        >>> format_timedelta(timedelta(seconds=1), locale='es')
        u'1 segundo'
    
        The granularity parameter can be provided to alter the lowest unit
        presented, which defaults to a second.
    
        >>> format_timedelta(timedelta(hours=3), granularity='day', locale='en_US')
        u'1 day'
    
        The threshold parameter can be used to determine at which value the
        presentation switches to the next higher unit. A higher threshold factor
        means the presentation will switch later. For example:
    
        >>> format_timedelta(timedelta(hours=23), threshold=0.9, locale='en_US')
        u'1 day'
        >>> format_timedelta(timedelta(hours=23), threshold=1.1, locale='en_US')
        u'23 hours'
    
        In addition directional information can be provided that informs
        the user if the date is in the past or in the future:
    
        >>> format_timedelta(timedelta(hours=1), add_direction=True, locale='en')
        u'in 1 hour'
        >>> format_timedelta(timedelta(hours=-1), add_direction=True, locale='en')
        u'1 hour ago'
    
        The format parameter controls how compact or wide the presentation is:
    
        >>> format_timedelta(timedelta(hours=3), format='short', locale='en')
        u'3 hr'
        >>> format_timedelta(timedelta(hours=3), format='narrow', locale='en')
        u'3h'
    
        :param delta: a ``timedelta`` object representing the time difference to
                      format, or the delta in seconds as an `int` value
        :param granularity: determines the smallest unit that should be displayed,
                            the value can be one of "year", "month", "week", "day",
                            "hour", "minute" or "second"
        :param threshold: factor that determines at which point the presentation
                          switches to the next higher unit
        :param add_direction: if this flag is set to `True` the return value will
                              include directional information.  For instance a
                              positive timedelta will include the information about
                              it being in the future, a negative will be information
                              about the value being in the past.
        :param format: the format, can be "narrow", "short" or "long". (
                       "medium" is deprecated, currently converted to "long" to
                       maintain compatibility)
        :param locale: a `Locale` object or a locale identifier
        
        """
        pass


code format_interval:
  body: |
    def format_interval(start: _Instant, end: _Instant, skeleton: str | None=None, tzinfo: datetime.tzinfo | None=None, fuzzy: bool=True, locale: Locale | str | None=LC_TIME):
        """
        Format an interval between two instants according to the locale's rules.
    
        >>> from datetime import date, time
        >>> format_interval(date(2016, 1, 15), date(2016, 1, 17), "yMd", locale="fi")
        u'15.–17.1.2016'
    
        >>> format_interval(time(12, 12), time(16, 16), "Hm", locale="en_GB")
        '12:12–16:16'
    
        >>> format_interval(time(5, 12), time(16, 16), "hm", locale="en_US")
        '5:12 AM – 4:16 PM'
    
        >>> format_interval(time(16, 18), time(16, 24), "Hm", locale="it")
        '16:18–16:24'
    
        If the start instant equals the end instant, the interval is formatted like the instant.
    
        >>> format_interval(time(16, 18), time(16, 18), "Hm", locale="it")
        '16:18'
    
        Unknown skeletons fall back to "default" formatting.
    
        >>> format_interval(date(2015, 1, 1), date(2017, 1, 1), "wzq", locale="ja")
        '2015/01/01～2017/01/01'
    
        >>> format_interval(time(16, 18), time(16, 24), "xxx", locale="ja")
        '16:18:00～16:24:00'
    
        >>> format_interval(date(2016, 1, 15), date(2016, 1, 17), "xxx", locale="de")
        '15.01.2016 – 17.01.2016'
    
        :param start: First instant (datetime/date/time)
        :param end: Second instant (datetime/date/time)
        :param skeleton: The "skeleton format" to use for formatting.
        :param tzinfo: tzinfo to use (if none is already attached)
        :param fuzzy: If the skeleton is not found, allow choosing a skeleton that's
                      close enough to it.
        :param locale: A locale object or identifier.
        :return: Formatted interval
        
        """
        pass


code get_period_id:
  body: |
    def get_period_id(time: _Instant, tzinfo: datetime.tzinfo | None=None, type: Literal['selection'] | None=None, locale: Locale | str | None=LC_TIME):
        """
        Get the day period ID for a given time.
    
        This ID can be used as a key for the period name dictionary.
    
        >>> from datetime import time
        >>> get_period_names(locale="de")[get_period_id(time(7, 42), locale="de")]
        u'Morgen'
    
        >>> get_period_id(time(0), locale="en_US")
        u'midnight'
    
        >>> get_period_id(time(0), type="selection", locale="en_US")
        u'night1'
    
        :param time: The time to inspect.
        :param tzinfo: The timezone for the time. See ``format_time``.
        :param type: The period type to use. Either "selection" or None.
                     The selection type is used for selecting among phrases such as
                     “Your email arrived yesterday evening” or “Your email arrived last night”.
        :param locale: the `Locale` object, or a locale string
        :return: period ID. Something is always returned -- even if it's just "am" or "pm".
        
        """
        pass


code parse_date:
  body: |
    def parse_date(string: str, locale: Locale | str | None=LC_TIME, format: _PredefinedTimeFormat='medium'):
        """Parse a date from a string.
    
        This function first tries to interpret the string as ISO-8601
        date format, then uses the date format for the locale as a hint to
        determine the order in which the date fields appear in the string.
    
        >>> parse_date('4/1/04', locale='en_US')
        datetime.date(2004, 4, 1)
        >>> parse_date('01.04.2004', locale='de_DE')
        datetime.date(2004, 4, 1)
        >>> parse_date('2004-04-01', locale='en_US')
        datetime.date(2004, 4, 1)
        >>> parse_date('2004-04-01', locale='de_DE')
        datetime.date(2004, 4, 1)
    
        :param string: the string containing the date
        :param locale: a `Locale` object or a locale identifier
        :param format: the format to use (see ``get_date_format``)
        
        """
        pass


code parse_time:
  body: |
    def parse_time(string: str, locale: Locale | str | None=LC_TIME, format: _PredefinedTimeFormat='medium'):
        """Parse a time from a string.
    
        This function uses the time format for the locale as a hint to determine
        the order in which the time fields appear in the string.
    
        >>> parse_time('15:30:00', locale='en_US')
        datetime.time(15, 30)
    
        :param string: the string containing the time
        :param locale: a `Locale` object or a locale identifier
        :param format: the format to use (see ``get_time_format``)
        :return: the parsed time
        :rtype: `time`
        
        """
        pass


code DateTimeFormat__format_weekday:
  body: |
    def format_weekday(self, char: str='E', num: int=4):
        """
            Return weekday from parsed datetime according to format pattern.
    
            >>> from datetime import date
            >>> format = DateTimeFormat(date(2016, 2, 28), Locale.parse('en_US'))
            >>> format.format_weekday()
            u'Sunday'
    
            'E': Day of week - Use one through three letters for the abbreviated day name, four for the full (wide) name,
                 five for the narrow name, or six for the short name.
            >>> format.format_weekday('E',2)
            u'Sun'
    
            'e': Local day of week. Same as E except adds a numeric value that will depend on the local starting day of the
                 week, using one or two letters. For this example, Monday is the first day of the week.
            >>> format.format_weekday('e',2)
            '01'
    
            'c': Stand-Alone local day of week - Use one letter for the local numeric value (same as 'e'), three for the
                 abbreviated day name, four for the full (wide) name, five for the narrow name, or six for the short name.
            >>> format.format_weekday('c',1)
            '1'
    
            :param char: pattern format character ('e','E','c')
            :param num: count of format character
    
            
        """
        pass


code DateTimeFormat__format_period:
  body: |
    def format_period(self, char: str, num: int):
        """
            Return period from parsed datetime according to format pattern.
    
            >>> from datetime import datetime, time
            >>> format = DateTimeFormat(time(13, 42), 'fi_FI')
            >>> format.format_period('a', 1)
            u'ip.'
            >>> format.format_period('b', 1)
            u'iltap.'
            >>> format.format_period('b', 4)
            u'iltapäivä'
            >>> format.format_period('B', 4)
            u'iltapäivällä'
            >>> format.format_period('B', 5)
            u'ip.'
    
            >>> format = DateTimeFormat(datetime(2022, 4, 28, 6, 27), 'zh_Hant')
            >>> format.format_period('a', 1)
            u'上午'
            >>> format.format_period('b', 1)
            u'清晨'
            >>> format.format_period('B', 1)
            u'清晨'
    
            :param char: pattern format character ('a', 'b', 'B')
            :param num: count of format character
    
            
        """
        pass


code DateTimeFormat__format_frac_seconds:
  body: |
    def format_frac_seconds(self, num: int):
        """ Return fractional seconds.
    
            Rounds the time's microseconds to the precision given by the number         of digits passed in.
            
        """
        pass


code DateTimeFormat__get_week_number:
  body: |
    def get_week_number(self, day_of_period: int, day_of_week: int | None=None):
        """Return the number of the week of a day within a period. This may be
            the week number in a year or the week number in a month.
    
            Usually this will return a value equal to or greater than 1, but if the
            first week of the period is so short that it actually counts as the last
            week of the previous period, this function will return 0.
    
            >>> date = datetime.date(2006, 1, 8)
            >>> DateTimeFormat(date, 'de_DE').get_week_number(6)
            1
            >>> DateTimeFormat(date, 'en_US').get_week_number(6)
            2
    
            :param day_of_period: the number of the day in the period (usually
                                  either the day of month or the day of year)
            :param day_of_week: the week day; if omitted, the week day of the
                                current date is assumed
            
        """
        pass


code parse_pattern:
  body: |
    def parse_pattern(pattern: str | DateTimePattern):
        """Parse date, time, and datetime format patterns.
    
        >>> parse_pattern("MMMMd").format
        u'%(MMMM)s%(d)s'
        >>> parse_pattern("MMM d, yyyy").format
        u'%(MMM)s %(d)s, %(yyyy)s'
    
        Pattern can contain literal strings in single quotes:
    
        >>> parse_pattern("H:mm' Uhr 'z").format
        u'%(H)s:%(mm)s Uhr %(z)s'
    
        An actual single quote can be used by using two adjacent single quote
        characters:
    
        >>> parse_pattern("hh' o''clock'").format
        u"%(hh)s o'clock"
    
        :param pattern: the formatting pattern to parse
        
        """
        pass


code tokenize_pattern:
  body: |
    def tokenize_pattern(pattern: str):
        """
        Tokenize date format patterns.
    
        Returns a list of (token_type, token_value) tuples.
    
        ``token_type`` may be either "chars" or "field".
    
        For "chars" tokens, the value is the literal value.
    
        For "field" tokens, the value is a tuple of (field character, repetition count).
    
        :param pattern: Pattern string
        :type pattern: str
        :rtype: list[tuple]
        
        """
        pass


code untokenize_pattern:
  body: |
    def untokenize_pattern(tokens: Iterable[tuple[str, str | tuple[str, int]]]):
        """
        Turn a date format pattern token stream back into a string.
    
        This is the reverse operation of ``tokenize_pattern``.
    
        :type tokens: Iterable[tuple]
        :rtype: str
        
        """
        pass


code split_interval_pattern:
  body: |
    def split_interval_pattern(pattern: str):
        """
        Split an interval-describing datetime pattern into multiple pieces.
    
        > The pattern is then designed to be broken up into two pieces by determining the first repeating field.
        - https://www.unicode.org/reports/tr35/tr35-dates.html#intervalFormats
    
        >>> split_interval_pattern(u'E d.M. – E d.M.')
        [u'E d.M. – ', 'E d.M.']
        >>> split_interval_pattern("Y 'text' Y 'more text'")
        ["Y 'text '", "Y 'more text'"]
        >>> split_interval_pattern(u"E, MMM d – E")
        [u'E, MMM d – ', u'E']
        >>> split_interval_pattern("MMM d")
        ['MMM d']
        >>> split_interval_pattern("y G")
        ['y G']
        >>> split_interval_pattern(u"MMM d – d")
        [u'MMM d – ', u'd']
    
        :param pattern: Interval pattern string
        :return: list of "subpatterns"
        
        """
        pass


code match_skeleton:
  body: |
    def match_skeleton(skeleton: str, options: Iterable[str], allow_different_fields: bool=False):
        """
        Find the closest match for the given datetime skeleton among the options given.
    
        This uses the rules outlined in the TR35 document.
    
        >>> match_skeleton('yMMd', ('yMd', 'yMMMd'))
        'yMd'
    
        >>> match_skeleton('yMMd', ('jyMMd',), allow_different_fields=True)
        'jyMMd'
    
        >>> match_skeleton('yMMd', ('qyMMd',), allow_different_fields=False)
    
        >>> match_skeleton('hmz', ('hmv',))
        'hmv'
    
        :param skeleton: The skeleton to match
        :type skeleton: str
        :param options: An iterable of other skeletons to match against
        :type options: Iterable[str]
        :return: The closest skeleton match, or if no match was found, None.
        :rtype: str|None
        
        """
        pass


code get_official_languages:
  body: |
    def get_official_languages(territory: str, regional: bool=False, de_facto: bool=False):
        """
        Get the official language(s) for the given territory.
    
        The language codes, if any are known, are returned in order of descending popularity.
    
        If the `regional` flag is set, then languages which are regionally official are also returned.
    
        If the `de_facto` flag is set, then languages which are "de facto" official are also returned.
    
        .. warning:: Note that the data is as up to date as the current version of the CLDR used
                     by Babel.  If you need scientifically accurate information, use another source!
    
        :param territory: Territory code
        :type territory: str
        :param regional: Whether to return regionally official languages too
        :type regional: bool
        :param de_facto: Whether to return de-facto official languages too
        :type de_facto: bool
        :return: Tuple of language codes
        :rtype: tuple[str]
        
        """
        pass


code get_territory_language_info:
  body: |
    def get_territory_language_info(territory: str):
        """
        Get a dictionary of language information for a territory.
    
        The dictionary is keyed by language code; the values are dicts with more information.
    
        The following keys are currently known for the values:
    
        * `population_percent`: The percentage of the territory's population speaking the
                                language.
        * `official_status`: An optional string describing the officiality status of the language.
                             Known values are "official", "official_regional" and "de_facto_official".
    
        .. warning:: Note that the data is as up to date as the current version of the CLDR used
                     by Babel.  If you need scientifically accurate information, use another source!
    
        .. note:: Note that the format of the dict returned may change between Babel versions.
    
        See https://www.unicode.org/cldr/charts/latest/supplemental/territory_language_information.html
    
        :param territory: Territory code
        :type territory: str
        :return: Language information dictionary
        :rtype: dict[str, dict]
        
        """
        pass


code format_list:
  body: |
    def format_list(lst: Sequence[str], style: Literal['standard', 'standard-short', 'or', 'or-short', 'unit', 'unit-short', 'unit-narrow']='standard', locale: Locale | str | None=DEFAULT_LOCALE):
        """
        Format the items in `lst` as a list.
    
        >>> format_list(['apples', 'oranges', 'pears'], locale='en')
        u'apples, oranges, and pears'
        >>> format_list(['apples', 'oranges', 'pears'], locale='zh')
        u'apples、oranges和pears'
        >>> format_list(['omena', 'peruna', 'aplari'], style='or', locale='fi')
        u'omena, peruna tai aplari'
    
        These styles are defined, but not all are necessarily available in all locales.
        The following text is verbatim from the Unicode TR35-49 spec [1].
    
        * standard:
          A typical 'and' list for arbitrary placeholders.
          eg. "January, February, and March"
        * standard-short:
          A short version of an 'and' list, suitable for use with short or abbreviated placeholder values.
          eg. "Jan., Feb., and Mar."
        * or:
          A typical 'or' list for arbitrary placeholders.
          eg. "January, February, or March"
        * or-short:
          A short version of an 'or' list.
          eg. "Jan., Feb., or Mar."
        * unit:
          A list suitable for wide units.
          eg. "3 feet, 7 inches"
        * unit-short:
          A list suitable for short units
          eg. "3 ft, 7 in"
        * unit-narrow:
          A list suitable for narrow units, where space on the screen is very limited.
          eg. "3′ 7″"
    
        [1]: https://www.unicode.org/reports/tr35/tr35-49/tr35-general.html#ListPatterns
    
        :param lst: a sequence of items to format in to a list
        :param style: the style to format the list with. See above for description.
        :param locale: the locale
        
        """
        pass


code normalize_locale:
  body: |
    def normalize_locale(name: str):
        """Normalize a locale ID by stripping spaces and apply proper casing.
    
        Returns the normalized locale ID string or `None` if the ID is not
        recognized.
        
        """
        pass


code resolve_locale_filename:
  body: |
    def resolve_locale_filename(name: os.PathLike[str] | str):
        """
        Resolve a locale identifier to a `.dat` path on disk.
        
        """
        pass


code exists:
  body: |
    def exists(name: str):
        """Check whether locale data is available for the given locale.
    
        Returns `True` if it exists, `False` otherwise.
    
        :param name: the locale identifier string
        
        """
        pass


code locale_identifiers:
  body: |
    def locale_identifiers():
        """Return a list of all locale identifiers for which locale data is
        available.
    
        This data is cached after the first invocation.
        You can clear the cache by calling `locale_identifiers.cache_clear()`.
    
        .. versionadded:: 0.8.1
    
        :return: a list of locale identifiers (strings)
        
        """
        pass


code load:
  body: |
    def load(name: os.PathLike[str] | str, merge_inherited: bool=True):
        """Load the locale data for the given locale.
    
        The locale data is a dictionary that contains much of the data defined by
        the Common Locale Data Repository (CLDR). This data is stored as a
        collection of pickle files inside the ``babel`` package.
    
        >>> d = load('en_US')
        >>> d['languages']['sv']
        u'Swedish'
    
        Note that the results are cached, and subsequent requests for the same
        locale return the same dictionary:
    
        >>> d1 = load('en_US')
        >>> d2 = load('en_US')
        >>> d1 is d2
        True
    
        :param name: the locale identifier string (or "root")
        :param merge_inherited: whether the inherited data should be merged into
                                the data of the requested locale
        :raise `IOError`: if no locale data file is found for the given locale
                          identifier, or one of the locales it inherits from
        
        """
        pass


code merge:
  body: |
    def merge(dict1: MutableMapping[Any, Any], dict2: Mapping[Any, Any]):
        """Merge the data from `dict2` into the `dict1` dictionary, making copies
        of nested dictionaries.
    
        >>> d = {1: 'foo', 3: 'baz'}
        >>> merge(d, {1: 'Foo', 2: 'Bar'})
        >>> sorted(d.items())
        [(1, 'Foo'), (2, 'Bar'), (3, 'baz')]
    
        :param dict1: the dictionary to merge into
        :param dict2: the dictionary containing the data that should be merged
        
        """
        pass


code Alias__resolve:
  body: |
    def resolve(self, data: Mapping[str | int | None, Any]):
        """Resolve the alias based on the given data.
    
            This is done recursively, so if one alias resolves to a second alias,
            that second alias will also be resolved.
    
            :param data: the locale data
            :type data: `dict`
            
        """
        pass


code _get_tzinfo:
  body: |
    def _get_tzinfo(tzenv: str):
        """Get the tzinfo from `zoneinfo` or `pytz`
    
        :param tzenv: timezone in the form of Continent/City
        :return: tzinfo object or None if not found
        
        """
        pass


code _get_localzone:
  body: |
    def _get_localzone(_root: str='/'):
        """Tries to find the local timezone configuration.
        This method prefers finding the timezone name and passing that to
        zoneinfo or pytz, over passing in the localtime file, as in the later
        case the zoneinfo name is unknown.
        The parameter _root makes the function look for files like /etc/localtime
        beneath the _root directory. This is primarily used by the tests.
        In normal usage you call the function without parameters.
        
        """
        pass


code valuestodict:
  body: |
    def valuestodict(key):
        """Convert a registry key's values to a dictionary."""
        pass


code get_close_matches:
  body: |
    def get_close_matches(word, possibilities, n=3, cutoff=0.6):
        """A modified version of ``difflib.get_close_matches``.
    
        It just passes ``autojunk=False`` to the ``SequenceMatcher``, to work
        around https://github.com/python/cpython/issues/90825.
        
        """
        pass


code Message__is_identical:
  body: |
    def is_identical(self, other: Message):
        """Checks whether messages are identical, taking into account all
            properties.
            
        """
        pass


code Message__check:
  body: |
    def check(self, catalog: Catalog | None=None):
        """Run various validation checks on the message.  Some validations
            are only performed if the catalog is provided.  This method returns
            a sequence of `TranslationError` objects.
    
            :rtype: ``iterator``
            :param catalog: A catalog instance that is passed to the checkers
            :see: `Catalog.check` for a way to perform checks for all messages
                  in a catalog.
            
        """
        pass


code Message__fuzzy:
  body: |
    def fuzzy(self):
        """Whether the translation is fuzzy.
    
            >>> Message('foo').fuzzy
            False
            >>> msg = Message('foo', 'foo', flags=['fuzzy'])
            >>> msg.fuzzy
            True
            >>> msg
            <Message 'foo' (flags: ['fuzzy'])>
    
            :type:  `bool`
        """
        pass


code Message__pluralizable:
  body: |
    def pluralizable(self):
        """Whether the message is plurizable.
    
            >>> Message('foo').pluralizable
            False
            >>> Message(('foo', 'bar')).pluralizable
            True
    
            :type:  `bool`
        """
        pass


code Message__python_format:
  body: |
    def python_format(self):
        """Whether the message contains Python-style parameters.
    
            >>> Message('foo %(name)s bar').python_format
            True
            >>> Message(('foo %(name)s', 'foo %(name)s')).python_format
            True
    
            :type:  `bool`
        """
        pass


code Catalog__num_plurals:
  body: |
    def num_plurals(self):
        """The number of plurals used by the catalog or locale.
    
            >>> Catalog(locale='en').num_plurals
            2
            >>> Catalog(locale='ga').num_plurals
            5
    
            :type: `int`
        """
        pass


code Catalog__plural_expr:
  body: |
    def plural_expr(self):
        """The plural expression used by the catalog or locale.
    
            >>> Catalog(locale='en').plural_expr
            '(n != 1)'
            >>> Catalog(locale='ga').plural_expr
            '(n==1 ? 0 : n==2 ? 1 : n>=3 && n<=6 ? 2 : n>=7 && n<=10 ? 3 : 4)'
            >>> Catalog(locale='ding').plural_expr  # unknown locale
            '(n != 1)'
    
            :type: `str`
        """
        pass


code Catalog__plural_forms:
  body: |
    def plural_forms(self):
        """Return the plural forms declaration for the locale.
    
            >>> Catalog(locale='en').plural_forms
            'nplurals=2; plural=(n != 1);'
            >>> Catalog(locale='pt_BR').plural_forms
            'nplurals=2; plural=(n > 1);'
    
            :type: `str`
        """
        pass


code Catalog__add:
  body: |
    def add(self, id: _MessageID, string: _MessageID | None=None, locations: Iterable[tuple[str, int]]=(), flags: Iterable[str]=(), auto_comments: Iterable[str]=(), user_comments: Iterable[str]=(), previous_id: _MessageID=(), lineno: int | None=None, context: str | None=None):
        """Add or update the message with the specified ID.
    
            >>> catalog = Catalog()
            >>> catalog.add(u'foo')
            <Message ...>
            >>> catalog[u'foo']
            <Message u'foo' (flags: [])>
    
            This method simply constructs a `Message` object with the given
            arguments and invokes `__setitem__` with that object.
    
            :param id: the message ID, or a ``(singular, plural)`` tuple for
                       pluralizable messages
            :param string: the translated message string, or a
                           ``(singular, plural)`` tuple for pluralizable messages
            :param locations: a sequence of ``(filename, lineno)`` tuples
            :param flags: a set or sequence of flags
            :param auto_comments: a sequence of automatic comments
            :param user_comments: a sequence of user comments
            :param previous_id: the previous message ID, or a ``(singular, plural)``
                                tuple for pluralizable messages
            :param lineno: the line number on which the msgid line was found in the
                           PO file, if any
            :param context: the message context
            
        """
        pass


code Catalog__check:
  body: |
    def check(self):
        """Run various validation checks on the translations in the catalog.
    
            For every message which fails validation, this method yield a
            ``(message, errors)`` tuple, where ``message`` is the `Message` object
            and ``errors`` is a sequence of `TranslationError` objects.
    
            :rtype: ``generator`` of ``(message, errors)``
            
        """
        pass


code Catalog__get:
  body: |
    def get(self, id: _MessageID, context: str | None=None):
        """Return the message with the specified ID and context.
    
            :param id: the message ID
            :param context: the message context, or ``None`` for no context
            
        """
        pass


code Catalog__delete:
  body: |
    def delete(self, id: _MessageID, context: str | None=None):
        """Delete the message with the specified ID and context.
    
            :param id: the message ID
            :param context: the message context, or ``None`` for no context
            
        """
        pass


code Catalog__update:
  body: |
    def update(self, template: Catalog, no_fuzzy_matching: bool=False, update_header_comment: bool=False, keep_user_comments: bool=True, update_creation_date: bool=True):
        """Update the catalog based on the given template catalog.
    
            >>> from babel.messages import Catalog
            >>> template = Catalog()
            >>> template.add('green', locations=[('main.py', 99)])
            <Message ...>
            >>> template.add('blue', locations=[('main.py', 100)])
            <Message ...>
            >>> template.add(('salad', 'salads'), locations=[('util.py', 42)])
            <Message ...>
            >>> catalog = Catalog(locale='de_DE')
            >>> catalog.add('blue', u'blau', locations=[('main.py', 98)])
            <Message ...>
            >>> catalog.add('head', u'Kopf', locations=[('util.py', 33)])
            <Message ...>
            >>> catalog.add(('salad', 'salads'), (u'Salat', u'Salate'),
            ...             locations=[('util.py', 38)])
            <Message ...>
    
            >>> catalog.update(template)
            >>> len(catalog)
            3
    
            >>> msg1 = catalog['green']
            >>> msg1.string
            >>> msg1.locations
            [('main.py', 99)]
    
            >>> msg2 = catalog['blue']
            >>> msg2.string
            u'blau'
            >>> msg2.locations
            [('main.py', 100)]
    
            >>> msg3 = catalog['salad']
            >>> msg3.string
            (u'Salat', u'Salate')
            >>> msg3.locations
            [('util.py', 42)]
    
            Messages that are in the catalog but not in the template are removed
            from the main collection, but can still be accessed via the `obsolete`
            member:
    
            >>> 'head' in catalog
            False
            >>> list(catalog.obsolete.values())
            [<Message 'head' (flags: [])>]
    
            :param template: the reference catalog, usually read from a POT file
            :param no_fuzzy_matching: whether to use fuzzy matching of message IDs
            
        """
        pass


code Catalog___to_fuzzy_match_key:
  body: |
    def _to_fuzzy_match_key(self, key: tuple[str, str] | str):
        """Converts a message key to a string suitable for fuzzy matching."""
        pass


code Catalog___key_for:
  body: |
    def _key_for(self, id: _MessageID, context: str | None=None):
        """The key for a message is just the singular ID even for pluralizable
            messages, but is a ``(msgid, msgctxt)`` tuple for context-specific
            messages.
            
        """
        pass


code Catalog__is_identical:
  body: |
    def is_identical(self, other: Catalog):
        """Checks if catalogs are identical, taking into account messages and
            headers.
            
        """
        pass


code num_plurals:
  body: |
    def num_plurals(catalog: Catalog | None, message: Message):
        """Verify the number of plurals in the translation."""
        pass


code python_format:
  body: |
    def python_format(catalog: Catalog | None, message: Message):
        """Verify the format string placeholders in the translation."""
        pass


code _validate_format:
  body: |
    def _validate_format(format: str, alternative: str):
        """Test format string `alternative` against `format`.  `format` can be the
        msgid of a message and `alternative` one of the `msgstr`\s.  The two
        arguments are not interchangeable as `alternative` may contain less
        placeholders if `format` uses named placeholders.
    
        The behavior of this function is undefined if the string does not use
        string formatting.
    
        If the string formatting of `alternative` is compatible to `format` the
        function returns `None`, otherwise a `TranslationError` is raised.
    
        Examples for compatible format strings:
    
        >>> _validate_format('Hello %s!', 'Hallo %s!')
        >>> _validate_format('Hello %i!', 'Hallo %d!')
    
        Example for an incompatible format strings:
    
        >>> _validate_format('Hello %(name)s!', 'Hallo %s!')
        Traceback (most recent call last):
          ...
        TranslationError: the format strings are of different kinds
    
        This function is used by the `python_format` checker.
    
        :param format: The original format string
        :param alternative: The alternative format string that should be checked
                            against format
        :raises TranslationError: on formatting errors
        
        """
        pass


code _strip_comment_tags:
  body: |
    def _strip_comment_tags(comments: MutableSequence[str], tags: Iterable[str]):
        """Helper function for `extract` that strips comment tags from strings
        in a list of comment lines.  This functions operates in-place.
        
        """
        pass


code extract_from_dir:
  body: |
    def extract_from_dir(dirname: str | os.PathLike[str] | None=None, method_map: Iterable[tuple[str, str]]=DEFAULT_MAPPING, options_map: SupportsItems[str, dict[str, Any]] | None=None, keywords: Mapping[str, _Keyword]=DEFAULT_KEYWORDS, comment_tags: Collection[str]=(), callback: Callable[[str, str, dict[str, Any]], object] | None=None, strip_comment_tags: bool=False, directory_filter: Callable[[str], bool] | None=None):
        """Extract messages from any source files found in the given directory.
    
        This function generates tuples of the form ``(filename, lineno, message,
        comments, context)``.
    
        Which extraction method is used per file is determined by the `method_map`
        parameter, which maps extended glob patterns to extraction method names.
        For example, the following is the default mapping:
    
        >>> method_map = [
        ...     ('**.py', 'python')
        ... ]
    
        This basically says that files with the filename extension ".py" at any
        level inside the directory should be processed by the "python" extraction
        method. Files that don't match any of the mapping patterns are ignored. See
        the documentation of the `pathmatch` function for details on the pattern
        syntax.
    
        The following extended mapping would also use the "genshi" extraction
        method on any file in "templates" subdirectory:
    
        >>> method_map = [
        ...     ('**/templates/**.*', 'genshi'),
        ...     ('**.py', 'python')
        ... ]
    
        The dictionary provided by the optional `options_map` parameter augments
        these mappings. It uses extended glob patterns as keys, and the values are
        dictionaries mapping options names to option values (both strings).
    
        The glob patterns of the `options_map` do not necessarily need to be the
        same as those used in the method mapping. For example, while all files in
        the ``templates`` folders in an application may be Genshi applications, the
        options for those files may differ based on extension:
    
        >>> options_map = {
        ...     '**/templates/**.txt': {
        ...         'template_class': 'genshi.template:TextTemplate',
        ...         'encoding': 'latin-1'
        ...     },
        ...     '**/templates/**.html': {
        ...         'include_attrs': ''
        ...     }
        ... }
    
        :param dirname: the path to the directory to extract messages from.  If
                        not given the current working directory is used.
        :param method_map: a list of ``(pattern, method)`` tuples that maps of
                           extraction method names to extended glob patterns
        :param options_map: a dictionary of additional options (optional)
        :param keywords: a dictionary mapping keywords (i.e. names of functions
                         that should be recognized as translation functions) to
                         tuples that specify which of their arguments contain
                         localizable strings
        :param comment_tags: a list of tags of translator comments to search for
                             and include in the results
        :param callback: a function that is called for every file that message are
                         extracted from, just before the extraction itself is
                         performed; the function is passed the filename, the name
                         of the extraction method and and the options dictionary as
                         positional arguments, in that order
        :param strip_comment_tags: a flag that if set to `True` causes all comment
                                   tags to be removed from the collected comments.
        :param directory_filter: a callback to determine whether a directory should
                                 be recursed into. Receives the full directory path;
                                 should return True if the directory is valid.
        :see: `pathmatch`
        
        """
        pass


code check_and_call_extract_file:
  body: |
    def check_and_call_extract_file(filepath: str | os.PathLike[str], method_map: Iterable[tuple[str, str]], options_map: SupportsItems[str, dict[str, Any]], callback: Callable[[str, str, dict[str, Any]], object] | None, keywords: Mapping[str, _Keyword], comment_tags: Collection[str], strip_comment_tags: bool, dirpath: str | os.PathLike[str] | None=None):
        """Checks if the given file matches an extraction method mapping, and if so, calls extract_from_file.
    
        Note that the extraction method mappings are based relative to dirpath.
        So, given an absolute path to a file `filepath`, we want to check using
        just the relative path from `dirpath` to `filepath`.
    
        Yields 5-tuples (filename, lineno, messages, comments, context).
    
        :param filepath: An absolute path to a file that exists.
        :param method_map: a list of ``(pattern, method)`` tuples that maps of
                           extraction method names to extended glob patterns
        :param options_map: a dictionary of additional options (optional)
        :param callback: a function that is called for every file that message are
                         extracted from, just before the extraction itself is
                         performed; the function is passed the filename, the name
                         of the extraction method and and the options dictionary as
                         positional arguments, in that order
        :param keywords: a dictionary mapping keywords (i.e. names of functions
                         that should be recognized as translation functions) to
                         tuples that specify which of their arguments contain
                         localizable strings
        :param comment_tags: a list of tags of translator comments to search for
                             and include in the results
        :param strip_comment_tags: a flag that if set to `True` causes all comment
                                   tags to be removed from the collected comments.
        :param dirpath: the path to the directory to extract messages from.
        :return: iterable of 5-tuples (filename, lineno, messages, comments, context)
        :rtype: Iterable[tuple[str, int, str|tuple[str], list[str], str|None]
        
        """
        pass


code extract_from_file:
  body: |
    def extract_from_file(method: _ExtractionMethod, filename: str | os.PathLike[str], keywords: Mapping[str, _Keyword]=DEFAULT_KEYWORDS, comment_tags: Collection[str]=(), options: Mapping[str, Any] | None=None, strip_comment_tags: bool=False):
        """Extract messages from a specific file.
    
        This function returns a list of tuples of the form ``(lineno, message, comments, context)``.
    
        :param filename: the path to the file to extract messages from
        :param method: a string specifying the extraction method (.e.g. "python")
        :param keywords: a dictionary mapping keywords (i.e. names of functions
                         that should be recognized as translation functions) to
                         tuples that specify which of their arguments contain
                         localizable strings
        :param comment_tags: a list of translator tags to search for and include
                             in the results
        :param strip_comment_tags: a flag that if set to `True` causes all comment
                                   tags to be removed from the collected comments.
        :param options: a dictionary of additional options (optional)
        :returns: list of tuples of the form ``(lineno, message, comments, context)``
        :rtype: list[tuple[int, str|tuple[str], list[str], str|None]
        
        """
        pass


code extract:
  body: |
    def extract(method: _ExtractionMethod, fileobj: _FileObj, keywords: Mapping[str, _Keyword]=DEFAULT_KEYWORDS, comment_tags: Collection[str]=(), options: Mapping[str, Any] | None=None, strip_comment_tags: bool=False):
        """Extract messages from the given file-like object using the specified
        extraction method.
    
        This function returns tuples of the form ``(lineno, message, comments, context)``.
    
        The implementation dispatches the actual extraction to plugins, based on the
        value of the ``method`` parameter.
    
        >>> source = b'''# foo module
        ... def run(argv):
        ...    print(_('Hello, world!'))
        ... '''
    
        >>> from io import BytesIO
        >>> for message in extract('python', BytesIO(source)):
        ...     print(message)
        (3, u'Hello, world!', [], None)
    
        :param method: an extraction method (a callable), or
                       a string specifying the extraction method (.e.g. "python");
                       if this is a simple name, the extraction function will be
                       looked up by entry point; if it is an explicit reference
                       to a function (of the form ``package.module:funcname`` or
                       ``package.module.funcname``), the corresponding function
                       will be imported and used
        :param fileobj: the file-like object the messages should be extracted from
        :param keywords: a dictionary mapping keywords (i.e. names of functions
                         that should be recognized as translation functions) to
                         tuples that specify which of their arguments contain
                         localizable strings
        :param comment_tags: a list of translator tags to search for and include
                             in the results
        :param options: a dictionary of additional options (optional)
        :param strip_comment_tags: a flag that if set to `True` causes all comment
                                   tags to be removed from the collected comments.
        :raise ValueError: if the extraction method is not registered
        :returns: iterable of tuples of the form ``(lineno, message, comments, context)``
        :rtype: Iterable[tuple[int, str|tuple[str], list[str], str|None]
        
        """
        pass


code extract_nothing:
  body: |
    def extract_nothing(fileobj: _FileObj, keywords: Mapping[str, _Keyword], comment_tags: Collection[str], options: Mapping[str, Any]):
        """Pseudo extractor that does not actually extract anything, but simply
        returns an empty list.
        
        """
        pass


code extract_python:
  body: |
    def extract_python(fileobj: IO[bytes], keywords: Mapping[str, _Keyword], comment_tags: Collection[str], options: _PyOptions):
        """Extract messages from Python source code.
    
        It returns an iterator yielding tuples in the following form ``(lineno,
        funcname, message, comments)``.
    
        :param fileobj: the seekable, file-like object the messages should be
                        extracted from
        :param keywords: a list of keywords (i.e. function names) that should be
                         recognized as translation functions
        :param comment_tags: a list of translator tags to search for and include
                             in the results
        :param options: a dictionary of additional options (optional)
        :rtype: ``iterator``
        
        """
        pass


code extract_javascript:
  body: |
    def extract_javascript(fileobj: _FileObj, keywords: Mapping[str, _Keyword], comment_tags: Collection[str], options: _JSOptions, lineno: int=1):
        """Extract messages from JavaScript source code.
    
        :param fileobj: the seekable, file-like object the messages should be
                        extracted from
        :param keywords: a list of keywords (i.e. function names) that should be
                         recognized as translation functions
        :param comment_tags: a list of translator tags to search for and include
                             in the results
        :param options: a dictionary of additional options (optional)
                        Supported options are:
                        * `jsx` -- set to false to disable JSX/E4X support.
                        * `template_string` -- if `True`, supports gettext(`key`)
                        * `parse_template_string` -- if `True` will parse the
                                                     contents of javascript
                                                     template strings.
        :param lineno: line number offset (for parsing embedded fragments)
        
        """
        pass


code parse_template_string:
  body: |
    def parse_template_string(template_string: str, keywords: Mapping[str, _Keyword], comment_tags: Collection[str], options: _JSOptions, lineno: int=1):
        """Parse JavaScript template string.
    
        :param template_string: the template string to be parsed
        :param keywords: a list of keywords (i.e. function names) that should be
                         recognized as translation functions
        :param comment_tags: a list of translator tags to search for and include
                             in the results
        :param options: a dictionary of additional options (optional)
        :param lineno: starting line number (optional)
        
        """
        pass


code listify_value:
  body: |
    def listify_value(arg, split=None):
        """
        Make a list out of an argument.
    
        Values from `distutils` argument parsing are always single strings;
        values from `optparse` parsing may be lists of strings that may need
        to be further split.
    
        No matter the input, this function returns a flat list of whitespace-trimmed
        strings, with `None` values filtered out.
    
        >>> listify_value("foo bar")
        ['foo', 'bar']
        >>> listify_value(["foo bar"])
        ['foo', 'bar']
        >>> listify_value([["foo"], "bar"])
        ['foo', 'bar']
        >>> listify_value([["foo"], ["bar", None, "foo"]])
        ['foo', 'bar', 'foo']
        >>> listify_value("foo, bar, quux", ",")
        ['foo', 'bar', 'quux']
    
        :param arg: A string or a list of strings
        :param split: The argument to pass to `str.split()`.
        :return:
        
        """
        pass


code _make_directory_filter:
  body: |
    def _make_directory_filter(ignore_patterns):
        """
        Build a directory_filter function based on a list of ignore patterns.
        
        """
        pass


code CommandLineInterface__run:
  body: |
    def run(self, argv=None):
        """Main entry point of the command-line interface.
    
            :param argv: list of arguments passed on the command-line
            
        """
        pass


code CommandLineInterface___configure_command:
  body: |
    def _configure_command(self, cmdname, argv):
        """
            :type cmdname: str
            :type argv: list[str]
            
        """
        pass


code parse_mapping:
  body: |
    def parse_mapping(fileobj, filename=None):
        """Parse an extraction method mapping from a file-like object.
    
        >>> buf = StringIO('''
        ... [extractors]
        ... custom = mypackage.module:myfunc
        ...
        ... # Python source files
        ... [python: **.py]
        ...
        ... # Genshi templates
        ... [genshi: **/templates/**.html]
        ... include_attrs =
        ... [genshi: **/templates/**.txt]
        ... template_class = genshi.template:TextTemplate
        ... encoding = latin-1
        ...
        ... # Some custom extractor
        ... [custom: **/custom/*.*]
        ... ''')
    
        >>> method_map, options_map = parse_mapping(buf)
        >>> len(method_map)
        4
    
        >>> method_map[0]
        ('**.py', 'python')
        >>> options_map['**.py']
        {}
        >>> method_map[1]
        ('**/templates/**.html', 'genshi')
        >>> options_map['**/templates/**.html']['include_attrs']
        ''
        >>> method_map[2]
        ('**/templates/**.txt', 'genshi')
        >>> options_map['**/templates/**.txt']['template_class']
        'genshi.template:TextTemplate'
        >>> options_map['**/templates/**.txt']['encoding']
        'latin-1'
    
        >>> method_map[3]
        ('**/custom/*.*', 'mypackage.module:myfunc')
        >>> options_map['**/custom/*.*']
        {}
    
        :param fileobj: a readable file-like object containing the configuration
                        text to parse
        :see: `extract_from_directory`
        
        """
        pass


code parse_keywords:
  body: |
    def parse_keywords(strings: Iterable[str]=()):
        """Parse keywords specifications from the given list of strings.
    
        >>> import pprint
        >>> keywords = ['_', 'dgettext:2', 'dngettext:2,3', 'pgettext:1c,2',
        ...             'polymorphic:1', 'polymorphic:2,2t', 'polymorphic:3c,3t']
        >>> pprint.pprint(parse_keywords(keywords))
        {'_': None,
         'dgettext': (2,),
         'dngettext': (2, 3),
         'pgettext': ((1, 'c'), 2),
         'polymorphic': {None: (1,), 2: (2,), 3: ((3, 'c'),)}}
    
        The input keywords are in GNU Gettext style; see :doc:`cmdline` for details.
    
        The output is a dictionary mapping keyword names to a dictionary of specifications.
        Keys in this dictionary are numbers of arguments, where ``None`` means that all numbers
        of arguments are matched, and a number means only calls with that number of arguments
        are matched (which happens when using the "t" specifier). However, as a special
        case for backwards compatibility, if the dictionary of specifications would
        be ``{None: x}``, i.e., there is only one specification and it matches all argument
        counts, then it is collapsed into just ``x``.
    
        A specification is either a tuple or None. If a tuple, each element can be either a number
        ``n``, meaning that the nth argument should be extracted as a message, or the tuple
        ``(n, 'c')``, meaning that the nth argument should be extracted as context for the
        messages. A ``None`` specification is equivalent to ``(1,)``, extracting the first
        argument.
        
        """
        pass


code get_rules:
  body: |
    def get_rules(jsx: bool, dotted: bool, template_string: bool):
        """
        Get a tokenization rule list given the passed syntax options.
    
        Internal to this module.
        
        """
        pass


code indicates_division:
  body: |
    def indicates_division(token: Token):
        """A helper function that helps the tokenizer to decide if the current
        token may be followed by a division operator.
        
        """
        pass


code unquote_string:
  body: |
    def unquote_string(string: str):
        """Unquote a string with JavaScript rules.  The string has to start with
        string delimiters (``'``, ``"`` or the back-tick/grave accent (for template strings).)
        
        """
        pass


code tokenize:
  body: |
    def tokenize(source: str, jsx: bool=True, dotted: bool=True, template_string: bool=True, lineno: int=1):
        """
        Tokenize JavaScript/JSX source.  Returns a generator of tokens.
    
        :param jsx: Enable (limited) JSX parsing.
        :param dotted: Read dotted names as single name token.
        :param template_string: Support ES6 template strings
        :param lineno: starting line number (optional)
        
        """
        pass


code read_mo:
  body: |
    def read_mo(fileobj: SupportsRead[bytes]):
        """Read a binary MO file from the given file-like object and return a
        corresponding `Catalog` object.
    
        :param fileobj: the file-like object to read the MO file from
    
        :note: The implementation of this function is heavily based on the
               ``GNUTranslations._parse`` method of the ``gettext`` module in the
               standard library.
        
        """
        pass


code write_mo:
  body: |
    def write_mo(fileobj: SupportsWrite[bytes], catalog: Catalog, use_fuzzy: bool=False):
        """Write a catalog to the specified file-like object using the GNU MO file
        format.
    
        >>> import sys
        >>> from babel.messages import Catalog
        >>> from gettext import GNUTranslations
        >>> from io import BytesIO
    
        >>> catalog = Catalog(locale='en_US')
        >>> catalog.add('foo', 'Voh')
        <Message ...>
        >>> catalog.add((u'bar', u'baz'), (u'Bahr', u'Batz'))
        <Message ...>
        >>> catalog.add('fuz', 'Futz', flags=['fuzzy'])
        <Message ...>
        >>> catalog.add('Fizz', '')
        <Message ...>
        >>> catalog.add(('Fuzz', 'Fuzzes'), ('', ''))
        <Message ...>
        >>> buf = BytesIO()
    
        >>> write_mo(buf, catalog)
        >>> x = buf.seek(0)
        >>> translations = GNUTranslations(fp=buf)
        >>> if sys.version_info[0] >= 3:
        ...     translations.ugettext = translations.gettext
        ...     translations.ungettext = translations.ngettext
        >>> translations.ugettext('foo')
        u'Voh'
        >>> translations.ungettext('bar', 'baz', 1)
        u'Bahr'
        >>> translations.ungettext('bar', 'baz', 2)
        u'Batz'
        >>> translations.ugettext('fuz')
        u'fuz'
        >>> translations.ugettext('Fizz')
        u'Fizz'
        >>> translations.ugettext('Fuzz')
        u'Fuzz'
        >>> translations.ugettext('Fuzzes')
        u'Fuzzes'
    
        :param fileobj: the file-like object to write to
        :param catalog: the `Catalog` instance
        :param use_fuzzy: whether translations marked as "fuzzy" should be included
                          in the output
        
        """
        pass


code get_plural:
  body: |
    def get_plural(locale: str | None=LC_CTYPE):
        """A tuple with the information catalogs need to perform proper
        pluralization.  The first item of the tuple is the number of plural
        forms, the second the plural expression.
    
        >>> get_plural(locale='en')
        (2, '(n != 1)')
        >>> get_plural(locale='ga')
        (5, '(n==1 ? 0 : n==2 ? 1 : n>=3 && n<=6 ? 2 : n>=7 && n<=10 ? 3 : 4)')
    
        The object returned is a special tuple with additional members:
    
        >>> tup = get_plural("ja")
        >>> tup.num_plurals
        1
        >>> tup.plural_expr
        '0'
        >>> tup.plural_forms
        'nplurals=1; plural=0;'
    
        Converting the tuple into a string prints the plural forms for a
        gettext catalog:
    
        >>> str(tup)
        'nplurals=1; plural=0;'
        
        """
        pass


code unescape:
  body: |
    def unescape(string: str):
        """Reverse `escape` the given string.
    
        >>> print(unescape('"Say:\\n  \\"hello, world!\\"\\n"'))
        Say:
          "hello, world!"
        <BLANKLINE>
    
        :param string: the string to unescape
        
        """
        pass


code denormalize:
  body: |
    def denormalize(string: str):
        """Reverse the normalization done by the `normalize` function.
    
        >>> print(denormalize(r'''""
        ... "Say:\n"
        ... "  \"hello, world!\"\n"'''))
        Say:
          "hello, world!"
        <BLANKLINE>
    
        >>> print(denormalize(r'''""
        ... "Say:\n"
        ... "  \"Lorem ipsum dolor sit "
        ... "amet, consectetur adipisicing"
        ... " elit, \"\n"'''))
        Say:
          "Lorem ipsum dolor sit amet, consectetur adipisicing elit, "
        <BLANKLINE>
    
        :param string: the string to denormalize
        
        """
        pass


code PoFileParser___add_message:
  body: |
    def _add_message(self):
        """
            Add a message to the catalog based on the current parser state and
            clear the state ready to process the next message.
            
        """
        pass


code PoFileParser__parse:
  body: |
    def parse(self, fileobj: IO[AnyStr]):
        """
            Reads from the file-like object `fileobj` and adds any po file
            units found in it to the `Catalog` supplied to the constructor.
            
        """
        pass


code read_po:
  body: |
    def read_po(fileobj: IO[AnyStr], locale: str | Locale | None=None, domain: str | None=None, ignore_obsolete: bool=False, charset: str | None=None, abort_invalid: bool=False):
        """Read messages from a ``gettext`` PO (portable object) file from the given
        file-like object and return a `Catalog`.
    
        >>> from datetime import datetime
        >>> from io import StringIO
        >>> buf = StringIO('''
        ... #: main.py:1
        ... #, fuzzy, python-format
        ... msgid "foo %(name)s"
        ... msgstr "quux %(name)s"
        ...
        ... # A user comment
        ... #. An auto comment
        ... #: main.py:3
        ... msgid "bar"
        ... msgid_plural "baz"
        ... msgstr[0] "bar"
        ... msgstr[1] "baaz"
        ... ''')
        >>> catalog = read_po(buf)
        >>> catalog.revision_date = datetime(2007, 4, 1)
    
        >>> for message in catalog:
        ...     if message.id:
        ...         print((message.id, message.string))
        ...         print(' ', (message.locations, sorted(list(message.flags))))
        ...         print(' ', (message.user_comments, message.auto_comments))
        (u'foo %(name)s', u'quux %(name)s')
          ([(u'main.py', 1)], [u'fuzzy', u'python-format'])
          ([], [])
        ((u'bar', u'baz'), (u'bar', u'baaz'))
          ([(u'main.py', 3)], [])
          ([u'A user comment'], [u'An auto comment'])
    
        .. versionadded:: 1.0
           Added support for explicit charset argument.
    
        :param fileobj: the file-like object to read the PO file from
        :param locale: the locale identifier or `Locale` object, or `None`
                       if the catalog is not bound to a locale (which basically
                       means it's a template)
        :param domain: the message domain
        :param ignore_obsolete: whether to ignore obsolete messages in the input
        :param charset: the character set of the catalog.
        :param abort_invalid: abort read if po file is invalid
        
        """
        pass


code escape:
  body: |
    def escape(string: str):
        """Escape the given string so that it can be included in double-quoted
        strings in ``PO`` files.
    
        >>> escape('''Say:
        ...   "hello, world!"
        ... ''')
        '"Say:\\n  \\"hello, world!\\"\\n"'
    
        :param string: the string to escape
        
        """
        pass


code normalize:
  body: |
    def normalize(string: str, prefix: str='', width: int=76):
        """Convert a string into a format that is appropriate for .po files.
    
        >>> print(normalize('''Say:
        ...   "hello, world!"
        ... ''', width=None))
        ""
        "Say:\n"
        "  \"hello, world!\"\n"
    
        >>> print(normalize('''Say:
        ...   "Lorem ipsum dolor sit amet, consectetur adipisicing elit, "
        ... ''', width=32))
        ""
        "Say:\n"
        "  \"Lorem ipsum dolor sit "
        "amet, consectetur adipisicing"
        " elit, \"\n"
    
        :param string: the string to normalize
        :param prefix: a string that should be prepended to every line
        :param width: the maximum line width; use `None`, 0, or a negative number
                      to completely disable line wrapping
        
        """
        pass


code write_po:
  body: |
    def write_po(fileobj: SupportsWrite[bytes], catalog: Catalog, width: int=76, no_location: bool=False, omit_header: bool=False, sort_output: bool=False, sort_by_file: bool=False, ignore_obsolete: bool=False, include_previous: bool=False, include_lineno: bool=True):
        """Write a ``gettext`` PO (portable object) template file for a given
        message catalog to the provided file-like object.
    
        >>> catalog = Catalog()
        >>> catalog.add(u'foo %(name)s', locations=[('main.py', 1)],
        ...             flags=('fuzzy',))
        <Message...>
        >>> catalog.add((u'bar', u'baz'), locations=[('main.py', 3)])
        <Message...>
        >>> from io import BytesIO
        >>> buf = BytesIO()
        >>> write_po(buf, catalog, omit_header=True)
        >>> print(buf.getvalue().decode("utf8"))
        #: main.py:1
        #, fuzzy, python-format
        msgid "foo %(name)s"
        msgstr ""
        <BLANKLINE>
        #: main.py:3
        msgid "bar"
        msgid_plural "baz"
        msgstr[0] ""
        msgstr[1] ""
        <BLANKLINE>
        <BLANKLINE>
    
        :param fileobj: the file-like object to write to
        :param catalog: the `Catalog` instance
        :param width: the maximum line width for the generated output; use `None`,
                      0, or a negative number to completely disable line wrapping
        :param no_location: do not emit a location comment for every message
        :param omit_header: do not include the ``msgid ""`` entry at the top of the
                            output
        :param sort_output: whether to sort the messages in the output by msgid
        :param sort_by_file: whether to sort the messages in the output by their
                             locations
        :param ignore_obsolete: whether to ignore obsolete messages and not include
                                them in the output; by default they are included as
                                comments
        :param include_previous: include the old msgid as a comment when
                                 updating the catalog
        :param include_lineno: include line number in the location comment
        
        """
        pass


code _sort_messages:
  body: |
    def _sort_messages(messages: Iterable[Message], sort_by: Literal['message', 'location']):
        """
        Sort the given message iterable by the given criteria.
    
        Always returns a list.
    
        :param messages: An iterable of Messages.
        :param sort_by: Sort by which criteria? Options are `message` and `location`.
        :return: list[Message]
        
        """
        pass


code check_message_extractors:
  body: |
    def check_message_extractors(dist, name, value):
        """Validate the ``message_extractors`` keyword argument to ``setup()``.
    
        :param dist: the distutils/setuptools ``Distribution`` object
        :param name: the name of the keyword argument (should always be
                     "message_extractors")
        :param value: the value of the keyword argument
        :raise `DistutilsSetupError`: if the value is not valid
        
        """
        pass


code list_currencies:
  body: |
    def list_currencies(locale: Locale | str | None=None):
        """ Return a `set` of normalized currency codes.
    
        .. versionadded:: 2.5.0
    
        :param locale: filters returned currency codes by the provided locale.
                       Expected to be a locale instance or code. If no locale is
                       provided, returns the list of all currencies from all
                       locales.
        
        """
        pass


code validate_currency:
  body: |
    def validate_currency(currency: str, locale: Locale | str | None=None):
        """ Check the currency code is recognized by Babel.
    
        Accepts a ``locale`` parameter for fined-grained validation, working as
        the one defined above in ``list_currencies()`` method.
    
        Raises a `UnknownCurrencyError` exception if the currency is unknown to Babel.
        
        """
        pass


code is_currency:
  body: |
    def is_currency(currency: str, locale: Locale | str | None=None):
        """ Returns `True` only if a currency is recognized by Babel.
    
        This method always return a Boolean and never raise.
        
        """
        pass


code normalize_currency:
  body: |
    def normalize_currency(currency: str, locale: Locale | str | None=None):
        """Returns the normalized identifier of any currency code.
    
        Accepts a ``locale`` parameter for fined-grained validation, working as
        the one defined above in ``list_currencies()`` method.
    
        Returns None if the currency is unknown to Babel.
        
        """
        pass


code get_currency_name:
  body: |
    def get_currency_name(currency: str, count: float | decimal.Decimal | None=None, locale: Locale | str | None=LC_NUMERIC):
        """Return the name used by the locale for the specified currency.
    
        >>> get_currency_name('USD', locale='en_US')
        u'US Dollar'
    
        .. versionadded:: 0.9.4
    
        :param currency: the currency code.
        :param count: the optional count.  If provided the currency name
                      will be pluralized to that number if possible.
        :param locale: the `Locale` object or locale identifier.
        
        """
        pass


code get_currency_symbol:
  body: |
    def get_currency_symbol(currency: str, locale: Locale | str | None=LC_NUMERIC):
        """Return the symbol used by the locale for the specified currency.
    
        >>> get_currency_symbol('USD', locale='en_US')
        u'$'
    
        :param currency: the currency code.
        :param locale: the `Locale` object or locale identifier.
        
        """
        pass


code get_currency_precision:
  body: |
    def get_currency_precision(currency: str):
        """Return currency's precision.
    
        Precision is the number of decimals found after the decimal point in the
        currency's format pattern.
    
        .. versionadded:: 2.5.0
    
        :param currency: the currency code.
        
        """
        pass


code get_currency_unit_pattern:
  body: |
    def get_currency_unit_pattern(currency: str, count: float | decimal.Decimal | None=None, locale: Locale | str | None=LC_NUMERIC):
        """
        Return the unit pattern used for long display of a currency value
        for a given locale.
        This is a string containing ``{0}`` where the numeric part
        should be substituted and ``{1}`` where the currency long display
        name should be substituted.
    
        >>> get_currency_unit_pattern('USD', locale='en_US', count=10)
        u'{0} {1}'
    
        .. versionadded:: 2.7.0
    
        :param currency: the currency code.
        :param count: the optional count.  If provided the unit
                      pattern for that number will be returned.
        :param locale: the `Locale` object or locale identifier.
        
        """
        pass


code get_territory_currencies:
  body: |
    def get_territory_currencies(territory: str, start_date: datetime.date | None=None, end_date: datetime.date | None=None, tender: bool=True, non_tender: bool=False, include_details: bool=False):
        """Returns the list of currencies for the given territory that are valid for
        the given date range.  In addition to that the currency database
        distinguishes between tender and non-tender currencies.  By default only
        tender currencies are returned.
    
        The return value is a list of all currencies roughly ordered by the time
        of when the currency became active.  The longer the currency is being in
        use the more to the left of the list it will be.
    
        The start date defaults to today.  If no end date is given it will be the
        same as the start date.  Otherwise a range can be defined.  For instance
        this can be used to find the currencies in use in Austria between 1995 and
        2011:
    
        >>> from datetime import date
        >>> get_territory_currencies('AT', date(1995, 1, 1), date(2011, 1, 1))
        ['ATS', 'EUR']
    
        Likewise it's also possible to find all the currencies in use on a
        single date:
    
        >>> get_territory_currencies('AT', date(1995, 1, 1))
        ['ATS']
        >>> get_territory_currencies('AT', date(2011, 1, 1))
        ['EUR']
    
        By default the return value only includes tender currencies.  This
        however can be changed:
    
        >>> get_territory_currencies('US')
        ['USD']
        >>> get_territory_currencies('US', tender=False, non_tender=True,
        ...                          start_date=date(2014, 1, 1))
        ['USN', 'USS']
    
        .. versionadded:: 2.0
    
        :param territory: the name of the territory to find the currency for.
        :param start_date: the start date.  If not given today is assumed.
        :param end_date: the end date.  If not given the start date is assumed.
        :param tender: controls whether tender currencies should be included.
        :param non_tender: controls whether non-tender currencies should be
                           included.
        :param include_details: if set to `True`, instead of returning currency
                                codes the return value will be dictionaries
                                with detail information.  In that case each
                                dictionary will have the keys ``'currency'``,
                                ``'from'``, ``'to'``, and ``'tender'``.
        
        """
        pass


code get_decimal_symbol:
  body: |
    def get_decimal_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the symbol used by the locale to separate decimal fractions.
    
        >>> get_decimal_symbol('en_US')
        u'.'
        >>> get_decimal_symbol('ar_EG', numbering_system='default')
        u'٫'
        >>> get_decimal_symbol('ar_EG', numbering_system='latn')
        u'.'
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code get_plus_sign_symbol:
  body: |
    def get_plus_sign_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the plus sign symbol used by the current locale.
    
        >>> get_plus_sign_symbol('en_US')
        u'+'
        >>> get_plus_sign_symbol('ar_EG', numbering_system='default')
        u'؜+'
        >>> get_plus_sign_symbol('ar_EG', numbering_system='latn')
        u'‎+'
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code get_minus_sign_symbol:
  body: |
    def get_minus_sign_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the plus sign symbol used by the current locale.
    
        >>> get_minus_sign_symbol('en_US')
        u'-'
        >>> get_minus_sign_symbol('ar_EG', numbering_system='default')
        u'؜-'
        >>> get_minus_sign_symbol('ar_EG', numbering_system='latn')
        u'‎-'
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code get_exponential_symbol:
  body: |
    def get_exponential_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the symbol used by the locale to separate mantissa and exponent.
    
        >>> get_exponential_symbol('en_US')
        u'E'
        >>> get_exponential_symbol('ar_EG', numbering_system='default')
        u'اس'
        >>> get_exponential_symbol('ar_EG', numbering_system='latn')
        u'E'
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code get_group_symbol:
  body: |
    def get_group_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the symbol used by the locale to separate groups of thousands.
    
        >>> get_group_symbol('en_US')
        u','
        >>> get_group_symbol('ar_EG', numbering_system='default')
        u'٬'
        >>> get_group_symbol('ar_EG', numbering_system='latn')
        u','
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code get_infinity_symbol:
  body: |
    def get_infinity_symbol(locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Return the symbol used by the locale to represent infinity.
    
        >>> get_infinity_symbol('en_US')
        u'∞'
        >>> get_infinity_symbol('ar_EG', numbering_system='default')
        u'∞'
        >>> get_infinity_symbol('ar_EG', numbering_system='latn')
        u'∞'
    
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for fetching the symbol. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code format_number:
  body: |
    def format_number(number: float | decimal.Decimal | str, locale: Locale | str | None=LC_NUMERIC):
        """Return the given number formatted for a specific locale.
    
        >>> format_number(1099, locale='en_US')  # doctest: +SKIP
        u'1,099'
        >>> format_number(1099, locale='de_DE')  # doctest: +SKIP
        u'1.099'
    
        .. deprecated:: 2.6.0
    
           Use babel.numbers.format_decimal() instead.
    
        :param number: the number to format
        :param locale: the `Locale` object or locale identifier
    
    
        
        """
        pass


code get_decimal_precision:
  body: |
    def get_decimal_precision(number: decimal.Decimal):
        """Return maximum precision of a decimal instance's fractional part.
    
        Precision is extracted from the fractional part only.
        
        """
        pass


code get_decimal_quantum:
  body: |
    def get_decimal_quantum(precision: int | decimal.Decimal):
        """Return minimal quantum of a number, as defined by precision."""
        pass


code format_decimal:
  body: |
    def format_decimal(number: float | decimal.Decimal | str, format: str | NumberPattern | None=None, locale: Locale | str | None=LC_NUMERIC, decimal_quantization: bool=True, group_separator: bool=True, *, numbering_system: Literal['default'] | str='latn'):
        """Return the given decimal number formatted for a specific locale.
    
        >>> format_decimal(1.2345, locale='en_US')
        u'1.234'
        >>> format_decimal(1.2346, locale='en_US')
        u'1.235'
        >>> format_decimal(-1.2346, locale='en_US')
        u'-1.235'
        >>> format_decimal(1.2345, locale='sv_SE')
        u'1,234'
        >>> format_decimal(1.2345, locale='de')
        u'1,234'
        >>> format_decimal(1.2345, locale='ar_EG', numbering_system='default')
        u'1٫234'
        >>> format_decimal(1.2345, locale='ar_EG', numbering_system='latn')
        u'1.234'
    
        The appropriate thousands grouping and the decimal separator are used for
        each locale:
    
        >>> format_decimal(12345.5, locale='en_US')
        u'12,345.5'
    
        By default the locale is allowed to truncate and round a high-precision
        number by forcing its format pattern onto the decimal part. You can bypass
        this behavior with the `decimal_quantization` parameter:
    
        >>> format_decimal(1.2346, locale='en_US')
        u'1.235'
        >>> format_decimal(1.2346, locale='en_US', decimal_quantization=False)
        u'1.2346'
        >>> format_decimal(12345.67, locale='fr_CA', group_separator=False)
        u'12345,67'
        >>> format_decimal(12345.67, locale='en_US', group_separator=True)
        u'12,345.67'
    
        :param number: the number to format
        :param format:
        :param locale: the `Locale` object or locale identifier
        :param decimal_quantization: Truncate and round high-precision numbers to
                                     the format pattern. Defaults to `True`.
        :param group_separator: Boolean to switch group separator on/off in a locale's
                                number format.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code format_compact_decimal:
  body: |
    def format_compact_decimal(number: float | decimal.Decimal | str, *, format_type: Literal['short', 'long']='short', locale: Locale | str | None=LC_NUMERIC, fraction_digits: int=0, numbering_system: Literal['default'] | str='latn'):
        """Return the given decimal number formatted for a specific locale in compact form.
    
        >>> format_compact_decimal(12345, format_type="short", locale='en_US')
        u'12K'
        >>> format_compact_decimal(12345, format_type="long", locale='en_US')
        u'12 thousand'
        >>> format_compact_decimal(12345, format_type="short", locale='en_US', fraction_digits=2)
        u'12.34K'
        >>> format_compact_decimal(1234567, format_type="short", locale="ja_JP")
        u'123万'
        >>> format_compact_decimal(2345678, format_type="long", locale="mk")
        u'2 милиони'
        >>> format_compact_decimal(21000000, format_type="long", locale="mk")
        u'21 милион'
        >>> format_compact_decimal(12345, format_type="short", locale='ar_EG', fraction_digits=2, numbering_system='default')
        u'12٫34 ألف'
    
        :param number: the number to format
        :param format_type: Compact format to use ("short" or "long")
        :param locale: the `Locale` object or locale identifier
        :param fraction_digits: Number of digits after the decimal point to use. Defaults to `0`.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code _get_compact_format:
  body: |
    def _get_compact_format(number: float | decimal.Decimal | str, compact_format: LocaleDataDict, locale: Locale, fraction_digits: int):
        """Returns the number after dividing by the unit and the format pattern to use.
        The algorithm is described here:
        https://www.unicode.org/reports/tr35/tr35-45/tr35-numbers.html#Compact_Number_Formats.
        
        """
        pass


code format_currency:
  body: |
    def format_currency(number: float | decimal.Decimal | str, currency: str, format: str | NumberPattern | None=None, locale: Locale | str | None=LC_NUMERIC, currency_digits: bool=True, format_type: Literal['name', 'standard', 'accounting']='standard', decimal_quantization: bool=True, group_separator: bool=True, *, numbering_system: Literal['default'] | str='latn'):
        """Return formatted currency value.
    
        >>> format_currency(1099.98, 'USD', locale='en_US')
        '$1,099.98'
        >>> format_currency(1099.98, 'USD', locale='es_CO')
        u'US$1.099,98'
        >>> format_currency(1099.98, 'EUR', locale='de_DE')
        u'1.099,98\xa0\u20ac'
        >>> format_currency(1099.98, 'EGP', locale='ar_EG', numbering_system='default')
        u'‏1٬099٫98 ج.م.‏'
    
        The format can also be specified explicitly.  The currency is
        placed with the '¤' sign.  As the sign gets repeated the format
        expands (¤ being the symbol, ¤¤ is the currency abbreviation and
        ¤¤¤ is the full name of the currency):
    
        >>> format_currency(1099.98, 'EUR', u'¤¤ #,##0.00', locale='en_US')
        u'EUR 1,099.98'
        >>> format_currency(1099.98, 'EUR', u'#,##0.00 ¤¤¤', locale='en_US')
        u'1,099.98 euros'
    
        Currencies usually have a specific number of decimal digits. This function
        favours that information over the given format:
    
        >>> format_currency(1099.98, 'JPY', locale='en_US')
        u'\xa51,100'
        >>> format_currency(1099.98, 'COP', u'#,##0.00', locale='es_ES')
        u'1.099,98'
    
        However, the number of decimal digits can be overridden from the currency
        information, by setting the last parameter to ``False``:
    
        >>> format_currency(1099.98, 'JPY', locale='en_US', currency_digits=False)
        u'\xa51,099.98'
        >>> format_currency(1099.98, 'COP', u'#,##0.00', locale='es_ES', currency_digits=False)
        u'1.099,98'
    
        If a format is not specified the type of currency format to use
        from the locale can be specified:
    
        >>> format_currency(1099.98, 'EUR', locale='en_US', format_type='standard')
        u'\u20ac1,099.98'
    
        When the given currency format type is not available, an exception is
        raised:
    
        >>> format_currency('1099.98', 'EUR', locale='root', format_type='unknown')
        Traceback (most recent call last):
            ...
        UnknownCurrencyFormatError: "'unknown' is not a known currency format type"
    
        >>> format_currency(101299.98, 'USD', locale='en_US', group_separator=False)
        u'$101299.98'
    
        >>> format_currency(101299.98, 'USD', locale='en_US', group_separator=True)
        u'$101,299.98'
    
        You can also pass format_type='name' to use long display names. The order of
        the number and currency name, along with the correct localized plural form
        of the currency name, is chosen according to locale:
    
        >>> format_currency(1, 'USD', locale='en_US', format_type='name')
        u'1.00 US dollar'
        >>> format_currency(1099.98, 'USD', locale='en_US', format_type='name')
        u'1,099.98 US dollars'
        >>> format_currency(1099.98, 'USD', locale='ee', format_type='name')
        u'us ga dollar 1,099.98'
    
        By default the locale is allowed to truncate and round a high-precision
        number by forcing its format pattern onto the decimal part. You can bypass
        this behavior with the `decimal_quantization` parameter:
    
        >>> format_currency(1099.9876, 'USD', locale='en_US')
        u'$1,099.99'
        >>> format_currency(1099.9876, 'USD', locale='en_US', decimal_quantization=False)
        u'$1,099.9876'
    
        :param number: the number to format
        :param currency: the currency code
        :param format: the format string to use
        :param locale: the `Locale` object or locale identifier
        :param currency_digits: use the currency's natural number of decimal digits
        :param format_type: the currency format type to use
        :param decimal_quantization: Truncate and round high-precision numbers to
                                     the format pattern. Defaults to `True`.
        :param group_separator: Boolean to switch group separator on/off in a locale's
                                number format.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code format_compact_currency:
  body: |
    def format_compact_currency(number: float | decimal.Decimal | str, currency: str, *, format_type: Literal['short']='short', locale: Locale | str | None=LC_NUMERIC, fraction_digits: int=0, numbering_system: Literal['default'] | str='latn'):
        """Format a number as a currency value in compact form.
    
        >>> format_compact_currency(12345, 'USD', locale='en_US')
        u'$12K'
        >>> format_compact_currency(123456789, 'USD', locale='en_US', fraction_digits=2)
        u'$123.46M'
        >>> format_compact_currency(123456789, 'EUR', locale='de_DE', fraction_digits=1)
        '123,5 Mio. €'
    
        :param number: the number to format
        :param currency: the currency code
        :param format_type: the compact format type to use. Defaults to "short".
        :param locale: the `Locale` object or locale identifier
        :param fraction_digits: Number of digits after the decimal point to use. Defaults to `0`.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code format_percent:
  body: |
    def format_percent(number: float | decimal.Decimal | str, format: str | NumberPattern | None=None, locale: Locale | str | None=LC_NUMERIC, decimal_quantization: bool=True, group_separator: bool=True, *, numbering_system: Literal['default'] | str='latn'):
        """Return formatted percent value for a specific locale.
    
        >>> format_percent(0.34, locale='en_US')
        u'34%'
        >>> format_percent(25.1234, locale='en_US')
        u'2,512%'
        >>> format_percent(25.1234, locale='sv_SE')
        u'2\xa0512\xa0%'
        >>> format_percent(25.1234, locale='ar_EG', numbering_system='default')
        u'2٬512%'
    
        The format pattern can also be specified explicitly:
    
        >>> format_percent(25.1234, u'#,##0‰', locale='en_US')
        u'25,123‰'
    
        By default the locale is allowed to truncate and round a high-precision
        number by forcing its format pattern onto the decimal part. You can bypass
        this behavior with the `decimal_quantization` parameter:
    
        >>> format_percent(23.9876, locale='en_US')
        u'2,399%'
        >>> format_percent(23.9876, locale='en_US', decimal_quantization=False)
        u'2,398.76%'
    
        >>> format_percent(229291.1234, locale='pt_BR', group_separator=False)
        u'22929112%'
    
        >>> format_percent(229291.1234, locale='pt_BR', group_separator=True)
        u'22.929.112%'
    
        :param number: the percent number to format
        :param format:
        :param locale: the `Locale` object or locale identifier
        :param decimal_quantization: Truncate and round high-precision numbers to
                                     the format pattern. Defaults to `True`.
        :param group_separator: Boolean to switch group separator on/off in a locale's
                                number format.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code format_scientific:
  body: |
    def format_scientific(number: float | decimal.Decimal | str, format: str | NumberPattern | None=None, locale: Locale | str | None=LC_NUMERIC, decimal_quantization: bool=True, *, numbering_system: Literal['default'] | str='latn'):
        """Return value formatted in scientific notation for a specific locale.
    
        >>> format_scientific(10000, locale='en_US')
        u'1E4'
        >>> format_scientific(10000, locale='ar_EG', numbering_system='default')
        u'1اس4'
    
        The format pattern can also be specified explicitly:
    
        >>> format_scientific(1234567, u'##0.##E00', locale='en_US')
        u'1.23E06'
    
        By default the locale is allowed to truncate and round a high-precision
        number by forcing its format pattern onto the decimal part. You can bypass
        this behavior with the `decimal_quantization` parameter:
    
        >>> format_scientific(1234.9876, u'#.##E0', locale='en_US')
        u'1.23E3'
        >>> format_scientific(1234.9876, u'#.##E0', locale='en_US', decimal_quantization=False)
        u'1.2349876E3'
    
        :param number: the number to format
        :param format:
        :param locale: the `Locale` object or locale identifier
        :param decimal_quantization: Truncate and round high-precision numbers to
                                     the format pattern. Defaults to `True`.
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code parse_number:
  body: |
    def parse_number(string: str, locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Parse localized number string into an integer.
    
        >>> parse_number('1,099', locale='en_US')
        1099
        >>> parse_number('1.099', locale='de_DE')
        1099
    
        When the given string cannot be parsed, an exception is raised:
    
        >>> parse_number('1.099,98', locale='de')
        Traceback (most recent call last):
            ...
        NumberFormatError: '1.099,98' is not a valid number
    
        :param string: the string to parse
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :return: the parsed number
        :raise `NumberFormatError`: if the string can not be converted to a number
        :raise `UnsupportedNumberingSystemError`: if the numbering system is not supported by the locale.
        
        """
        pass


code parse_decimal:
  body: |
    def parse_decimal(string: str, locale: Locale | str | None=LC_NUMERIC, strict: bool=False, *, numbering_system: Literal['default'] | str='latn'):
        """Parse localized decimal string into a decimal.
    
        >>> parse_decimal('1,099.98', locale='en_US')
        Decimal('1099.98')
        >>> parse_decimal('1.099,98', locale='de')
        Decimal('1099.98')
        >>> parse_decimal('12 345,123', locale='ru')
        Decimal('12345.123')
        >>> parse_decimal('1٬099٫98', locale='ar_EG', numbering_system='default')
        Decimal('1099.98')
    
        When the given string cannot be parsed, an exception is raised:
    
        >>> parse_decimal('2,109,998', locale='de')
        Traceback (most recent call last):
            ...
        NumberFormatError: '2,109,998' is not a valid decimal number
    
        If `strict` is set to `True` and the given string contains a number
        formatted in an irregular way, an exception is raised:
    
        >>> parse_decimal('30.00', locale='de', strict=True)
        Traceback (most recent call last):
            ...
        NumberFormatError: '30.00' is not a properly formatted decimal number. Did you mean '3.000'? Or maybe '30,00'?
    
        >>> parse_decimal('0.00', locale='de', strict=True)
        Traceback (most recent call last):
            ...
        NumberFormatError: '0.00' is not a properly formatted decimal number. Did you mean '0'?
    
        :param string: the string to parse
        :param locale: the `Locale` object or locale identifier
        :param strict: controls whether numbers formatted in a weird way are
                       accepted or rejected
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise NumberFormatError: if the string can not be converted to a
                                  decimal number
        :raise UnsupportedNumberingSystemError: if the numbering system is not supported by the locale.
        
        """
        pass


code _remove_trailing_zeros_after_decimal:
  body: |
    def _remove_trailing_zeros_after_decimal(string: str, decimal_symbol: str):
        """
        Remove trailing zeros from the decimal part of a numeric string.
    
        This function takes a string representing a numeric value and a decimal symbol.
        It removes any trailing zeros that appear after the decimal symbol in the number.
        If the decimal part becomes empty after removing trailing zeros, the decimal symbol
        is also removed. If the string does not contain the decimal symbol, it is returned unchanged.
    
        :param string: The numeric string from which to remove trailing zeros.
        :type string: str
        :param decimal_symbol: The symbol used to denote the decimal point.
        :type decimal_symbol: str
        :return: The numeric string with trailing zeros removed from its decimal part.
        :rtype: str
    
        Example:
        >>> _remove_trailing_zeros_after_decimal("123.4500", ".")
        '123.45'
        >>> _remove_trailing_zeros_after_decimal("100.000", ".")
        '100'
        >>> _remove_trailing_zeros_after_decimal("100", ".")
        '100'
        
        """
        pass


code parse_grouping:
  body: |
    def parse_grouping(p: str):
        """Parse primary and secondary digit grouping
    
        >>> parse_grouping('##')
        (1000, 1000)
        >>> parse_grouping('#,###')
        (3, 3)
        >>> parse_grouping('#,####,###')
        (3, 4)
        
        """
        pass


code parse_pattern:
  body: |
    def parse_pattern(pattern: NumberPattern | str):
        """Parse number format patterns"""
        pass


code NumberPattern__compute_scale:
  body: |
    def compute_scale(self):
        """Return the scaling factor to apply to the number before rendering.
    
            Auto-set to a factor of 2 or 3 if presence of a ``%`` or ``‰`` sign is
            detected in the prefix or suffix of the pattern. Default is to not mess
            with the scale at all and keep it to 0.
            
        """
        pass


code NumberPattern__scientific_notation_elements:
  body: |
    def scientific_notation_elements(self, value: decimal.Decimal, locale: Locale | str | None, *, numbering_system: Literal['default'] | str='latn'):
        """ Returns normalized scientific notation components of a value.
            
        """
        pass


code NumberPattern__apply:
  body: |
    def apply(self, value: float | decimal.Decimal | str, locale: Locale | str | None, currency: str | None=None, currency_digits: bool=True, decimal_quantization: bool=True, force_frac: tuple[int, int] | None=None, group_separator: bool=True, *, numbering_system: Literal['default'] | str='latn'):
        """Renders into a string a number following the defined pattern.
    
            Forced decimal quantization is active by default so we'll produce a
            number string that is strictly following CLDR pattern definitions.
    
            :param value: The value to format. If this is not a Decimal object,
                          it will be cast to one.
            :type value: decimal.Decimal|float|int
            :param locale: The locale to use for formatting.
            :type locale: str|babel.core.Locale
            :param currency: Which currency, if any, to format as.
            :type currency: str|None
            :param currency_digits: Whether or not to use the currency's precision.
                                    If false, the pattern's precision is used.
            :type currency_digits: bool
            :param decimal_quantization: Whether decimal numbers should be forcibly
                                         quantized to produce a formatted output
                                         strictly matching the CLDR definition for
                                         the locale.
            :type decimal_quantization: bool
            :param force_frac: DEPRECATED - a forced override for `self.frac_prec`
                               for a single formatting invocation.
            :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                     The special value "default" will use the default numbering system of the locale.
            :return: Formatted decimal string.
            :rtype: str
            :raise UnsupportedNumberingSystemError: If the numbering system is not supported by the locale.
            
        """
        pass


code Format__date:
  body: |
    def date(self, date: datetime.date | None=None, format: _PredefinedTimeFormat | str='medium'):
        """Return a date formatted according to the given pattern.
    
            >>> from datetime import date
            >>> fmt = Format('en_US')
            >>> fmt.date(date(2007, 4, 1))
            u'Apr 1, 2007'
            
        """
        pass


code Format__datetime:
  body: |
    def datetime(self, datetime: datetime.date | None=None, format: _PredefinedTimeFormat | str='medium'):
        """Return a date and time formatted according to the given pattern.
    
            >>> from datetime import datetime
            >>> from babel.dates import get_timezone
            >>> fmt = Format('en_US', tzinfo=get_timezone('US/Eastern'))
            >>> fmt.datetime(datetime(2007, 4, 1, 15, 30))
            u'Apr 1, 2007, 11:30:00 AM'
            
        """
        pass


code Format__time:
  body: |
    def time(self, time: datetime.time | datetime.datetime | None=None, format: _PredefinedTimeFormat | str='medium'):
        """Return a time formatted according to the given pattern.
    
            >>> from datetime import datetime
            >>> from babel.dates import get_timezone
            >>> fmt = Format('en_US', tzinfo=get_timezone('US/Eastern'))
            >>> fmt.time(datetime(2007, 4, 1, 15, 30))
            u'11:30:00 AM'
            
        """
        pass


code Format__timedelta:
  body: |
    def timedelta(self, delta: datetime.timedelta | int, granularity: Literal['year', 'month', 'week', 'day', 'hour', 'minute', 'second']='second', threshold: float=0.85, format: Literal['narrow', 'short', 'medium', 'long']='long', add_direction: bool=False):
        """Return a time delta according to the rules of the given locale.
    
            >>> from datetime import timedelta
            >>> fmt = Format('en_US')
            >>> fmt.timedelta(timedelta(weeks=11))
            u'3 months'
            
        """
        pass


code Format__number:
  body: |
    def number(self, number: float | decimal.Decimal | str):
        """Return an integer number formatted for the locale.
    
            >>> fmt = Format('en_US')
            >>> fmt.number(1099)
            u'1,099'
            
        """
        pass


code Format__decimal:
  body: |
    def decimal(self, number: float | decimal.Decimal | str, format: str | None=None):
        """Return a decimal number formatted for the locale.
    
            >>> fmt = Format('en_US')
            >>> fmt.decimal(1.2345)
            u'1.234'
            
        """
        pass


code Format__compact_decimal:
  body: |
    def compact_decimal(self, number: float | decimal.Decimal | str, format_type: Literal['short', 'long']='short', fraction_digits: int=0):
        """Return a number formatted in compact form for the locale.
    
            >>> fmt = Format('en_US')
            >>> fmt.compact_decimal(123456789)
            u'123M'
            >>> fmt.compact_decimal(1234567, format_type='long', fraction_digits=2)
            '1.23 million'
            
        """
        pass


code Format__currency:
  body: |
    def currency(self, number: float | decimal.Decimal | str, currency: str):
        """Return a number in the given currency formatted for the locale.
            
        """
        pass


code Format__compact_currency:
  body: |
    def compact_currency(self, number: float | decimal.Decimal | str, currency: str, format_type: Literal['short']='short', fraction_digits: int=0):
        """Return a number in the given currency formatted for the locale
            using the compact number format.
    
            >>> Format('en_US').compact_currency(1234567, "USD", format_type='short', fraction_digits=2)
            '$1.23M'
            
        """
        pass


code Format__percent:
  body: |
    def percent(self, number: float | decimal.Decimal | str, format: str | None=None):
        """Return a number formatted as percentage for the locale.
    
            >>> fmt = Format('en_US')
            >>> fmt.percent(0.34)
            u'34%'
            
        """
        pass


code Format__scientific:
  body: |
    def scientific(self, number: float | decimal.Decimal | str):
        """Return a number formatted using scientific notation for the locale.
            
        """
        pass


code NullTranslations__dgettext:
  body: |
    def dgettext(self, domain: str, message: str):
        """Like ``gettext()``, but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__ldgettext:
  body: |
    def ldgettext(self, domain: str, message: str):
        """Like ``lgettext()``, but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__udgettext:
  body: |
    def udgettext(self, domain: str, message: str):
        """Like ``ugettext()``, but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__dngettext:
  body: |
    def dngettext(self, domain: str, singular: str, plural: str, num: int):
        """Like ``ngettext()``, but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__ldngettext:
  body: |
    def ldngettext(self, domain: str, singular: str, plural: str, num: int):
        """Like ``lngettext()``, but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__udngettext:
  body: |
    def udngettext(self, domain: str, singular: str, plural: str, num: int):
        """Like ``ungettext()`` but look the message up in the specified
            domain.
            
        """
        pass


code NullTranslations__pgettext:
  body: |
    def pgettext(self, context: str, message: str):
        """Look up the `context` and `message` id in the catalog and return the
            corresponding message string, as an 8-bit string encoded with the
            catalog's charset encoding, if known.  If there is no entry in the
            catalog for the `message` id and `context` , and a fallback has been
            set, the look up is forwarded to the fallback's ``pgettext()``
            method. Otherwise, the `message` id is returned.
            
        """
        pass


code NullTranslations__lpgettext:
  body: |
    def lpgettext(self, context: str, message: str):
        """Equivalent to ``pgettext()``, but the translation is returned in the
            preferred system encoding, if no other encoding was explicitly set with
            ``bind_textdomain_codeset()``.
            
        """
        pass


code NullTranslations__npgettext:
  body: |
    def npgettext(self, context: str, singular: str, plural: str, num: int):
        """Do a plural-forms lookup of a message id.  `singular` is used as the
            message id for purposes of lookup in the catalog, while `num` is used to
            determine which plural form to use.  The returned message string is an
            8-bit string encoded with the catalog's charset encoding, if known.
    
            If the message id for `context` is not found in the catalog, and a
            fallback is specified, the request is forwarded to the fallback's
            ``npgettext()`` method.  Otherwise, when ``num`` is 1 ``singular`` is
            returned, and ``plural`` is returned in all other cases.
            
        """
        pass


code NullTranslations__lnpgettext:
  body: |
    def lnpgettext(self, context: str, singular: str, plural: str, num: int):
        """Equivalent to ``npgettext()``, but the translation is returned in the
            preferred system encoding, if no other encoding was explicitly set with
            ``bind_textdomain_codeset()``.
            
        """
        pass


code NullTranslations__upgettext:
  body: |
    def upgettext(self, context: str, message: str):
        """Look up the `context` and `message` id in the catalog and return the
            corresponding message string, as a Unicode string.  If there is no entry
            in the catalog for the `message` id and `context`, and a fallback has
            been set, the look up is forwarded to the fallback's ``upgettext()``
            method.  Otherwise, the `message` id is returned.
            
        """
        pass


code NullTranslations__unpgettext:
  body: |
    def unpgettext(self, context: str, singular: str, plural: str, num: int):
        """Do a plural-forms lookup of a message id.  `singular` is used as the
            message id for purposes of lookup in the catalog, while `num` is used to
            determine which plural form to use.  The returned message string is a
            Unicode string.
    
            If the message id for `context` is not found in the catalog, and a
            fallback is specified, the request is forwarded to the fallback's
            ``unpgettext()`` method.  Otherwise, when `num` is 1 `singular` is
            returned, and `plural` is returned in all other cases.
            
        """
        pass


code NullTranslations__dpgettext:
  body: |
    def dpgettext(self, domain: str, context: str, message: str):
        """Like `pgettext()`, but look the message up in the specified
            `domain`.
            
        """
        pass


code NullTranslations__udpgettext:
  body: |
    def udpgettext(self, domain: str, context: str, message: str):
        """Like `upgettext()`, but look the message up in the specified
            `domain`.
            
        """
        pass


code NullTranslations__ldpgettext:
  body: |
    def ldpgettext(self, domain: str, context: str, message: str):
        """Equivalent to ``dpgettext()``, but the translation is returned in the
            preferred system encoding, if no other encoding was explicitly set with
            ``bind_textdomain_codeset()``.
            
        """
        pass


code NullTranslations__dnpgettext:
  body: |
    def dnpgettext(self, domain: str, context: str, singular: str, plural: str, num: int):
        """Like ``npgettext``, but look the message up in the specified
            `domain`.
            
        """
        pass


code NullTranslations__udnpgettext:
  body: |
    def udnpgettext(self, domain: str, context: str, singular: str, plural: str, num: int):
        """Like ``unpgettext``, but look the message up in the specified
            `domain`.
            
        """
        pass


code NullTranslations__ldnpgettext:
  body: |
    def ldnpgettext(self, domain: str, context: str, singular: str, plural: str, num: int):
        """Equivalent to ``dnpgettext()``, but the translation is returned in
            the preferred system encoding, if no other encoding was explicitly set
            with ``bind_textdomain_codeset()``.
            
        """
        pass


code Translations__load:
  body: |
    def load(cls, dirname: str | os.PathLike[str] | None=None, locales: Iterable[str | Locale] | str | Locale | None=None, domain: str | None=None):
        """Load translations from the given directory.
    
            :param dirname: the directory containing the ``MO`` files
            :param locales: the list of locales in order of preference (items in
                            this list can be either `Locale` objects or locale
                            strings)
            :param domain: the message domain (default: 'messages')
            
        """
        pass


code Translations__add:
  body: |
    def add(self, translations: Translations, merge: bool=True):
        """Add the given translations to the catalog.
    
            If the domain of the translations is different than that of the
            current catalog, they are added as a catalog that is only accessible
            by the various ``d*gettext`` functions.
    
            :param translations: the `Translations` instance with the messages to
                                 add
            :param merge: whether translations for message domains that have
                          already been added should be merged with the existing
                          translations
            
        """
        pass


code Translations__merge:
  body: |
    def merge(self, translations: Translations):
        """Merge the given translations into the catalog.
    
            Message translations in the specified catalog override any messages
            with the same identifier in the existing catalog.
    
            :param translations: the `Translations` instance with the messages to
                                 merge
            
        """
        pass


code _locales_to_names:
  body: |
    def _locales_to_names(locales: Iterable[str | Locale] | str | Locale | None):
        """Normalize a `locales` argument to a list of locale names.
    
        :param locales: the list of locales in order of preference (items in
                        this list can be either `Locale` objects or locale
                        strings)
        
        """
        pass


code get_unit_name:
  body: |
    def get_unit_name(measurement_unit: str, length: Literal['short', 'long', 'narrow']='long', locale: Locale | str | None=LC_NUMERIC):
        """
        Get the display name for a measurement unit in the given locale.
    
        >>> get_unit_name("radian", locale="en")
        'radians'
    
        Unknown units will raise exceptions:
    
        >>> get_unit_name("battery", locale="fi")
        Traceback (most recent call last):
            ...
        UnknownUnitError: battery/long is not a known unit/length in fi
    
        :param measurement_unit: the code of a measurement unit.
                                 Known units can be found in the CLDR Unit Validity XML file:
                                 https://unicode.org/repos/cldr/tags/latest/common/validity/unit.xml
    
        :param length: "short", "long" or "narrow"
        :param locale: the `Locale` object or locale identifier
        :return: The unit display name, or None.
        
        """
        pass


code _find_unit_pattern:
  body: |
    def _find_unit_pattern(unit_id: str, locale: Locale | str | None=LC_NUMERIC):
        """
        Expand a unit into a qualified form.
    
        Known units can be found in the CLDR Unit Validity XML file:
        https://unicode.org/repos/cldr/tags/latest/common/validity/unit.xml
    
        >>> _find_unit_pattern("radian", locale="en")
        'angle-radian'
    
        Unknown values will return None.
    
        >>> _find_unit_pattern("horse", locale="en")
    
        :param unit_id: the code of a measurement unit.
        :return: A key to the `unit_patterns` mapping, or None.
        
        """
        pass


code format_unit:
  body: |
    def format_unit(value: str | float | decimal.Decimal, measurement_unit: str, length: Literal['short', 'long', 'narrow']='long', format: str | None=None, locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """Format a value of a given unit.
    
        Values are formatted according to the locale's usual pluralization rules
        and number formats.
    
        >>> format_unit(12, 'length-meter', locale='ro_RO')
        u'12 metri'
        >>> format_unit(15.5, 'length-mile', locale='fi_FI')
        u'15,5 mailia'
        >>> format_unit(1200, 'pressure-millimeter-ofhg', locale='nb')
        u'1\xa0200 millimeter kvikks\xf8lv'
        >>> format_unit(270, 'ton', locale='en')
        u'270 tons'
        >>> format_unit(1234.5, 'kilogram', locale='ar_EG', numbering_system='default')
        u'1٬234٫5 كيلوغرام'
    
        Number formats may be overridden with the ``format`` parameter.
    
        >>> import decimal
        >>> format_unit(decimal.Decimal("-42.774"), 'temperature-celsius', 'short', format='#.0', locale='fr')
        u'-42,8\u202f\xb0C'
    
        The locale's usual pluralization rules are respected.
    
        >>> format_unit(1, 'length-meter', locale='ro_RO')
        u'1 metru'
        >>> format_unit(0, 'length-mile', locale='cy')
        u'0 mi'
        >>> format_unit(1, 'length-mile', locale='cy')
        u'1 filltir'
        >>> format_unit(3, 'length-mile', locale='cy')
        u'3 milltir'
    
        >>> format_unit(15, 'length-horse', locale='fi')
        Traceback (most recent call last):
            ...
        UnknownUnitError: length-horse is not a known unit in fi
    
        .. versionadded:: 2.2.0
    
        :param value: the value to format. If this is a string, no number formatting will be attempted.
        :param measurement_unit: the code of a measurement unit.
                                 Known units can be found in the CLDR Unit Validity XML file:
                                 https://unicode.org/repos/cldr/tags/latest/common/validity/unit.xml
        :param length: "short", "long" or "narrow"
        :param format: An optional format, as accepted by `format_decimal`.
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code _find_compound_unit:
  body: |
    def _find_compound_unit(numerator_unit: str, denominator_unit: str, locale: Locale | str | None=LC_NUMERIC):
        """
        Find a predefined compound unit pattern.
    
        Used internally by format_compound_unit.
    
        >>> _find_compound_unit("kilometer", "hour", locale="en")
        'speed-kilometer-per-hour'
    
        >>> _find_compound_unit("mile", "gallon", locale="en")
        'consumption-mile-per-gallon'
    
        If no predefined compound pattern can be found, `None` is returned.
    
        >>> _find_compound_unit("gallon", "mile", locale="en")
    
        >>> _find_compound_unit("horse", "purple", locale="en")
    
        :param numerator_unit: The numerator unit's identifier
        :param denominator_unit: The denominator unit's identifier
        :param locale: the `Locale` object or locale identifier
        :return: A key to the `unit_patterns` mapping, or None.
        :rtype: str|None
        
        """
        pass


code format_compound_unit:
  body: |
    def format_compound_unit(numerator_value: str | float | decimal.Decimal, numerator_unit: str | None=None, denominator_value: str | float | decimal.Decimal=1, denominator_unit: str | None=None, length: Literal['short', 'long', 'narrow']='long', format: str | None=None, locale: Locale | str | None=LC_NUMERIC, *, numbering_system: Literal['default'] | str='latn'):
        """
        Format a compound number value, i.e. "kilometers per hour" or similar.
    
        Both unit specifiers are optional to allow for formatting of arbitrary values still according
        to the locale's general "per" formatting specifier.
    
        >>> format_compound_unit(7, denominator_value=11, length="short", locale="pt")
        '7/11'
    
        >>> format_compound_unit(150, "kilometer", denominator_unit="hour", locale="sv")
        '150 kilometer per timme'
    
        >>> format_compound_unit(150, "kilowatt", denominator_unit="year", locale="fi")
        '150 kilowattia / vuosi'
    
        >>> format_compound_unit(32.5, "ton", 15, denominator_unit="hour", locale="en")
        '32.5 tons per 15 hours'
    
        >>> format_compound_unit(1234.5, "ton", 15, denominator_unit="hour", locale="ar_EG", numbering_system="arab")
        '1٬234٫5 طن لكل 15 ساعة'
    
        >>> format_compound_unit(160, denominator_unit="square-meter", locale="fr")
        '160 par m\xe8tre carr\xe9'
    
        >>> format_compound_unit(4, "meter", "ratakisko", length="short", locale="fi")
        '4 m/ratakisko'
    
        >>> format_compound_unit(35, "minute", denominator_unit="fathom", locale="sv")
        '35 minuter per famn'
    
        >>> from babel.numbers import format_currency
        >>> format_compound_unit(format_currency(35, "JPY", locale="de"), denominator_unit="liter", locale="de")
        '35\xa0\xa5 pro Liter'
    
        See https://www.unicode.org/reports/tr35/tr35-general.html#perUnitPatterns
    
        :param numerator_value: The numerator value. This may be a string,
                                in which case it is considered preformatted and the unit is ignored.
        :param numerator_unit: The numerator unit. See `format_unit`.
        :param denominator_value: The denominator value. This may be a string,
                                  in which case it is considered preformatted and the unit is ignored.
        :param denominator_unit: The denominator unit. See `format_unit`.
        :param length: The formatting length. "short", "long" or "narrow"
        :param format: An optional format, as accepted by `format_decimal`.
        :param locale: the `Locale` object or locale identifier
        :param numbering_system: The numbering system used for formatting number symbols. Defaults to "latn".
                                 The special value "default" will use the default numbering system of the locale.
        :return: A formatted compound value.
        :raise `UnsupportedNumberingSystemError`: If the numbering system is not supported by the locale.
        
        """
        pass


code distinct:
  body: |
    def distinct(iterable: Iterable[_T]):
        """Yield all items in an iterable collection that are distinct.
    
        Unlike when using sets for a similar effect, the original ordering of the
        items in the collection is preserved by this function.
    
        >>> print(list(distinct([1, 2, 1, 3, 4, 4])))
        [1, 2, 3, 4]
        >>> print(list(distinct('foobar')))
        ['f', 'o', 'b', 'a', 'r']
    
        :param iterable: the iterable collection providing the data
        
        """
        pass


code parse_encoding:
  body: |
    def parse_encoding(fp: IO[bytes]):
        """Deduce the encoding of a source file from magic comment.
    
        It does this in the same way as the `Python interpreter`__
    
        .. __: https://docs.python.org/3.4/reference/lexical_analysis.html#encoding-declarations
    
        The ``fp`` argument should be a seekable file object.
    
        (From Jeff Dairiki)
        
        """
        pass


code parse_future_flags:
  body: |
    def parse_future_flags(fp: IO[bytes], encoding: str='latin-1'):
        """Parse the compiler flags by :mod:`__future__` from the given Python
        code.
        
        """
        pass


code pathmatch:
  body: |
    def pathmatch(pattern: str, filename: str):
        """Extended pathname pattern matching.
    
        This function is similar to what is provided by the ``fnmatch`` module in
        the Python standard library, but:
    
         * can match complete (relative or absolute) path names, and not just file
           names, and
         * also supports a convenience pattern ("**") to match files at any
           directory level.
    
        Examples:
    
        >>> pathmatch('**.py', 'bar.py')
        True
        >>> pathmatch('**.py', 'foo/bar/baz.py')
        True
        >>> pathmatch('**.py', 'templates/index.html')
        False
    
        >>> pathmatch('./foo/**.py', 'foo/bar/baz.py')
        True
        >>> pathmatch('./foo/**.py', 'bar/baz.py')
        False
    
        >>> pathmatch('^foo/**.py', 'foo/bar/baz.py')
        True
        >>> pathmatch('^foo/**.py', 'bar/baz.py')
        False
    
        >>> pathmatch('**/templates/*.html', 'templates/index.html')
        True
        >>> pathmatch('**/templates/*.html', 'templates/foo/bar.html')
        False
    
        :param pattern: the glob pattern
        :param filename: the path name of the file to match against
        
        """
        pass


code wraptext:
  body: |
    def wraptext(text: str, width: int=70, initial_indent: str='', subsequent_indent: str=''):
        """Simple wrapper around the ``textwrap.wrap`` function in the standard
        library. This version does not wrap lines on hyphens in words.
    
        :param text: the text to wrap
        :param width: the maximum line width
        :param initial_indent: string that will be prepended to the first line of
                               wrapped output
        :param subsequent_indent: string that will be prepended to all lines save
                                  the first of wrapped output
        
        """
        pass
