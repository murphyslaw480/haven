module battle.state.performaction;

import dau.all;
import model.all;
import battle.battle;
import battle.pathfinder;
import battle.system.all;
import battle.state.applyeffect;

class PerformAction : State!Battle {
  this(Unit actor, int actionNum, Unit target) {
    _actor = actor;
    _actionNum = actionNum;
    _action = actor.getAction(actionNum);
    _target = target;
  }

  override {
    void enter(Battle b) {
      b.disableSystem!TileHoverSystem;
      b.disableSystem!BattleCameraSystem;
      auto onAnimationEnd = delegate() {
        b.states.popState();
        for(int i = 0; i < _action.hits; ++i) {
          b.states.pushState(new ApplyEffect(_action, _target));
        }
      };
      _actor.playAnimation("action%d".format(_actionNum), onAnimationEnd);
      _effectAnim = _actor.getActionAnimation(_actionNum);
      _actor.getActionSound(_actionNum).play();
    }

    void update(Battle b, float time, InputManager input) {
      _effectAnim.update(time);
    }

    void draw(Battle b, SpriteBatch sb) {
      sb.draw(_effectAnim, _target.center);
    }

    void exit(Battle b) {
      _actor.consumeAp(_action.apCost);
    }
  }

  private:
  Unit _actor, _target;
  const UnitAction _action;
  int _actionNum;
  Animation _effectAnim;
}
