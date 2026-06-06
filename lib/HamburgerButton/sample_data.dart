List<String> notebooks = ['Notebook 1', 'Notebook 2', 'Notebook 3']; // list of notebooks (demo)
List<List<String>> sections = [ // list of sections (demo)
      ['Section 1', 'Section 2', 'Section 3'], // Notebook 1 (demo)
      ['Section A', 'Section B'], // Notebook 2 (demo)
      ['Section X', 'Section Y', 'Section Z'], // Notebook 3 (demo)
  ];
  
List<List<List<String>>> pages = [ // list of pages (demo)
    [
        ['Page 1', 'Page 2'], // Notebook 1 Section 1 (demo)
        ['Page 3', 'Page 4'], // Notebook 1 Section 2 (demo)
        ['Page 5'] // Notebook 1 Section 3 (demo)
    ],
    [
        ['Page A', 'Page B'], // Notebook 2 Section A (demo)
        ['Page C'] // Notebook 2 Section B (demo)
    ],
    [
        ['Page X', 'Page Y'], // Notebook 3 Section X (demo)
        ['Page Z'], // Notebook 3 Section Y (demo)
        [] // Notebook 3 Section Z is empty (demo)
    ],
  ];