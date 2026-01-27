from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime

class CityBase(BaseModel):
    name: str
    state: str

class CityCreate(CityBase):
    pass

class CityResponse(CityBase):
    id: int
    is_metro: int

    class Config:
        orm_mode = True

class FuelPriceBase(BaseModel):
    city_id: int
    fuel_type: str
    price: float
    change: Optional[float] = 0.0
    date: Optional[datetime]

class FuelPriceCreate(FuelPriceBase):
    pass

class FuelPriceResponse(FuelPriceBase):
    id: int
    source: str

    class Config:
        orm_mode = True

class LiveFuelPriceResponse(BaseModel):
    city: str
    price: str
    change: str

class HistoricalFuelPriceResponse(BaseModel):
    date: str
    name: str
    price: float
    change: float
    location_type: str
