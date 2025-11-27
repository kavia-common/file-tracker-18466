# Startup notes

Primary start commands:
- Procfile web: bash ./start.sh
- Direct: bash ./start.sh
- Node fallback: npm start (delegates to bash ./start.sh via package.json)

Notes:
- Only a single process type is defined in Procfile to avoid conflicts with some platforms. 
- The start script will try to run a Node/Python backend if present, otherwise it launches a static help server on PORT (default 8000).
- .npmrc disables interactive prompts and lockfile generation for CI/preview environments.
