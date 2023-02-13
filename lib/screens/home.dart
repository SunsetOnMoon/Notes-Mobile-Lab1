import 'dart:io';
//import 'dart:js_util';

import 'package:flutter/material.dart';
import 'notes_edit.dart';
import 'package:notes/models/note.dart';
import 'package:notes/models/notes_database.dart';
import 'package:notes/theme/note_colors.dart';

const c1 = 0xFFFDFFFC, c2 = 0xFFFF595E, c3 = 0xFF374B4A, c4 = 0xFF00B1CC, c5 = 0xFFFFD65C, c6 = 0xFFB9CACA,
    c7 = 0x80374B4A, c8 = 0x3300B1CC, c9 = 0xCCFF595E;

class Home extends StatefulWidget {
  @override
  _Home createState() => _Home();
}

class _Home extends State<Home> {
  List<Map<String, dynamic>>? notesData;
  List<Map<String, dynamic>>? duplicateNotesData = [];
  List<int> selectedNoteIds = [];
  final searchController = TextEditingController();
  //String search;
  //List<String> _filterList;
  String _query = "";
  bool _firstSearch = true;

  /*_Home() {
    searchController.addListener(() {
      if (searchController.text.isEmpty) {
        setState(() {
          _firstSearch = true;
          _query = "";
        });
      } else {
        setState(() {
          _firstSearch = false;
          _query = searchController.text;
        });
      }
    });
  }*/

  /*@override
  void initState() {
    super.initState();
    duplicateNotesData = notesData;
  }*/

  Future<List<Map<String, dynamic>>> readDatabase() async {
    try {
      NotesDatabase notesDB = NotesDatabase();
      await notesDB.initDatabase();
      List<Map> notesList = await notesDB.getAllNotes();
      await notesDB.closeDatabase();
      List<Map<String, dynamic>> notesData = List<Map<String, dynamic>>.from(notesList);
      notesData.sort((a, b) => (a['title']).compareTo(b['title']));
      return notesData;
    } catch(e) {
      print('Error retrieving notes');
      return [{}];
    }
  }

  void afterNavigatorPop() {
    setState(() {});
  }

  void handleNoteListLongPress(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == false)
        selectedNoteIds.add(id);
    });
  }

  void handleNoteListTapAfterSelect(int id) {
    setState(() {
      if (selectedNoteIds.contains(id) == true)
        selectedNoteIds.remove(id);
    });
  }

  void handleDelete() async {
    try {
      NotesDatabase notesDB = NotesDatabase();
      await notesDB.initDatabase();
      for (int id in selectedNoteIds) {
        int result = await notesDB.deleteNote(id);
      }
      await notesDB.closeDatabase();
    } catch (e) {
    } finally {
      setState(() {
        selectedNoteIds = [];
      });
    }
  }

  void handleSearch(String query) {
    /*List<Map<String, dynamic>> resultNotes = [];
    for (var note in notesData!) {
      if (note['content'].contains(searchController.text) || (note['title'].contains(searchController.text))) {
        resultNotes.add(note);
      }
      setState(() {
        notesData = resultNotes;
      });
    }
    AllNoteLists(resultNotes, selectedNoteIds,
      afterNavigatorPop,
      handleNoteListLongPress,
      handleNoteListTapAfterSelect);*/
    List<Map<String, dynamic>> searchedNotesList = [];
    searchedNotesList.addAll(notesData!);
    if (query.isNotEmpty) {
      List<Map<String, dynamic>> searchedNotesData = [];
      searchedNotesList.forEach((element) {
        if ((element['content'].contains(query)) || (element['title'].contains(query))) {
          searchedNotesData.add(element);
        }
      });
      print(searchedNotesData);
      setState(() {
        duplicateNotesData?.clear();
        duplicateNotesData!.addAll(searchedNotesData);
      });
      return;
    } else {
      setState(() {
        duplicateNotesData!.clear();
        duplicateNotesData?.addAll(notesData!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes',
      home: Scaffold(
        backgroundColor: Color(c6),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color(c2),
          brightness: Brightness.dark,

          title: Container(
            width: double.infinity,
            height: 40,
            color: Colors.white,
            child: Center(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Notes",
                  icon: Icon(Icons.search),
                ),
                onChanged: (value) {
                  handleSearch(value);
                },
                controller: searchController,
              ),
            ),
          ),
          /*title: Text(
            'Notes',
            style: TextStyle(
              color: const Color(c5),
            ),
          ),*/

          actions: [
           /* IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: SearchDelegate(),
                );
              },
            ),*/
            (selectedNoteIds.length > 0?
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: const Color(c1),
                ),
                tooltip: 'Delete',
                onPressed: () => handleDelete(),
              ) :
              Container()
            ),
          ],
        ),

        floatingActionButton: FloatingActionButton(
          child: const Icon(
            Icons.add,
            color: const Color(c5),
          ),
          tooltip: 'New note',
          backgroundColor: const Color(c4),
          onPressed: () {
            Navigator.push(
                context,
            MaterialPageRoute(builder: (context) => NotesEdit(['new', {}])),
            ).then((value) => {setState(() {
            })});
          },
        ),
        body: FutureBuilder(
            future: readDatabase(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                if (duplicateNotesData!.isNotEmpty && (snapshot.data?.length != duplicateNotesData?.length)) {
                  notesData = duplicateNotesData;
                }
                else {
                  notesData = snapshot.data;
                }
                return Stack(
                  children: <Widget>[
                    // Display Notes
                    AllNoteLists(
                      //snapshot.data,
                      notesData,
                      selectedNoteIds,
                      afterNavigatorPop,
                      handleNoteListLongPress,
                      handleNoteListTapAfterSelect,
                    ),
                  ],
                );
              } else if (snapshot.hasError) {
                print('Error reading database');
                exit(1);
              } else {
                return Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Color(c3),
                  ),
                );
              }
            }
        ),
      ),
    );
  }
}

class AllNoteLists extends StatelessWidget {
  final data;
  final selectedNoteIds;
  final afterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  AllNoteLists(
      this.data,
      this.selectedNoteIds,
      this.afterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        itemCount: data.length,
        itemBuilder: (context, index) {
          dynamic item = data[index];
          return DisplayNotes(
            item,
            selectedNoteIds,
            (selectedNoteIds.contains(item['id']) == false? false: true),
            afterNavigatorPop,
            handleNoteListLongPress,
            handleNoteListTapAfterSelect,
          );
        }
    );
  }
}

class DisplayNotes extends StatelessWidget {
  final notesData;
  final selectedNoteIds;
  final selectedNote;
  final callAfterNavigatorPop;
  final handleNoteListLongPress;
  final handleNoteListTapAfterSelect;

  DisplayNotes(
      this.notesData,
      this.selectedNoteIds,
      this.selectedNote,
      this.callAfterNavigatorPop,
      this.handleNoteListLongPress,
      this.handleNoteListTapAfterSelect,
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      child: Material(
        elevation: 1,
        color: (selectedNote == false? Color(c1): Color(c8)),
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(5.0),
        child: InkWell(
          onTap: () {
            if (selectedNote == false) {
              if (selectedNoteIds.length == 0) {
                // Go to edit screen to update notes
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => NotesEdit(['update', notesData])),
                ).then((dynamic value) => {
                  callAfterNavigatorPop()
                });
              }
              else {
                handleNoteListLongPress(notesData['id']);
              }
            }
            else {
              handleNoteListTapAfterSelect(notesData['id']);
            }
          },

          onLongPress: () {
            handleNoteListLongPress(notesData['id']);
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: (selectedNote == false?
                          Color(NoteColors[notesData['noteColor']]!['b']!):
                          Color(c9)
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(10),
                          child: (
                              selectedNote == false?
                              Text(
                                notesData['title'][0],
                                style: TextStyle(
                                  color: Color(c1),
                                  fontSize: 21,
                                ),
                              ):
                              Icon(
                                Icons.check,
                                color: Color(c1),
                                size: 21,
                              )
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  flex: 5,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children:<Widget>[
                      Text(
                        notesData['title'] != null? notesData['title']: "",
                        style: TextStyle(
                          color: Color(c3),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      Container(
                        height: 3,
                      ),

                      Text(
                        notesData['content'] != null? notesData['content'].split('\n')[0]: "",
                        style: TextStyle(
                          color: Color(c7),
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



/*class CustomSearch extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override buildResults(BuildContext context) {
    return StreamBuilder(
        stream: InheritedBlocs.of(context).searchBloc.searchResults,
        builder: builder)
  }


}*/