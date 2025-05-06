export async function getCurrentWeather(lat, lon) {
    try {
      const res = await fetch(
        `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}&hourly=temperature_2m`
      );
      return await res.json();
    } catch (e) {
      console.error('Weather API Error:', e);
      return null;
    }
  }
  