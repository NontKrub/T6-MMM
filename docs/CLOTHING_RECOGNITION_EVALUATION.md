# Clothing recognition evaluation

The release evaluation requires 40 owned or licensed, non-personal images:
five each for `top`, `pants`, `shoes`, `hat`, `outerwear`, `dress`, `bag`, and
`accessory`. The manifest must record the expected category, primary color, and
capture conditions for every fixture.

MMM's initial internal gate is an overall top-level category accuracy of at
least 85%, with no category below 70%. These are project thresholds, not an
industry or platform guarantee. A low-confidence local result must request
manual review, and guest images must never be sent anonymously to a paid AI
endpoint just to improve a score.

The harness writes one record per fixture and a summary containing overall and
per-category accuracy, confusion counts, and manual-review rate. The current
repository has only the example/white-shirt fixture, so the 40-image gate is
**BLOCKED**, and guest recognition remains a manual-review fallback.
