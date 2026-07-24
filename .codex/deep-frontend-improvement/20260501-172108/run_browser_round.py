from __future__ import annotations

import argparse
import json
from pathlib import Path

from playwright.sync_api import Page, sync_playwright


def click_text(page: Page, text: str) -> None:
    page.get_by_text(text, exact=True).click()


def screenshot(page: Page, root: Path, name: str) -> None:
    path = root / "screenshots" / f"{name}.png"
    path.parent.mkdir(parents=True, exist_ok=True)
    page.screenshot(path=str(path), full_page=True)


def record(steps: list[str], item: str) -> None:
    steps.append(item)


def build_recipe_step(page: Page, steps: list[str], station: str, tool: str, ingredient: str, action: str, duration: str) -> None:
    page.get_by_role("button", name="Add step").click()
    record(steps, f"Opened add-step wizard for {station}.")
    click_text(page, station)
    record(steps, f"Selected station: {station}.")
    if tool:
        click_text(page, tool)
        record(steps, f"Selected tool: {tool}.")
    page.get_by_placeholder("Search ingredients...").fill(ingredient)
    record(steps, f"Searched ingredient: {ingredient}.")
    click_text(page, ingredient)
    record(steps, f"Selected ingredient: {ingredient}.")
    click_text(page, "Done with Ingredients")
    record(steps, "Advanced to compatible action list.")
    click_text(page, action)
    record(steps, f"Selected action: {action}.")
    page.get_by_role("button", name=duration, exact=True).click()
    record(steps, f"Selected duration: {duration}.")
    click_text(page, "Add Step to Recipe")
    record(steps, "Saved step to recipe timeline.")


def run_round(round_id: int, base_url: str, bundle: Path) -> None:
    round_root = bundle / f"round-{round_id}"
    (round_root / "logs").mkdir(parents=True, exist_ok=True)
    (round_root / "screenshots").mkdir(parents=True, exist_ok=True)
    steps: list[str] = []
    console_messages: list[str] = []
    page_errors: list[str] = []
    request_failures: list[str] = []

    viewport = {
        1: {"width": 390, "height": 844},
        2: {"width": 768, "height": 1024},
        3: {"width": 1280, "height": 900},
    }[round_id]

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        page = browser.new_page(viewport=viewport)
        page.on("console", lambda message: console_messages.append(f"{message.type}: {message.text}"))
        page.on("pageerror", lambda error: page_errors.append(str(error)))
        page.on("requestfailed", lambda request: request_failures.append(f"{request.method} {request.url} {request.failure}"))

        page.goto(base_url)
        page.wait_for_load_state("networkidle")
        record(steps, f"Loaded app at {base_url} with viewport {viewport['width']}x{viewport['height']}.")
        screenshot(page, round_root, "01-community-home")

        page.get_by_role("button", name="Create recipe").click()
        page.wait_for_timeout(300)
        record(steps, "Opened recipe builder from bottom navigation.")
        screenshot(page, round_root, "02-builder-empty")

        build_recipe_step(page, steps, "Prep Station", "Chef Knife", "Tomato", "Chop", "5 mins")
        page.wait_for_timeout(300)
        screenshot(page, round_root, "03-prep-step-with-motion")

        build_recipe_step(page, steps, "Hot Station", "Frying Pan", "Chicken", "Stir Fry", "10 mins")
        page.wait_for_timeout(300)
        screenshot(page, round_root, "04-cook-step-with-motion")

        page.get_by_role("button", name="Decider", exact=True).click()
        page.wait_for_load_state("networkidle")
        record(steps, "Navigated from builder to decider using bottom navigation.")
        screenshot(page, round_root, "05-decider")
        page.get_by_role("button", name="Spin Cuisine").click()
        page.wait_for_timeout(3200)
        record(steps, "Spun cuisine wheel.")
        screenshot(page, round_root, "06-decider-result")

        page.get_by_role("button", name="Me", exact=True).click()
        page.wait_for_timeout(300)
        record(steps, "Opened profile tab.")
        screenshot(page, round_root, "07-profile")

        page.get_by_role("button", name="Home", exact=True).click()
        page.wait_for_load_state("networkidle")
        record(steps, "Returned to community home.")
        screenshot(page, round_root, "08-return-home")

        browser.close()

    (round_root / "steps.md").write_text(
        "\n".join(f"{index + 1}. {step}" for index, step in enumerate(steps)),
        encoding="utf-8",
    )
    (round_root / "logs" / "browser.json").write_text(
        json.dumps(
            {
                "console": console_messages,
                "page_errors": page_errors,
                "request_failures": request_failures,
            },
            indent=2,
        ),
        encoding="utf-8",
    )
    (round_root / "screenshot-index.md").write_text(
        "\n".join(
            [
                "# Screenshot Index",
                "",
                "- 01-community-home: Community feed loaded.",
                "- 02-builder-empty: Builder empty state and animation asset readiness panel.",
                "- 03-prep-step-with-motion: Prep step saved with generated transition/action motion.",
                "- 04-cook-step-with-motion: Cook step saved with generated transition/action motion.",
                "- 05-decider: Decider screen reachable after leaving builder.",
                "- 06-decider-result: Cuisine wheel result after spin.",
                "- 07-profile: Profile screen reachable.",
                "- 08-return-home: Navigation loop back to home.",
            ]
        ),
        encoding="utf-8",
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--round", type=int, required=True, choices=[1, 2, 3])
    parser.add_argument("--base-url", default="http://127.0.0.1:5173")
    parser.add_argument("--bundle", required=True)
    args = parser.parse_args()
    run_round(args.round, args.base_url, Path(args.bundle))
