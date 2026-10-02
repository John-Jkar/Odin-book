# Odinbook

Odinbook is a Rails 8.1 social media clone modeled after the classic Odin Project assignment. It implements users, authentication, posts, comments, likes, follow requests (with an accept/decline workflow), user profiles with avatars (Active Storage + Gravatar fallback), a personalized newsfeed, and a "For You" discovery feed.

## Features

- **Authentication**: Devise handles sign up/in/out, password resets and sessions.
- **Profiles**: Each user has a profile page with bio, location, website, birth date, follower/following counts, and an avatar.
- **Posts**: Authenticated users can create/delete their own posts (max 280 characters). Posts show author, timestamp, content, comment count and like count.
- **Comments**: Users can comment on posts and delete their own comments.
- **Likes**: Toggle likes on posts with counter caches keeping counts in sync.
- **Following**: Send, cancel, accept, or decline follow requests. Only accepted follows appear in the follower/following lists and in the feed.
- **Newsfeed**: The home/feed aggregates the current user's posts and those of everyone they follow, ordered newest first.
- **For You**: `/discover` lists the newest posts from every *other* user, regardless of follow status, so you can find people worth following.
- **Emails**: A welcome email is sent asynchronously to new users (previewed with Letter Opener in development).
- **File uploads**: Users can upload a profile picture via Active Storage; Gravatar is used as a fallback when no avatar is attached.

## User interface

The front end is a hand-rolled design system in `app/assets/stylesheets/application.css` (no CSS framework).

- **Design tokens** — colours, spacing, radii, shadows and motion are defined once as CSS custom properties in `:root`.
- **Dark mode** — the token set is overridden under `@media (prefers-color-scheme: dark)`, so the whole app follows the OS setting with no flash of the wrong theme.
- **Sticky glass navbar** — blurred translucent bar with an active-page highlight on the current section.
- **Cards, buttons, badges and forms** — consistent radii, elevation and hover/focus states, with visible `:focus-visible` rings for keyboard users.
- **Empty states** — every list has an illustrated empty state with a next action instead of a blank screen.
- **Responsive** — single column below 720px; profile headers stack and centre, and user rows reflow.
- **Accessible** — semantic landmarks, `aria-label`s on icon-style controls, labelled form fields, and `prefers-reduced-motion` support.

## Stack

- Ruby 3.3.8
- Rails 8.1.4
- PostgreSQL 14+
- Devise, Active Storage, Turbo, importmap-rails (no Node build step)
- Minitest, Capybara, Selenium for tests; RuboCop and Brakeman for lint and security

`libvips` is optional and only needed if you process Active Storage variants; basic avatar uploads work without it.

## Getting started

Prerequisites: Ruby 3.3+ and a running PostgreSQL 14+.

1. **Install dependencies**

   ```bash
   bin/setup
   ```

   This runs `bundle install`, creates the databases, loads the schema, seeds sample data, and starts the server. Use `bin/setup --skip-server` to stop before the server starts.

2. **Database credentials**

   `config/database.yml` reads the standard libpq environment variables and defaults to the usual local PostgreSQL role:

   | Variable | Default | Purpose |
   | --- | --- | --- |
   | `PGHOST` | `localhost` | Database host |
   | `PGPORT` | `5432` | Database port |
   | `PGUSER` | `postgres` | Database role |
   | `PGPASSWORD` | `postgres` | Database password |

   If your role differs, export the variables once per shell before running any Rails command:

   ```bash
   export PGUSER=odinbook PGPASSWORD=odinbook
   ```

   Leave `DATABASE_URL` unset when running the test suite. It overrides the database name from `config/database.yml`, and pointing it at the `postgres` maintenance database makes `db:test:prepare` fail with `cannot drop the currently open database`.

3. **Start the server**

   ```bash
   bin/rails server
   ```

   Visit [http://localhost:3000](http://localhost:3000) and sign in or create an account.

4. **Sample data**

   `bin/setup` and `bin/rails db:prepare` seed the development database automatically. To reseed by hand:

   ```bash
   bin/rails db:seed
   ```

   This creates four users — `alice`, `bob`, `carol`, `dan` — with posts, comments, likes, accepted follows, and one pending follow request (`dan -> alice`). **All seeded accounts use the password `password123`.**

   Useful state to try:

   - Sign in as `alice` to see a populated feed, a `1` pending-request badge, and a `Accept` button for Carol.
   - Sign in as `bob` to see the feed from the other side of that relationship.
   - `/discover` shows every other user's posts, so it contains a post `alice` never sees in her feed.

5. **Preview emails in development**

   Letter Opener opens welcome emails in your browser automatically, so registering a new account pops open the email without sending anything. No SMTP credentials are needed locally.

### Troubleshooting setup

`bin/setup` checks that PostgreSQL is reachable before touching the database, and stops with a short message if it is not. If you hit something it does not cover:

**`cannot drop the currently open database`** — `DATABASE_URL` is set and points at a maintenance database. Unset it, or point it at a real database name. See step 2.

**`template database "template1" has a collation version mismatch`** — the PostgreSQL cluster was created against an older glibc than the one now installed, so creating databases fails. Fix the recorded version, then retry:

```bash
psql -U postgres -d postgres -c "ALTER DATABASE template1 REFRESH COLLATION VERSION;"
psql -U postgres -d postgres -c "ALTER DATABASE postgres REFRESH COLLATION VERSION;"
```

If those databases contain data, run `REINDEX DATABASE <name>` afterwards as the PostgreSQL documentation recommends.

**`role "postgres" does not exist`** — the role named in step 2 does not exist on your server. Docker containers created with a different `POSTGRES_USER` will not have it; either create it or export `PGUSER`/`PGPASSWORD` to match what you have.

## Verifying the build

The fastest full check runs RuboCop, the gem and importmap audits, Brakeman, and the test suite:

```bash
bin/ci
```

Expected tail:

```
✅ Tests: Rails passed
✅ Continuous Integration passed
```

`bin/ci` is what GitHub Actions runs, so a green `bin/ci` locally matches a green pipeline.

## Project notes

- Follow requests default to `pending` and must be accepted (`status: accepted`) before they count as a mutual follow.
- A pending incoming request is always resolved *before* the "Following" state is checked, so a mutual follow is still answerable (regression covered by a test).
- Likes are unique per `(user, post)` and use counter caching (`posts.likes_count`).
- Comments are ordered chronologically on posts.
- Likes and comments `redirect_back` (falling back to `/posts`), so acting on a post keeps you on whichever feed you were reading.
- The feed uses `Post.from_feed_of(user)` which scopes to `[user.id, *user.following_ids]`.
- `/discover` uses `Post.from_discover_for(user)`, which excludes the current user's own posts.
- `UsersController#index` preloads pending requests by id so the people list stays at a constant number of queries.
- `db/seeds.rb` only runs in the development environment, so the `db:seed:replant` step in `bin/ci` is a no-op that verifies the seeds load without error rather than asserting seeded data.
- Welcome emails are enqueued via `deliver_later` using Active Job's test adapter in the test environment.
- Active Storage is configured for profile pictures; Gravatar is used as a clean fallback.
- Profile websites are validated as absolute `http(s)` URLs, since they are rendered as link `href`s.

## Testing

| Command | Covers |
| --- | --- |
| `bin/ci` | Everything below, in order. Start here. |
| `bin/rails test` | 117 model, mailer, and integration tests |
| `bin/rails test:system` | 12 browser-driven Capybara tests |
| `bin/rubocop` | Style (currently clean, 62 files) |
| `bin/brakeman --no-pager` | Static security analysis |

Integration tests cover authentication, posts, likes, comments, follows, profiles, the discovery feed, and page rendering. System tests drive real headless Chrome through sign up, sign in/out, posting, feed contents, For You, like/unlike, commenting, follow request accept/decline, and profile editing.

System tests need a browser. Set `CHROME_BINARY` if the browser installed on your machine does not match the `chromedriver` on your `PATH`:

```bash
CHROME_BINARY=/usr/bin/chromium bin/rails test:system
```

## Deployment

This app is configured for PostgreSQL and follows standard Rails 8 deployment practices (see `config/database.yml` and `config/environments/production.rb`).

- Database: set `PGHOST`, `PGPORT`, `PGUSER`, `PGPASSWORD` (or supply `DATABASE_URL`).
- Mailer: configure a real SMTP provider via the standard `SMTP_ADDRESS` / `SMTP_PORT` / `SMTP_USER_NAME` / `SMTP_PASSWORD` variables, and set `config.action_mailer.raise_delivery_errors = true`.
- Active Storage: for production, switch to a cloud service (e.g. `:amazon` in `config/storage.yml`) and provide its credentials.
- Assets: run `bin/rails assets:precompile` as part of the release step.

## Security

`bin/brakeman --no-pager` reports **0 errors and 0 unignored warnings**, and exits 0 so CI fails on any new finding.

One warning is acknowledged in `config/brakeman.ignore` (a JSON file of fingerprint-scoped entries, each with a written justification). It is the profile website link: the value is constrained to absolute `http(s)` URLs by the `User` model validation, the view re-checks the scheme, and the `href` is passed through `sanitize` — but Brakeman does not follow model validations, so it cannot see any of that. Because entries are fingerprint-scoped, any *different* finding still fails the build.

To keep the ignore file honest:

```bash
bin/brakeman --no-pager --ensure-ignore-notes --ensure-no-obsolete-ignore-entries
```
