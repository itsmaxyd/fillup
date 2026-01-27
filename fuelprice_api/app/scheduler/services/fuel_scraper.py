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
        """Get comprehensive city to state mapping for Indian cities"""
        return {
            # Major cities (original 25)
            "Mumbai": "Maharashtra", "Delhi": "Delhi", "Bangalore": "Karnataka",
            "Hyderabad": "Telangana", "Ahmedabad": "Gujarat", "Chennai": "Tamil Nadu",
            "Kolkata": "West Bengal", "Surat": "Gujarat", "Pune": "Maharashtra",
            "Jaipur": "Rajasthan", "Lucknow": "Uttar Pradesh", "Kanpur": "Uttar Pradesh",
            "Nagpur": "Maharashtra", "Indore": "Madhya Pradesh", "Thane": "Maharashtra",
            "Bhopal": "Madhya Pradesh", "Visakhapatnam": "Andhra Pradesh",
            "Patna": "Bihar", "Vadodara": "Gujarat", "Ghaziabad": "Uttar Pradesh",
            "Ludhiana": "Punjab", "Agra": "Uttar Pradesh", "Nashik": "Maharashtra",
            "Faridabad": "Haryana", "Meerut": "Uttar Pradesh",
            
            # Additional cities from API (expanding to comprehensive coverage)
            "Adilabad": "Telangana", "Agar": "Madhya Pradesh", "Agartala": "Tripura",
            "Aizwal": "Mizoram", "Ajmer": "Rajasthan", "Akola": "Maharashtra",
            "Alappuzha": "Kerala", "Aligarh": "Uttar Pradesh", "Alipurduar": "West Bengal",
            "Alirajpur": "Madhya Pradesh", "Allahabad": "Uttar Pradesh", "Almora": "Uttarakhand",
            "Alwar": "Rajasthan", "Ambala": "Haryana", "Ambedkarnagar": "Uttar Pradesh",
            "Amethi CSM Nagar": "Uttar Pradesh", "Amravati": "Maharashtra", "Amreli": "Gujarat",
            "Amritsar": "Punjab", "Amroha": "Uttar Pradesh", "Anand": "Gujarat",
            "Anantapur": "Andhra Pradesh", "Anantnag": "Jammu and Kashmir", "Angul": "Odisha",
            "Anupur": "Madhya Pradesh", "Araria": "Bihar", "Aravalli": "Gujarat",
            "Ariyalur": "Tamil Nadu", "Arwal": "Bihar", "Ashoknagar": "Madhya Pradesh",
            "Auraiya": "Uttar Pradesh", "Aurangabad": "Maharashtra", "Azamgarh": "Uttar Pradesh",
            "Badgam": "Jammu and Kashmir", "Badwani": "Madhya Pradesh", "Bagalkot": "Karnataka",
            "Bageshwar": "Uttarakhand", "Bagpat": "Uttar Pradesh", "Bahraich": "Uttar Pradesh",
            "Baksa": "Assam", "Balaghat": "Madhya Pradesh", "Baleshwar": "Odisha",
            "Ballia": "Uttar Pradesh", "Balod": "Chhattisgarh", "Balodabazar": "Chhattisgarh",
            "Balrampur": "Uttar Pradesh", "Banas Kantha": "Gujarat", "Banda": "Uttar Pradesh",
            "Bandipora": "Jammu and Kashmir", "Banka": "Bihar", "Bankura": "West Bengal",
            "Banswara": "Rajasthan", "Barabanki": "Uttar Pradesh", "Baramullah": "Jammu and Kashmir",
            "Baran": "Rajasthan", "Bareilly": "Uttar Pradesh", "Bargarh": "Odisha",
            "Barmer": "Rajasthan", "Barnala": "Punjab", "Barpeta": "Assam",
            "Bastar": "Chhattisgarh", "Basti": "Uttar Pradesh", "Bathinda": "Punjab",
            "Beed": "Maharashtra", "Begusarai": "Bihar", "Belgaum": "Karnataka",
            "Bellary": "Karnataka", "Bemetara": "Chhattisgarh", "Betul": "Madhya Pradesh",
            "Bhadradri Kothagudem": "Telangana", "Bhadrak": "Odisha", "Bhagalpur": "Bihar",
            "Bhandara": "Maharashtra", "Bharatpur": "Rajasthan", "Bharuch": "Gujarat",
            "Bhavnagar": "Gujarat", "Bhilwara": "Rajasthan", "Bhind": "Madhya Pradesh",
            "Bhiwani": "Haryana", "Bhojpur": "Bihar", "Botad": "Gujarat",
            "Boudh": "Odisha", "Budaun": "Uttar Pradesh", "Bulandshahr": "Uttar Pradesh",
            "Buldhana": "Maharashtra", "Bundi": "Rajasthan", "Burhanpur": "Madhya Pradesh",
            "Buxar": "Bihar", "Cachar": "Assam", "Central Delhi": "Delhi",
            "Chamba": "Himachal Pradesh", "Chamoli": "Uttarakhand", "Champawat": "Uttarakhand",
            "Champhai": "Mizoram", "Chamrajnagar": "Karnataka", "Chandauli": "Uttar Pradesh",
            "Chandel": "Manipur", "Chandigarh": "Chandigarh", "Chandrapur": "Maharashtra",
            "Changlang": "Arunachal Pradesh", "Charaideo": "Assam", "Charki Dadri": "Haryana",
            "Chatra": "Jharkhand", "Chhatarpur": "Madhya Pradesh", "Chhindware": "Madhya Pradesh",
            "Chhotaudepur": "Gujarat", "Chickmagaluru": "Karnataka", "Chikkaballapura": "Karnataka",
            "Chirang": "Assam", "Chitradurga": "Karnataka", "Chitrakut": "Uttar Pradesh",
            "Chittoor": "Andhra Pradesh", "Chittorgarh": "Rajasthan", "Churachandpur": "Manipur",
            "Churu": "Rajasthan", "Coimbatore": "Tamil Nadu", "Cooch Behar": "West Bengal",
            "Cuddalore": "Tamil Nadu", "Cuddapah": "Andhra Pradesh", "Cuttack": "Odisha",
            "Dahod": "Gujarat", "Dakshin Dinajpur": "West Bengal", "Dakshin Kannad": "Karnataka",
            "Daman": "Daman and Diu", "Damoh": "Madhya Pradesh", "Dantewada": "Chhattisgarh",
            "Darbhanga": "Bihar", "Darjeeling": "West Bengal", "Darrang": "Assam",
            "Datia": "Madhya Pradesh", "Dausa": "Rajasthan", "Davangere": "Karnataka",
            "Dehradun": "Uttarakhand", "Delhi Shahdara": "Delhi", "Deoghar": "Jharkhand",
            "Deoria": "Uttar Pradesh", "Devbhumi Dwarka": "Gujarat", "Dewas": "Madhya Pradesh",
            "Dhalai": "Tripura", "Dhamtari": "Chhattisgarh", "Dhanbad": "Jharkhand",
            "Dhar": "Madhya Pradesh", "Dharmapuri": "Tamil Nadu", "Dharwad": "Karnataka",
            "Dhaulpur": "Rajasthan", "Dhemaji": "Assam", "Dhenkanal": "Odisha",
            "Dhuburi": "Assam", "Dhule": "Maharashtra", "Dibrugarh": "Assam",
            "Dima Hasao": "Assam", "Dimapur": "Nagaland", "Dindigul": "Tamil Nadu",
            "Dindori": "Madhya Pradesh", "Diu": "Daman and Diu", "Doda": "Jammu and Kashmir",
            "Dumka": "Jharkhand", "Dungarpur": "Rajasthan", "Durg": "Chhattisgarh",
            "East Champaran": "Bihar", "East Delhi": "Delhi", "East District": "Sikkim",
            "East Garo Hills": "Meghalaya", "East Godavari": "Andhra Pradesh", "East Imphal": "Manipur",
            "East Jaintia Hills": "Meghalaya", "East Khameng": "Meghalaya", "East Khasi Hills": "Meghalaya",
            "East Siang": "Arunachal Pradesh", "East Singhbhum": "Jharkhand", "Ernakulam": "Kerala",
            "Erode": "Tamil Nadu", "Etah": "Uttar Pradesh", "Etawah": "Uttar Pradesh",
            "Faizabad": "Uttar Pradesh", "Fatehabad": "Haryana", "Fatehgarh Sahib": "Punjab",
            "Fatehpur": "Uttar Pradesh", "Fazilka": "Punjab", "Firozabad": "Uttar Pradesh",
            "Firozpur": "Punjab", "Gadag": "Karnataka", "Gadchiroli": "Maharashtra",
            "Gajapati": "Odisha", "Ganderbal": "Jammu and Kashmir", "Gandhinagar": "Gujarat",
            "Ganganagar": "Rajasthan", "Gangtok": "Sikkim", "Ganjam": "Odisha",
            "Garhwa": "Jharkhand", "Gariyaband": "Chhattisgarh", "Gautam Budh Nagar": "Uttar Pradesh",
            "Gaya": "Bihar", "Ghazipur": "Uttar Pradesh", "Gir Somnath": "Gujarat",
            "Giridih": "Jharkhand", "Goalpara": "Assam", "Godda": "Jharkhand",
            "Golaghat": "Assam", "Gomati": "Tripura", "Gonda": "Uttar Pradesh",
            "Gondia": "Maharashtra", "Gopalganj": "Bihar", "Gorakhpur": "Uttar Pradesh",
            "Greater Mumbai": "Maharashtra", "Gulbarga": "Karnataka", "Gumla": "Jharkhand",
            "Guna": "Madhya Pradesh", "Guntur": "Andhra Pradesh", "Gurdaspur": "Punjab",
            "Gurgaon": "Haryana", "Guwahati": "Assam", "Gwalior": "Madhya Pradesh",
            "Hailakandi": "Assam", "Hamirpur": "Himachal Pradesh", "Hanumangarh": "Rajasthan",
            "Hapur": "Uttar Pradesh", "Harda": "Madhya Pradesh", "Hardoi": "Uttar Pradesh",
            "Haridwar": "Uttarakhand", "Hassan": "Karnataka", "Hathras": "Uttar Pradesh",
            "Haveri": "Karnataka", "Hazaribagh": "Jharkhand", "Hingoli": "Maharashtra",
            "Hissar": "Haryana", "Hojai": "Assam", "Hooghly": "West Bengal",
            "Hoshangabad": "Madhya Pradesh", "Hoshiarpur": "Punjab", "Howrah": "West Bengal",
            "Idukki": "Kerala", "Imphal": "Manipur", "Itanagar": "Arunachal Pradesh",
            "Jabalpur": "Madhya Pradesh", "Jagatsinghpur": "Odisha", "Jagitial": "Telangana",
            "Jaintia Hills": "Meghalaya", "Jaisalmer": "Rajasthan", "Jajpur": "Odisha",
            "Jalandhar": "Punjab", "Jalaun": "Uttar Pradesh", "Jalgaon": "Maharashtra",
            "Jalna": "Maharashtra", "Jalor": "Rajasthan", "Jalpaiguri": "West Bengal",
            "Jammu": "Jammu and Kashmir", "Jamnagar": "Gujarat", "Jamtara": "Jharkhand",
            "Jamui": "Bihar", "Jangaon": "Telangana", "Janjgir": "Chhattisgarh",
            "Jashpur": "Chhattisgarh", "Jaunpur": "Uttar Pradesh", "Jayashankar Bhupalpa": "Telangana",
            "Jehanabad": "Bihar", "Jhabua": "Madhya Pradesh", "Jhajjar": "Haryana",
            "Jhalawar": "Rajasthan", "Jhansi": "Uttar Pradesh", "Jhargram": "West Bengal",
            "Jharsuguda": "Odisha", "Jhunjhunu": "Rajasthan", "Jind": "Haryana",
            "Jiribam": "Manipur", "Jodhpur": "Rajasthan", "Jogulamba Gadwal": "Telangana",
            "Jorhat": "Assam", "Junagadh": "Gujarat", "Kaimur": "Bihar",
            "Kaithal": "Haryana", "Kakching": "Manipur", "Kalahandi": "Odisha",
            "Kalimpong": "West Bengal", "Kamareddy": "Telangana", "Kamrup": "Assam",
            "Kamrup Metro": "Assam", "Kanchipuram": "Tamil Nadu", "Kandhamal": "Odisha",
            "Kangpokpi": "Manipur", "Kangra": "Himachal Pradesh", "Kanker": "Chhattisgarh",
            "Kannauj": "Uttar Pradesh", "Kanniyakumari": "Tamil Nadu", "Kannur": "Kerala",
            "Kanpur Rural": "Uttar Pradesh", "Kanpur Urban": "Uttar Pradesh", "Kapurthala": "Punjab",
            "Karaikal": "Puducherry", "Karauli": "Rajasthan", "Karbi Anglong": "Assam",
            "Kargil": "Jammu and Kashmir", "Karimganj": "Assam", "Karimnagar": "Telangana",
            "Karnal": "Haryana", "Karur": "Tamil Nadu", "Kasaragod": "Kerala",
            "Kashi Ram Nagar": "Uttar Pradesh", "Kathua": "Jammu and Kashmir", "Katihar": "Bihar",
            "Katni": "Madhya Pradesh", "Kaushambi": "Uttar Pradesh", "Kawardha": "Chhattisgarh",
            "Kendrapara": "Odisha", "Keonjhar": "Odisha", "Khagaria": "Bihar",
            "Khammam": "Telangana", "Khandwa": "Madhya Pradesh", "Khargone": "Madhya Pradesh",
            "Kheda": "Gujarat", "Khordha": "Odisha", "Khowai": "Tripura",
            "Khunti": "Jharkhand", "Kinnaur": "Himachal Pradesh", "Kiphere": "Nagaland",
            "Kishanganj": "Bihar", "Kishtwar": "Jammu and Kashmir", "Kodagu": "Karnataka",
            "Koderma": "Jharkhand", "Kohima": "Nagaland", "Kokrajhar": "Assam",
            "Kolar": "Karnataka", "Kolasib": "Mizoram", "Kolhapur": "Maharashtra",
            "Kollam": "Kerala", "Komram Bheem Asifaba": "Telangana", "Kondagaon": "Chhattisgarh",
            "Koppal": "Karnataka", "Koraput": "Odisha", "Korba": "Chhattisgarh",
            "Koria": "Chhattisgarh", "Kota": "Rajasthan", "Kottayam": "Kerala",
            "Kozhikode": "Kerala", "Krishna": "Andhra Pradesh", "Krishnagiri": "Tamil Nadu",
            "Kulgam": "Jammu and Kashmir", "Kullu": "Himachal Pradesh", "Kupwara": "Jammu and Kashmir",
            "Kurnool": "Andhra Pradesh", "Kurukshetra": "Haryana", "Kushinagar": "Uttar Pradesh",
            "Kutch": "Gujarat", "Lahul and Spiti": "Himachal Pradesh", "Lakhimpur Kheri": "Uttar Pradesh",
            "Lakhisarai": "Bihar", "Lalitpur": "Uttar Pradesh", "Latehar": "Jharkhand",
            "Latur": "Maharashtra", "Lawngtlai": "Mizoram", "Leh": "Jammu and Kashmir",
            "Lohardaga": "Jharkhand", "Lohit": "Arunachal Pradesh", "Longding": "Arunachal Pradesh",
            "Longleng": "Nagaland", "Lower Dibang Valley": "Arunachal Pradesh", "Lower Subansiri": "Arunachal Pradesh",
            "Madhepura": "Bihar", "Madhubani": "Bihar", "Mahabubabad": "Telangana",
            "Mahabubnagar": "Telangana", "Maharajganj": "Uttar Pradesh", "Mahasamund": "Chhattisgarh",
            "Mahe": "Puducherry", "Mahendragarh": "Haryana", "Mahisagar": "Gujarat",
            "Mahoba": "Uttar Pradesh", "Mainpuri": "Uttar Pradesh", "Majuli": "Assam",
            "Malappuram": "Kerala", "Malda": "West Bengal", "Malkangiri": "Odisha",
            "Mamit": "Mizoram", "Mancherial": "Telangana", "Mandi": "Himachal Pradesh",
            "Mandla": "Madhya Pradesh", "Mandsaur": "Madhya Pradesh", "Mandya": "Karnataka",
            "Mansa": "Punjab", "Mathura": "Uttar Pradesh", "Maunathbhanjan": "Uttar Pradesh",
            "Mayurbhanj": "Odisha", "Medak": "Telangana", "Medchal Malkajgiri": "Telangana",
            "Mehsana": "Gujarat", "Mirzapur": "Uttar Pradesh", "Moga": "Punjab",
            "Mokokchung": "Nagaland", "Mon": "Nagaland", "Moradabad": "Uttar Pradesh",
            "Morbi": "Gujarat", "Morena": "Madhya Pradesh", "Morigaon": "Assam",
            "Muktsar": "Punjab", "Mungeli": "Chhattisgarh", "Munger": "Bihar",
            "Murshidabad": "West Bengal", "Muzaffarnagar": "Uttar Pradesh", "Muzaffarpur": "Bihar",
            "Mysore": "Karnataka", "Nabarangapur": "Odisha", "Nadia": "West Bengal",
            "Nadiad": "Gujarat", "Nagaon": "Assam", "Nagapattinam": "Tamil Nadu",
            "Nagarkurnool": "Telangana", "Nagaur": "Rajasthan", "Nainital": "Uttarakhand",
            "Nalanda": "Bihar", "Nalbari": "Assam", "Nalgonda": "Telangana",
            "Namakkal": "Tamil Nadu", "Nanded": "Maharashtra", "Nandurbar": "Maharashtra",
            "Narmada": "Gujarat", "Narsimhapur": "Madhya Pradesh", "Navsari": "Gujarat",
            "Nawada": "Bihar", "Nayagarh": "Odisha", "Neemuch": "Madhya Pradesh",
            "Nellore": "Andhra Pradesh", "New Delhi": "Delhi", "Nicobar": "Andaman and Nicobar Islands",
            "Nilgiris": "Tamil Nadu", "Nirmal": "Telangana", "Nizamabad": "Telangana",
            "Noida": "Uttar Pradesh", "Noney": "Manipur", "North 24 Parganas": "West Bengal",
            "North and middle Andaman": "Andaman and Nicobar Islands", "North Delhi": "Delhi",
            "North East Delhi": "Delhi", "North Garo Hills": "Meghalaya", "North Goa": "Goa",
            "North Tripura": "Tripura", "North West Delhi": "Delhi", "Nuaparha": "Assam",
            "Osmanabad": "Maharashtra", "Pakur": "Jharkhand", "Palakkad": "Kerala",
            "Palamau": "Jharkhand", "Palghar": "Maharashtra", "Pali": "Rajasthan",
            "Palwal": "Haryana", "Panch Mahal": "Gujarat", "Panchkula": "Haryana",
            "Panipat": "Haryana", "Panjim": "Goa", "Panna": "Madhya Pradesh",
            "Papumpare": "Arunachal Pradesh", "Parbhani": "Maharashtra", "Paschim Bardhaman": "West Bengal",
            "Paschim Medinipur": "West Bengal", "Patiala": "Punjab", "Pauri": "Uttarakhand",
            "Peddapalli": "Telangana", "Perambalur": "Tamil Nadu", "Peren": "Nagaland",
            "Phek": "Nagaland", "Pilibhit": "Uttar Pradesh", "Pithoragarh": "Uttarakhand",
            "Pondicherry": "Puducherry", "Poonch": "Jammu and Kashmir", "Porbandar": "Gujarat",
            "Port Blair": "Andaman and Nicobar Islands", "Prakasam": "Andhra Pradesh", "Pratapgarh": "Rajasthan",
            "Pudukkottai": "Tamil Nadu", "Pulwama": "Jammu and Kashmir", "Purba Bardhaman": "West Bengal",
            "Purba Medinipur": "West Bengal", "Puri": "Odisha", "Purnia": "Bihar",
            "Purulia": "West Bengal", "Raebareli": "Uttar Pradesh", "Raichur": "Karnataka",
            "Raigarh": "Chhattisgarh", "Raipur": "Chhattisgarh", "Raisen": "Madhya Pradesh",
            "Rajanna Sircilla": "Telangana", "Rajgarh": "Madhya Pradesh", "Rajkot": "Gujarat",
            "Rajnandgaon": "Chhattisgarh", "Rajouri": "Jammu and Kashmir", "Rajsamand": "Rajasthan",
            "Ramanagara": "Karnataka", "Ramanathapuram": "Tamil Nadu", "Ramban": "Jammu and Kashmir",
            "Ramgarh": "Jharkhand", "Rampur": "Uttar Pradesh", "Ranchi": "Jharkhand",
            "Rangareddi": "Telangana", "Ratlam": "Madhya Pradesh", "Ratnagiri": "Maharashtra",
            "Rayagada": "Odisha", "Reasi": "Jammu and Kashmir", "Rewa": "Madhya Pradesh",
            "Rewari": "Haryana", "Ri Bhoi": "Meghalaya", "Rohtak": "Haryana",
            "Rohtas": "Bihar", "Rudraprayag": "Uttarakhand", "Rupnagar": "Punjab",
            "Sabar Kantha": "Gujarat", "Sagar": "Madhya Pradesh", "Saharanpur": "Uttar Pradesh",
            "Saharsa": "Bihar", "Sahibganj": "Jharkhand", "Saiha": "Mizoram",
            "Salem": "Tamil Nadu", "Samastipur": "Bihar", "Samba": "Jammu and Kashmir",
            "Sambalpur": "Odisha", "Sambhal": "Uttar Pradesh", "Sangareddy": "Telangana",
            "Sangli": "Maharashtra", "Sangrur": "Punjab", "Sant Kabir Nagar": "Uttar Pradesh",
            "Sant Ravi Nagar": "Uttar Pradesh", "Saran": "Bihar", "Sas Nagar": "Punjab",
            "Satara": "Maharashtra", "Satna": "Madhya Pradesh", "Sawai Madhopur": "Rajasthan",
            "Sehore": "Madhya Pradesh", "Senapati": "Manipur", "Seoni": "Madhya Pradesh",
            "Sepahijhala": "Tripura", "Seraikela": "Jharkhand", "Serchhip": "Mizoram",
            "Shahdol": "Madhya Pradesh", "Shahid Bhagat Singh Nagar": "Punjab", "Shahjahanpur": "Uttar Pradesh",
            "Shajapur": "Madhya Pradesh", "Shamli": "Uttar Pradesh", "Sheikhpura": "Bihar",
            "Sheohar": "Bihar", "Sheopur": "Madhya Pradesh", "Shillong": "Meghalaya",
            "Shimla": "Himachal Pradesh", "Shimoga": "Karnataka", "Shivpuri": "Madhya Pradesh",
            "Shopian": "Jammu and Kashmir", "Shravasti": "Uttar Pradesh", "Sibsagar": "Assam",
            "Siddipet": "Telangana", "Sidharthnagar": "Uttar Pradesh", "Sidhi": "Madhya Pradesh",
            "Sikar": "Rajasthan", "Silvassa": "Dadra and Nagar Haveli", "Simdega": "Jharkhand",
            "Sindhudurg": "Maharashtra", "Singrauli": "Madhya Pradesh", "Sirmaur": "Himachal Pradesh",
            "Sirohi": "Rajasthan", "Sirsa": "Haryana", "Sitamarhi": "Bihar",
            "Sitapur": "Uttar Pradesh", "Sivaganga": "Tamil Nadu", "Siwan": "Bihar",
            "Solan": "Himachal Pradesh", "Solapur": "Maharashtra", "Sonapur": "Assam",
            "Sonbhadra": "Uttar Pradesh", "Sonepat": "Haryana", "Sonitpur": "Assam",
            "South 24 Parganas": "West Bengal", "South Andaman": "Andaman and Nicobar Islands",
            "South Delhi": "Delhi", "South District": "Sikkim", "South East Delhi": "Delhi",
            "South Garo Hills": "Meghalaya", "South Goa": "Goa", "South Tripura": "Tripura",
            "South West Delhi": "Delhi", "Southwest Khasi Hils": "Meghalaya", "Srikakulam": "Andhra Pradesh",
            "Srinagar": "Jammu and Kashmir", "Sukma": "Chhattisgarh", "Sultanpur": "Uttar Pradesh",
            "Sundargarh": "Odisha", "Supaul": "Bihar", "Surajpur": "Chhattisgarh",
            "Surendranagar": "Gujarat", "Surguja": "Chhattisgarh", "Suryapet": "Telangana",
            "Tamenglong": "Manipur", "Tapi": "Gujarat", "Tarn Taran Sahib": "Punjab",
            "Tawang": "Arunachal Pradesh", "Tehri Garhwal": "Uttarakhand", "Tengnoupal": "Manipur",
            "Thanjavur": "Tamil Nadu", "The Dangs": "Gujarat", "Theni": "Tamil Nadu",
            "Thiruvallur": "Tamil Nadu", "Thiruvarur": "Tamil Nadu", "Thoubal": "Manipur",
            "Thrissur": "Kerala", "Tikamgarh": "Madhya Pradesh", "Tinsukia": "Assam",
            "Tirap": "Arunachal Pradesh", "Tirunelveli": "Tamil Nadu", "Tiruppur": "Tamil Nadu",
            "Tiruvannamalai": "Tamil Nadu", "Tonk": "Rajasthan", "Trichy": "Tamil Nadu",
            "Trivandrum": "Kerala", "Tuensang": "Nagaland", "Tumkur": "Karnataka",
            "Tuticorin": "Tamil Nadu", "Udaipur": "Rajasthan", "Udalguri": "Assam",
            "Udham Singh Nagar": "Uttarakhand", "Udhampur": "Jammu and Kashmir", "Udupi": "Karnataka",
            "Ujjain": "Madhya Pradesh", "Ukhrul": "Manipur", "Umaria": "Madhya Pradesh",
            "Una": "Himachal Pradesh", "Unakoti": "Tripura", "Unnao": "Uttar Pradesh",
            "Upper Dibang Valley": "Arunachal Pradesh", "Upper Siang": "Arunachal Pradesh",
            "Upper Sibansiri": "Arunachal Pradesh", "Uttar Dinajpur": "West Bengal",
            "Uttar Kannad": "Karnataka", "Uttarkashi": "Uttarakhand", "Vaishali": "Bihar",
            "Valsad": "Gujarat", "Varanasi": "Uttar Pradesh", "Vellore": "Tamil Nadu",
            "Vidisha": "Madhya Pradesh", "Vikarabad": "Telangana", "Viluppuram": "Tamil Nadu",
            "Virudhunagar": "Tamil Nadu", "Vizianagaram": "Andhra Pradesh", "Wanaparthy": "Telangana",
            "Warangal": "Telangana", "Warangal Rural": "Telangana", "Wardha": "Maharashtra",
            "Washim": "Maharashtra", "Wayanad": "Kerala", "West Champaran": "Bihar",
            "West Delhi": "Delhi", "West District": "Sikkim", "West Garo Hills": "Meghalaya",
            "West Godavari": "Andhra Pradesh", "West Imphal": "Manipur", "West Kameng": "Arunachal Pradesh",
            "West Karbi Anglong": "Assam", "West Khasi Hills": "Meghalaya", "West Siang": "Arunachal Pradesh",
            "West Singhbhum": "Jharkhand", "West Tripura": "Tripura", "Wokha": "Nagaland",
            "Yadadri Bhuvanagiri": "Telangana", "Yadgir": "Karnataka", "Yamuna Nagar": "Haryana",
            "Yanam": "Puducherry", "Yavatmal": "Maharashtra", "Zunheboto": "Nagaland"
        }

    def ensure_cities_exist(self, db, api_cities_data):
        """Ensure all cities from API response exist in database"""
        city_state_map = self.get_city_state_mapping()
        
        # Get current cities in database
        existing_cities = {city.name: city for city in db.query(City).all()}
        
        # Add new cities from API response
        for item in api_cities_data:
            city_name = item.get("city")
            if not city_name:
                continue
                
            # Get state from mapping, default to "Unknown" if not found
            state = city_state_map.get(city_name, "Unknown")
            
            if city_name not in existing_cities:
                # Add new city
                new_city = City(name=city_name, state=state, is_metro=0)  # Default to non-metro
                db.add(new_city)
                logger.info(f"Added new city: {city_name}, {state}")
            else:
                # Update existing city if state changed
                existing_city = existing_cities[city_name]
                if existing_city.state != state:
                    existing_city.state = state
                    logger.info(f"Updated city state: {city_name} -> {state}")
        
        # Remove cities that are no longer in API response
        api_city_names = {item.get("city") for item in api_cities_data if item.get("city")}
        cities_to_remove = [city for city_name, city in existing_cities.items() 
                          if city_name not in api_city_names]
        
        for city in cities_to_remove:
            # Check if city has fuel price data
            fuel_price_count = db.query(FuelPrice).filter(FuelPrice.city_id == city.id).count()
            if fuel_price_count == 0:
                db.delete(city)
                logger.info(f"Removed city not in API: {city.name}")
            else:
                logger.warning(f"Keeping city with fuel data: {city.name} ({fuel_price_count} records)")
        
        db.commit()

    def scrape_and_store_prices(self, fuel_type: str = "petrol"):
        """Scrape fuel prices and store in database"""
        db = SessionLocal()

        try:
            # Fetch prices from API first
            price_data = self.fetch_fuel_prices(fuel_type)

            if not price_data:
                logger.error("No price data received from API")
                return False

            # Handle both list and dict responses
            if isinstance(price_data, dict) and "data" in price_data:
                items = price_data["data"]
            elif isinstance(price_data, list):
                items = price_data
            else:
                logger.error("Unexpected API response format")
                return False

            # Ensure cities exist (pass the API data)
            self.ensure_cities_exist(db, items)

            # Process and store prices for all cities in API response
            processed_count = 0
            for item in items:
                city_name = item.get("city")
                if not city_name:
                    continue

                # Get city from database
                city = db.query(City).filter(City.name == city_name).first()
                if not city:
                    logger.warning(f"City not found in database: {city_name}")
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
