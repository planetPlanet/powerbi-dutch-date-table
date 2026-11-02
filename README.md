# Power BI Dutch Date Table

A reusable Power Query M date dimension for Microsoft Power BI, specifically designed for reporting in the Netherlands.

The date table includes Dutch calendar attributes, public holidays, ISO 8601 week numbering, working-day indicators, and relative date periods.

## Features

- Dutch month and weekday names
- Integer date key (`YYYYMMDD`)
- Gregorian calendar attributes, including century
- ISO 8601 week numbers and week-years
- Dutch public holidays, including Easter-based holidays
- Working-day and weekend indicators
- Relative day, week, month, quarter, and year offsets
- Current and previous period indicators
- Rolling 7-day, 30-day, and 12-calendar-month filters
- Year-to-date, quarter-to-date, and month-to-date indicators
- Chronological sorting by date
- Netherlands-aware daylight saving time handling

## Installation

1. Open Power BI Desktop.
2. Select **Transform data**.
3. Create a **Blank Query**.
4. Open the **Advanced Editor**.
5. Copy the contents of `DateTable_NL.pq`.
6. Paste the code into the editor.
7. Adjust `StartJaar` and `EindJaar` if necessary.
8. Select **Close & Apply**.

After loading, mark the table as a date table using the `Datum` column.

## Configuration

The default date range is 2020–2035.

```powerquery
StartJaar = 2020,
EindJaar = 2035,
Cultuur = "nl-NL"
```

## Relative date periods

Relative date attributes are calculated against the current date in the Netherlands.

For example, `RelatieveMaand` returns:

| Value | Meaning |
|---|---|
| -2 | Two months ago |
| -1 | Previous month |
| 0 | Current month |
| 1 | Next month |
| 2 | Two months ahead |

Relative attributes are updated when the Power BI dataset refreshes.

## Dutch public holidays

The table includes official Dutch public holidays. Note that public holidays are not necessarily non-working days for every employee or organization.

The `IsWerkdag` attribute assumes that all included public holidays are non-working days.

## Contributing

Contributions are welcome!

If you find a bug or have an idea for a new date attribute, please open an Issue.

If you would like to contribute code, fork the repository and submit a Pull Request.

Please read [CONTRIBUTING.md](CONTRIBUTING.md) before contributing.

## License

This project is licensed under the MIT License.
