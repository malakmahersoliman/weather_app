import 'package:flutter/material.dart';
import 'package:weather/models/weather_model.dart';
import 'package:weather/services/weather_service.dart';
import 'package:lottie/lottie.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  final _weatherService = WeatherService('68c054f429c6dff9cd7ebdca9af5de92');
  Weather? _weather;
  bool _isLoading = false;
  String? _errorMessage;
  String _cityName = '';
  bool _isSearchVisible = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchWeatherForCurrentLocation(); // Optionally fetch weather for current location on startup
  }

  Future<void> _fetchWeather(String cityName) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final weather = await _weatherService.getWeather(cityName);
      setState(() {
        _weather = weather;
        _isLoading = false;
        _cityName = cityName;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch weather data for $cityName.';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeatherForCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
        _errorMessage = 'Failed to fetch weather data for current location.';
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

  Future<void> _handleSearch() async {
    final cityName = _searchController.text.trim();
    if (cityName.isNotEmpty) {
      await _fetchWeather(cityName);
      setState(() {
        _isSearchVisible = false; // Hide search field after search
        _searchController.clear(); // Clear the input field
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Weather App"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
              });
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[800],
      body: Column(
        children: [
          // Input field to enter city name
          if (_isSearchVisible)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                onSubmitted: (_) => _handleSearch(),
                decoration: InputDecoration(
                  hintText: 'Enter city name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),
          // Center everything else
          Expanded(
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : _errorMessage != null
                      ? Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        )
                      : _weather != null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // City name
                                Text(
                                  _weather!.cityName,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Weather animation
                                Lottie.asset(getWeatherAnimation(
                                    _weather?.mainCondition)),
                                const SizedBox(height: 10),
                                // Temperature
                                Text(
                                  '${_weather?.temperature?.round() ?? 'N/A'}°C',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    color: Colors.white,
                                  ),
                                ),
                                // Weather condition
                                Text(
                                  _weather?.mainCondition ?? '',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),

                                ElevatedButton(
                                  onPressed: _fetchWeatherForCurrentLocation,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 30, vertical: 15),
                                  ),
                                  child: const Text('Refresh'),
                                ),
                              ],
                            )
                          : Container(), // Empty container if no data
            ),
          ),
        ],
      ),
    );
  }
}
