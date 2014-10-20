module dau.state;

import std.container : SList;
import dau.input;
import dau.graphics.spritebatch;

/// Generic behavioral state
class State(T) {
  /// called once whenever the state becomes active (pushed to top or state above is popped)
  void enter(T object) { }
  /// called once whenever the state becomes inactive (popped or new state pushed above)
  void exit(T object) { }
  /// called every frame before drawing
  void update(T object, float time, InputManager input) { }
  /// called every frame between screen clear and screen flip
  void draw(T object, SpriteBatch sb) { }

  private bool _active;
}

/// State stack for managing states
class StateMachine(T) {
  @property auto currentState() { return _stateStack.front; }

  /// place a new state on the state stack
  void pushState(State!T state) {
    _stateStack.insertFront(state);
  }

  /// remove the current state
  void popState() {
    currentState._active = false;
    _stateStack.removeFront;
  }

  /// pop the current state (if there is a current state) and push a new state
  void setState(State!T state) {
    if (!_stateStack.empty) {
      _prevState = currentState;
      popState();
    }
    pushState(state);
  }

  void update(T object, float time, InputManager input) {
    if (!currentState._active) { // call enter() is state is returning to activity
      if (_prevState !is null) {
        _prevState.exit(object);
      }
      currentState.enter(object);
      currentState._active = true;
    }
    currentState.update(object, time, input);
  }

  void draw(T object, SpriteBatch sb) {
    currentState.draw(object, sb);
  }

  private:
  SList!(State!T) _stateStack;
  State!T _prevState;
}