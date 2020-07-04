import nico
import strformat

const
  colors = 3
  levels = 2
const
  Wall = 1'u8
  Floor = 2'u8
  Spawn = 3'u8
  End = 4'u8
  Switch = 5'u8
  Door = 11'u8
  DoorOpen = Door + colors
  Terminal = 17

const
  SolidFlag = 1
  DoorFlag = 2
  SwitchFlag = 4
  TermFlag = 8
  SpawnFlag = 128
  EndFlag = 64

type Mode = enum
  Play, Menu, Select

type Pos = object
    x, y: int

type ColorPos = array[3, seq[Pos]]

type Prompt = object
    w, h: int
    text: string
    options: seq[string]
    idx: int
    active: bool
  
var
  pspawn: Pos
  player: Pos

var cursor: Pos

var cx, cy = 0

var doors: ColorPos

var lvl = 0

var mode = Play

var prompt =
  Prompt(w: 96, h: 96,
         text: "LVL[" & $lvl & "]",
         options: @["CONTINUE",
                    "RESTART",
                    "EXIT"],
         idx: 0,
         active: false)


template tileAt(x, y: typed): uint8 =
  mget(x div 8, y div 8)

proc posAt(x, y: int): Pos =
  Pos(x: x * 8, y: y * 8)

proc scanMap() =
  for i in 0..mapWidth():
    for j in 0..mapHeight():
      let tile = mget(i, j)
      case fget(tile):
      of DoorFlag: # Uncollidable door(open)
        doors[tile - DoorOpen].add Pos(x: i, y: j)
      of DoorFlag + SolidFlag: # Collidable door(closed)
        doors[tile - Door].add Pos(x: i, y: j)
      of SpawnFlag:
        pspawn = posAt(i, j)
      else: discard

proc toggleDoor(x, y: int) =
  let t = mget(x, y)
  let offset: uint8 =
    if fget(t, 0): 1
    else: -1
  mset(x, y, t + colors * offset)

proc isSolid(x, y: int): bool =
  let tile = tileAt(x, y)
  fget(tile, 0)

proc isDoor(x, y: int): bool =
  let tile = tileAt(x, y)
  fget(tile, 1)

proc initLvl(lvl: int) =
  loadMap(0, &"levels/lvl{lvl}.json")
  setMap(0)
  for i in 0..2:
    doors[i] = @[]
  scanMap()
  player.x = pspawn.x
  player.y = pspawn.y
  
  prompt.active = false
  prompt.idx = 0

proc gameInit() =
  loadFont(0, "font.png")
  loadSpritesheet(0, "spritesheet.png")
  loadMusic(0, "switchnditch.ogg")
  sfxVol(64)
  musicVol(127)
  music(15, 0)
  fset(Wall, SolidFlag)
  fset(Spawn, SpawnFlag)
  fset(Terminal, TermFlag)
  fset(End, EndFlag)
  for t in Door..<DoorOpen + colors:
    if t < DoorOpen:
      fset(t, DoorFlag + SolidFlag)
    else:
      fset(t, DoorFlag)
  for t in Switch..<Switch + colors:
    fset(t, SwitchFlag)

  initLvl(lvl)

proc gameUpdate(dt: float32) =
  case mode
  of Menu:
    let didx =
      if btnp(pcDown): 1
      elif btnp(pcUp): -1
      else: 0

    if didx != 0:
      prompt.idx = wrap(prompt.idx + didx, prompt.options.len)
      synth(0, synP25, 300, 15, -2, 12)

    if btnp(pcA):
      case prompt.options[prompt.idx]:
      of "CONTINUE":
        mode = Play
      of "RESTART":
        initLvl(lvl)
        mode = Play
      of "EXIT":
        shutdown()

      synth(0, synSqr, 510, 10, 2, 8) 
  of Play:
    let dx =
      if btnpr(pcRight, 10): 8
      elif btnpr(pcLeft, 10): -8
      else: 0
    let dy =
      if btnpr(pcUp, 10): -8
      elif btnpr(pcDown, 10): 8
      else: 0

    if dx != 0 or dy != 0:
      if not isSolid(player.x + dx, player.y + dy):
        player.x += dx
        player.y += dy
        synth(0, synP12, 180, 3, 5, 6)

    if btnp(pcA):
      let active = tileAt(player.x, player.y)
      case fget(active)
      of SwitchFlag:
        for tile in doors[active - Switch]:
          toggleDoor(tile.x, tile.y)
        mset(player.x div 8, player.y div 8, active + colors)
        synth(0, synSaw, 320, 15, 0, 4)
      of TermFlag:
        mode = Select
        cursor.x = player.x
        cursor.y = player.y
      of EndFlag:
        if lvl < 4:
          lvl += 1
          initLvl(lvl)
        synth(0, synSqr, 220, 5, 2, 12)
      else: discard

    if btnp(pcStart):
      mode = Menu
      synth(0, synSqr, 510, 15, -2, 12) 

    if player.x > cx + 120:
      cx += 128
    elif player.x < cx:
      cx -= 128
    if player.y < cy:
      cy -= 128
    elif player.y > cy + 120:
      cy += 128

  of Select:
    let dy =
      if btnpr(pcUp, 10): -8
      elif btnpr(pcDown, 10): 8
      else: 0
    let dx =
      if btnpr(pcLeft, 10): -8
      elif btnpr(pcRight, 10): 8
      else: 0

    if dx != 0 or dy != 0:
      cursor.x = mid(player.x - 8 * 5, wrap(cursor.x + dx, screenWidth + 8), player.x + 8 * 5)
      cursor.y = mid(player.y - 8 * 5, wrap(cursor.y + dy, screenHeight + 8), player.y + 8 * 5)
      if isDoor(cursor.x, cursor.y):
        synth(0, synP25, 420, 15, 0, 5)
      else:
        synth(0, synP25, 320, 5, 0, 3)

    if btnp(pcA):
      let
        x = cursor.x
        y = cursor.y
      if isDoor(x, y):
        toggleDoor(cursor.x div 8, cursor.y div 8)
        mset(player.x div 8, player.y div 8, Terminal + 1)
        synth(0, synSaw, 320, 15, 0, 4)
        mode = Play
    if btnp(pcB):
      mode = Play

proc gameDraw() =
  cls()
  setCamera(cx, cy)
  setColor(6)
  mapDraw(0, 0, 32, 32, 0, 0)
  spr(0, player.x, player.y)

  case mode
  of Menu:
    let
      x = cx + (screenWidth - prompt.w) div 2
      y = cy + (screenHeight - prompt.h) div 2
    setColor(13)
    boxfill(x, y, prompt.w, prompt.h)
    setColor(0)
    boxfill(x + 4, y + 4, prompt.w - 8, prompt.h - 8)
    setColor(11)
    printc(prompt.text, x + prompt.w div 2, y + 8)
    for i, txt in prompt.options:
      let my = cy + (prompt.h - 8 * prompt.options.len) + 10 * i
      print(txt, x + 8, my)
      if i == prompt.idx:
        printc(">", x + 6, my)
  of Select:
    let color =
      if fget( tileAt(cursor.x, cursor.y), 1): 11
      else: 3
    setColor(color)
    rectCorner(cursor.x, cursor.y, cursor.x + 7, cursor.y + 7)
  of Play:
    discard

nico.init("myOrg", "myApp")
nico.createWindow("myApp", 128, 128, 4, false)
nico.run(gameInit, gameUpdate, gameDraw)
