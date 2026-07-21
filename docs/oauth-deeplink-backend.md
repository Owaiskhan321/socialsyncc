# OAuth → App Deep Link (Backend)

After social OAuth completes on the server (`/oauth/{platform}/callback`), redirect the **user’s browser** into the mobile app.

## Redirect URLs (use these exact forms)

### Success
```
socialsyncc://oauth/callback?platform=meta&status=success
```

### Error
```
socialsyncc://oauth/callback?platform=meta&status=error&message=access_denied
```

## Allowed `platform` values
`google` · `meta` · `thread` · `x` · `linkedin` · `linkedin_organization` · `pinterest` · `tiktok`

## Allowed `status` values
`success` · `error`  
(Also accepted: `ok`, `connected`)

## Example (Express)
```js
// Success
res.redirect(`socialsyncc://oauth/callback?platform=${platform}&status=success`);

// Failure
res.redirect(
  `socialsyncc://oauth/callback?platform=${platform}&status=error&message=${encodeURIComponent(msg)}`
);
```

## Flow
1. App calls `GET /oauth/connect?platform=meta` → gets `authorizationUrl`
2. App opens that URL in the system browser
3. User authorizes on Facebook / Google / etc.
4. Provider hits your server callback (`https://api.socialsyncc.com/oauth/meta/callback`)
5. **Your server** redirects browser → `socialsyncc://oauth/callback?platform=meta&status=success`
6. OS opens SocialSyncc; app refreshes connected accounts

## Notes
- Custom scheme works immediately (no Apple/Google domain verification needed).
- Optional later HTTPS link: `https://app.socialsyncc.com/oauth/callback?...` (needs Digital Asset Links + Apple AASA).
