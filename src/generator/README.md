# UX Log Generator

This package converts raw Olist CSV files into synthetic UX events.

Initial responsibilities:

- Load and join Olist source tables.
- Build product interaction records.
- Generate repeatable `view`, `cart`, and `purchase` event sequences.
- Inject anomalies, late events, duplicate events, and malformed events for experiments.

The first generated output should be written to `data/samples/sample_ux_events.jsonl`.
