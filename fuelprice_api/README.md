# Fuel Price API

A complete fuel price API system that scrapes live fuel prices for 709 Indian cities weekly and provides a FastAPI server for accessing the data.

## Features

- **Automated Scraping**: Fetches petrol and diesel prices from Indian API weekly (every 7 days at 3 AM IST)
- **709 Indian Cities**: Comprehensive coverage of all cities returned by the Indian API across all states and union territories
- **Historical Data**: Stores historical price data for trend analysis
- **REST API**: FastAPI server with OpenAPI documentation
- **Dockerized**: Ready for deployment with Docker and docker-compose
- **Authentication**: API key protection for endpoints

## Setup

### Prerequisites

- Docker and docker-compose installed
- Python 3.9+ (for local development)
- API key from [Indian API](https://indianapi.in)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/itsmaxyd/fillup.git
   cd fillup/fuelprice_api
   ```

2. **Create .env file**:
   ```bash
   cp .env.example .env
   ```
   Add your API key to the `.env` file:
   ```
   API_KEY=your_api_key_here
   ```

3. **Build and run with Docker**:
   ```bash
   docker-compose up --build
   ```

   The API will be available at `http://localhost:8000`

### Local Development

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the application:
   ```bash
   uvicorn main:app --reload
   ```

## API Endpoints

### Open Endpoints (No Authentication)

- `GET /` - Root endpoint with API information
- `GET /docs` - Swagger UI documentation
- `GET /redoc` - ReDoc documentation
- `POST /tasks/scrape-fuel-prices` - Manually trigger fuel price scraping
- `GET /tasks/scheduler-status` - Get scheduler status

### Authenticated Endpoints (Require `x-api-key` header)

- `GET /cities` - Get list of all 709 cities
- `GET /cities/states` - Get list of all states and union territories
- `GET /live_fuel_price` - Get live fuel prices
  - Parameters: `fuel_type` (diesel/petrol), `location_type` (state/city)
- `GET /live_fuel_price/historical_fuel_price` - Get historical fuel prices
  - Parameters: `fuel_type`, `location_type`, `location`, `n` (number of records)

## Scheduler

The scheduler runs automatically every 7 days at 3 AM IST to scrape fuel prices from the Indian API and store them in the database.

### Manual Trigger

You can manually trigger the scraping process:
```bash
curl -X POST http://localhost:8000/tasks/scrape-fuel-prices
```

## Database

The system uses SQLite for simplicity. The database file is stored in `fuel_prices.db` and contains:

- `cities` table: List of all 709 Indian cities with their states
- `fuel_prices` table: Historical fuel price data with timestamps

## Deployment

### Docker Deployment

1. Build the Docker image:
   ```bash
   docker build -t fuelprice-api .
   ```

2. Run the container:
   ```bash
   docker run -d -p 8000:8000 --name fuelprice-api fuelprice-api
   ```

### VPS Deployment

1. Copy the `.env` file with your API key
2. Run `docker-compose up -d` to start the service
3. Set up a reverse proxy (Nginx) for HTTPS
4. Configure a process manager (systemd) for auto-restart

## Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `API_KEY` | Indian API key for fuel price data | Yes |

## Testing

You can test the API using curl:

```bash
# Get cities (returns all 709 cities)
curl http://localhost:8000/cities

# Get live petrol prices for cities
curl -H "x-api-key: your_api_key" "http://localhost:8000/live_fuel_price?fuel_type=petrol&location_type=city"

# Get historical diesel prices for Mumbai
curl -H "x-api-key: your_api_key" "http://localhost:8000/live_fuel_price/historical_fuel_price?fuel_type=diesel&location_type=city&location=Mumbai&n=5"
```

## License

This project is licensed under the MIT License.
