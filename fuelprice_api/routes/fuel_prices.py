from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import City, FuelPrice
from schemas import LiveFuelPriceResponse, HistoricalFuelPriceResponse
from typing import List, Optional
from datetime import datetime, timedelta
import logging

router = APIRouter(
    prefix="/live_fuel_price",
    tags=["fuel_prices"]
)

logger = logging.getLogger(__name__)

@router.get("/", response_model=List[LiveFuelPriceResponse])
async def get_live_fuel_prices(
    fuel_type: str = Query(..., description="Type of fuel (diesel or petrol)"),
    location_type: str = Query(..., description="Type of location (state or city)"),
    db: Session = Depends(get_db)
):
    """
    Get live fuel prices
    """
    try:
        # Validate fuel_type
        if fuel_type not in ["diesel", "petrol"]:
            raise HTTPException(status_code=400, detail="Invalid fuel_type. Must be 'diesel' or 'petrol'")

        # Validate location_type
        if location_type not in ["state", "city"]:
            raise HTTPException(status_code=400, detail="Invalid location_type. Must be 'state' or 'city'")

        if location_type == "city":
            # Get latest prices for all cities
            query = db.query(FuelPrice, City).join(City).filter(
                FuelPrice.fuel_type == fuel_type
            ).order_by(FuelPrice.date.desc())

            # Get latest price for each city
            latest_prices = {}
            for fuel_price, city in query.all():
                if city.name not in latest_prices:
                    latest_prices[city.name] = {
                        "city": city.name,
                        "price": str(fuel_price.price),
                        "change": str(fuel_price.change)
                    }

            if not latest_prices:
                raise HTTPException(status_code=404, detail="No live data found")

            return list(latest_prices.values())

        else:  # location_type == "state"
            # Get latest prices grouped by state
            query = db.query(FuelPrice, City).join(City).filter(
                FuelPrice.fuel_type == fuel_type
            ).order_by(FuelPrice.date.desc())

            # Get latest price for each state
            latest_prices = {}
            for fuel_price, city in query.all():
                if city.state not in latest_prices:
                    latest_prices[city.state] = {
                        "city": city.state,
                        "price": str(fuel_price.price),
                        "change": str(fuel_price.change)
                    }

            if not latest_prices:
                raise HTTPException(status_code=404, detail="No live data found")

            return list(latest_prices.values())

    except Exception as e:
        logger.error(f"Error getting live fuel prices: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/historical_fuel_price", response_model=List[HistoricalFuelPriceResponse])
async def get_historical_fuel_prices(
    fuel_type: str = Query("petrol", description="Type of fuel (diesel or petrol)"),
    location_type: str = Query("state", description="Type of location (state or city)"),
    location: str = Query(..., description="Name of city or state"),
    n: int = Query(2, description="Number of historical records to return"),
    db: Session = Depends(get_db)
):
    """
    Get historical fuel prices
    """
    try:
        # Validate fuel_type
        if fuel_type not in ["diesel", "petrol"]:
            raise HTTPException(status_code=400, detail="Invalid fuel_type. Must be 'diesel' or 'petrol'")

        # Validate location_type
        if location_type not in ["state", "city"]:
            raise HTTPException(status_code=400, detail="Invalid location_type. Must be 'state' or 'city'")

        # Validate n
        if n < 1:
            raise HTTPException(status_code=400, detail="n must be at least 1")

        if location_type == "city":
            # Get city by name
            city = db.query(City).filter(City.name == location).first()
            if not city:
                raise HTTPException(status_code=400, detail="Invalid city name")

            # Get historical prices for this city
            prices = db.query(FuelPrice).filter(
                FuelPrice.city_id == city.id,
                FuelPrice.fuel_type == fuel_type
            ).order_by(FuelPrice.date.desc()).limit(n).all()

        else:  # location_type == "state"
            # Get cities in this state
            cities = db.query(City).filter(City.state == location).all()
            if not cities:
                raise HTTPException(status_code=400, detail="Invalid state name")

            # Get historical prices for this state (average of all cities)
            prices = db.query(FuelPrice).join(City).filter(
                City.state == location,
                FuelPrice.fuel_type == fuel_type
            ).order_by(FuelPrice.date.desc()).limit(n).all()

        if not prices:
            raise HTTPException(status_code=404, detail="No data found")

        # Format response
        response = []
        for price in prices:
            response.append({
                "date": price.date.strftime("%Y-%m-%d %H:%M:%S"),
                "name": location,
                "price": float(price.price),
                "change": float(price.change),
                "location_type": location_type
            })

        return response

    except Exception as e:
        logger.error(f"Error getting historical fuel prices: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
