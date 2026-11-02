# Contributing to Power BI Dutch Date Table

Thank you for your interest in contributing!

Contributions, bug reports, and suggestions are welcome.

## How to contribute

1. Check existing Issues and Pull Requests.
2. Open an Issue to discuss significant changes.
3. Fork this repository.
4. Create a new branch for your changes.
5. Update `DateTable_NL.pq`.
6. Test your changes in Power BI Desktop.
7. Submit a Pull Request describing your changes.

## Development guidelines

- Use Power Query M.
- Keep column names in Dutch.
- Follow ISO 8601 for week numbering.
- Maintain compatibility with Power BI Desktop.
- Avoid unnecessary performance overhead.
- Preserve existing functionality unless a breaking change is intentional.
- Update the README when adding or changing attributes.

## Testing

Before submitting a Pull Request, please verify:

- The query runs without errors.
- Dates are unique and sorted chronologically.
- ISO weeks are correct around year boundaries.
- Dutch public holidays are calculated correctly.
- Relative date attributes produce expected results.

## Reporting bugs

Please open a GitHub Issue with a description of the problem, the expected result, and an example date where applicable.

## License

By contributing, you agree that your contributions will be distributed under the project's MIT License.
