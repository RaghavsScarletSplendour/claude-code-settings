# Fix: FxTwitter Link-Only Tweets

## Problem
For link-only tweets (where `tweet.text` is empty), the current code returns just engagement metrics instead of the actual content.

Example: `https://x.com/ryancarson/status/2008548371712135632`
- `tweet.text` = "" (empty)
- `tweet.raw_text` = "https://t.co/..." (just the link)
- But FxTwitter DOES provide article preview data

## Fix

Update `fetchXPost()` in `/app/api/summarize/route.ts` to:

1. Check for article/external content data in the response
2. Extract article title and description when present
3. Fall back gracefully for different tweet types

```typescript
async function fetchXPost(url: string): Promise<string> {
  const apiUrl = url.replace('x.com', 'api.fxtwitter.com')
  const response = await fetchWithTimeout(apiUrl)

  if (!response.ok) {
    throw new Error(`FxTwitter fetch failed: ${response.status}`)
  }

  const data = await response.json()
  const tweet = data.tweet

  if (!tweet) {
    throw new Error('No tweet data in response')
  }

  let content = `Tweet by @${tweet.author?.screen_name || 'unknown'}:`

  // Primary content: tweet text
  if (tweet.text && tweet.text.trim()) {
    content += `\n${tweet.text}`
  }

  // If tweet has article/URL card, include that
  if (tweet.article || tweet.card) {
    const article = tweet.article || tweet.card
    if (article.title) {
      content += `\n\nLinked Article: ${article.title}`
    }
    if (article.description) {
      content += `\n${article.description}`
    }
  }

  // Media info
  if (tweet.media?.photos?.length) {
    content += `\n[Contains ${tweet.media.photos.length} image(s)]`
  }
  if (tweet.media?.videos?.length) {
    content += `\n[Contains ${tweet.media.videos.length} video(s)]`
  }

  // Engagement context
  content += `\nLikes: ${tweet.likes || 0}, Retweets: ${tweet.retweets || 0}`

  return content
}
```

## File to Modify
`/app/api/summarize/route.ts` - Update the `fetchXPost()` function
