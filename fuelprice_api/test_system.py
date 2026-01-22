#!/usr/bin/env python3
"""
Test script to verify the fuel price API system functionality
"""

import os
import sys
from datetime import datetime
import logging

# Add current directory to path for imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def test_database_connection():
    """Test database connection and initialization"""
    try:
        from database import init_db, SessionLocal, get_cities_list
        from models import City, FuelPrice

        logger.info("Testing database connection...")

        # Initialize database
        init_db()

        # Test session
        db = SessionLocal()

        # Test cities list
        cities = get_cities_list()
        logger.info(f"Found {len(cities)} cities in configuration")

        # Check if cities exist in database
        existing_cities = db.query(City).count()
        logger.info(f"Found {existing_cities} cities in database")

        db.close()
        logger.info("✓ Database connection test passed")
        return True

    except Exception as e:
        logger.error(f"✗ Database connection test failed: {e}")
        return False

def test_scraper_initialization():
    """Test scraper initialization"""
    try:
        from app.scheduler.services.fuel_scraper import FuelPriceScraper

        logger.info("Testing scraper initialization...")

        # Check if API key is set
        api_key = os.getenv("API_KEY")
        if not api_key:
            logger.warning("API_KEY not set in environment variables")
            return False

        scraper = FuelPriceScraper()
        logger.info(f"Scraper initialized with API URL: {scraper.api_url}")
        logger.info(f"Scraper configured for {len(scraper.cities)} cities")

        logger.info("✓ Scraper initialization test passed")
        return True

    except Exception as e:
        logger.error(f"✗ Scraper initialization test failed: {e}")
        return False

def test_scheduler_configuration():
    """Test scheduler configuration"""
    try:
        from app.scheduler.config import scheduler

        logger.info("Testing scheduler configuration...")

        # Check scheduler jobs
        jobs = scheduler.scheduler.get_jobs()
        logger.info(f"Found {len(jobs)} scheduled jobs")

        for job in jobs:
            logger.info(f"Job: {job.name} - Trigger: {job.trigger}")

        logger.info("✓ Scheduler configuration test passed")
        return True

    except Exception as e:
        logger.error(f"✗ Scheduler configuration test failed: {e}")
        return False

def test_api_routes():
    """Test API route imports"""
    try:
        from main import app
        from routes.cities import router as cities_router
        from routes.fuel_prices import router as fuel_prices_router
        from app.scheduler.tasks import router as tasks_router

        logger.info("Testing API routes...")

        # Check if routes are included
        routes = [route.path for route in app.routes]
        logger.info(f"Found {len(routes)} routes in main app")

        logger.info("✓ API routes test passed")
        return True

    except Exception as e:
        logger.error(f"✗ API routes test failed: {e}")
        return False

def main():
    """Run all tests"""
    logger.info("Starting Fuel Price API system tests...")
    logger.info(f"Current time: {datetime.now()}")

    tests = [
        ("Database Connection", test_database_connection),
        ("Scraper Initialization", test_scraper_initialization),
        ("Scheduler Configuration", test_scheduler_configuration),
        ("API Routes", test_api_routes)
    ]

    results = []
    for test_name, test_func in tests:
        logger.info(f"\n--- Running {test_name} Test ---")
        result = test_func()
        results.append((test_name, result))

    # Summary
    logger.info("\n=== Test Results ===")
    passed = sum(1 for _, result in results if result)
    total = len(results)

    for test_name, result in results:
        status = "PASSED" if result else "FAILED"
        logger.info(f"{test_name}: {status}")

    logger.info(f"\nOverall: {passed}/{total} tests passed")

    if passed == total:
        logger.info("🎉 All tests passed! System is ready for deployment.")
        return 0
    else:
        logger.error("❌ Some tests failed. Please check the error messages.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
