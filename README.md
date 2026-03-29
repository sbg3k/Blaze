# Blaze

A fintech mobile application for collaborative savings groups (Ajo/Esusu). Built for the Enyata x Interswitch Buildathon.

## To the Judges
Please login using these details
- Email: "prize-daily-storm@duck.com"
- Password: "string234"

## Tech Stack

| Layer | Technology |
|-------|------------|
| Backend | Python 3.12, FastAPI, SQLAlchemy 2.0, PostgreSQL |
| Frontend | Flutter (Dart 3.11+), Material Design 3 |
| Auth | JWT + Rotating Refresh Tokens, OTP Email Verification |
| Integrations | Interswitch (BVN Verification, Virtual Accounts), SMTP |

## Team Contributions

- Adeyemi Sanusi (@Codehearl): Developer, Designer
- Bakare Abdullahi (@plainsight16): Developer, Designer, Product Manager
- Phillip Owoeye (@sbg3k): Developer
- Adeniji Ifeoluwatobi (@TobiAdeniji94): Developer

## Live Docs

- Swagger UI: https://blaze-tpja.onrender.com/docs

## Project Structure

```
Blaze/
├── backend/
│   ├── app/
│   │   ├── models/         # SQLAlchemy ORM models
│   │   ├── routes/         # FastAPI endpoints
│   │   ├── schemas/        # Pydantic request/response schemas
│   │   ├── services/       # Business logic layer
│   │   ├── utils/          # Security helpers, dependencies
│   │   ├── main.py         # FastAPI app entry point
│   │   ├── config.py       # Environment configuration
│   │   └── database.py     # Database connection
│   ├── tests/              # Unit tests
│   ├── Makefile            # Build commands
│   ├── requirements.txt    # Python dependencies
│   ├── schema.sql          # Database DDL
│   └── seed.sql            # Sample data
│
├── frontend/ajo_mobile/
│   ├── lib/
│   │   ├── core/           # Theme, widgets, API client
│   │   ├── features/       # Feature modules (auth, home, pools, profile)
│   │   └── main.dart       # App entry point
│   └── pubspec.yaml        # Flutter dependencies
│
└── requests.http           # API test collection
```

## Getting Started

### Prerequisites

- Python 3.12
- Flutter SDK ^3.11.0
- PostgreSQL database (or Supabase)

### Backend Setup

```bash
cd backend

# Create .env from template
cp .env.example .env
# Edit .env with your configuration

# Install dependencies
make setup

# Run development server (http://127.0.0.1:8000)
make dev

# Run production server
make run
```

### Frontend Setup

```bash
cd frontend/ajo_mobile

# Get dependencies
flutter pub get

# Run app
flutter run

# Analyze code
flutter analyze
```

## Environment Variables

Create `backend/.env` with the following:

```env
# Database (PostgreSQL)
DATABASE_URL=postgresql://user:password@host:5432/blaze

# Security
SECRET_KEY=your-secret-key-here
BVN_SALT=your-bvn-salt-here

# Email (SMTP)
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_USER=your-email
SMTP_PASS=your-password

# Interswitch BVN Verification
ISW_CLIENT_ID=
ISW_CLIENT_SECRET=
ISW_TOKEN_URL=https://passport-v2.k8.isw.la/passport/oauth/token
ISW_BVN_VERIFY_URL=https://api-marketplace-routing.k8.isw.la/...
ISW_MERCHANT_CODE=
ISW_TIMEOUT_SECONDS=15

# Interswitch Virtual Accounts
ISW_QA_URL=
ISW_QA_CLIENT_ID=
ISW_QA_CLIENT_SECRET=
ISW_VIRTUAL_ACCOUNT_URL=

# CORS
ALLOWED_ORIGINS=http://localhost:3000

# Token Configuration (optional, has defaults)
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30
OTP_EXPIRY_MINUTES=5
OTP_RATE_LIMIT_SECONDS=60
```

## API Endpoints

| Route | Description |
|-------|-------------|
| `/auth` | Registration, login, OTP verification, password reset, token refresh |
| `/kyc` | BVN verification, bank statement generation |
| `/wallet` | Virtual wallet provisioning and retrieval |
| `/groups` | Group CRUD, membership, join requests, invites |
| `/cycles` | Savings cycle management |
| `/user` | User profile operations |
| `/health` | Health check |
| `/docs` | Swagger UI documentation |

## Database

Initialize the database using the provided SQL files:

```bash
# Create schema (drops existing tables)
psql -d your_database -f backend/schema.sql

# Load sample data (optional)
psql -d your_database -f backend/seed.sql
```

**Key Models:**
- `User` - Accounts with email verification
- `Group` - Savings groups (public/private)
- `UserGroup` - Membership with roles (member/admin)
- `KYC` - BVN verification records
- `Wallet` - Virtual accounts (Interswitch)
- `Cycle` - Savings periods with payout slots

## Testing

### Backend Tests
```bash
cd backend
python -m pytest tests/
```

### Frontend Tests
```bash
cd frontend/ajo_mobile
flutter test
```

### API Testing
Use `requests.http` at the repository root for manual API testing. It contains the full test flow:

1. Health check
2. Sign up → Verify OTP → Login
3. KYC/BVN verification
4. Wallet provisioning
5. Bank statement generation

## Contributing

### Pull Request Requirements

1. **Screen recording required** - All PRs must include a screen recording demonstrating the changes
2. **Test coverage** - Add tests for new functionality
3. **Code style**:
   - Python: 4-space indentation
   - Dart: 2-space indentation
4. Run `flutter analyze` before submitting frontend changes

See `.github/pull_request_template.md` for the full checklist.

## Architecture Patterns

### Backend
- Dependency injection via FastAPI `Depends()`
- Service layer for business logic, routes for HTTP concerns
- Background tasks for email sending (APScheduler)
- JWT access tokens + rotating refresh tokens
- OTP rate limiting and expiry

### Frontend
- Feature-based folder structure
- Centralized theming with `ValueListenableBuilder` for dark/light mode
- Material Design 3 components
- Reusable widgets in `core/widgets/`
