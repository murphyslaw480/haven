module gui.deploymenu;

import std.string;
import std.conv;
import dau.all;
import model.all;

private enum {
  bgName            = "gui/deploy_menu",
  buttonName        = "gui/deploy_button",
  firstButtonOffset = Vector2i(0, 22),
}

/// bar that displays progress as discrete elements (pips)
class DeployMenu : Menu!(string, DeployButton) {
  this(const string[] unitKeys, Vector2i offset) {
    // TODO: choose corner of unit based on screen positioning
    super(new Sprite(bgName), offset, firstButtonOffset);
    foreach(key ; unitKeys) {
      addEntry(key);
    }
  }
}

class DeployButton : MenuButton!string {
  private enum {
    costOffset   = Vector2i(172, 10),
    spriteOffset = Vector2i(0, 0),
    nameOffset   = Vector2i(48, 4),
  }

  this(string unitKey, Vector2i pos) {
    super(unitKey, new Sprite(buttonName), pos);
    auto data = getUnitData(unitKey);
    addChild(new Icon(new Animation(unitKey, "idle", Animation.Repeat.loop), spriteOffset));
    addChild(new TextBox(data.name, _font, nameOffset));
    addChild(new TextBox(Unit.basicUnitDeployCost, _font, costOffset));
  }
}

Font _font;

static this() {
  onInit({ _font = Font("Mecha", 20); });
}
