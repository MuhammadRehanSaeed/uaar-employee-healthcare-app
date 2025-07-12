import 'package:employeehealthcare/screens/article.dart';
import 'package:employeehealthcare/screens/article_list_screen.dart';
import 'package:employeehealthcare/screens/hospital.dart';
import 'package:employeehealthcare/screens/labs.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'Doctor_Detail_Page.dart';
import 'alldoctorspage.dart';
import 'article_data.dart';
import 'article_detail_screen.dart';
import 'doctor_data.dart';
import 'login_screen.dart';



class FullMedical extends StatefulWidget {
  @override
  _FullMedicalState createState() => _FullMedicalState();
}

class _FullMedicalState extends State<FullMedical> {
  List<Map<String, dynamic>> previewDoctors = doctorList.take(3).toList();


  FocusNode _focusNode = FocusNode();

  // Dispose the focus node when the widget is disposed
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        // Dismiss keyboard when tapping anywhere outside the TextField
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode());
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Find your desire\nhealth solution",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search, color: Colors.teal), // Customize icon color
                    hintText: "Search doctor, drugs, articles...",
                    hintStyle: TextStyle(color: Colors.grey.shade600), // Hint text color
                    filled: true, // Fill the background
                    fillColor: Colors.grey.shade200, // Light grey background
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20), // Round the corners
                      borderSide: BorderSide.none, // Remove border line
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), // Add padding for better spacing
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.teal, width: 2), // Border color on focus
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: const BorderSide(color: Colors.transparent), // Remove border when not focused
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildIconCard(Icons.person, "Doctor", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AllDoctorsPage()),
                      );
                    }),
                    _buildIconCard(Icons.local_pharmacy, "Labs", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LabPage()),
                      );
                    }),
                    _buildIconCard(Icons.local_hospital, "Hospitals", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const HospitalPage()),
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Early protection for\nyour family health",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(context,MaterialPageRoute(builder: (context)=>const ArticleListScreen()));
                              },
                              child: const Text("Learn more", style: TextStyle(color: Colors.white)), // White text
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white, backgroundColor: Colors.teal, // Text color when button is pressed
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 65, // Adjust the width of the circle
                        height: 90, // Adjust the height of the circle
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle, // Ensures the container is circular
                          color: Colors.white, // White background around the image
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/doctor.png",
                            width: 60, // Adjust width here
                            height: 60, // Adjust height here
                            fit: BoxFit.cover, // Ensures the image fills the circle
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(context, "Top Doctor", onTap: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context)=>
                  const AllDoctorsPage()));
                }),
                const SizedBox(height: 10),
                SizedBox(
                  height: 200,
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance.collection('externalDoctors').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No doctors found'));
                      }
                      final doctors = snapshot.data!.docs;

                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: doctors.length,
                        itemBuilder: (context, index) {
                          final doctorData = {
                            ...doctors[index].data() as Map<String, dynamic>,
                            'id': doctors[index].id, // this is critical!
                          };
                          return _buildFirestoreDoctorCard(context, doctorData);

                        },
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),
                _buildSectionTitle(context, "Health article", onTap: () {
                  Navigator.push(context,MaterialPageRoute(builder: (context)=>const ArticleListScreen()));
                }),
                // Add your articles widget here
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: articleList.length,
                    itemBuilder: (context, index) {
                      final article = articleList[index];
                      return _buildArticleCard(article);
                    },
                  ),
                ),

              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to login page using pushReplacement
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()), // Navigate to the LoginScreen
          );
        },
        child: const Icon(Icons.logout),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildIconCard(IconData icon, String label,{VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.teal.shade100,
            child: Icon(icon, size: 20, color: Colors.teal),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
  Widget _buildSectionTitle(BuildContext context, String title, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        GestureDetector(
          onTap: onTap, // <-- use the passed callback here!
          child: const Text("See all", style: TextStyle(color: Colors.teal)),
        ),
      ],
    );
  }

  Widget _buildArticleCard(Article article) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.asset(
                article.image,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }



  Widget _buildDoctorCard(Map<String, dynamic> doctor) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage(doctor["image"]),
            radius: 30,
          ),
          const SizedBox(height: 8),
          Text(doctor["name"],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center),
          Text(doctor["type"],
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 14),
              Text("${doctor["rating"]} "),
              Text("• ${doctor["distance"]}", style: const TextStyle(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }
  // Widget _buildFirestoreDoctorCard(Map<String, dynamic> doctor) {
  //   final randomDoctor = doctorList[(doctor['name'].hashCode % doctorList.length)];
  //
  //   return Container(
  //     width: 160,
  //     margin: const EdgeInsets.only(right: 12),
  //     padding: const EdgeInsets.all(12),
  //     decoration: BoxDecoration(
  //       borderRadius: BorderRadius.circular(16),
  //       border: Border.all(color: Colors.grey.shade200),
  //     ),
  //     child: Column(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         CircleAvatar(
  //           backgroundColor: Colors.teal.shade100,
  //           radius: 30,
  //           backgroundImage: AssetImage(randomDoctor['image']),
  //         ),
  //         const SizedBox(height: 8),
  //         Text(
  //           doctor['name'] ?? 'Unknown',
  //           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  //           textAlign: TextAlign.center,
  //         ),
  //         Text(
  //           doctor['specialization'] ?? '',
  //           style: const TextStyle(fontSize: 12, color: Colors.grey),
  //         ),
  //         const SizedBox(height: 6),
  //         Text(
  //           doctor['hospital'] ?? '',
  //           style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
  //           textAlign: TextAlign.center,
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildFirestoreDoctorCard(BuildContext context, Map<String, dynamic> doctor) {
    final String doctorName = doctor['name'] ?? 'Unknown';
    final String specialization = doctor['specialization'] ?? 'Specialist';
    final String hospital = doctor['hospital'] ?? 'Unknown Hospital';

    // Use hashCode only if doctorName is not null
    final randomDoctor = doctorList[(doctorName.hashCode % doctorList.length)];
    final imagePath = randomDoctor['image'];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DoctorDetailPage(
              doctorId: doctor['id'] ?? '', // fallback to empty string
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: Colors.teal.shade100,
              radius: 30,
              backgroundImage: AssetImage(imagePath),
            ),
            const SizedBox(height: 8),
            Text(
              doctorName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              specialization,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            Text(
              hospital,
              style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }




}
