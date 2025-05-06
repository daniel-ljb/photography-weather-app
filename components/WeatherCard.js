import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

export default function WeatherCard({ weather }) {
  const { main, weather: info, name } = weather;

  return (
    <View style={styles.card}>
      <Text style={styles.city}>{name}</Text>
      <Text style={styles.temp}>{main.temp}°C</Text>
      <Text style={styles.desc}>{info[0].description}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  card: {
    backgroundColor: '#444', padding: 20, borderRadius: 10, alignItems: 'center', marginBottom: 20,
  },
  city: { fontSize: 22, color: '#fff' },
  temp: { fontSize: 40, color: '#fff', fontWeight: 'bold' },
  desc: { fontSize: 18, color: '#ccc' },
});
