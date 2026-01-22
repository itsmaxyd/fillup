from sqlalchemy import Column, Integer, String, Float, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from database import Base

class City(Base):
    __tablename__ = "cities"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), unique=True, index=True)
    state = Column(String(100))
    is_metro = Column(Integer, default=1)  # 1 for metro cities

    fuel_prices = relationship("FuelPrice", back_populates="city")

class FuelPrice(Base):
    __tablename__ = "fuel_prices"

    id = Column(Integer, primary_key=True, index=True)
    city_id = Column(Integer, ForeignKey("cities.id"))
    fuel_type = Column(String(20))  # petrol or diesel
    price = Column(Float)
    change = Column(Float, default=0.0)
    date = Column(DateTime, default=datetime.utcnow)
    source = Column(String(100), default="indianapi.in")

    city = relationship("City", back_populates="fuel_prices")
