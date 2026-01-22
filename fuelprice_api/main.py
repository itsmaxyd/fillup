from fastapi import FastAPI, Depends, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from database import init_db, get_db
from routes.cities import router as cities_router
from routes.fuel_prices import router as fuel_prices_router
from app.scheduler.tasks import router as tasks_router
from middleware.auth import APIKeyAuth
import logging
import os

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize FastAPI app
app = FastAPI(
    title="Fuel Price API",
    description="API for retrieving live and historical fuel prices for 25 major Indian cities",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Add CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Add API key authentication middleware
app.add_middleware(APIKeyAuth)

# Include routers
app.include_router(cities_router)
app.include_router(fuel_prices_router)
app.include_router(tasks_router)

@app.on_event("startup")
async def startup_event():
    """Initialize database and start scheduler on startup"""
    logger.info("Starting Fuel Price API...")

    # Initialize database
    init_db()

    # Start scheduler
    from app.scheduler.config import scheduler
    scheduler.start_scheduler()

    logger.info("Fuel Price API started successfully")

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    logger.info("Shutting down Fuel Price API...")

    # Shutdown scheduler
    from app.scheduler.config import scheduler
    scheduler.shutdown_scheduler()

    logger.info("Fuel Price API shutdown complete")

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "Fuel Price API",
        "version": "1.0.0",
        "description": "API for retrieving live and historical fuel prices for 25 major Indian cities",
        "endpoints": {
            "/cities": "Get list of cities",
            "/states": "Get list of states",
            "/live_fuel_price": "Get live fuel prices",
            "/historical_fuel_price": "Get historical fuel prices",
            "/tasks/scrape-fuel-prices": "Manually trigger scraping",
            "/tasks/scheduler-status": "Get scheduler status"
        }
    }
