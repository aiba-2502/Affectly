# Suggested Development Commands

## Quick Start
```bash
make init           # Initialize project (build + start + DB setup)
make quick-start    # Complete setup with env files and JWT key
```

## Daily Development
```bash
make up             # Start all services
make down           # Stop all services
make restart        # Restart all services
make logs           # View logs (follow mode)
make ps             # Check container status
```

## Frontend Development
```bash
cd frontend
npm run dev         # Start development server (Turbopack)
npm run build       # Build for production
npm run lint        # Run ESLint
npm run type-check  # TypeScript type checking
npm run format      # Format code with Prettier
npm run test        # Run tests
```

## Backend Development
```bash
make rails-console  # Open Rails console
make rails-routes   # Show all routes
make db-migrate     # Run database migrations
make db-seed        # Seed database
make bundle-install # Install Ruby gems
```

## Testing
```bash
make test           # Run all tests
make test-backend   # Rails tests only
make test-frontend  # Frontend tests only
make lint           # Run linters for both
make format         # Format code for both
```

## Database
```bash
make db-init        # Create and migrate database
make db-reset       # Reset database (WARNING: destroys data)
make db-console     # PostgreSQL console access
```

## Shell Access
```bash
make shell          # Access backend container
make shell-frontend # Access frontend container
make shell-db       # Access PostgreSQL container
```

## Production (t3.micro optimized)
```bash
make prod-up        # Start with memory optimization
make prod-down      # Stop production services
make prod-logs      # View production logs
make prod-init      # Initial production setup
```