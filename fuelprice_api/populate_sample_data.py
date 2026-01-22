from database import SessionLocal, init_db
from models import City, FuelPrice
from datetime import datetime, timedelta

def populate_sample_data():
    """Populate database with sample fuel price data for testing"""
    db = SessionLocal()
    
    try:
        # Initialize database
        init_db()
        
        # Get all cities
        cities = db.query(City).all()
        
        print(f"Found {len(cities)} cities")
        
        # Sample fuel prices (₹/liter)
        base_prices = {
            "Mumbai": {"petrol": 106.31, "diesel": 94.27},
            "Delhi": {"petrol": 96.72, "diesel": 89.62},
            "Bangalore": {"petrol": 101.94, "diesel": 87.89},
            "Hyderabad": {"petrol": 109.68, "diesel": 98.06},
            "Ahmedabad": {"petrol": 96.46, "diesel": 92.43},
            "Chennai": {"petrol": 102.63, "diesel": 94.24},
            "Kolkata": {"petrol": 106.03, "diesel": 92.76},
            "Surat": {"petrol": 96.46, "diesel": 92.43},
            "Pune": {"petrol": 106.31, "diesel": 94.27},
            "Jaipur": {"petrol": 108.48, "diesel": 93.72},
            "Lucknow": {"petrol": 96.55, "diesel": 89.75},
            "Kanpur": {"petrol": 96.55, "diesel": 89.75},
            "Nagpur": {"petrol": 106.31, "diesel": 94.27},
            "Indore": {"petrol": 108.71, "diesel": 93.24},
            "Thane": {"petrol": 106.31, "diesel": 94.27},
            "Bhopal": {"petrol": 108.71, "diesel": 93.24},
            "Visakhapatnam": {"petrol": 107.49, "diesel": 95.67},
            "Patna": {"petrol": 107.66, "diesel": 94.52},
            "Vadodara": {"petrol": 96.46, "diesel": 92.43},
            "Ghaziabad": {"petrol": 96.55, "diesel": 89.75},
            "Ludhiana": {"petrol": 97.88, "diesel": 87.66},
            "Agra": {"petrol": 96.55, "diesel": 89.75},
            "Nashik": {"petrol": 106.31, "diesel": 94.27},
            "Faridabad": {"petrol": 96.55, "diesel": 89.75},
            "Meerut": {"petrol": 96.55, "diesel": 89.75},
        }
        
        # Add fuel prices for each city
        added_count = 0
        for city in cities:
            if city.name in base_prices:
                # Add petrol price
                petrol_price = FuelPrice(
                    city_id=city.id,
                    fuel_type="petrol",
                    price=base_prices[city.name]["petrol"],
                    change=0.0,
                    date=datetime.utcnow(),
                    source="sample_data"
                )
                db.add(petrol_price)
                added_count += 1
                
                # Add diesel price
                diesel_price = FuelPrice(
                    city_id=city.id,
                    fuel_type="diesel",
                    price=base_prices[city.name]["diesel"],
                    change=0.0,
                    date=datetime.utcnow(),
                    source="sample_data"
                )
                db.add(diesel_price)
                added_count += 1
                
                print(f"Added prices for {city.name}")
        
        # Add some historical data (last 5 days)
        for city in cities:
            if city.name in base_prices:
                for days_ago in range(1, 6):
                    past_date = datetime.utcnow() - timedelta(days=days_ago)
                    
                    # Add slight variation to prices
                    petrol_price = FuelPrice(
                        city_id=city.id,
                        fuel_type="petrol",
                        price=base_prices[city.name]["petrol"] + (days_ago * 0.15),
                        change=0.15,
                        date=past_date,
                        source="sample_data"
                    )
                    db.add(petrol_price)
                    
                    diesel_price = FuelPrice(
                        city_id=city.id,
                        fuel_type="diesel",
                        price=base_prices[city.name]["diesel"] + (days_ago * 0.12),
                        change=0.12,
                        date=past_date,
                        source="sample_data"
                    )
                    db.add(diesel_price)
        
        db.commit()
        print(f"✅ Successfully populated {added_count} fuel price records")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        db.rollback()
    finally:
        db.close()

if __name__ == "__main__":
    populate_sample_data()
