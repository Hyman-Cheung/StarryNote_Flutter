//======================================================================================================
// db_helper.dart
//======================================================================================================

/*
  It contains the database helper class (DBHelper), 
  which is responsible for interacting with the SQLite database in your Flutter app. 
  Its main purpose is to manage all database operations such as 
  inserting, retrieving, updating, and deleting data for various entities.
*/

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../Note_Hierarchy_Structure/Data_Model/Notebook_DataModel.dart';
import '../Note_Hierarchy_Structure/Data_Model/Page_DataModel.dart';
import '../Note_Hierarchy_Structure/Data_Model/Section_DataModel.dart';
import '../RelationList/Data_Model/node_and_edge.dart';
import '../RelationList/Data_Model/relation_model.dart';

class DBHelper {
  static Database? _database;
  // Table Names:
  static final taskTableName = 'task_table';
  static final notificationTableName = 'notification_table';
  static final taskReviewTableName = 'task_review_table';
  // Singleton pattern for DBHelper
  static Future<Database> getDatabase() async {
    if (_database != null) {
      return _database!;
    }

    // Deleting the old database if necessary
    // final delpath = join(await getDatabasesPath(), 'my_database.db');
    // await deleteDatabase(delpath);  // This will delete the old database

    // Initialize database
    String path = join(await getDatabasesPath(), 'my_database.db');
    _database = await openDatabase(path, version: 2, onCreate: _createDb);
    return _database!;
  }

  // Create tables for Notebooks, Sections, Pages
  static Future<void> _createDb(Database db, int version) async {
    // Note hierarachy related
    await db.execute('''
      CREATE TABLE notebooks (
        notebook_id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        create_at TEXT NOT NULL,
        user_id INTEGER DEFAULT NULL,
        last_editTime TEXT NOT NULL,
        relations TEXT DEFAULT NULL,
        studyList TEXT DEFAULT NULL
      )
    '''); // remarks: user_id is DEFAULT NULL as UAC is not yet implemented,
    // change to NOT NULL when implemented.

    await db.execute('''
      CREATE TABLE sections (
        sectionId TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createAt TEXT NOT NULL,
        lastEditTime TEXT NOT NULL,
        notebookId INTEGER NOT NULL,
        relations INTEGER DEFAULT NULL,
        FOREIGN KEY (notebookId) REFERENCES notebooks (notebook_id)
      )
    ''');

    await db.execute('''
      CREATE TABLE pages (
        pageId TEXT PRIMARY KEY,
        title TEXT,
        createAt TEXT,
        lastEditTime TEXT,
        sectionId INTEGER NOT NULL,
        notebookId INTEGER NOT NULL,
        relations INTEGER DEFAULT NULL,
        questionList TEXT DEFAULT NULL,
        FOREIGN KEY (sectionId) REFERENCES sections (sectionId),
        FOREIGN KEY (notebookId) REFERENCES notebooks (notebook_id)
      )
    ''');

    // Relation list related
    await db.execute('''
      CREATE TABLE relation (
        relationID INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        createAt TIMESTAMP,
        lastEditTime TIMESTAMP
      );
    ''');

    await db.execute('''
      CREATE TABLE mind_map_nodes (
        id INTEGER PRIMARY KEY,
        relationID INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        position_x REAL NOT NULL,
        position_y REAL NOT NULL,
        notebookId INTEGER,
        sectionId TEXT,
        pageId TEXT,             
        labelId INTEGER,
        FOREIGN KEY (notebookId) REFERENCES notebooks(notebook_id) ON DELETE SET NULL,
        FOREIGN KEY (sectionId) REFERENCES sections(sectionID) ON DELETE SET NULL,
        FOREIGN KEY (pageId) REFERENCES pages(pageID) ON DELETE SET NULL,
        FOREIGN KEY (labelId) REFERENCES label(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE mind_map_edges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        relationID INTEGER,
        fromID INTEGER,
        toID INTEGER,
        FOREIGN KEY (relationID) REFERENCES relation (relationID)
        FOREIGN KEY (fromID) REFERENCES mind_map_nodes (id) ON DELETE CASCADE,
        FOREIGN KEY (toID) REFERENCES mind_map_nodes (id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
        CREATE TABLE label_table (
          id INTEGER PRIMARY KEY,
          labelType TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          position_x REAL NOT NULL,
          position_y REAL NOT NULL,
          priority TEXT NOT NULL,
          createAt TEXT NOT NULL,
          lastEditTime TEXT NOT NULL,
          pageId TEXT NOT NULL,
          sectionId TEXT NOT NULL,
          notebookId INTEGER NOT NULL,
          FOREIGN KEY (pageId) REFERENCES pages (pageId) ON DELETE CASCADE,
          FOREIGN KEY (sectionId) REFERENCES sections (sectionId),
          FOREIGN KEY (notebookId) REFERENCES notebooks (notebook_id)
        )
      ''');

    // Task Table:
    await db.execute('''
    CREATE TABLE $taskTableName (
      id INTEGER PRIMARY KEY,
      taskDate TEXT NOT NULL,
      taskTime TEXT NOT NULL,
      taskName TEXT NOT NULL,
      taskVenue TEXT NOT NULL,
      taskDescription TEXT NOT NULL,
      taskPriority INTEGER NOT NULL,
      isRepeating INTEGER NOT NULL,
      createAt TEXT NOT NULL,
      lastEditTime TEXT NOT NULL
    )
    ''');

    // Notification Table:
    await db.execute('''
    CREATE TABLE $notificationTableName (
      id INTEGER PRIMARY KEY,
      notificationTitle TEXT NOT NULL,
      notificationBody TEXT NOT NULL,
      scheduledDate TEXT NOT NULL,
      intervalType TEXT,
      createAt TEXT NOT NULL,
      lastEditTime TEXT NOT NULL,
      taskId INTEGER NOT NULL,
      FOREIGN KEY (taskId) REFERENCES $taskTableName(id) ON DELETE CASCADE
    )
    ''');
    // Task review table:
    await db.execute('''
        CREATE TABLE $taskReviewTableName (
          id INTEGER PRIMARY KEY,
          createAt TEXT NOT NULL,
          lastEditTime TEXT NOT NULL,
          taskId INTEGER NOT NULL,
          labelId INTEGER NOT NULL,
          FOREIGN KEY (taskId) REFERENCES $taskTableName(id) ON DELETE CASCADE
          FOREIGN KEY (labelId) REFERENCES label_table(id) ON DELETE CASCADE
        )
      ''');
    debugPrint("Tables created successfully!");
  }

  /* Database method for note hierarchy structure */

  // Insert notebook
  Future<int> insertNotebook(Notebook notebook) async {
    final db = await getDatabase();

    // Get the count of notebook
    final notebooks = await db.query('notebooks');

    notebook.notebook_id =
        notebooks.length + 1; // assign notebook id automatically

    return await db.insert(
      'notebooks',
      notebook.toMap(), // Convert Notebook to Map before inserting
      conflictAlgorithm: ConflictAlgorithm.replace, // Prevent duplicate IDs
    );
  }

  // Insert section with generated ID
  Future<int> insertSection(Section section) async {
    final db = await getDatabase();

    // Get the count of sections for this notebook
    final sections = await db.query(
      'sections',
      where: 'notebookId = ?',
      whereArgs: [section.notebookId],
    );

    // Generate the new section ID in the format "N$S@"
    final newSectionId = 'N${section.notebookId}S${sections.length + 1}';
    section.sectionId = newSectionId; // Set the generated section ID

    // Insert the section
    return await db.insert(
      'sections',
      section.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Insert page with generated ID
  Future<void> insertPage(NotePage page) async {
    final db = await getDatabase();

    // Get the count of pages for this section
    final pages = await db.query(
      'pages',
      where: 'sectionId = ?',
      whereArgs: [page.sectionId],
    );

    // Get the notebook ID from the section
    final section = await db.query(
      'sections',
      where: 'sectionId = ?',
      whereArgs: [page.sectionId],
    );
    page.notebookId = int.parse(section[0]['notebookId'].toString());

    // Generate the new page ID in the format "N$S@P#"
    final newPageId = '${page.sectionId}P${pages.length + 1}';
    page.pageId = newPageId; // Set the generated page ID

    // Insert the page
    await db.insert(
      'pages',
      page.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Get all notebooks
  Future<List<Notebook>> getNotebooks() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('notebooks');
    return List.generate(maps.length, (i) {
      return Notebook(
        notebook_id: maps[i]['notebook_id'],
        title: maps[i]['title'],
        create_at: DateTime.parse(maps[i]['create_at']),
        // user_id: maps[i]['user_id'],
        last_editTime: DateTime.parse(maps[i]['last_editTime']),
        // relations: List.from(maps[i]['relations']),
        // studyList: List.from(maps[i]['studyList']),
      );
    });
  }

  // get notebook title by id
  Future<String> readNotebookNamebyId(int id) async {
    final db = await getDatabase();

    // Query the notebook table to get the notebook with the given id
    final List<Map<String, dynamic>> maps = await db.query(
      'notebooks',
      where: 'notebook_id = ?',
      whereArgs: [id],
    );

    // If a notebook with the given id exists, return its title
    if (maps.isNotEmpty) {
      return maps[0]['title']; // Return the title of the notebook
    } else {
      throw Exception(
          'Notebook not found'); // Handle the case where the notebook is not found
    }
  }

  // Get sections by notebook id
  Future<List<Section>> getSectionsFromNotebookId(int notebookId) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db
        .query('sections', where: 'notebookId = ?', whereArgs: [notebookId]);
    return List.generate(maps.length, (i) {
      return Section(
        sectionId: maps[i]['sectionId'],
        title: maps[i]['title'],
        createAt: DateTime.parse(maps[i]['createAt']),
        lastEditTime: DateTime.parse(maps[i]['lastEditTime']),
        notebookId: maps[i]['notebookId'],
        // relations: maps[i]['relations'],
      );
    });
  }

  // Get section by section id
  Future<Section> getSectionsFromId(String id) async {
    final db = await getDatabase();

    // Query the page table to get the page with the given id
    final List<Map<String, dynamic>> maps = await db.query(
      'sections',
      where: 'sectionId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Section.fromMap(maps.first);
    } else {
      throw Exception(
          'Page not found'); // Handle the case where the page is not found
    }
  }

  // get section title by id
  Future<String> readSectionNamebyId(String id) async {
    final db = await getDatabase();

    // Query the section table to get the section with the given id
    final List<Map<String, dynamic>> maps = await db.query(
      'sections',
      where: 'sectionId = ?',
      whereArgs: [id],
    );

    // If a section with the given id exists, return its title
    if (maps.isNotEmpty) {
      return maps[0]['title']; // Return the title of the section
    } else {
      throw Exception(
          'Section not found'); // Handle the case where the section is not found
    }
  }

  // Get pages by section id along with notebook id
  Future<List<NotePage>> getPagesFromSectionId(String sectionId) async {
    final db = await getDatabase();

    // SQL Query with JOIN to fetch pages and notebookId
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT pages.pageId, pages.title, pages.createAt, pages.lastEditTime, pages.sectionId, sections.notebookId
      FROM pages
      JOIN sections ON pages.sectionId = sections.sectionId
      WHERE pages.sectionId = ?
    ''', [sectionId]);

    return List.generate(maps.length, (i) {
      return NotePage(
        pageId: maps[i]['pageId'],
        title: maps[i]['title'],
        createAt: DateTime.parse(maps[i]['createAt']),
        lastEditTime: DateTime.parse(maps[i]['lastEditTime']),
        sectionId: maps[i]['sectionId'],
        notebookId: maps[i]['notebookId'], // Fetch and include the notebookId
      );
    });
  }

  // Get page by page id
  Future<NotePage> getPageFromId(String id) async {
    final db = await getDatabase();

    // Query the page table to get the page with the given id
    final List<Map<String, dynamic>> maps = await db.query(
      'pages',
      where: 'pageId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return NotePage.fromMap(maps.first);
    } else {
      throw Exception(
          'Page not found'); // Handle the case where the page is not found
    }
  }

  // get page title by id
  Future<String> readPageNamebyId(String id) async {
    final db = await getDatabase();

    // Query the page table to get the page with the given id
    final List<Map<String, dynamic>> maps = await db.query(
      'pages',
      where: 'pageId = ?',
      whereArgs: [id],
    );

    // If a page with the given id exists, return its title
    if (maps.isNotEmpty) {
      return maps[0]['title']; // Return the title of the page
    } else {
      throw Exception(
          'Page not found'); // Handle the case where the page is not found
    }
  }

  // Delete notebook by id (Deletes sections and pages related to it)
  Future<void> deleteNotebook(int notebookId) async {
    final db = await getDatabase();
    // Delete all pages in sections belonging to the notebook
    await db.delete('pages',
        where:
            'sectionId IN (SELECT sectionId FROM sections WHERE notebookId = ?)',
        whereArgs: [notebookId]);

    // Delete all sections in the notebook
    await db
        .delete('sections', where: 'notebookId = ?', whereArgs: [notebookId]);

    // Finally, delete the notebook
    await db
        .delete('notebooks', where: 'notebook_id = ?', whereArgs: [notebookId]);
  }

  // Delete section by id (Deletes pages related to it)
  Future<void> deleteSection(String sectionId) async {
    final db = await getDatabase();

    // Delete all pages belonging to the section
    await db.delete('pages', where: 'sectionId = ?', whereArgs: [sectionId]);

    // Finally, delete the section
    await db.delete('sections', where: 'sectionId = ?', whereArgs: [sectionId]);
  }

  // Delete page by id
  Future<void> deletePage(String pageId) async {
    final db = await getDatabase();
    await db.delete('pages', where: 'pageId = ?', whereArgs: [pageId]);
  }

  // Rename a notebook
  Future<void> renameNotebook(int notebookId, String newTitle) async {
    final db = await getDatabase();
    await db.update(
      'notebooks',
      {'title': newTitle, 'last_editTime': DateTime.now().toIso8601String()},
      where: 'notebook_id = ?',
      whereArgs: [notebookId],
    );
  }

  // Rename a section
  Future<void> renameSection(String sectionId, String newTitle) async {
    final db = await getDatabase();
    await db.update(
      'sections',
      {'title': newTitle, 'lastEditTime': DateTime.now().toIso8601String()},
      where: 'sectionId = ?',
      whereArgs: [sectionId],
    );
  }

  // Rename a page
  Future<void> renamePage(String pageId, String newTitle) async {
    final db = await getDatabase();
    await db.update(
      'pages',
      {'title': newTitle, 'lastEditTime': DateTime.now().toIso8601String()},
      where: 'pageId = ?',
      whereArgs: [pageId],
    );
  }

  /* End of note hierarachy structure */

  /* Database method for Relation List */
  // Create
  Future<int> insertRelation(Relation newRelation) async {
    final db = await getDatabase();
    // Get the count of relations
    final relations = await db.query('relation');
    newRelation.relationID = relations.length + 1; // assign id automatically
    await db.insert('relation', newRelation.toMap());
    return newRelation.relationID;
  }

  // Insert a MindMapNode into the database
  Future<int> insertMindMapNode(MindMapNode node) async {
    final db = await getDatabase();

    return db.insert(
      'mind_map_nodes',
      node.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace if the ID already exists
    );
  }

  // Insert a MindMapEdge into the database
  Future<void> insertMindMapEdge(MindMapEdge edge) async {
    final db = await getDatabase();

    await db.insert(
      'mind_map_edges',
      edge.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace if the ID already exists
    );
  }

  // Read all Relations
  Future<List<Relation>> getRelations() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('relation');

    // Convert List<Map<String, dynamic>> to List<relation>
    return List.generate(maps.length, (i) {
      return Relation.fromMap(maps[i]);
    });
  }

  // Fetch all MindMapNodes from a relation
  Future<List<MindMapNode>> getAllMindMapNodesbyRelation(int relationID) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query('mind_map_nodes',
        where: 'relationID = ?', whereArgs: [relationID], orderBy: 'id');

    return List.generate(maps.length, (i) {
      return MindMapNode.fromMap(maps[i]);
    });
  }

  // Fetch a single MindMapNode by its id
  Future<MindMapNode> getMindMapNodeById(int id) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'mind_map_nodes',
      where: 'id = ?',
      whereArgs: [id],
    );

    try {
      return MindMapNode.fromMap(maps.first);
    } catch (e) {
      throw ("node not found");
    }
  }

  // Fetch all MindMapEdges from a relation and resolve the related nodes
  Future<List<Map<String, dynamic>>> getAllMindMapEdgesbyRelation(
      int relationID) async {
    final db = await getDatabase();

    return await db.query('mind_map_edges',
        where: 'relationID = ?', whereArgs: [relationID]);
  }

  // Fetch a single MindMapEdge by its id and resolve the related nodes
  Future<MindMapEdge?> getMindMapEdgeById(int id) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> edgeMaps = await db.query(
      'mind_map_edges',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (edgeMaps.isNotEmpty) {
      var edgeMap = edgeMaps.first;

      // Fetch the fromNode and toNode by their IDs
      int fromNodeId = edgeMap['fromID'];
      int toNodeId = edgeMap['toID'];

      // Retrieve the corresponding nodes
      MindMapNode fromNode = await getMindMapNodeById(fromNodeId);
      MindMapNode toNode = await getMindMapNodeById(toNodeId);

      // Return the edge object with the resolved nodes
      return MindMapEdge(
        id: edgeMap['id'],
        relationID: edgeMap['relationID'],
        from: fromNode,
        to: toNode,
      );
    } else {
      return null; // Return null if no edge is found
    }
  }

  // Update Relation
  Future<int> updateRelation(Relation updatedRelation) async {
    final db = await getDatabase();
    return await db.update(
      'relation',
      updatedRelation.toMap(),
      where: 'relationID = ?',
      whereArgs: [updatedRelation.relationID],
    );
  }

  // Update a MindMapNode in the database
  Future<void> updateMindMapNode(MindMapNode node) async {
    final db = await getDatabase();

    // Update the node with the new values, using the id as the condition for the update
    await db.update(
      'mind_map_nodes', // Table name
      node.toMap(), // Map representation of the MindMapNode object
      where: 'id = ?', // Condition for identifying the node to update
      whereArgs: [node.id], // The id of the node to be updated
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace in case of conflicts
    );
  }

  // Update the title of a Relation
  Future<int> updateTitle(String title, int relationID) async {
    final db = await getDatabase();
    final updatedTitle = {
      'title': title,
      'lastEditTime': DateTime.now().toString(),
    };

    return await db.update(
      'relation',
      updatedTitle,
      where: 'relationID = ?',
      whereArgs: [relationID],
    );
  }

  // Delete Relation
  Future<int> deleteRelation(int relationID) async {
    final db = await getDatabase();

    // Delete all MindMapNode in the relation
    await db.delete('mind_map_nodes',
        where: 'relationID = ?', whereArgs: [relationID]);

    return await db.delete(
      'relation',
      where: 'relationID = ?',
      whereArgs: [relationID],
    );
  }

  // Delete all MindMapNodes associated with a specific notebookId and return their IDs
  Future<List<int>> deleteNodesByNotebookId(int notebookId) async {
    final db = await getDatabase();

    // Fetch the ids of the MindMapNodes that will be deleted
    final List<Map<String, dynamic>> nodesToDelete = await db.query(
      'mind_map_nodes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );

    // Extract the node ids from the result
    List<int> deletedNodeIds =
        nodesToDelete.map((node) => node['id'] as int).toList();

    // Delete the MindMapNodes associated with the specified notebookId
    await db.delete(
      'mind_map_nodes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );

    // Return the list of deleted node IDs
    return deletedNodeIds;
  }

  // Delete all MindMapNodes associated with a specific sectionId and return their IDs
  Future<List<int>> deleteNodesBySectionId(String sectionId) async {
    final db = await getDatabase();

    // Fetch the ids of the MindMapNodes that will be deleted
    final List<Map<String, dynamic>> nodesToDelete = await db.query(
      'mind_map_nodes',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
    );

    // Extract the node ids from the result
    List<int> deletedNodeIds =
        nodesToDelete.map((node) => node['id'] as int).toList();

    // Delete the MindMapNodes associated with the specified sectionId
    await db.delete(
      'mind_map_nodes',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
    );

    // Return the list of deleted node IDs
    return deletedNodeIds;
  }

  // Delete all MindMapNodes associated with a specific pageId and return their IDs
  Future<List<int>> deleteNodesByPageId(String pageId) async {
    final db = await getDatabase();

    // Fetch the ids of the MindMapNodes that will be deleted
    final List<Map<String, dynamic>> nodesToDelete = await db.query(
      'mind_map_nodes',
      where: 'pageId = ?',
      whereArgs: [pageId],
    );

    // Extract the node ids from the result
    List<int> deletedNodeIds =
        nodesToDelete.map((node) => node['id'] as int).toList();

    // Delete the MindMapNodes associated with the specified pageId
    await db.delete(
      'mind_map_nodes',
      where: 'pageId = ?',
      whereArgs: [pageId],
    );

    // Return the list of deleted node IDs
    return deletedNodeIds;
  }

  // Delete all MindMapNodes associated with a specific labelId and return their IDs
  Future<List<int>> deleteNodesByLabelId(int labelId) async {
    final db = await getDatabase();

    // Fetch the ids of the MindMapNodes that will be deleted
    final List<Map<String, dynamic>> nodesToDelete = await db.query(
      'mind_map_nodes',
      where: 'labelId = ?',
      whereArgs: [labelId],
    );

    // Extract the node ids from the result
    List<int> deletedNodeIds =
        nodesToDelete.map((node) => node['id'] as int).toList();

    // Delete the MindMapNodes associated with the specified labelId
    await db.delete(
      'mind_map_nodes',
      where: 'labelId = ?',
      whereArgs: [labelId],
    );

    // Return the list of deleted node IDs
    return deletedNodeIds;
  }

  // Delete MindMapEdges where either fromID or toID matches
  Future<void> deleteMindMapEdgeByNodes(int id) async {
    final db = await getDatabase();

    int fromID = id, toID = id;

    // Delete the edge(s) where either fromID or toID match
    await db.delete(
      'mind_map_edges',
      where: 'fromID = ? OR toID = ?',
      whereArgs: [fromID, toID],
    );
  }

  Future<void> renameNotebookNode(int notebookId, String newTitle) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'mind_map_nodes',
      where: 'notebookId = ?',
      whereArgs: [notebookId],
    );

    if (maps.isNotEmpty) {
      List<MindMapNode> nodes = List.generate(maps.length, (i) {
        return MindMapNode.fromMap(maps[i]);
      });
      for (var node in nodes) {
        node.title = newTitle;

        await db.update(
          'mind_map_nodes',
          node.toMap(),
          where: 'id = ?',
          whereArgs: [node.id],
        );
      }
    }
  }

  Future<void> renameSectionNode(String sectionId, String newTitle) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'mind_map_nodes',
      where: 'sectionId = ?',
      whereArgs: [sectionId],
    );

    if (maps.isNotEmpty) {
      List<MindMapNode> nodes = List.generate(maps.length, (i) {
        return MindMapNode.fromMap(maps[i]);
      });
      for (var node in nodes) {
        node.title = newTitle;

        await db.update(
          'mind_map_nodes',
          node.toMap(),
          where: 'id = ?',
          whereArgs: [node.id],
        );
      }
    }
  }

  Future<void> renamePageNode(String pageId, String newTitle) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'mind_map_nodes',
      where: 'pageId = ?',
      whereArgs: [pageId],
    );

    if (maps.isNotEmpty) {
      List<MindMapNode> nodes = List.generate(maps.length, (i) {
        return MindMapNode.fromMap(maps[i]);
      });
      for (var node in nodes) {
        node.title = newTitle;

        await db.update(
          'mind_map_nodes',
          node.toMap(),
          where: 'id = ?',
          whereArgs: [node.id],
        );
      }
    }
  }

  Future<void> renameLabelNode(int labelId, String newTitle) async {
    final db = await getDatabase();

    final List<Map<String, dynamic>> maps = await db.query(
      'mind_map_nodes',
      where: 'labelId = ?',
      whereArgs: [labelId],
    );

    if (maps.isNotEmpty) {
      List<MindMapNode> nodes = List.generate(maps.length, (i) {
        return MindMapNode.fromMap(maps[i]);
      });
      for (var node in nodes) {
        node.title = newTitle;

        await db.update(
          'mind_map_nodes',
          node.toMap(),
          where: 'id = ?',
          whereArgs: [node.id],
        );
      }
    }
  }

  Future<int> insertMindMapNodeWithTransaction(
      MindMapNode node, Transaction txn) async {
    return txn.insert(
      'mind_map_nodes',
      node.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace if the ID already exists
    );
  }

  Future<void> updateMindMapNodeWithTransaction(
      MindMapNode node, Transaction txn) async {
    await txn.update(
      'mind_map_nodes',
      node.toMap(),
      where: 'id = ?',
      whereArgs: [node.id],
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Replace in case of conflicts
    );
  }

  Future<void> insertMindMapEdgeWithTransaction(
      MindMapEdge edge, Transaction txn) async {
    await txn.insert(
      'mind_map_edges',
      edge.toMap(),
      conflictAlgorithm:
          ConflictAlgorithm.replace, // Use replace if the ID already exists
    );
  }

  Future<void> deleteMindMapNodeWithTransaction(int id, Transaction txn) async {
    // Delete the node from the mind_map_nodes table
    await txn.delete(
      'mind_map_nodes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteMindMapEdgeByNodesWithTransaction(
      int id, Transaction txn) async {
    await txn.delete(
      'mind_map_edges',
      where: 'fromID = ? OR toID = ?',
      whereArgs: [id, id],
    );
  }

  Future<void> deleteMindMapEdgeWithTransaction(int id, Transaction txn) async {
    await txn.delete(
      'mind_map_edges',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
