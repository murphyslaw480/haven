module battle.state.performaction;

import dau.all;
import model.all;
import battle.battle;
import battle.pathfinder;
import battle.util;
import battle.system.all;
import battle.state.performcounter;
import battle.state.applyeffect;
import battle.state.applybuff;
import battle.state.deploytrap;
import battle.state.checkunitdestruction;

private enum apBarFadeDuration = 0.2f;

class PerformAction : State!Battle {
  this(Unit actor, int actionNum, Unit target) {
    _actor = actor;
    _actionNum = actionNum;
    _action = actor.getAction(actionNum);
    _target = target.tile;
  }

  this(Unit actor, int actionNum, Tile target) {
    _actor = actor;
    _actionNum = actionNum;
    _action = actor.getAction(actionNum);
    _target = target;
  }

  override {
    void start(Battle b) {
      b.disableSystem!TileHoverSystem;
      // place actor in left unit info slot, target in right
      b.lockLeftUnitInfo = false;
      b.displayUnitInfo(_actor);
      b.lockLeftUnitInfo = true;
      _tilesAffected = tilesAffected(b.map, _target, _actor, _action);
      auto unitsAffected = unitsAffected(b.map, _target, _actor, _action);

      // trigger new state once animation ends
      void delegate() onAnimationEnd = null;
      if (_action.target == UnitAction.Target.trap) {
        onAnimationEnd = delegate() {
          b.states.setState(new DeployTrap(_actor, _action, _target));
        };
      }
      else if (_action.isAttack) {
        onAnimationEnd = delegate() {
          b.states.popState();
          b.states.pushState(new CheckUnitDestruction(_actor));
          foreach(unit ; unitsAffected) {
            b.states.pushState(new PerformCounter(unit, _actor));
          }
          foreach(unit ; unitsAffected) {
            b.states.pushState(new CheckUnitDestruction(unit));
            for(int i = 0 ; i < _action.hits ; i++) {
              b.states.pushState(new ApplyEffect(_action, unit));
            }
          }
        };
      }
      else {
        onAnimationEnd = delegate() {
          foreach(unit ; unitsAffected) {
            b.states.setState(new ApplyBuff(_action, unit));
          }
        };
      }
      // play animation and sound
      _actor.playAnimation("action%d".format(_actionNum), onAnimationEnd);
      _effectAnim = _actor.getActionAnimation(_actionNum);
      _actor.getActionSound(_actionNum).play();

      // drain ap and animate ap change
      auto ui = b.unitInfoFor(_actor);
      int prevAp = _actor.ap;
      _actor.consumeAp(_action.apCost);
      b.activePlayer.consumeCommandPoints(1);
      b.updateBattlePanel();
      ui.animateApChange(prevAp, _actor.ap, apBarFadeDuration);
    }

    void update(Battle b, float time, InputManager input) {
      _effectAnim.update(time);
    }

    void draw(Battle b, SpriteBatch sb) {
      foreach(tile ; _tilesAffected) {
        sb.draw(_effectAnim, tile.center);
      }
    }
  }

  private:
  Unit _actor;
  Tile _target;
  Tile[] _tilesAffected;
  const UnitAction _action;
  int _actionNum;
  Animation _effectAnim;
}
