from __future__ import annotations

import csv
import html
import json
import subprocess
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_DIR = PROJECT_ROOT / "data" / "generated" / "starrocks_dashboard"
STARROCKS_CONTAINER = "realtime-bi-starrocks"


@dataclass(frozen=True)
class QueryResult:
    columns: list[str]
    rows: list[dict[str, str]]


def run_starrocks_query(sql: str) -> QueryResult:
    command = [
        "docker",
        "exec",
        STARROCKS_CONTAINER,
        "mysql",
        "-h127.0.0.1",
        "-P9030",
        "-uroot",
        "--batch",
        "--raw",
        "-e",
        sql,
    ]
    completed = subprocess.run(
        command,
        cwd=PROJECT_ROOT,
        check=True,
        text=True,
        capture_output=True,
    )
    lines = [line for line in completed.stdout.splitlines() if line.strip()]
    if not lines:
        return QueryResult(columns=[], rows=[])

    reader = csv.reader(lines, delimiter="\t")
    columns = next(reader)
    rows = [dict(zip(columns, row, strict=False)) for row in reader]
    return QueryResult(columns=columns, rows=rows)


def scalar(result: QueryResult, column: str, default: str = "0") -> str:
    if not result.rows:
        return default
    return result.rows[0].get(column, default)


def fmt_rate(value: str | None) -> str:
    if value in (None, "", "NULL", "<NULL>"):
        return "-"
    try:
        return f"{float(value) * 100:.1f}%"
    except ValueError:
        return value


def fmt_number(value: str | None) -> str:
    if value in (None, "", "NULL", "<NULL>"):
        return "-"
    try:
        return f"{float(value):,.0f}"
    except ValueError:
        return value


def html_escape(value: object) -> str:
    if value is None:
        return ""
    return html.escape(str(value))


def table_html(columns: list[str], rows: Iterable[dict[str, str]]) -> str:
    header = "".join(f"<th>{html_escape(column)}</th>" for column in columns)
    body_rows: list[str] = []
    for row in rows:
        cells = "".join(f"<td>{html_escape(row.get(column, ''))}</td>" for column in columns)
        body_rows.append(f"<tr>{cells}</tr>")
    body = "\n".join(body_rows)
    return f"<table><thead><tr>{header}</tr></thead><tbody>{body}</tbody></table>"


def build_html(
    summary: QueryResult,
    severity: QueryResult,
    baseline_scope: QueryResult,
    top_segments: QueryResult,
    watchlist: QueryResult,
    exported_at: str,
) -> str:
    summary_row = summary.rows[0] if summary.rows else {}
    watchlist_count = len(watchlist.rows)

    return f"""<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Realtime Funnel BI Serving Dashboard</title>
  <style>
    :root {{
      color-scheme: light;
      --bg: #f6f7f9;
      --panel: #ffffff;
      --line: #d8dde6;
      --text: #172033;
      --muted: #657083;
      --accent: #2563eb;
      --good: #15803d;
      --warn: #b45309;
      --bad: #b91c1c;
    }}
    * {{ box-sizing: border-box; }}
    body {{
      margin: 0;
      font-family: Inter, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      background: var(--bg);
      color: var(--text);
    }}
    main {{
      width: min(1180px, calc(100vw - 40px));
      margin: 32px auto 56px;
    }}
    header {{
      display: flex;
      justify-content: space-between;
      gap: 24px;
      align-items: end;
      margin-bottom: 24px;
    }}
    h1 {{
      margin: 0 0 6px;
      font-size: 30px;
      letter-spacing: 0;
    }}
    h2 {{
      margin: 0 0 14px;
      font-size: 18px;
      letter-spacing: 0;
    }}
    p {{
      margin: 0;
      color: var(--muted);
      line-height: 1.5;
    }}
    .timestamp {{
      color: var(--muted);
      font-size: 13px;
      white-space: nowrap;
    }}
    .metrics {{
      display: grid;
      grid-template-columns: repeat(4, minmax(0, 1fr));
      gap: 12px;
      margin-bottom: 16px;
    }}
    .metric, section {{
      background: var(--panel);
      border: 1px solid var(--line);
      border-radius: 8px;
      box-shadow: 0 1px 2px rgba(15, 23, 42, 0.04);
    }}
    .metric {{
      padding: 16px;
    }}
    .metric .label {{
      color: var(--muted);
      font-size: 12px;
      text-transform: uppercase;
    }}
    .metric .value {{
      margin-top: 8px;
      font-size: 26px;
      font-weight: 700;
    }}
    .grid {{
      display: grid;
      grid-template-columns: 1fr 1fr;
      gap: 16px;
      margin-bottom: 16px;
    }}
    section {{
      padding: 18px;
      overflow-x: auto;
    }}
    table {{
      width: 100%;
      border-collapse: collapse;
      font-size: 13px;
    }}
    th, td {{
      padding: 9px 10px;
      border-bottom: 1px solid #e8ecf2;
      text-align: left;
      vertical-align: top;
      white-space: nowrap;
    }}
    th {{
      color: var(--muted);
      font-weight: 600;
      background: #fbfcfe;
    }}
    .empty {{
      border: 1px dashed var(--line);
      border-radius: 8px;
      padding: 18px;
      color: var(--muted);
      background: #fbfcfe;
    }}
    .status-good {{ color: var(--good); }}
    .status-warn {{ color: var(--warn); }}
    .status-bad {{ color: var(--bad); }}
    @media (max-width: 900px) {{
      header {{ display: block; }}
      .timestamp {{ margin-top: 8px; }}
      .metrics, .grid {{ grid-template-columns: 1fr; }}
      main {{ width: min(100vw - 24px, 1180px); margin-top: 20px; }}
    }}
  </style>
</head>
<body>
  <main>
    <header>
      <div>
        <h1>Realtime Funnel BI Serving Dashboard</h1>
        <p>StarRocks serving views backed by the DQ-passed Paimon anomaly mart.</p>
      </div>
      <div class="timestamp">Exported at {html_escape(exported_at)}</div>
    </header>

    <div class="metrics">
      <div class="metric">
        <div class="label">Served Rows</div>
        <div class="value">{html_escape(fmt_number(summary_row.get("served_rows")))}</div>
      </div>
      <div class="metric">
        <div class="label">View Sessions</div>
        <div class="value">{html_escape(fmt_number(summary_row.get("total_views")))}</div>
      </div>
      <div class="metric">
        <div class="label">Cart Rate</div>
        <div class="value">{html_escape(fmt_rate(summary_row.get("overall_view_to_cart_rate")))}</div>
      </div>
      <div class="metric">
        <div class="label">Watchlist</div>
        <div class="value {'status-good' if watchlist_count == 0 else 'status-warn'}">{watchlist_count}</div>
      </div>
    </div>

    <div class="grid">
      <section>
        <h2>Severity Distribution</h2>
        {table_html(severity.columns, severity.rows)}
      </section>
      <section>
        <h2>Baseline Scope Usage</h2>
        {table_html(baseline_scope.columns, baseline_scope.rows)}
      </section>
    </div>

    <section>
      <h2>Anomaly Watchlist</h2>
      {table_html(watchlist.columns, watchlist.rows) if watchlist.rows else '<div class="empty">No warning or critical rows met the current sample-size threshold.</div>'}
    </section>

    <section style="margin-top: 16px;">
      <h2>Top Funnel Segments By Volume</h2>
      {table_html(top_segments.columns, top_segments.rows)}
    </section>
  </main>
</body>
</html>
"""


def main() -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    exported_at = datetime.now(timezone.utc).isoformat()

    summary = run_starrocks_query(
        """
        SELECT
            COUNT(*) AS served_rows,
            SUM(view_count) AS total_views,
            SUM(cart_count) AS total_carts,
            SUM(purchase_count) AS total_purchases,
            SUM(cart_count) / NULLIF(SUM(view_count), 0) AS overall_view_to_cart_rate,
            SUM(purchase_count) / NULLIF(SUM(cart_count), 0) AS overall_cart_to_purchase_rate,
            SUM(purchase_count) / NULLIF(SUM(view_count), 0) AS overall_view_to_purchase_rate,
            MIN(window_start) AS min_window_start,
            MAX(window_end) AS max_window_end
        FROM bi_serving.v_funnel_health;
        """
    )
    severity = run_starrocks_query(
        """
        SELECT
            severity,
            COALESCE(anomaly_stage, 'none') AS anomaly_stage,
            COUNT(*) AS row_count
        FROM bi_serving.v_funnel_health
        GROUP BY severity, COALESCE(anomaly_stage, 'none')
        ORDER BY row_count DESC, severity, anomaly_stage;
        """
    )
    baseline_scope = run_starrocks_query(
        """
        SELECT
            baseline_scope,
            COUNT(*) AS row_count,
            MIN(baseline_window_count) AS min_baseline_windows,
            MAX(baseline_window_count) AS max_baseline_windows
        FROM bi_serving.v_funnel_health
        GROUP BY baseline_scope
        ORDER BY row_count DESC, baseline_scope;
        """
    )
    top_segments = run_starrocks_query(
        """
        SELECT
            category_code,
            price_tier,
            customer_state,
            seller_state,
            SUM(view_count) AS views,
            SUM(cart_count) AS carts,
            SUM(purchase_count) AS purchases,
            SUM(cart_count) / NULLIF(SUM(view_count), 0) AS view_to_cart_rate,
            SUM(purchase_count) / NULLIF(SUM(cart_count), 0) AS cart_to_purchase_rate,
            MAX(severity) AS max_severity
        FROM bi_serving.v_funnel_health
        GROUP BY category_code, price_tier, customer_state, seller_state
        ORDER BY views DESC, carts DESC, purchases DESC
        LIMIT 20;
        """
    )
    watchlist = run_starrocks_query(
        """
        SELECT
            window_start,
            category_code,
            price_tier,
            customer_state,
            seller_state,
            view_count,
            cart_count,
            purchase_count,
            drop_rate,
            severity,
            anomaly_stage
        FROM bi_serving.v_anomaly_watchlist
        ORDER BY
            CASE severity
                WHEN 'critical' THEN 1
                WHEN 'warning' THEN 2
                ELSE 3
            END,
            drop_rate DESC,
            window_start
        LIMIT 50;
        """
    )

    payload = {
        "exported_at": exported_at,
        "summary": summary.rows,
        "severity": severity.rows,
        "baseline_scope": baseline_scope.rows,
        "top_segments": top_segments.rows,
        "watchlist": watchlist.rows,
    }

    json_path = OUTPUT_DIR / "dashboard_data.json"
    html_path = OUTPUT_DIR / "dashboard.html"

    json_path.write_text(json.dumps(payload, indent=2), encoding="utf-8")
    html_path.write_text(
        build_html(
            summary=summary,
            severity=severity,
            baseline_scope=baseline_scope,
            top_segments=top_segments,
            watchlist=watchlist,
            exported_at=exported_at,
        ),
        encoding="utf-8",
    )

    print(f"wrote {json_path}")
    print(f"wrote {html_path}")


if __name__ == "__main__":
    main()
