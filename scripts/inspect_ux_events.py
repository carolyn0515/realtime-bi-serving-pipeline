import json
from collections import Counter, defaultdict
from pathlib import Path


INPUT_PATH = Path("data/samples/sample_ux_events.jsonl")


def main() -> None:
    events = []

    with INPUT_PATH.open("r", encoding="utf-8") as f:
        for line in f:
            events.append(json.loads(line))

    counts = Counter(event["event_type"] for event in events)

    by_session = defaultdict(list)
    for event in events:
        by_session[event["session_id"]].append(event)

    bad_sessions = []

    for session_id, session_events in by_session.items():
        ordered = sorted(session_events, key=lambda event: event["event_time"])
        sequence = [event["event_type"] for event in ordered]

        if sequence not in (
            ["view"],
            ["view", "cart"],
            ["view", "cart", "purchase"],
        ):
            bad_sessions.append((session_id, sequence))

    view_count = counts["view"]
    cart_count = counts["cart"]
    purchase_count = counts["purchase"]

    view_to_cart_rate = cart_count / view_count if view_count else None
    cart_to_purchase_rate = purchase_count / cart_count if cart_count else None
    view_to_purchase_rate = purchase_count / view_count if view_count else None

    print(f"events={len(events)}")
    print(f"sessions={len(by_session)}")
    print(f"event_counts={dict(counts)}")
    print(f"view_to_cart_rate={view_to_cart_rate:.4f}")
    print(f"cart_to_purchase_rate={cart_to_purchase_rate:.4f}")
    print(f"view_to_purchase_rate={view_to_purchase_rate:.4f}")
    print(f"bad_sessions={len(bad_sessions)}")

    if bad_sessions:
        print("first_bad_session=", bad_sessions[0])


if __name__ == "__main__":
    main()