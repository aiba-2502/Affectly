# Project Overview: 心のログ (Kokoro Log)

## Project Purpose
A web application that helps users verbalize, record, and organize their emotions and thoughts through chat conversations with an AI VTuber. The app focuses on self-understanding, clarifying values, and supporting life/career decisions.

## Tech Stack
### Frontend
- **Framework**: Next.js 15.5.0 with React 19.1.0
- **Language**: TypeScript 5.9.2
- **Styling**: TailwindCSS v4
- **State Management**: Zustand 5.0.8
- **Testing**: Jest with ts-jest
- **Linting**: ESLint with Next.js config
- **Formatting**: Prettier

### Backend
- **Framework**: Rails 8.0.2 (API mode)
- **Language**: Ruby (version from .ruby-version file)
- **Database**: PostgreSQL 16 (primary), MongoDB 9.0 (future use)
- **Authentication**: JWT with bcrypt
- **AI Services**: OpenAI (GPT-4o), Anthropic, Gemini
- **Testing**: Rails built-in test framework
- **Linting**: RuboCop with Rails Omakase styling

### Infrastructure
- **Containerization**: Docker & Docker Compose
- **Development**: Local Docker environment
- **Production**: Docker Compose with optimizations for t3.micro

## Project Structure
- `/frontend` - Next.js application
  - `/src/app` - App router pages
  - `/src/components` - React components
  - `/src/stores` - Zustand stores
  - `/src/services` - API services
  - `/src/types` - TypeScript types
  - `/src/utils` - Utility functions
- `/backend` - Rails API
  - `/app/controllers` - API controllers
  - `/app/models` - Data models
  - `/app/services` - Business logic services
- `/docs` - Documentation
- `/scripts` - Utility scripts
- `Makefile` - Development automation
- `docker-compose.yml` - Local development setup
- `docker-compose.prod.yml` - Production setup