set scraping_kit:
  intent: reusable bundle for HTML extraction
  tools:
    - fetch_url
    - readability_js
  skills:
    - extract_jsonld
  extensions:
    - mcp_playwright
  memory: |
    site_selectors:
      "example.com": { title: "h1", body: "article" }


agent extract_article:
  intent: extract structured fields from HTML
  use: scraping_kit
  prompt: |
    Return JSON with title and body.
  fallback: readability_js


agent multi_use_agent:
  intent: agent that uses multiple sets
  use:
    - scraping_kit
  prompt: |
    Demo of list-form use.
