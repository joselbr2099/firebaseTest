// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {

  // se utiliza para llamar a codigo nativo en funciones main que usen async como en este caso
  WidgetsFlutterBinding.ensureInitialized();

  //se inicializa firebase
  await Firebase.initializeApp();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      // Remove the debug banner
      debugShowCheckedModeBanner: true, //que es
      title: 'Ejemplo FIrestore',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   
  //controladores para los campos de entrada
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  //se crea una instancia de la coleccion products en firestore
  final CollectionReference _productss = FirebaseFirestore.instance.collection('products');

  /*esta funcion es llamada cuando el boton flotante o el boton de editar son presionados
    agrega un elemento a la coleccion en firestore si:
    documentSnapshot es != null entonces actualiza un elemento existente
    de lo contrario agrega un elemento a la coleccion
    documentSnapshot puede ser de tipo null por eso DocumentSnapshot? (?)
  */
  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {

    String action = 'create';

    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _priceController.text = documentSnapshot['price'].toString();
    }

    //ventana modal para agregar un producto
    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20, //borde superior
                left: 20, //borde izquierdo
                right: 20,//borde derecho
                //previene que el teclado se desplace al abrir el modal ademas define el borde inferior
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                //widgets para datos de entrada
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nombre'),
                ),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: _priceController,
                  decoration: const InputDecoration( labelText: 'Precio'),
                ),
                const SizedBox(
                  height: 20,
                ),

                //boton "Create" o "Update"
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'), //condicional en una linea en funcion a la accion
                  onPressed: () async {
                    final String? name = _nameController.text; //puede ser null por el ?
                    final double? price = double.tryParse(_priceController.text); //se convierte de string a double
                    
                    //si los campos no estan vacios
                    if (name != null && price != null) {
                      
                      //enviamos y guardamos los datos en firestore para  crearlos
                      if (action == 'create') {
                        await _productss.add({"name": name, "price": price});
                      }

                      //enviamos los datos para actualizarlos
                      if (action == 'update') {
                        await _productss.doc(documentSnapshot!.id).update({"name": name, "price": price});
                      }

                      //se limpian los controladores
                      _nameController.text = '';
                      _priceController.text = '';

                      //ocultamos la ventana modal despues de presionar el boton
                      Navigator.of(context).pop();
                    }
                  },
                )
              ],
            ),
          );
        });
  }

  // clase que se llama cuando se presiona el boton de borrar
  Future<void> _deleteProduct(String productId) async {

    // se elimina un elemento de la coleccion en firestore
    await _productss.doc(productId).delete();

    // muestra un mensaje de confirmacion en forma de showSnackBar
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('You have successfully deleted a product')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ejemplo Firestore'),
      ),
      // StreamBuilder para mostrar los productos
      body: StreamBuilder(
        stream: _productss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder( // se construye una lista de elementos en funcion a los elementos de la coleccion en firestore
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {

                final DocumentSnapshot documentSnapshot = streamSnapshot.data!.docs[index];
                //retorna cada elemento de la coleccion en firestore en una card (read)
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['name']),
                    subtitle: Text(documentSnapshot['price'].toString()),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        children: [
                          // boton para editar un producto (update)_
                          IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _createOrUpdate(documentSnapshot)),
                          // boton para eliminar un producto (delete)
                          IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _deleteProduct(documentSnapshot.id)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      // boton para agregar un producto (create)
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
