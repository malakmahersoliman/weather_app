import 'package:flutter/material.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/services/weather_service.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:lottie/lottie.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('68c054f429c6dff9cd7ebdca9af5de92');
  Weather? _weather;
  bool _isLoading = true;
  String? _errorMessage;
  String _cityName = '';

  @override
  void initState() {
    super.initState();
    _fetchWeatherForCurrentLocation();
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition();
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      String cityName = placemarks[0].locality ?? 'Unknown City';

      await _fetchWeather(cityName);
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch weather data.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather(String cityName) async {
    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
        _isLoading = false;
        _cityName = cityName;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch weather data.';
        _isLoading = false;
      });
    }
  }

  String getWeatherAnimation(String? mainCondition) {
    if (mainCondition == null) return 'assets/Sunny.json'; // Default to sunny
    switch (mainCondition.toLowerCase()) {
      case 'clouds':
      case 'mist':
      case 'smoke':
      case 'haze':
      case 'fog':
        return 'assets/cloud.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
        return 'assets/rain.json';
      case 'thunderstorm':
        return 'assets/thunder.json';
      case 'clear':
        return 'assets/Sunny.json';
      default:
        return 'assets/Sunny.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[800],
      appBar: AppBar(
        title: Text('Weather App'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Loading indicator
            : _errorMessage != null
                ? Text(_errorMessage!) // Error message
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // City name
                      Text(_weather?.cityName ?? "Unknown City",
                          style: TextStyle(fontSize: 24, color: Colors.white)),
                      // Weather animation
                      Lottie.asset(
                          getWeatherAnimation(_weather?.mainCondition)),
                      // Temperature
                      Text('${_weather?.temperature?.round() ?? 'N/A'}°C',
                          style: TextStyle(fontSize: 32, color: Colors.white)),
                      // Weather condition
                      Text(_weather?.mainCondition ?? "",
                          style: TextStyle(fontSize: 18, color: Colors.white)),
                      SizedBox(height: 20),
                      // Search input
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              _fetchWeather(value);
                            }
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Search for a city',
                            suffixIcon: Icon(Icons.search),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          _fetchWeatherForCurrentLocation();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 15),
                        ),
                        child: Text('Refresh'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
