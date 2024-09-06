import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:weather/models/weather_model.dart';

class WeatherService {
  static const BASE_URL = 'https://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final url = Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Weather.fromJson(data);
    } else {
      // More descriptive error message
      throw Exception('Failed to load weather data: ${response.reasonPhrase}');
    }
  }

  Future<String> getCurrentCity() async {
    try {
      // Check and request location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.deniedForever) {
          throw Exception('Location permissions are permanently denied');
        } else if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      // Fetch the current location
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // Convert the location into a list of placemarks
      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      // Extract the city name from the first placemark
      String city = placemarks.isNotEmpty
          ? placemarks[0].locality ?? "Unknown city"
          : "Unknown city";

      return city;
    } catch (e) {
      // Handle errors from geolocation or geocoding
      throw Exception('Failed to get current city: $e');
    }
  }
}
