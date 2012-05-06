
tile_size = 60

tile_css = (id, $sel) -> 
    tx = -(id % 20) * tile_size
    ty = -(Math.floor(id / 20)) * tile_size

    $sel.css { 
        backgroundPosition: tx.toString() + " " + ty.toString()
    }

amount_text = (amount) ->
    text = []
    text.push amount.food.toString() + " food" if amount.food
    text.push amount.wood.toString() + " wood" if amount.wood
    text.push amount.ore.toString() + " ore" if amount.ore

    text.join ", "

class Tile
    constructor: (@x, @y, @map, @name) ->
        @data = tile_data[@name];
        @icon = random_choice @data.icons
        @fogged = true;

    div: () ->
        @bind $('<div>').addClass 'tile'
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
            $sel.append @building.create_div()

        $sel

    left: () ->
        @x * 60

    top: () ->
        @y * 60

    bind: (@sel) ->

    get_action: () ->
        if @fogged
            surrounded_by_fog = (
                @map.getattr(@x - 1, @y, "fogged", true)  &&
                @map.getattr(@x + 1, @y, "fogged", true) &&
                @map.getattr(@x, @y - 1, "fogged", true) &&
                @map.getattr(@x, @y + 1, "fogged", true)
            )

            if not surrounded_by_fog
                return new Explore this

            return false

        if not @building and @data.building
            return new AddBuilding this

        if @building
            if @building.ready()
                return new Harvest this
            else
                return new Upgrade this

        false

    add_building: (building) ->
        @building = building
        game.buildings.push building

    update_panel_info: ($panel) ->
        @update $panel.find '.tile'

        if @fogged
            $panel.find('.name').text "???"
            return

        $panel.find('.name').text @name

    update_panel_action: ($panel, action) ->
        if not action
            $panel.find('.action_info').remove()
            return

        $panel.find('.action').text action.explain()

        cost = action.cost()

        if $.isEmptyObject cost
            $panel.find('.cost_info').hide()
        else
            $panel.find('.cost').text amount_text(cost) + "."


    update_panel: ($panel) ->
        $panel.append $('.templates .tile_panel').clone()
        @update_panel_info $panel

        @update_panel_action $panel, @get_action()

class Action
    constructor: (@tile) ->

    cost: () -> {}

class AddBuilding extends Action
    act: () ->
        @tile.add_building  new Building @tile.data.building

    explain: () ->
        "add a building"

    cost: () -> { wood: 10 }

class Explore extends Action
    act: () ->
        @tile.fogged = false
        game.gain_resources @tile.data.explore_bonus

    explain: () ->
        "explore"

class Harvest extends Action
    act: () ->
        game.gain_resources @tile.building.harvest()

    explain: () ->
        "harvest for " + amount_text(@tile.building.harvest_amount())

class Upgrade extends Action
    act: () ->
        @tile.building.level++

    explain: () ->
        "upgrade"

    cost: () -> {
            wood: @tile.building.level * 10
        }

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
    next_id: 1

    constructor: (@name) ->
        @data = building_data[@name]
        @level = 1
        @ticks = 0
        @id = Building::next_id++

    create_div: () ->
        @div = $("<div>").addClass 'building'
        @div.addClass @name
        tile_css @data.icon, @div

        progress_frame = $("<div>").addClass 'progress_frame'
        progress_bar = $("<div>").addClass 'progress_bar'
        progress_bar.addClass @css_class()

        progress_frame.append progress_bar
        @div.append progress_frame

        @update()
        @div

    css_class: () ->
        'pb_' + @id.toString()

    max_ticks: () ->
        @level * 3 + 1

    ready: () ->
        @ticks >= @max_ticks()

    tick: () ->
        @ticks++ unless @ready()

    harvest_amount: () ->
        amount = {}
        amount[@data.resource] = @level * 3
        return amount

    harvest: () ->
        @ticks = 0
        return @harvest_amount()

    update: () ->
        progress_bars = $('.' + @css_class())
        progress_bars.css "width", (@ticks / @max_ticks() * 100).toString() + "%"
        progress_bars.toggleClass 'ready', @ready()

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
        @panel_tile.update_panel @panel if @panel_tile

class TimeoutSingleton
    constructor: (@delay) ->

    call: (fun) ->
        @cancel()
        @timeout = setTimeout fun, @delay

    cancel: () ->
        clearTimeout @timeout

tile_data = {
    grass: {
        icons: [20]
        explore_bonus: {}
        building: "farm"
    }
    forest: {
        icons: [204, 205, 206, 207]
        explore_bonus: { wood: 5 }
        building: "lumber_mill"
    }
    mountain: {
        icons: [208]
        explore_bonus: { ore: 5 }
        building: "mine"
    }
}

building_data = {
    mine: {
        icon: 249
        resource: "ore"
    }
    lumber_mill: {
        icon: 254
        resource: "wood"
    }
    farm: {
        icon: 139
        resource: "food"
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
        @wood =  200
        @d_wood =  0
        @buildings = []

    take_turn: (tile) ->
        action = tile.get_action()

        if not action
            return

        cost = action.cost()

        for own resource, amount of cost
            if game[resource] < amount
                return

        for own resource, amount of cost
            game[resource] -= amount

        action.act()
        tile.update()

        for building in @buildings
            building.tick()
            building.update()

        @turn++

        ###
        @d_food = @d_ore = @d_wood = 0

        for building in @buildings
            @d_food += building.data.food || 0
            @d_ore += building.data.ore || 0
            @d_wood += building.data.wood || 0

        @food += @d_food
        @ore += @d_ore
        @wood += @d_wood
        ###

        ui.inspector.update(this)

    gain_resources: (resources) ->
        for own resource, value of resources
            @[resource] += value

window.game = new Game

window.game_start = () ->
    game.map = new Map $('.map'), 20, 20
    for x in [0..20]
        for y in [0..20]
            tile_name = random_choice ["grass", "grass", "grass", "grass", "forest", "forest", "mountain"]
            tile = game.map.create_tile(x, y, tile_name)
            tile.fogged = false if x == y == 10
            $('.map').append tile.div()

    ui.map = $('.map')

    hover_update = new TimeoutSingleton 20
    ui.map.bind 'mousemove', (event) ->
        hover_update.call () ->
            ui.map.find('.tile.selected').removeClass 'selected'
            $tile = $(event.target).closest '.tile'
            $tile.addClass 'selected'
            ui.inspector.bind_panel $tile.data('tile')

    ui.map.delegate '.tile', 'mousedown', (first) ->
        $this = $(this)
        tile = $this.data('tile')

        $this.addClass 'depressed'

        $(window).one 'mouseup', (second) =>
            if click_dist(first, second) < 10
                game.take_turn tile

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