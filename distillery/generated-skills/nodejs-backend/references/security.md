# Authentication & Security

## Authentication

- **Access token**: JWT, 15min expiry, payload: `{ userId, email }`
- **Refresh token**: JWT, 7d expiry, stored in DB (revocable)
- **Passwords**: bcrypt (10+ rounds) or argon2
- **Middleware**: extract `Bearer` token → `jwt.verify` → attach `req.user` → `next()`
- **Authorization**: after auth, check role or resource ownership per request
- Always return generic "Invalid credentials" — never reveal if user exists

## Security Checklist

- [ ] All inputs validated (Zod/TypeBox at route boundary)
- [ ] Parameterized queries only (no string concatenation)
- [ ] Passwords hashed (bcrypt/argon2, never plaintext)
- [ ] JWT: verify signature + expiry, short-lived access tokens
- [ ] Rate limiting (express-rate-limit + Redis store, stricter on auth endpoints)
- [ ] Security headers (Helmet)
- [ ] HTTPS everywhere in production
- [ ] CORS restricted to specific origins
- [ ] Secrets from env vars only, validated at startup
- [ ] `npm audit` regularly
- [ ] No stack traces in production error responses
- [ ] Authorization per request, not just authentication

OWASP API Top 10: Broken Object-Level Auth | Broken Auth | Broken Property-Level Auth | Unrestricted Resource Consumption | Broken Function-Level Auth | Sensitive Business Flow | SSRF | Security Misconfiguration | Improper Inventory | Unsafe API Consumption
