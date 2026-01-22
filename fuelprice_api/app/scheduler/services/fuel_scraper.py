import requests
import os
import time
from typing import Dict, List, Optional
from tenacity import retry, stop_after_attempt, wait_exponential
from datetime import datetime
from database import SessionLocal, get_cities_list
from models import City, FuelPrice
from schemas import FuelPriceCreate
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class FuelPriceScraper:
    def __init__(self):
        self.api_url = "https://fuel.indianapi.in/live_fuel_price"
        self.api_key = os.getenv("API_KEY")
        self.headers = {
            "X-Api-Key": self.api_key
        }
        self.cities = get_cities_list()

    @retry(
        stop=stop_after_attempt(3),
        wait=wait_exponential(multiplier=1, min=4, max=10)
    )
    def fetch_fuel_prices(self, fuel_type: str = "petrol") -> Optional[Dict]:
        """Fetch fuel prices from external API with automatic retry"""
        try:
            params = {
                "fuel_type": fuel_type,
                "location_type": "city"
            }

            logger.info(f"Fetching {fuel_type} prices from {self.api_url}")
            response = requests.get(
                self.api_url,
                headers=self.headers,
                params=params,
                timeout=30
            )
            response.raise_for_status()
            return response.json()
        except requests.exceptions.RequestException as e:
            logger.error(f"Attempt failed: {e}")
            raise

    def get_city_state_mapping(self) -> Dict[str, str]:
        """Get city to state mapping for Indian cities"""
        return {
            "Mumbai": "Maharashtra", "Delhi": "Delhi", "Bangalore": "Karnataka",
            "Hyderabad": "Telangana", "Ahmedabad": "Gujarat", "Chennai": "Tamil Nadu",
            "Kolkata": "West Bengal", "Surat": "Gujarat", "Pune": "Maharashtra",
            "Jaipur": "Rajasthan", "Lucknow": "Uttar Pradesh", "Kanpur": "Uttar Pradesh",
            "Nagpur": "Maharashtra", "Indore": "Madhya Pradesh", "Thane": "Maharashtra",
            "Bhopal": "Madhya Pradesh", "Visakhapatnam": "Andhra Pradesh",
            "Patna": "Bihar", "Vadodara": "Gujarat", "Ghaziabad": "Uttar Pradesh",
            "Ludhiana": "Punjab", "Agra": "Uttar Pradesh", "Nashik": "Maharashtra",
            "Faridabad": "Haryana", "Meerut": "Uttar Pradesh"
        }

    def ensure_cities_exist(self, db):
        """Ensure all 25 cities exist in database"""
        city_state_map = self.get_city_state_mapping()

        for city_name, state in city_state_map.items():
            existing_city = db.query(City).filter(City.name == city_name).first()
            if not existing_city:
                new_city = City(name=city_name, state=state, is_metro=1)
                db.add(new_city)
                logger.info(f"Added new city: {city_name}, {state}")

        db.commit()

    def scrape_and_store_prices(self, fuel_type: str = "petrol"):
        """Scrape fuel prices and store in database"""
        db = SessionLocal()

        try:
            # Ensure cities exist
            self.ensure_cities_exist(db)

            # Fetch prices from API
            price_data = self.fetch_fuel_prices(fuel_type)

            if not price_data or "data" not in price_data:
                logger.error("No price data received from API")
                return False

            # Process and store prices
            processed_count = 0
            for item in price_data["data"]:
                city_name = item.get("city")
                if city_name not in self.cities:
                    continue

                # Get city from database
                city = db.query(City).filter(City.name == city_name).first()
                if not city:
                    continue

                # Calculate price change from previous record
                previous_price = db.query(FuelPrice).filter(
                    FuelPrice.city_id == city.id,
                    FuelPrice.fuel_type == fuel_type
                ).order_by(FuelPrice.date.desc()).first()

                current_price = float(item.get("price", 0))
                price_change = 0.0

                if previous_price:
                    price_change = current_price - previous_price.price

                # Create new fuel price record
                fuel_price_data = FuelPriceCreate(
                    city_id=city.id,
                    fuel_type=fuel_type,
                    price=current_price,
                    change=price_change,
                    date=datetime.utcnow()
                )

                db_fuel_price = FuelPrice(**fuel_price_data.dict())
                db.add(db_fuel_price)
                processed_count += 1

            db.commit()
            logger.info(f"Successfully stored {processed_count} {fuel_type} prices")
            return True

        except Exception as e:
            logger.error(f"Error in scrape_and_store_prices: {e}")
            db.rollback()
            return False
        finally:
            db.close()

    def scrape_all_fuel_types(self):
        """Scrape both petrol and diesel prices with rate limiting"""
        success = True

        # Scrape petrol prices
        logger.info("Scraping petrol prices...")
        petrol_success = self.scrape_and_store_prices("petrol")
        if not petrol_success:
            logger.warning("Failed to scrape petrol prices")
        
        # Rate limiting: wait 1 second after petrol API call
        logger.info("Waiting 1 second for rate limiting...")
        time.sleep(1.0)

        # Scrape diesel prices
        logger.info("Scraping diesel prices...")
        diesel_success = self.scrape_and_store_prices("diesel")
        if not diesel_success:
            logger.warning("Failed to scrape diesel prices")

        return petrol_success and diesel_success
