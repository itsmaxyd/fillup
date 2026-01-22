import os
from datetime import datetime, timedelta
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.cron import CronTrigger
from app.scheduler.services.fuel_scraper import FuelPriceScraper
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class SchedulerConfig:
    def __init__(self):
        self.scheduler = BackgroundScheduler()
        self.scraper = FuelPriceScraper()
        self.setup_scheduler()

    def setup_scheduler(self):
        """Configure scheduler to run twice monthly at 3 AM IST"""
        # Convert to UTC (IST is UTC+5:30, so 3 AM IST = 9:30 PM UTC previous day)
        trigger = CronTrigger(
            day='2,16',  # 2nd and 16th of each month
            hour='21',    # 9:30 PM UTC = 3 AM IST
            minute='30',
            timezone='UTC'
        )

        # Add job to scheduler
        self.scheduler.add_job(
            self.scrape_fuel_prices_job,
            trigger=trigger,
            id='fuel_price_scraper',
            name='Scrape fuel prices from Indian API',
            replace_existing=True
        )

        logger.info("Scheduler configured to run on 2nd and 16th at 3 AM IST")

    def scrape_fuel_prices_job(self):
        """Job function to scrape fuel prices"""
        logger.info("Starting scheduled fuel price scraping...")
        try:
            success = self.scraper.scrape_all_fuel_types()
            if success:
                logger.info("Fuel price scraping completed successfully")
            else:
                logger.warning("Fuel price scraping completed with some failures")
        except Exception as e:
            logger.error(f"Error in scheduled scraping job: {e}")

    def start_scheduler(self):
        """Start the scheduler"""
        if not self.scheduler.running:
            self.scheduler.start()
            logger.info("Scheduler started")

    def shutdown_scheduler(self):
        """Shutdown the scheduler"""
        if self.scheduler.running:
            self.scheduler.shutdown()
            logger.info("Scheduler shutdown")

# Global scheduler instance
scheduler = SchedulerConfig()
