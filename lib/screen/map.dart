import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});



  @override
  State<MapScreen> createState() => _MapScreenState();
}


final initialPosition = LatLng(15.854909, 120.600655);
final Set<Marker> markers = {};
var descriptionController= TextEditingController();
late CollectionReference faveplaces = FirebaseFirestore.instance.collection('favorites');
class _MapScreenState extends State<MapScreen> {


void Description(LatLng position) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(hintText:'Enter description'),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                ElevatedButton(
                  child: Text('Save'),
                  onPressed: () {
                    saveFavorite(position, descriptionController.text);
                    addMarker(position, descriptionController.text);
                    Navigator.of(context).pop();
                    descriptionController.clear();
                  },
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}


void addMarker(LatLng p, String desc) {
  setState(() {
    markers.add(
      Marker(
        markerId: MarkerId('${p.latitude}-${p.longitude}'),
        position: LatLng(p.latitude, p.longitude),
        infoWindow: InfoWindow(title: 'Favorite', snippet: desc),
        onTap: () => DeleteDialog(p),
      ),
    );
  });
}


void DeleteDialog(LatLng position) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('WARNING!'),
        content: const Text('Are you sure you want to remove this pinned location?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              deleteFavorite('${position.latitude}-${position.longitude}');
              Navigator.of(context).pop();
            },
            child: const Text('YES'),
          ),
        ],
      );
    },
  );
}

void deleteFavorite(String markerId) async {
  markers.removeWhere((marker) => marker.markerId.value == markerId);
  setState(() {});
  QuerySnapshot querySnapshot = await faveplaces.where('details.markerId', isEqualTo: markerId).get();
  querySnapshot.docs.forEach((doc) {
    doc.reference.delete();
  });
}

void saveFavorite(LatLng position, String description) {
  faveplaces.add({'details': {'latitude': position.latitude, 'longitude': position.longitude, 'description': description, 'markerId': '${position.latitude}-${position.longitude}'}});
}

void getfavorite() async {
  QuerySnapshot querySnapshot = await faveplaces.get();
  querySnapshot.docs.forEach((doc) {
    try{
      var details = doc['details'];
      if (details != null && details is Map<String, dynamic> && details.containsKey('latitude') && details.containsKey('longitude')) {
      double lat = details['latitude'];
      double lng = details['longitude'];
      LatLng position = LatLng(lat, lng);
      addMarker(position, details['description']);
    } else {
      print('Invalid location data: ${doc.id}');
    }
  }catch(e){
    print(e);
  }  
  });
}

@override
  void initState() {
    // TODO: implement initState
    super.initState();
    getfavorite();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Favorite Places",
        style: TextStyle(
          fontSize: 25,
          color: Colors.white),),
        backgroundColor: const Color.fromARGB(255, 3, 58, 84),
      ),
      body: SafeArea(
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
          target: initialPosition,
          zoom: 12
          ),
          markers: markers,
          onTap: (position) {
            Description(position);
          },
          ),
        ),
    );
  }
}