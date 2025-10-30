import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '3x3 Sudoku Solver',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const SudokuGameScreen(),
    );
  }
}

class SudokuGameScreen extends StatefulWidget {
  const SudokuGameScreen({super.key});

  @override
  State<SudokuGameScreen> createState() => _SudokuGameScreenState();
}

class _SudokuGameScreenState extends State<SudokuGameScreen> {
  // 9x9 grid to store the sudoku values (0 means empty)
  List<List<int>> grid = List.generate(9, (_) => List.generate(9, (_) => 0));

  // Track which cells are pre-filled (for styling)
  List<List<bool>> isFixed = List.generate(
    9,
    (_) => List.generate(9, (_) => false),
  );

  // Track validation state
  bool isValid = true;
  String message = '';

  // Track selected cell
  int? selectedRow;
  int? selectedCol;

  // Focus node for keyboard input
  final FocusNode _focusNode = FocusNode();

  // Toggle solve state
  bool isSolved = false;
  List<List<int>> originalGrid = List.generate(
    9,
    (_) => List.generate(9, (_) => 0),
  );
  List<List<bool>> originalFixed = List.generate(
    9,
    (_) => List.generate(9, (_) => false),
  );

  // Difficulty selection
  double _preFilledCount = 30.0; // Default: 30 pre-filled squares
  bool _showDifficultySelector = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _generatePuzzle() {
    // Simple 9x9 sudoku puzzle (partial for demonstration)
    setState(() {
      grid = [
        [5, 3, 0, 0, 7, 0, 0, 0, 0],
        [6, 0, 0, 1, 9, 5, 0, 0, 0],
        [0, 9, 8, 0, 0, 0, 0, 6, 0],
        [8, 0, 0, 0, 6, 0, 0, 0, 3],
        [4, 0, 0, 8, 0, 3, 0, 0, 1],
        [7, 0, 0, 0, 2, 0, 0, 0, 6],
        [0, 6, 0, 0, 0, 0, 2, 8, 0],
        [0, 0, 0, 4, 1, 9, 0, 0, 5],
        [0, 0, 0, 0, 8, 0, 0, 7, 9],
      ];

      // Mark pre-filled cells as fixed
      isFixed = List.generate(
        9,
        (row) => List.generate(9, (col) => grid[row][col] != 0),
      );

      message =
          'Fill in the missing numbers (1-9)! Click a cell and press a number key.';
      isValid = true;
      selectedRow = null;
      selectedCol = null;
      isSolved = false;

      // Store original state for toggle functionality
      _storeOriginalState();
    });
  }

  void _resetGame() {
    setState(() {
      grid = List.generate(9, (_) => List.generate(9, (_) => 0));
      isFixed = List.generate(9, (_) => List.generate(9, (_) => false));
      message =
          'Enter numbers 1-9 to create a valid Sudoku! Click a cell and press a number key.';
      isValid = true;
      selectedRow = null;
      selectedCol = null;
      isSolved = false;

      // Store original state for toggle functionality
      _storeOriginalState();
    });
  }

  void _startNewGame() {
    _startNewGameWithDifficulty(_preFilledCount.toInt());
  }

  void _startNewGameWithDifficulty(int preFilledCount) {
    setState(() {
      // Reset solve state first
      isSolved = false;
      selectedRow = null;
      selectedCol = null;
      _showDifficultySelector = false;

      // Generate a complete solved puzzle first
      grid = _generateCompletePuzzle();

      // Remove numbers to create the desired difficulty
      _createPuzzleWithDifficulty(preFilledCount);

      // Mark pre-filled cells as fixed
      isFixed = List.generate(
        9,
        (row) => List.generate(9, (col) => grid[row][col] != 0),
      );

      String difficultyName = _getDifficultyName(preFilledCount);
      message =
          'New $difficultyName game started! ($preFilledCount pre-filled squares)';
      isValid = true;

      // Store original state for toggle functionality
      _storeOriginalState();
    });
  }

  List<List<int>> _generateCompletePuzzle() {
    // Start with a base complete solution
    List<List<int>> completePuzzle = [
      [5, 3, 4, 6, 7, 8, 9, 1, 2],
      [6, 7, 2, 1, 9, 5, 3, 4, 8],
      [1, 9, 8, 3, 4, 2, 5, 6, 7],
      [8, 5, 9, 7, 6, 1, 4, 2, 3],
      [4, 2, 6, 8, 5, 3, 7, 9, 1],
      [7, 1, 3, 9, 2, 4, 8, 5, 6],
      [9, 6, 1, 5, 3, 7, 2, 8, 4],
      [2, 8, 7, 4, 1, 9, 6, 3, 5],
      [3, 4, 5, 2, 8, 6, 1, 7, 9],
    ];

    // Apply some random transformations to create variation
    _shufflePuzzle(completePuzzle);

    return completePuzzle;
  }

  void _shufflePuzzle(List<List<int>> puzzle) {
    var random = DateTime.now().millisecondsSinceEpoch;

    // Swap some rows within the same 3x3 block
    for (int block = 0; block < 3; block++) {
      if (random % 2 == 0) {
        int row1 = block * 3 + (random % 3);
        int row2 = block * 3 + ((random + 1) % 3);
        if (row1 != row2) {
          List<int> temp = puzzle[row1];
          puzzle[row1] = puzzle[row2];
          puzzle[row2] = temp;
        }
      }
      random = random ~/ 2;
    }
  }

  void _createPuzzleWithDifficulty(int preFilledCount) {
    // Get all cell positions
    List<List<int>> allPositions = [];
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        allPositions.add([row, col]);
      }
    }

    // Shuffle positions randomly
    allPositions.shuffle();

    // Calculate how many cells to remove
    int cellsToRemove = 81 - preFilledCount;

    // Remove numbers from random positions
    for (int i = 0; i < cellsToRemove && i < allPositions.length; i++) {
      int row = allPositions[i][0];
      int col = allPositions[i][1];
      grid[row][col] = 0;
    }
  }

  String _getDifficultyName(int preFilledCount) {
    if (preFilledCount >= 50) return 'Very Easy';
    if (preFilledCount >= 35) return 'Easy';
    if (preFilledCount >= 25) return 'Medium';
    if (preFilledCount >= 17) return 'Hard';
    return 'Expert';
  }

  Widget _buildDifficultyPreset(String name, int count) {
    bool isSelected = _preFilledCount.toInt() == count;
    return InkWell(
      onTap: () {
        setState(() {
          _preFilledCount = count.toDouble();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade600 : Colors.blue.shade100,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(
            color: isSelected ? Colors.blue.shade800 : Colors.blue.shade300,
          ),
        ),
        child: Text(
          name,
          style: TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  void _storeOriginalState() {
    // Deep copy current grid and fixed states
    originalGrid = List.generate(
      9,
      (row) => List.generate(9, (col) => grid[row][col]),
    );
    originalFixed = List.generate(
      9,
      (row) => List.generate(9, (col) => isFixed[row][col]),
    );
  }

  void _updateCell(int row, int col, int value) {
    if (isFixed[row][col]) return;

    setState(() {
      grid[row][col] = value;
      _validateGrid();

      // Store state after manual changes (only if not currently solved)
      if (!isSolved) {
        _storeOriginalState();
      }
    });
  }

  void _validateGrid() {
    // Check if the current state is valid
    isValid = _isValidSudoku();

    if (_isComplete() && isValid) {
      message = '🎉 Congratulations! Puzzle solved!';
    } else if (!isValid) {
      message = '❌ Invalid solution - check for duplicates!';
    } else {
      message = 'Keep going! Fill in the missing numbers.';
    }
  }

  bool _isValidSudoku() {
    // Check rows
    for (int row = 0; row < 9; row++) {
      Set<int> seen = {};
      for (int col = 0; col < 9; col++) {
        int value = grid[row][col];
        if (value != 0) {
          if (seen.contains(value)) return false;
          seen.add(value);
        }
      }
    }

    // Check columns
    for (int col = 0; col < 9; col++) {
      Set<int> seen = {};
      for (int row = 0; row < 9; row++) {
        int value = grid[row][col];
        if (value != 0) {
          if (seen.contains(value)) return false;
          seen.add(value);
        }
      }
    }

    // Check 3x3 subgrids
    for (int boxRow = 0; boxRow < 3; boxRow++) {
      for (int boxCol = 0; boxCol < 3; boxCol++) {
        Set<int> seen = {};
        for (int row = boxRow * 3; row < boxRow * 3 + 3; row++) {
          for (int col = boxCol * 3; col < boxCol * 3 + 3; col++) {
            int value = grid[row][col];
            if (value != 0) {
              if (seen.contains(value)) return false;
              seen.add(value);
            }
          }
        }
      }
    }

    return true;
  }

  bool _isComplete() {
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (grid[row][col] == 0) return false;
      }
    }
    return true;
  }

  void _handleKeyPress(KeyEvent event) {
    if (selectedRow == null || selectedCol == null) return;
    if (isFixed[selectedRow!][selectedCol!]) return;

    if (event is KeyDownEvent) {
      String key = event.logicalKey.keyLabel;
      int? value;

      // Handle number keys 1-9
      if (key.length == 1 && '123456789'.contains(key)) {
        value = int.parse(key);
      }
      // Handle Delete/Backspace to clear cell
      else if (event.logicalKey == LogicalKeyboardKey.delete ||
          event.logicalKey == LogicalKeyboardKey.backspace) {
        value = 0;
      }

      if (value != null) {
        _updateCell(selectedRow!, selectedCol!, value);
      }
    }
  }

  void _solvePuzzle() {
    if (isSolved) {
      // Revert to original state
      setState(() {
        grid = List.generate(
          9,
          (row) => List.generate(9, (col) => originalGrid[row][col]),
        );
        isFixed = List.generate(
          9,
          (row) => List.generate(9, (col) => originalFixed[row][col]),
        );
        isSolved = false;
        _validateGrid();
        message = 'Puzzle reverted to original state!';
      });
    } else {
      // Store current state before solving
      _storeOriginalState();

      // Create a copy of the current grid for solving
      List<List<int>> solvedGrid = List.generate(
        9,
        (row) => List.generate(9, (col) => grid[row][col]),
      );

      if (_solveSudoku(solvedGrid)) {
        setState(() {
          grid = solvedGrid;
          // Don't change isFixed - keep original pre-filled cells marked
          isSolved = true;
          _validateGrid();
          message = '🤖 Puzzle solved automatically! Click again to revert.';
        });
      } else {
        setState(() {
          message = '❌ No solution exists for this puzzle!';
          isValid = false;
        });
      }
    }
  }

  bool _solveSudoku(List<List<int>> puzzle) {
    // Find the next empty cell
    for (int row = 0; row < 9; row++) {
      for (int col = 0; col < 9; col++) {
        if (puzzle[row][col] == 0) {
          // Try numbers 1-9
          for (int num = 1; num <= 9; num++) {
            if (_isValidMove(puzzle, row, col, num)) {
              puzzle[row][col] = num;

              // Recursively solve the rest
              if (_solveSudoku(puzzle)) {
                return true;
              }

              // Backtrack if this number doesn't lead to a solution
              puzzle[row][col] = 0;
            }
          }
          // If no number works, return false
          return false;
        }
      }
    }
    // If no empty cells, puzzle is solved
    return true;
  }

  bool _isValidMove(List<List<int>> puzzle, int row, int col, int num) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (puzzle[row][c] == num) return false;
    }

    // Check column
    for (int r = 0; r < 9; r++) {
      if (puzzle[r][col] == num) return false;
    }

    // Check 3x3 subgrid
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if (puzzle[r][c] == num) return false;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyPress,
      autofocus: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('9x9 Sudoku'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            IconButton(
              onPressed: _solvePuzzle,
              icon: Icon(isSolved ? Icons.undo : Icons.auto_fix_high),
              tooltip: isSolved ? 'Revert Puzzle' : 'Solve Puzzle',
            ),
            IconButton(
              onPressed: _startNewGame,
              icon: const Icon(Icons.refresh),
              tooltip: 'New Game',
            ),
            IconButton(
              onPressed: _resetGame,
              icon: const Icon(Icons.clear),
              tooltip: 'Clear Grid',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Add some top spacing
              const SizedBox(height: 16.0),

              // Status message
              Container(
                padding: const EdgeInsets.all(12.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                decoration: BoxDecoration(
                  color: isValid ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isValid ? Colors.green : Colors.red,
                    width: 2.0,
                  ),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: isValid
                        ? Colors.green.shade800
                        : Colors.red.shade800,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Sudoku Grid
              _buildSudokuGrid(),

              const SizedBox(height: 16.0),

              // Instructions
              const Text(
                'Click a cell and press number keys 1-9, or Delete/Backspace to clear',
                style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12.0),

              // Difficulty selector (when visible)
              if (_showDifficultySelector) ...[
                Container(
                  padding: const EdgeInsets.all(12.0),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Select Difficulty',
                        style: TextStyle(
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      Text(
                        'Pre-filled squares: ${_preFilledCount.toInt()}/81',
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      Text(
                        _getDifficultyName(_preFilledCount.toInt()),
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue.shade600,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      Slider(
                        value: _preFilledCount,
                        min: 0,
                        max: 70,
                        divisions: 70,
                        activeColor: Colors.blue.shade600,
                        inactiveColor: Colors.blue.shade200,
                        onChanged: (value) {
                          setState(() {
                            _preFilledCount = value;
                          });
                        },
                      ),
                      const SizedBox(height: 8.0),
                      // Preset difficulty buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildDifficultyPreset('Expert', 17),
                          _buildDifficultyPreset('Hard', 25),
                          _buildDifficultyPreset('Medium', 30),
                          _buildDifficultyPreset('Easy', 40),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showDifficultySelector = false;
                              });
                            },
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _startNewGameWithDifficulty(
                                _preFilledCount.toInt(),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Start Game'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Game control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // New Game button with difficulty selection
                  Column(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showDifficultySelector = !_showDifficultySelector;
                          });
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('NEW GAME'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(140, 50),
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      TextButton(
                        onPressed: _startNewGame,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(140, 30),
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        ),
                        child: Text(
                          'Quick Start',
                          style: TextStyle(
                            fontSize: 12.0,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Solve/Revert button
                  ElevatedButton.icon(
                    onPressed: _solvePuzzle,
                    icon: Icon(isSolved ? Icons.undo : Icons.auto_fix_high),
                    label: Text(isSolved ? 'REVERT' : 'SOLVE'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(140, 50),
                      backgroundColor: isSolved
                          ? Colors.orange.shade600
                          : Colors.green.shade600,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              // Add bottom padding to ensure scrolling space
              const SizedBox(height: 20.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSudokuGrid() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 3.0),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: List.generate(9, (row) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(9, (col) {
              return _buildCell(row, col);
            }),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    bool isSelected = selectedRow == row && selectedCol == col;
    bool hasConflict = !isValid && _hasCellConflict(row, col);

    // Determine border thickness for 3x3 subgrid divisions
    double topBorder = (row % 3 == 0) ? 2.0 : 1.0;
    double leftBorder = (col % 3 == 0) ? 2.0 : 1.0;
    double rightBorder = (col == 8 || col % 3 == 2) ? 2.0 : 1.0;
    double bottomBorder = (row == 8 || row % 3 == 2) ? 2.0 : 1.0;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedRow = row;
          selectedCol = col;
        });
      },
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.black, width: topBorder),
            left: BorderSide(color: Colors.black, width: leftBorder),
            right: BorderSide(color: Colors.black, width: rightBorder),
            bottom: BorderSide(color: Colors.black, width: bottomBorder),
          ),
          color: isSelected
              ? Colors.blue.shade100
              : hasConflict
              ? Colors.red.shade100
              : isFixed[row][col]
              ? Colors.grey.shade200
              : Colors.white,
        ),
        child: Center(
          child: Text(
            grid[row][col] == 0 ? '' : '${grid[row][col]}',
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: isFixed[row][col]
                  ? Colors.black87
                  : hasConflict
                  ? Colors.red
                  : Colors.blue.shade700,
            ),
          ),
        ),
      ),
    );
  }

  bool _hasCellConflict(int row, int col) {
    int value = grid[row][col];
    if (value == 0) return false;

    // Check row conflicts
    for (int c = 0; c < 9; c++) {
      if (c != col && grid[row][c] == value) return true;
    }

    // Check column conflicts
    for (int r = 0; r < 9; r++) {
      if (r != row && grid[r][col] == value) return true;
    }

    // Check 3x3 subgrid conflicts
    int boxRow = (row ~/ 3) * 3;
    int boxCol = (col ~/ 3) * 3;
    for (int r = boxRow; r < boxRow + 3; r++) {
      for (int c = boxCol; c < boxCol + 3; c++) {
        if ((r != row || c != col) && grid[r][c] == value) {
          return true;
        }
      }
    }

    return false;
  }
}
