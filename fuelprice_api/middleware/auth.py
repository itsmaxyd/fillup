from fastapi import Request
from starlette.middleware.base import BaseHTTPMiddleware

class APIKeyAuth(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        # No authentication required - just pass through all requests
        return await call_next(request)
