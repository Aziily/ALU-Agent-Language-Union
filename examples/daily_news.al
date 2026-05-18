flow daily_news_digest:
  intent: fetch news every morning, clean, summarize, email
  schedule: daily 09:00
  steps:
    - fetch_sources
    - clean_data
    - summarize
    - deliver


flow fetch_sources:
  intent: fetch from RSS feeds and news sites in parallel
  output: list[Article](article objects)
  steps:
    - parallel:
        - read_feeds
        - scrape_html
    - merge_results


code read_feeds:
  intent: read RSS feeds and parse entries
  input: list[str](URLs)
  output: list[Article](article objects)
  body: |
    import feedparser

    def read_feeds(urls):
        items = []
        for url in urls:
            feed = feedparser.parse(url)
            for entry in feed.entries:
                items.append({
                    "title": entry.title,
                    "url": entry.link,
                    "published_at": entry.published,
                })
        return items


agent scrape_html:
  intent: scrape sites without RSS, adapt when page structure changes
  input: list[Site](site definitions)
  output: list[Article](article objects)
  steps:
    - each site:
        - fetch_page
        - extract_article


code fetch_page:
  intent: HTTP GET, handle redirects / UA / throttling
  input: str(URL)
  output: str(HTML body)
  body: |
    import httpx

    UA = {"User-Agent": "AgentLang/0.6"}

    def fetch_page(url):
        r = httpx.get(url, headers=UA, follow_redirects=True, timeout=15)
        r.raise_for_status()
        return r.text


set scraping_kit:
  intent: reusable bundle for agents that read messy HTML
  tools:
    - fetch_url
    - readability_js
    - html_to_markdown
  skills:
    - extract_jsonld
    - normalize_dates
  extensions:
    - mcp_playwright
    - mcp_serpapi
  memory: |
    site_selectors:
      "nytimes.com":  { title: "h1.headline", body: "section.article-body" }
      "medium.com":   { title: "h1", body: "article" }
      "substack.com": { title: "h1.post-title", body: "div.body" }
    paywall_domains: ["wsj.com", "ft.com", "economist.com"]


agent extract_article:
  intent: extract structured fields from HTML, adapt when pages change
  input: str(raw HTML)
  output:
    title: str
    author: str
    body: str
    published_at: datetime
  use: scraping_kit
  prompt: |
    Given the HTML below, return JSON with title, author, body, published_at.
    If the page is a listing or paywall, return null.
  fallback: readability_js


code merge_results:
  intent: merge feed + scrape results, dedupe by URL
  input: tuple[list[Article], list[Article]](feed_results, scrape_results)
  output: list[Article](deduped articles)
  body: |
    def merge_results(a, b):
        seen = set()
        out = []
        for x in [*a, *b]:
            if x["url"] in seen:
                continue
            seen.add(x["url"])
            out.append(x)
        return out


flow clean_data:
  intent: dedupe, filter noise, normalize fields
  steps:
    - parallel:
        - dedupe_fuzzy
        - filter_spam
    - each item:
        - normalize


agent dedupe_fuzzy:
  intent: cluster near-duplicate stories from different outlets
  use:
    - scraping_kit
  prompt: |
    Embed each title into a vector.
    Cluster by cosine similarity > 0.88.
    Keep one item per cluster (the most recent one).


agent filter_spam:
  intent: drop ads, press releases, low quality content
  prompt: |
    Look at the title and lead paragraph.
    Is this a press release, paid promo, or low quality?
    Answer: yes or no.


code normalize:
  intent: standardize fields — ISO dates, trimmed authors, lowercase tags
  input: Article(one article)
  output: Article(normalized article)
  body: |
    from dateutil import parser as dateparser

    def normalize(x):
        return {
            **x,
            "published_at": dateparser.parse(x["published_at"]).isoformat(),
            "tags": [t.lower() for t in x.get("tags", [])],
        }


flow summarize:
  intent: write per-item summaries, pick top items, write daily digest
  steps:
    - each item:
        - summarize_item
    - rank_items
    - write_digest


agent summarize_item:
  intent: write a tight summary for one news item
  prompt: |
    Summarize in two sentences, plain English.
    Then return three lowercase tags.


agent rank_items:
  intent: rank by user interest, novelty, importance
  input: tuple[list[Article], UserProfile](items, user profile)
  output: list[Article](top 10 ranked items)
  prompt: |
    Score each item on relevance to user, novelty vs recent items,
    and broad importance. Return the top 10 by combined score.


agent write_digest:
  intent: compose a fluent daily digest from the top items
  prompt: |
    Write a friendly daily digest in markdown.
    Open with a one-sentence overview.
    Group by theme. Cite sources inline as [link].


flow deliver:
  intent: render email, send, retry on failure
  steps:
    - render_email
    - send_smtp
    - log_delivery


code render_email:
  intent: MJML to HTML
  input: Digest(daily digest)
  output: str(rendered email HTML)
  body: |
    from mjml import mjml_to_html

    def render_email(digest):
        return mjml_to_html(template(digest)).html


code send_smtp:
  intent: send via SMTP, retry with exponential backoff on failure
  input: tuple[str, list[str]](html body, recipient emails)
  body: |
    from tenacity import retry, stop_after_attempt, wait_exponential

    @retry(stop=stop_after_attempt(3), wait=wait_exponential(min=1, max=8))
    def send_smtp(html, recipients):
        smtp.send(html=html, to=recipients)


code log_delivery:
  intent: write delivery log (success / failure / open rate)
  input: dict[str, str](delivery result)
  body: |
    def log_delivery(result):
        db.deliveries.insert_one(result)
