from itertools import chain
from typing import Optional, List
from pydantic import BaseModel


class SearchRequestModel(BaseModel):
    term: str
    location_types : Optional[str] = 'airport'
    locale: Optional[str] = 'en-US'
    limit: Optional[int] = 10
    active_only: Optional[bool] = True
    sort: Optional[str] = 'rank'


class FlightRequestModel(BaseModel):
    fly_from: str
    fly_to: str
    date_from: str
    date_to: str
    partner: str = 'picky'



class RouteModel(BaseModel):
    lat_from: float
    lng_from: float
    lat_to: float
    lng_to: float

    @staticmethod
    def to_model(route_data):
        return RouteModel(lat_from=route_data['latFrom'],
                          lng_from=route_data['lngFrom'],
                          lat_to=route_data['latTo'],
                          lng_to=route_data['lngTo'])

class FlightDataModel(BaseModel):
    departure_time: int
    price: float
    routes: List[RouteModel]

    @staticmethod
    def to_model(flight_data):
        return FlightDataModel(departure_time=flight_data["dTimeUTC"],
                               price=flight_data['price'],
                               routes=[RouteModel.to_model(route_data) for route_data in flight_data['route']])


class FlightAPIResponseModel(BaseModel):
    data: List[FlightDataModel]

    @staticmethod
    def from_response(flight_api_response):
        return FlightAPIResponseModel(data=[FlightDataModel.to_model(flight_data) for flight_data in flight_api_response['data']])


class RouteDistanceModel(BaseModel):
    routes: List[RouteModel]
    distance: float
    price: float
    dollars_per_km: float