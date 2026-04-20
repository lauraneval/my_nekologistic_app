import 'package:flutter/material.dart';
import 'package:my_nekologistic_app/proof_of_delivery/components/pod_cards.dart';
import '../components/secondary_appbar.dart';

class ProofOfDeliveryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: secondaryAppbar(),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.indigo[100],
                borderRadius: BorderRadius.circular(16)
              ),
              child: Text(
                  "#PACKAGE_NUMBER",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1
                ),
              ),
            ),
            Text(
                "Proof Of Delivery",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
                "Capture a clear photo of the package at the drop off location.",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Colors.black45
              ),
            ),
            Row(
              children: [
                Expanded(child: Container(
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent
                  ),
                  child: Text("Proof button"),
                ))
              ],
            ),
            podCards(
                "location tag",
                [
                  Row(
                    children: [
                      Icon(
                          Icons.location_on_outlined,
                        color: Colors.indigo,
                        size: 16,
                      ),
                      Text(
                          "42nd West Ave, NYC",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    ],
                  ),
                  Text(
                      "Estimated Precision : 2.4m",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: Colors.black87
                    ),
                  )
                ]
            ),
            podCards(
              "arrival time",
              [
                Text(
                    "14:28",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: Colors.blue[900]
                  ),
                ),
                Text(
                    "Oct 24, 2023",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87
                  ),
                )
              ]
            ),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.indigo[50], // Light blue background
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                children: [
                  // The orange vertical indicator on the left
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.orange[800],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Text Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'Recipient Signature',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF1A1C1E),
                          ),
                        ),
                        Text(
                          'Required for High Value',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The "Add Now" Button
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00459E), // Navy blue text
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Add Now', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900]
                ),
                child: Padding(
                  padding: EdgeInsetsGeometry.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          "Upload & Complete Delivery",
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                          )
                      ),
                      Padding(padding: EdgeInsets.only(left: 8)),
                      Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      )
                    ],
                  ),
                )
            )
          ],
        )
      ),
    );
  }
}