# Code Style and Conventions

## Frontend (TypeScript/React)
### Formatting (Prettier)
- Semi-colons: true
- Quotes: double quotes
- Print width: 100
- Tab width: 2 spaces
- Trailing comma: ES5
- Arrow parens: always
- Line endings: LF

### Linting (ESLint)
- Extends: next/core-web-vitals
- TypeScript any: allowed (warning disabled)
- Unused vars: warning (ignore underscore prefix)
- React hooks exhaustive deps: warning

### Conventions
- Components in `/src/components`
- API services in `/src/services`
- Type definitions in `/src/types`
- State management with Zustand stores in `/src/stores`
- Utility functions in `/src/utils`

## Backend (Ruby/Rails)
### Style (RuboCop)
- Uses rubocop-rails-omakase gem
- Rails Omakase styling conventions
- Standard Rails directory structure

### Conventions
- API-only Rails application
- Controllers inherit from ApplicationController
- Services pattern in `/app/services`
- JWT authentication
- RESTful API design

## General
- No comments unless explicitly needed
- Follow existing patterns in codebase
- Security: Never commit secrets or API keys
- Test coverage for new features
- Meaningful commit messages