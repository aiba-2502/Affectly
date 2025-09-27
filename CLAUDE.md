# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
**心のログ (Kokoro Log)** - A web app for emotional journaling through AI VTuber chat conversations, helping users with self-understanding and life decisions.

## Tech Stack
- **Frontend**: Next.js 15.5, React 19, TypeScript, TailwindCSS v4, Zustand
- **Backend**: Rails 8.0.2 API, Ruby, PostgreSQL, JWT auth
- **AI Services**: OpenAI GPT-4o, Anthropic, Gemini
- **Infrastructure**: Docker, Docker Compose

## Essential Commands

### Development Workflow
```bash
# Quick start
make init          # Build + start + DB setup
make up            # Start all services
make logs          # View logs

# Frontend
cd frontend && npm run dev          # Start dev server
cd frontend && npm run type-check   # TypeScript check
cd frontend && npm run lint          # ESLint
cd frontend && npm run format        # Prettier

# Backend
make rails-console   # Rails console
make db-migrate      # Run migrations
bundle exec rubocop  # Ruby linting

# Testing
make test           # Run all tests
make lint           # Lint both frontend/backend
make format         # Format all code
```

### Task Completion Checklist
When completing tasks, always run:
1. **Frontend**: `npm run type-check` and `npm run lint` in frontend/
2. **Backend**: `bundle exec rubocop` in backend/
3. **Both**: `make test` to ensure tests pass

## Project Structure
```
├── frontend/          # Next.js app
│   ├── src/app/      # App router pages
│   ├── src/components/
│   ├── src/stores/   # Zustand state
│   └── src/services/ # API calls
├── backend/          # Rails API
│   ├── app/controllers/
│   ├── app/models/
│   └── app/services/
└── docker-compose.yml
```

## Code Conventions
- **TypeScript**: Double quotes, semicolons, 2-space indent
- **Ruby**: Rails Omakase style (rubocop-rails-omakase)
- **Git**: Never commit secrets or .env files
- Follow existing patterns in the codebase

## Development URLs
- Frontend: http://localhost:3001
- Backend API: http://localhost:3000