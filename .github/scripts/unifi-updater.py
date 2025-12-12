#!/usr/bin/env python3
import urllib.request
import xml.etree.ElementTree as ET
import re
import sys
import email.utils
from datetime import datetime

FEED_URL = "https://community.ui.com/rss/releases/UniFi-Network-Application/e6712595-81bb-4829-8e42-9e2630fabcfe"
DOCKERFILE = "Dockerfile"
README = "README.md"


def fetch(url: str) -> bytes:
    req = urllib.request.Request(
        url,
        headers={"User-Agent": "Mozilla/5.0 (GitHub Actions UniFi Updater)"}
    )
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read()


def parse_rss_latest(feed_bytes):
    """
    Parse the RSS feed and pick the newest release.

    Priority:
    1. Stable (no 'beta', 'rc', or 'release candidate' in title)
    2. RC (no 'beta' in title)
    3. Any entry with a version, as a last resort
    """
    root = ET.fromstring(feed_bytes)
    items = root.findall(".//item")
    if not items:
        raise RuntimeError("No <item> entries in RSS feed")

    releases = []

    for item in items:
        title_el = item.find("title")
        link_el = item.find("link")
        date_el = item.find("pubDate")

        if title_el is None or link_el is None:
            continue

        title = (title_el.text or "").strip()
        link = (link_el.text or "").strip()
        date_raw = (date_el.text or "").strip() if date_el is not None else ""

        # Try to extract version like 10.0.160 or 9.5.21
        m = re.search(r"(\d+\.\d+\.\d+)", title)
        if not m:
            # Fallback to 2-part versions like 10.0
            m = re.search(r"(\d+\.\d+)", title)
        if not m:
            continue

        version = m.group(1)

        if date_raw:
            try:
                dt = email.utils.parsedate_to_datetime(date_raw)
                date_str = dt.date().isoformat()
            except Exception:
                date_str = ""
        else:
            date_str = ""

        releases.append(
            {
                "title": title,
                "title_lc": title.lower(),
                "version": version,
                "link": link,
                "date": date_str,
            }
        )

    if not releases:
        raise RuntimeError("No releases with a recognizable version found in RSS feed")

    # 1. Prefer "stable" (no beta/rc)
    stable = [
        r for r in releases
        if not any(tag in r["title_lc"] for tag in ("beta", " rc", "release candidate"))
    ]
    if stable:
        return stable[0]

    # 2. Fallback: allow RCs but still skip explicit "beta"
    rc = [r for r in releases if "beta" not in r["title_lc"]]
    if rc:
        return rc[0]

    # 3. Last resort: whatever is first in the feed
    return releases[0]


def build_pkgurl(version: str) -> str:
    """
    Construct the expected sysvinit .deb URL from the version.
    Example: 9.5.21 -> https://dl.ui.com/unifi/9.5.21/unifi_sysvinit_all.deb
    """
    return f"https://dl.ui.com/unifi/{version}/unifi_sysvinit_all.deb"


def update_dockerfile(url: str) -> None:
    with open(DOCKERFILE, "r", encoding="utf-8") as f:
        src = f.read()

    new_src, subs = re.subn(
        r"ARG\s+PKGURL=.*",
        f"ARG PKGURL={url}",
        src,
        count=1,
    )

    if subs == 0:
        raise RuntimeError("Failed to update PKGURL in Dockerfile")

    if new_src != src:
        with open(DOCKERFILE, "w", encoding="utf-8") as f:
            f.write(new_src)


def update_readme(version: str, date_str: str, link: str) -> None:
    with open(README, "r", encoding="utf-8") as f:
        src = f.read()

    new_row = (
        f"| [`latest` `v{version}`](https://github.com/jacobalberty/unifi-docker/blob/master/Dockerfile) "
        f"| Current Stable: Version {version} as of {date_str} "
        f"| [Change Log {version}]({link}) |"
    )

    # Replace the first "latest" row in the Current Information table
    new_src, subs = re.subn(
        r"^\| \[`latest` `v[0-9.]+`\]\(.*?\) \| Current Stable: Version [0-9.]+ as of [0-9-]+ \| \[Change Log [0-9.]+\]\(.*?\) \|$",
        new_row,
        src,
        count=1,
        flags=re.MULTILINE,
    )

    if subs == 0:
        raise RuntimeError("Failed to update README row")

    if new_src != src:
        with open(README, "w", encoding="utf-8") as f:
            f.write(new_src)


def main() -> None:
    feed = fetch(FEED_URL)
    rel = parse_rss_latest(feed)

    version = rel["version"]
    link = rel["link"]
    date_str = rel["date"] or datetime.now(timezone.utc)

    pkg_url = build_pkgurl(version)

    update_dockerfile(pkg_url)
    update_readme(version, date_str, link)

    # Printed so GitHub Actions step can capture it
    print(version)


if __name__ == "__main__":
    main()
