import 'package:flutter/material.dart';

class TipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(

      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 2, // Two cards in one row
          padding: EdgeInsets.all(16.0),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildCategoryCard(
              context,
              "Cats",
              "assets/images/cat.png",
              CatTipsPage(),
            ),
            _buildCategoryCard(
              context,
              "Birds",
              "assets/images/bird.png",
              BirdTipsPage(),
            ),
            _buildCategoryCard(
              context,
              "Dogs",
              "assets/images/dog.png",
              DogTipsPage(),
            ),
            _buildCategoryCard(
              context,
              "Others",
              "assets/images/others.png",
              OtherTipsPage(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, Widget page) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CatTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen("Cat Tips", [
      "Provide fresh water daily.",
      "Regularly groom your cat.",
      "Keep the litter box clean.",
    ]);
  }
}

class BirdTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen("Bird Tips", [
      "Provide a spacious cage.",
      "Ensure a balanced diet.",
      "Give them toys for mental stimulation.",
    ]);
  }
}

class DogTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen("Dog Tips", [
      "Take your dog for regular walks.",
      "Provide a healthy diet.",
      "Train your dog with positive reinforcement.",
    ]);
  }
}

class OtherTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen("Other Pet Tips", [
      "Research your pet's needs.",
      "Provide a suitable habitat.",
      "Ensure proper hygiene and care.",
    ]);
  }
}

// Reusable function to build a Tips Page
Widget _buildTipsScreen(String title, List<String> tips) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: EdgeInsets.all(16.0),
      children: tips.map((tip) => _buildTipCard(tip)).toList(),
    ),
  );
}

// Reusable Tip Card Widget
Widget _buildTipCard(String tip) {
  return Card(
    margin: EdgeInsets.symmetric(vertical: 6.0),
    child: ListTile(
      leading: Icon(Icons.pets, color: Colors.teal),
      title: Text(tip),
    ),
  );
}
