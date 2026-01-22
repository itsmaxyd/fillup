from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import City
from typing import List
import logging

router = APIRouter(
    prefix="/cities",
    tags=["cities"]
)

logger = logging.getLogger(__name__)

@router.get("/", response_model=List[dict])
async def get_cities(db: Session = Depends(get_db)):
    """
    Get list of cities
    """
    try:
        cities = db.query(City).all()

        if not cities:
            raise HTTPException(status_code=404, detail="No cities found")

        # Format response according to OpenAPI spec
        response = [
            {
                "name": city.name,
                "value": city.name
            }
            for city in cities
        ]

        return response

    except Exception as e:
        logger.error(f"Error getting cities: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")

@router.get("/states", response_model=List[dict])
async def get_states(db: Session = Depends(get_db)):
    """
    Get list of states
    """
    try:
        # Get unique states from cities
        states = db.query(City.state).distinct().all()

        if not states:
            raise HTTPException(status_code=404, detail="No states found")

        # Format response according to OpenAPI spec
        response = [
            {
                "name": state[0],
                "value": state[0]
            }
            for state in states
        ]

        return response

    except Exception as e:
        logger.error(f"Error getting states: {e}")
        raise HTTPException(status_code=500, detail="Internal server error")
