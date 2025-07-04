import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class TipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pet Care Tips',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.8,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 70,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        flexibleSpace: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF008080),
                  Color(0xFF006D6D),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 12,
                  spreadRadius: 0.5,
                  offset: Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: GridView.count(
                  crossAxisCount: 2,
                  childAspectRatio: 0.85,
                  padding: EdgeInsets.all(8.0),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildCategoryCard(
                      context,
                      "Cats",
                      "assets/images/cat.png",
                      Colors.orange[200]!,
                      CatTipsPage(),
                    ),
                    _buildCategoryCard(
                      context,
                      "Birds",
                      "assets/images/bird.png",
                      Colors.lightBlue[200]!,
                      BirdTipsPage(),
                    ),
                    _buildCategoryCard(
                      context,
                      "Dogs",
                      "assets/images/dog.png",
                      Colors.brown[200]!,
                      DogTipsPage(),
                    ),
                    _buildCategoryCard(
                      context,
                      "Others",
                      "assets/images/others.png",
                      Colors.green[200]!,
                      OtherTipsPage(),
                    ),
                  ],
                ),
              ),
            ),
            _buildHelplineSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHelplineSection(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.teal[800]!.withOpacity(0.1),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'Emergency Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildHelplineCard(
                  "Pet Poison Helpline",
                  "(855) 764-7661",
                  Icons.warning_amber,
                  Colors.red[400]!,
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildHelplineCard(
                  "Vet Emergency",
                  "(888) 426-4435",
                  Icons.local_hospital,
                  Colors.green[400]!,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          _buildEmergencyButton(context),
        ],
      ),
    );
  }

  Widget _buildHelplineCard(String title, String number, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.teal[900],
              ),
            ),
            SizedBox(height: 4),
            Text(
              number,
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(Icons.emergency, color: Colors.white),
        label: Text('Emergency Vet Assistance'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red[400],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Emergency Contacts'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmergencyContactItem(
                    "Animal Poison Control",
                    "(888) 426-4435",
                  ),
                  Divider(),
                  _buildEmergencyContactItem(
                    "Pet Emergency Hotline",
                    "(855) 764-7661",
                  ),
                  Divider(),
                  _buildEmergencyContactItem(
                    "24/7 Vet Consultation",
                    "(800) 738-7237",
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Close'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmergencyContactItem(String title, String number) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(number),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String title, String imagePath, Color accentColor, Widget page) {
    return AnimatedPetCard(
      accentColor: accentColor,
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => page));
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Padding(
                padding: EdgeInsets.all(12),
                child: Hero(
                  tag: title,
                  child: Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                  ),
                )),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.teal[900],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 8.0),
            child: Text(
              "Care Guide",
              style: TextStyle(
                fontSize: 12,
                color: Colors.teal[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedPetCard extends StatefulWidget {
  final Widget child;
  final Color accentColor;
  final VoidCallback onTap;

  const AnimatedPetCard({
    required this.child,
    required this.accentColor,
    required this.onTap,
  });

  @override
  _AnimatedPetCardState createState() => _AnimatedPetCardState();
}

class _AnimatedPetCardState extends State<AnimatedPetCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 4, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _elevationAnimation,
        builder: (context, child) {
          return InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            onHighlightChanged: (highlighted) {
              if (highlighted) {
                _controller.reverse();
              } else {
                _controller.forward();
              }
            },
            child: Card(
              elevation: _elevationAnimation.value,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.accentColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: widget.child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class CatTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen(
      "Cat Care Guide",
      "assets/images/cat.png",
      Colors.orange[200]!,
      [
        _buildTipSection(
          "Nutrition",
          Icons.fastfood,
          [
            "Provide fresh water daily in a clean bowl",
            "High-quality commercial cat food appropriate for age",
            "Avoid milk - most cats are lactose intolerant",
            "Limit treats to 10% of daily calories",
          ],
        ),
        _buildTipSection(
          "Grooming",
          Icons.brush,
          [
            "Brush shorthaired cats weekly, longhaired daily",
            "Trim nails every 2-3 weeks",
            "Clean ears gently with vet-approved solution",
            "Dental care: brush teeth or use dental treats",
          ],
        ),
        _buildTipSection(
          "Health",
          Icons.medical_services,
          [
            "Annual vet checkups with vaccinations",
            "Spay/neuter by 5 months old",
            "Watch for signs of illness: changes in appetite/behavior",
            "Keep indoors to prevent accidents/diseases",
          ],
        ),
        _buildTipSection(
          "Environment",
          Icons.home,
          [
            "Clean litter box daily (1 per cat + 1 extra)",
            "Provide scratching posts and climbing spaces",
            "Safe, quiet hiding places",
            "Interactive toys for mental stimulation",
          ],
        ),
      ],
    );
  }
}

class BirdTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen(
      "Bird Care Guide",
      "assets/images/bird.png",
      Colors.lightBlue[200]!,
      [
        _buildTipSection(
          "Housing",
          Icons.fastfood,
          [
            "Cage should allow full wing extension (minimum 2x bird length)",
            "Horizontal bars for climbing",
            "Place in active family area but not kitchen",
            "Night cover for 10-12 hours of sleep",
          ],
        ),
        _buildTipSection(
          "Nutrition",
          Icons.fastfood,
          [
            "Species-appropriate pellets as base diet",
            "Fresh veggies daily (avoid avocado, onion, chocolate)",
            "Limited fruits and seeds as treats",
            "Clean water changed twice daily",
          ],
        ),
        _buildTipSection(
          "Enrichment",
          Icons.toys,
          [
            "Rotate toys weekly to prevent boredom",
            "Foraging opportunities (hide treats in paper)",
            "Out-of-cage time daily (bird-proof room)",
            "Social interaction - birds are flock animals",
          ],
        ),
        _buildTipSection(
          "Health",
          Icons.medical_services,
          [
            "Annual avian vet checkups",
            "Watch for signs: fluffed feathers, changes in droppings",
            "Avoid non-stick cookware (toxic fumes)",
            "Maintain proper humidity (species-dependent)",
          ],
        ),
      ],
    );
  }
}

class DogTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen(
      "Dog Care Guide",
      "assets/images/dog.png",
      Colors.brown[200]!,
      [
        _buildTipSection(
          "Exercise",
          Icons.directions_run,
          [
            "Daily walks (breed-dependent duration)",
            "Play sessions: fetch, tug, puzzle toys",
            "Socialization with other dogs",
            "Mental stimulation through training",
          ],
        ),
        _buildTipSection(
          "Nutrition",
          Icons.fastfood,
          [
            "Age/size appropriate high-quality food",
            "Measure portions to prevent obesity",
            "Avoid toxic foods: chocolate, grapes, onions",
            "Fresh water available at all times",
          ],
        ),
        _buildTipSection(
          "Training",
          Icons.school,
          [
            "Positive reinforcement methods only",
            "Start basic commands early (sit, stay, come)",
            "Consistency is key - all family members same rules",
            "Socialization window closes around 16 weeks",
          ],
        ),
        _buildTipSection(
          "Health",
          Icons.medical_services,
          [
            "Annual vet exams with vaccinations",
            "Monthly flea/tick/heartworm prevention",
            "Dental care: brushing or dental chews",
            "Spay/neuter unless breeding responsibly",
          ],
        ),
      ],
    );
  }
}

class OtherTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _buildTipsScreen(
      "Exotic Pet Care",
      "assets/images/others.png",
      Colors.green[200]!,
      [
        _buildTipSection(
          "Small Mammals",
          Icons.pets,
          [
            "Species-appropriate habitat size",
            "Proper bedding (avoid cedar/pine shavings)",
            "Hide boxes for security",
            "Exercise wheels/balls for rodents",
          ],
        ),
        _buildTipSection(
          "Reptiles",
          Icons.eco,
          [
            "Proper temperature gradient with basking spot",
            "UVB lighting for most species",
            "Humidity control as needed",
            "Species-appropriate substrate",
          ],
        ),
        _buildTipSection(
          "Aquatic Pets",
          Icons.water,
          [
            "Proper tank size with filtration",
            "Regular water testing and changes",
            "Species-appropriate tank mates",
            "Avoid overfeeding - major cause of issues",
          ],
        ),
        _buildTipSection(
          "General Tips",
          Icons.lightbulb,
          [
            "Research before getting any pet",
            "Find an exotic pet veterinarian first",
            "Handle gently and appropriately",
            "Watch for signs of stress/illness",
          ],
        ),
      ],
    );
  }
}

Widget _buildTipsScreen(String title, String heroImage, Color accentColor, List<Widget> sections) {
  return Scaffold(
    body: CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(title, style: TextStyle(color: Colors.white, fontSize: 20)),
            background: Hero(
              tag: title,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.3),
                  BlendMode.darken,
                ),
                child: Image.asset(
                  heroImage,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          backgroundColor: accentColor,
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              return AnimatedTipsSection(
                delay: index * 100,
                child: sections[index],
              );
            },
            childCount: sections.length,
          ),
        ),
      ],
    ),
  );
}

Widget _buildTipSection(String title, IconData icon, List<String> tips) {
  return Card(
    margin: EdgeInsets.all(16),
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.teal),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ...tips.map((tip) => Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 3, right: 8),
                  child: Icon(Icons.fiber_manual_record, size: 8, color: Colors.teal),
                ),
                Expanded(
                  child: Text(
                    tip,
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    ),
  );
}

class AnimatedTipsSection extends StatefulWidget {
  final int delay;
  final Widget child;

  const AnimatedTipsSection({
    required this.delay,
    required this.child,
  });

  @override
  _AnimatedTipsSectionState createState() => _AnimatedTipsSectionState();
}

class _AnimatedTipsSectionState extends State<AnimatedTipsSection> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_animation),
        child: widget.child,
      ),
    );
  }
}