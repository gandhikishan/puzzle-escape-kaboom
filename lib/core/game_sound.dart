/// Sound effects emitted by the game. Kept as a plain enum so the Flame layer
/// can stay decoupled from whichever audio backend the app wires up.
enum GameSound { tap, explode, collide, win }
