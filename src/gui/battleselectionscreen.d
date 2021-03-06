module gui.battleselectionscreen;

import std.algorithm, std.range, std.file, std.path, std.array, std.format;
import dau.all;
import net.all;
import model.all;
import gui.factionmenu;
import gui.mapselector;
import battle.battle;
import title.title;
import title.state.showtitle;

private enum PostColor : Color {
  self = Color.blue,
  other = Color.green,
  error = Color.red,
  note = Color.black
}

private enum PostFormat : string {
  self  = "you: %s",
  other = "opponent: %s",
  error = "error: %s",
  note  = "system: %s",
  youChoseMap = "you chose map %s: %s",
  otherChoseMap = "opponent chose map %s: %s",
  youChoseFaction = "you chose faction %s",
  otherChoseFaction = "opponent chose faction %s",
}

/// bar that displays progress as discrete elements (pips)
class BattleSelectionScreen : GUIElement {
  const bool isHost;

  this(Title title, MapType mapType, NetworkClient client = null, bool isHost = true) {
    super(getGUIData("selectBattle"), Vector2i.zero);

    _client = client;
    _title = title;
    this.isHost = isHost || client is null; // if singleplayer, default to host
    assert(isHost);
    _playerIdx = isHost ? 1 : 2;

    _startButton = new Button(data.child["startButton"], &beginBattle);
    _startButton.enabled = canStartGame;

    _factionMenu1 = new FactionMenu(data.child["faction1"], (name) => selectFaction(1, name));
    _factionMenu2 = new FactionMenu(data.child["faction2"], (name) => selectFaction(2, name));
    addChildren(_startButton, _factionMenu1, _factionMenu2);

    addChildren!TextBox("player1label", "player2label");

    _player1button = addChild(new Button(data.child["player1button"], &swapPlayers));
    _player2button = addChild(new Button(data.child["player2button"], &swapPlayers));
    setPlayerButtonText();

    _messageBox = new MessageBox(data.child["messageBox"]);
    _messageInput = new TextInput(data.child["messageInput"], &postMessage);
    addChildren(_messageBox, _messageInput);

    addChild(new Button(data.child["backButton"], &backToMenu));

    addChildren!TextBox("titleText", "subtitle");

    auto mapDatas = mapLayoutsOfType(mapType).array;
    _mapSelector = addChild(new MapSelector(data.child["selectMap"], mapDatas, &selectMap));
    final switch (mapType) with (MapType) {
      case battle:
        _factionMenu1.banFaction(_factionMenu2.selection);
        _factionMenu2.banFaction(_factionMenu1.selection);
        break;
      case skirmish:
        forceSkirmishFactions();
        _factionMenu1.enabled = false;
        _factionMenu2.enabled = false;
        break;
      case tutorial:
    }
  }

  override void update(float time) {
    super.update(time);
    if (_client !is null) {
      NetworkMessage msg;
      bool gotSomething = _client.receive(msg);
      if (gotSomething) {
        processMessage(msg);
      }
    }
  }

  private:
  FactionMenu   _factionMenu1, _factionMenu2;
  MapSelector   _mapSelector;
  Button        _startButton;
  Button        _player1button, _player2button;
  MessageBox    _messageBox;
  TextInput     _messageInput;
  NetworkClient _client;
  Title         _title;
  int           _playerIdx;

  @property bool canStartGame() {
    return isHost;
  }

  void processMessage(NetworkMessage msg) {
    switch (msg.type) with (NetworkMessage.Type) {
      case closeConnection:
        _messageBox.postMessage("Client left", PostColor.error);
        backToMenu();
        break;
      case chat:
        _messageBox.postMessage(PostFormat.other.format(msg.chat.text), PostColor.other);
        break;
      case chooseMap:
        string mapName = msg.chooseMap.mapName;
        string layoutName = msg.chooseMap.layoutName;
        auto note = PostFormat.otherChoseMap.format(mapName, layoutName);
        _messageBox.postMessage(note, PostColor.note);
        _mapSelector.setSelection(mapName, layoutName);
        break;
      case chooseFaction:
        string name = msg.chooseFaction.name;
        int    idx  = msg.chooseFaction.playerIdx;
        auto   note = PostFormat.otherChoseFaction.format(name);
        _messageBox.postMessage(note, PostColor.note);
        if (idx == 1) {
          _factionMenu1.selection = name;
        }
        else {
          _factionMenu2.selection = name;
        }
        break;
      case startBattle:
        beginBattle();
        break;
      case swapPlayers:
        performPlayerSwap();
        break;
      default:
    }
  }

  void selectFaction(int playerIdx, string name) {
    if (_client !is null) {
      _client.send(NetworkMessage.makeChooseFaction(playerIdx, name));
    }
    if (playerIdx == 1) {
    }
  }

  void beginBattle() {
    auto playerFaction = getFaction(_factionMenu1.selection);
    auto otherFaction = getFaction(_factionMenu2.selection);
    if (isHost && _client !is null) {
      _client.send(NetworkMessage(NetworkMessage.Type.startBattle));
    }
    auto map = _mapSelector.selection;
    setScene(new Battle(map, playerFaction, otherFaction, _playerIdx, _client, isHost));
  }

  void backToMenu() {
    if (_client !is null) {
      _client.send(NetworkMessage.makeCloseConnection());
    }
    _title.states.popState();
  }

  void postMessage(string text) {
    _messageBox.postMessage(PostFormat.self.format(text), PostColor.self);
    _messageInput.text = "";
    if (_client !is null) {
      _client.send(NetworkMessage.makeChat(text));
    }
  }

  void selectMap(MapLayout layout) {
    if (_client !is null) {
      _client.send(NetworkMessage.makeChooseMap(layout.mapName, layout.layoutName));
    }
    forceSkirmishFactions();
  }

  void swapPlayers() {
    performPlayerSwap();
    if (_client !is null) {
      _client.send(NetworkMessage(NetworkMessage.Type.swapPlayers));
    }
  }

  void performPlayerSwap() {
    _playerIdx = _playerIdx == 1 ? 2 : 1;
    setPlayerButtonText();
  }

  void setPlayerButtonText() {
    string otherName;
    if      (_client is null) { otherName = "PC"; }
    else if (isHost)          { otherName = "Client"; }
    else                      { otherName = "Host"; }

    if (_playerIdx == 1) {
      _player1button.text = "You";
      _player2button.text = otherName;
    }
    else {
      _player1button.text = otherName;
      _player2button.text = "You";
    }
  }

  void forceSkirmishFactions() {
    if (_mapSelector.selection.type == MapType.skirmish) {
      _factionMenu1.selection = _mapSelector.selection.playerFaction(1);
      _factionMenu2.selection = _mapSelector.selection.playerFaction(2);
    }
  }
}
