import React from 'react';
import { View, Text, StyleSheet } from 'react-native';
import { formatTime } from '../utils/formatTime';

export default function SunTimes({ sunrise, sunset }) {
  return (
    <View style={styles.container}>
      <Text style={styles.label}>☀️ Sunrise: {formatTime(sunrise)}</Text>
      <Text style={styles.label}>🌇 Sunset: {formatTime(sunset)}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { alignItems: 'center' },
  label: { color: '#fff', fontSize: 16, marginVertical: 4 },
});
