# Task Completion Checklist

## When Completing a Frontend Task
1. **Type Check**: Run `npm run type-check` in frontend directory
2. **Lint**: Run `npm run lint` in frontend directory
3. **Format**: Run `npm run format` to ensure consistent formatting
4. **Test**: Run `npm run test` if tests exist for the modified code
5. **Build Check**: Run `npm run build` to ensure production build works

## When Completing a Backend Task
1. **Rubocop**: Run `bundle exec rubocop` or `make lint`
2. **Tests**: Run `bundle exec rails test` or `make test-backend`
3. **Routes Check**: Verify routes with `make rails-routes` if routes changed
4. **Migration Status**: Check `rails db:migrate:status` if DB changes made

## When Completing Any Task
1. **Docker Status**: Check `make ps` to ensure all services running
2. **Logs Review**: Check `make logs` for any errors
3. **Manual Testing**: Test the feature in browser at:
   - Frontend: http://localhost:3001
   - Backend API: http://localhost:3000

## Before Committing (if requested)
1. Run all linters: `make lint`
2. Run all tests: `make test`
3. Format code: `make format`
4. Ensure no secrets in code
5. Write clear commit message describing changes

## Important Notes
- Never commit `.env` files
- Always use environment variables for secrets
- Check that Docker containers are healthy with `make health`
- If errors occur, check logs with `make logs`