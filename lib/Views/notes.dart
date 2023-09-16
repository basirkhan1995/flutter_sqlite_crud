import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqlite_flutter_crud/JsonModels/note_model.dart';
import 'package:sqlite_flutter_crud/SQLite/sqlite.dart';
import 'package:sqlite_flutter_crud/Views/create_note.dart';

class Notes extends StatefulWidget {
  const Notes({super.key});

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  late DatabaseHelper handler;
  late Future<List<NoteModel>> notes;
  final db = DatabaseHelper();

  final title = TextEditingController();
  final content = TextEditingController();

  @override
  void initState() {
    handler = DatabaseHelper();
    notes = handler.getNotes();

    handler.initDB().whenComplete(() {
      notes = getAllNotes();
    });
    super.initState();
  }

  Future<List<NoteModel>> getAllNotes() {
    return handler.getNotes();
  }

  //Refresh method
  Future<void> _refresh() async {
    setState(() {
      notes = getAllNotes();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Notes"),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            //We need call refresh method after a new note is created
            //Now it works properly
            //We will do delete now
            Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const CreateNote()))
                .then((value) {
              if (value) {
                //This will be called
                _refresh();
              }
            });
          },
          child: const Icon(Icons.add),
        ),

        //First we are going to show notes
        //Here we go we are done to show the notes,
        //Now we will create a new note

        //We need a method to reload notes on every new notes that creates

        body: FutureBuilder<List<NoteModel>>(
          future: notes,
          builder:
              (BuildContext context, AsyncSnapshot<List<NoteModel>> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            } else if (snapshot.hasData && snapshot.data!.isEmpty) {
              return const Center(child: Text("No data"));
            } else if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            } else {
              final items = snapshot.data ?? <NoteModel>[];
              return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      subtitle: Text(DateFormat("yMd")
                          .format(DateTime.parse(items[index].createdAt))),
                      title: Text(items[index].noteTitle),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          //We call the delete method in database helper
                          db.deleteNote(items[index].noteId!).whenComplete(() {
                            //After success delete , refresh notes
                            //Done, next step is update notes
                            _refresh();
                          });
                        },
                      ),
                      onTap: () {
                        //When we click on note
                        setState(() {
                          title.text = items[index].noteTitle;
                          content.text = items[index].noteContent;
                        });
                        showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                actions: [
                                  Row(
                                    children: [
                                      TextButton(
                                        onPressed: () {
                                          //Now update method
                                          db
                                              .updateNote(
                                                  title.text,
                                                  content.text,
                                                  items[index].noteId)
                                              .whenComplete(() {
                                            //After update, note will refresh
                                            _refresh();
                                            Navigator.pop(context);
                                          });
                                        },
                                        child: const Text("Update"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Cancel"),
                                      ),
                                    ],
                                  ),
                                ],
                                title: const Text("Update note"),
                                content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      //We need two textfield
                                      TextFormField(
                                        controller: title,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Title is required";
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          label: Text("Title"),
                                        ),
                                      ),
                                      TextFormField(
                                        controller: content,
                                        validator: (value) {
                                          if (value!.isEmpty) {
                                            return "Content is required";
                                          }
                                          return null;
                                        },
                                        decoration: const InputDecoration(
                                          label: Text("Content"),
                                        ),
                                      ),
                                    ]),
                              );
                            });
                      },
                    );
                  });
            }
          },
        ));
  }
}
