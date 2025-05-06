import React, { useEffect, useState } from 'react';
import { View, Text, StyleSheet, ActivityIndicator } from 'react-native';
import * as Location from 'expo-location';
import { getCurrentWeather } from '../services/weatherService';
import { formatTime } from '../utils/formatTime';
import WeatherCard from '../components/WeatherCard';
import SunTimes from '../components/SunTimes';

export default function HomeScreen() {
  const [weather, setWeather] = useState(null);
  const [loading, setLoading] = useState(true);
  const [errorMsg, setErrorMsg] = useState(null);

  useEffect(() => {
    (async () => {
      let { status } = await Location.requestForegroundPermissionsAsync();
      if (status !== 'granted') {
        setErrorMsg('Location permission denied');
        setLoading(false);
        return;
      }

      let location = await Location.getCurrentPositionAsync({});
      const data = await getCurrentWeather(location.coords.latitude, location.coords.longitude);
      if (data) setWeather(data);
      else setErrorMsg('Failed to load weather');
      setLoading(false);
    })();
  }, []);

  if (loading) return <ActivityIndicator style={{ flex: 1 }} size="large" />;
  if (errorMsg) return <Text style={styles.error}>{errorMsg}</Text>;

  return (
    <View style={styles.container}>
      <Text style={styles.title}>📸 PhotoCast</Text>
      <WeatherCard weather={weather} />
      <SunTimes sunrise={weather.sys.sunrise} sunset={weather.sys.sunset} />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1, padding: 20, backgroundColor: '#222', alignItems: 'center',
  },
  title: {
    fontSize: 28, color: '#fff', marginVertical: 20,
  },
  error: {
    flex: 1, textAlign: 'center', color: 'red', marginTop: 50,
  },
});
