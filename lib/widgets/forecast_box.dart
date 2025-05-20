import 'package:flutter/material.dart';

class ForecastBox extends StatelessWidget {
  final String location;
  final VoidCallback? onTap;

  const ForecastBox({
    super.key,
    this.location = 'Cambridge',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 20, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Row(
                      children: [
                        Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                        SizedBox(width: 2),
                        Text('5:08am'),
                      ],
                    ),
                    SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.nights_stay,
                          size: 16,
                          color: Colors.deepOrange,
                        ),
                        SizedBox(width: 2),
                        Text('8:45pm'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 8,
                separatorBuilder: (context, index) => const SizedBox(width: 16),
                itemBuilder: (context, index) {
                  // Example data
                  final hours = [
                    '4pm',
                    '5pm',
                    '6pm',
                    '7pm',
                    '8pm',
                    '9pm',
                    '10pm',
                    '11pm',
                  ];
                  final temps = [15, 16, 17, 15, 12, 9, 7, 6];
                  final icons = [
                    Icons.wb_sunny,
                    Icons.wb_sunny,
                    Icons.wb_sunny,
                    Icons.cloud,
                    Icons.nights_stay,
                    Icons.nights_stay,
                    Icons.nights_stay,
                    Icons.nights_stay,
                  ];
                  return Column(
                    children: [
                      Text(hours[index], style: const TextStyle(fontSize: 14)),
                      Icon(icons[index], size: 24, color: Colors.blueGrey),
                      Text(
                        '${temps[index]}°C',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 