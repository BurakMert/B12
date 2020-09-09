import json
from typing import List
from datetime import datetime, timedelta
from haversine import haversine
from infra import http_client
from core import models
from utils import constants

class FlightOptimizer:

    def __init__(self, frm, to):
        self.fly_from = FlightOptimizer.get_main_airport(frm)
        self.fly_to = FlightOptimizer.get_main_airport(to)
        self.date_from = datetime.utcnow().strftime('%d/%m/%Y')
        self.date_to = (datetime.utcnow() + timedelta(days=1)).strftime('%d/%m/%Y')

    def to_model(self):
        return models.FlightRequestModel(**self.__dict__).json()

    def optimize_dpk(self) -> None:
        try:
            flight_info_response = http_client.make_http_call(constants.flight_api_url, params=json.loads(self.to_model()))
            flight_api_model = models.FlightAPIResponseModel.from_response(flight_info_response.json())
            route_distances = FlightOptimizer.calculate_route_distance(flight_api_model)

            sorted_routes_by_dpk = sorted(route_distances, key=lambda i: i.dollars_per_km)
            return sorted_routes_by_dpk[0]
        except Exception as e:
            print("Error in infra kiwi_client: {}".format(e))

    @classmethod
    def calculate_route_distance(cls, flight_api_model: models.FlightAPIResponseModel) -> List[models.RouteDistanceModel]:
        route_distances = []
        for data in flight_api_model.data:
            route_distance = 0
            routes = []
            for route in data.routes:
                try:
                    frm = (route.lat_from, route.lng_from)  # (lat, lon)
                    to = (route.lat_to, route.lng_to)
                    route_distance += haversine(frm, to)
                    routes.append(route)
                except Exception as e:
                    print("Error in calculating haversine distance between {} and {}".format(frm, to))


            route_distances.append(models.RouteDistanceModel(routes=routes,
                                                             distance=route_distance,
                                                             dollars_per_km=data.price/route_distance,
                                                             price=data.price))

        return route_distances

    @classmethod
    def get_main_airport(cls, city: str) -> None:
        try:
            search_model = models.SearchRequestModel(term=city).json()
            location_response = http_client.make_http_call(constants.location_api_url, json.loads(search_model)).json()
            airports = [{key: location[key] for key in location.keys() & {'code', 'dst_popularity_score'}}
                        for location in location_response['locations']]


            sorted_by_popularity = sorted(airports, key=lambda i: i['dst_popularity_score'], reverse=True)
            return sorted_by_popularity[0]['code']
        except Exception as e:
            print(e)
            return False