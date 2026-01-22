from fastapi import APIRouter, HTTPException, Depends
from app.scheduler.services.fuel_scraper import FuelPriceScraper
from app.scheduler.config import scheduler
import logging

router = APIRouter(
    prefix="/tasks",
    tags=["tasks"]
)

logger = logging.getLogger(__name__)

@router.post("/scrape-fuel-prices")
async def manual_scrape_fuel_prices():
    """
    Manually trigger fuel price scraping
    """
    try:
        scraper = FuelPriceScraper()
        success = scraper.scrape_all_fuel_types()

        if success:
            return {"message": "Fuel price scraping completed successfully"}
        else:
            return {"message": "Fuel price scraping completed with some failures"}

    except Exception as e:
        logger.error(f"Error in manual scraping: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.get("/scheduler-status")
async def get_scheduler_status():
    """
    Get scheduler status
    """
    return {
        "running": scheduler.scheduler.running,
        "jobs": [job.id for job in scheduler.scheduler.get_jobs()]
    }
