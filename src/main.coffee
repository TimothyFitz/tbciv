
tile_size = 60

tile_css = (id, $sel) -> 
    tx = -(id % 20) * tile_size
    ty = -(Math.floor(id / 20)) * tile_size

    $sel.css { 
        backgroundPosition: tx.toString() + " " + ty.toString()
    }

class Tile
    constructor: (@x, @y, @map, @name) ->
        @data = tile_data[@name];
        @icon = random_choice(@data.icons)
        @fogged = true;

    div: () ->
        @bind $('<div>').addClass('tile')
        @sel.css {
            left: @left()
            top: @top()
        }
        @update()

    update: ($sel) ->
        $sel = if $sel then $sel else @sel
        $sel.data 'tile', this
        $sel.toggleClass 'fogged', @fogged

        tile_css @icon, $sel

        $building = $sel.find '.building'
        $building.remove()
        if @building
            $sel.append @building.div()

        $sel

    left: () ->
        @x * 60

    top: () ->
        @y * 60

    bind: (@sel) ->

    act: () ->
        if @fogged
            surrounded_by_fog = (
                @map.getattr(@x - 1, @y, "fogged", true)  &&
                @map.getattr(@x + 1, @y, "fogged", true) && 
                @map.getattr(@x, @y - 1, "fogged", true) && 
                @map.getattr(@x, @y + 1, "fogged", true)
            )

            if not surrounded_by_fog
                @fogged = false
                @update()
                return true

            console.log 'surrounded by fog'
            return false

        if not @building and @data.building
            @add_building new Building(@data.building)
            @update()
            return true

        false

    add_building: (building) ->
        @building = building
        game.buildings.push building

    update_panel: ($panel) ->
        $panel.append $('.templates .tile_panel').clone()
        @update $panel.find('.tile')

        if @fogged
            $panel.find('.name').text "???"
            return

        $panel.find('.name').text @name

class Map
    constructor: (@root, @width, @height) ->
        @tiles = (new Array(@width) for n in [0..@height])
        @root.css {
            width: tile_size * @width
            height: tile_size * @height
        }

    create_tile: (x, y, args...) ->
        @set x, y, new Tile(x,y, this, args...)

    getattr: (x,y, attr, default_value) ->
        if 0 <= x < @width and 0 <= y < @height
            tile = @get x,y
            if tile
                return tile[attr]
        default_value

    get: (x, y) ->
        @tiles[y][x]

    set: (x, y, item) ->
        @tiles[y][x] = item

class Building
    constructor: (@name) ->
        @data = building_data[@name]
        @level = 1

    div: () ->
        $building = $("<div>").addClass('building')
        $building.addClass @name
        tile_css @data.icon, $building

        $building

class Inspector
    constructor: (@root) ->
        @panel = @root.find '.bottom'

    value_names: ["food", "d_food", "wood", "d_wood", "ore", "d_ore", "turn"]

    bind_panel: (@panel_tile) ->
        @update_panel()

    update: (game) ->
        for name in @value_names
            @root.find('.' + name).text game[name]

        @update_panel()

    update_panel: () ->
        ui.inspector.panel.empty()
        @panel_tile.update_panel @panel

tile_data = {
    grass: {
        icons: [20]
        pop: 10
        building: "farm"
    }
    forest: {
        icons: [204, 205, 206, 207]
        wood: 10
        building: "lumber_mill"
    }
    mountain: {
        icons: [208]
        ore: 10
        building: "mine"
    }
}

building_data = {
    mine: {
        icon: 249
        ore: 10
    }
    lumber_mill: {
        icon: 254
        wood: 10
    }
    farm: {
        icon: 139
        food: 10
    }
}

click_dist = (e1, e2) ->
    dx = e1.screenX - e2.screenX
    dy = e1.screenY - e2.screenY
    return Math.sqrt dx*dx+dy*dy

random_choice = (list) -> list[Math.floor(Math.random() * list.length)]

window.ui = {}

class Game
    constructor: () ->
        @turn =  0
        @food =  0
        @d_food =  0
        @ore =  0
        @d_ore =  0
        @wood =  0
        @d_wood =  0
        @buildings = []

    take_turn: (tile) ->
        did_act = tile.act()
        if not did_act
            return

        @turn++

        @d_food = @d_ore = @d_wood = 0

        for building in @buildings
            @d_food += building.data.food || 0
            @d_ore += building.data.ore || 0
            @d_wood += building.data.wood || 0

        @food += @d_food
        @ore += @d_ore
        @wood += @d_wood

        ui.inspector.update(this)

window.game = new Game

window.game_start = () ->
    game.map = new Map $('.map'), 20, 20
    for x in [0..20]
        for y in [0..20]
            tile_name = random_choice ["grass", "grass", "grass", "grass", "forest", "forest", "mountain"]
            tile = game.map.create_tile(x, y, tile_name)
            if x == y == 10 then tile.fogged = false
            $('.map').append tile.div()

    $('.map').delegate '.tile', 'mousedown', (first) -> 
        $this = $(this)
        tile = $this.data('tile')

        if $this.hasClass 'selected'
            $this.addClass 'depressed'

        $(window).one 'mouseup', (second) =>
            if click_dist(first, second) < 10
                if $this.hasClass 'depressed'
                    game.take_turn tile
                else
                    $('.map .tile.selected').removeClass 'selected'
                    $this.addClass 'selected'
                    ui.inspector.bind_panel tile

            $this.removeClass 'depressed'

    ui.inspector = new Inspector $('.inspector')
    ui.map_frame = new EasyScroller $('.map').get 0, {
        scrollingX: true 
        scrollingY: true
        zooming: true
        minZoom: 0.25
        maxZoom: 4
    }

    target_tile = game.map.get 10,10
    ui.map_frame.scroller.scrollTo target_tile.left() - $('.map_frame').width()/2 + tile_size/2, target_tile.top() - $('.map_frame').height()/2 + tile_size/2