module dau.entity;

import std.array;
import std.range;
import std.algorithm;
import dau.graphics.all;
import dau.geometry.all;

class Entity {
  const string tag;

  this(Vector2i pos, Sprite sprite, string tag = null) {
    _sprite = sprite;
    _area = Rect2i.centeredAt(pos, sprite.width, sprite.height);
    this.tag = tag;
  }

  @property {
    auto area() { return _area; }
    auto center() { return _area.center; }
    void center(Vector2i pos) { _area.center = pos; }
  }

  void update(float time) {
    _sprite.update(time);
  }

  void draw() {
    _sprite.draw(center);
  }

  void remove() {
    removeEntity(this);
  }

  protected:
  Sprite _sprite;

  private:
  Rect2i _area;
}

void registerEntity(Entity entity) {
  _entityMap[entity.tag] ~= entity;
}

auto findEntities(string tag) {
  return _entityMap[tag][];
}

void updateEntities(float time) {
  foreach(list ; _entityMap.values) {
    foreach(entity ; list) {
      entity.update(time);
    }
  }
}

void drawEntities() {
  foreach(list ; _entityMap.values) {
    foreach(entity ; list) {
      entity.draw();
    }
  }
}

void removeEntity(Entity entity) {
  _entityMap[entity.tag] = _entityMap[entity.tag].remove!(x => x == entity);
}

void removeEntities(string tag) {
  _entityMap[tag] = [];
}

void removeAllEntities() {
  _entityMap = null;
}

private:
Entity[][string] _entityMap;