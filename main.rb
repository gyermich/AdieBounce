require 'gosu'
include Gosu

module Tiles
  Wall = 0
  Desk = 1
  Empty = 2
  Cords = 3
end

class HeartGem
  attr_reader :x, :y

  def initialize(image, x, y)
    @image = image
    @x, @y = x, y
  end

  def draw
    @image.draw_rot(@x, @y, 0, 25 * Math.sin(milliseconds / 133.7))
  end
end

class Adie
  attr_reader :x, :y

  def initialize(window, x, y)
    @x, @y = x, y
    @dir = :left
    @vy = 0
    @map = window.map
    @image = Gosu::Image.new(window, "adie.png", false)
  end

  def draw
    if @dir == :left then
      offs_x = -25
      factor = 1.0
    else
      offs_x = 25
      factor = -1.0
    end
    @image.draw(@x + offs_x, @y - 49, 0, factor, 1.0)
  end


  def would_fit(offs_x, offs_y)
    not @map.solid?(@x + offs_x, @y + offs_y) and
      not @map.solid?(@x + offs_x, @y + offs_y - 45)
  end

  def update(move_x)
    if move_x > 0 then
      @dir = :right
      move_x.times { if would_fit(1, 0) then @x += 1 end }
    end
    if move_x < 0 then
      @dir = :left
      (-move_x).times { if would_fit(-1, 0) then @x -= 1 end }
    end

    @vy += 1
    if @vy > 0 then
      @vy.times { if would_fit(0, 1) then @y += 1 else @vy = 0 end }
    end
    if @vy < 0 then
      (-@vy).times { if would_fit(0, -1) then @y -= 1 else @vy = 0 end }
    end
  end

  def try_to_jump
    if @map.solid?(@x, @y + 1) then
      @vy = -20
    end
  end

  def collect_gems(gems)
    gems.reject! do |c|
      (c.x - @x).abs < 50 and (c.y - @y).abs < 50
    end
  end
end

class Map
  attr_reader :width, :height, :gems

  def initialize(window, filename)
    @tileset = Image.load_tiles(window, "tileset.png", 50, 50, true)

    gem_img = Image.new(window, "gem.png", false)
    @gems = []

    lines = File.readlines(filename).map { |line| line.chomp }
    @height = lines.size
    @width = lines[0].size
    @tiles = Array.new(@width) do |x|
      Array.new(@height) do |y|
        case lines[y][x, 1]
       when '"'
        Tiles::Desk
      when '#'
        Tiles::Wall
      when '-'
        Tiles::Cords
      when 'x'
          @gems.push(HeartGem.new(gem_img, x * 50 + 25, y * 50 + 25))
          nil
        else
          nil
        end
      end
    end
  end

  def draw
    @height.times do |y|
      @width.times do |x|
        tile = @tiles[x][y]
        if tile
          @tileset[tile].draw(x * 50 - 5, y * 50 - 5, 0)
        end
      end
    end
    @gems.each { |c| c.draw }
  end

  def solid?(x, y)
    y < 0 || @tiles[x / 50][y / 50]
  end
end

class Game < Window
  attr_reader :map

  def initialize
    super(640, 480, false)
    self.caption = "AdieBounce"
    @sky = Image.new(self, "sky.png", true)
    @map = Map.new(self, "map.txt")
    @adie = Adie.new(self, 400, 100)
    @camera_x = @camera_y = 0
  end
  def update
    move_x = 0
    move_x -= 5 if button_down? KbLeft
    move_x += 5 if button_down? KbRight
    @adie.update(move_x)
    @adie.collect_gems(@map.gems)
    @camera_x = [[@adie.x - 320, 0].max, @map.width * 50 - 640].min
    @camera_y = [[@adie.y - 240, 0].max, @map.height * 50 - 480].min
  end
  def draw
    @sky.draw 0, 0, 0
    translate(-@camera_x, -@camera_y) do
      @map.draw
      @adie.draw
    end
  end
  def button_down(id)
    if id == KbUp then @adie.try_to_jump end
    if id == KbEscape then close end
  end
end

Game.new.show