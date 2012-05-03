
tile_size = 60

class Tile
    constructor: (@x, @y, @map, @name) ->
        @data = tile_data[@name];
        @icon = random_choice(@data.icons)
        @fogged = true;

    div: () ->
        @bind $('<div>').addClass('tile')
        @update()

    update: ($sel) ->
        $sel = if $sel then $sel else @sel
        tx = -(@icon % 20) * tile_size
        ty = -(Math.floor(@icon / 20)) * tile_size
        $sel.data 'tile', this
        $sel.toggleClass 'fogged', @fogged
        $sel.css {
            backgroundPosition: tx.toString() + " " + ty.toString()
            left: @left()
            top: @top()
        }

    left: () ->
        @x * 60

    top: () ->
        @y * 60

    bind: ($sel) ->
        @sel = $sel

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
            else
                console.log 'surrounded by fog'
                return false

        false

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

tile_data = {
    grass: {
        icons: [20]
        pop: 10
    }
    forest: {
        icons: [204, 205, 206, 207]
        wood: 10
    }
    mountain: {
        icons: [208]
        ore: 10
    }
}

click_dist = (e1, e2) ->
    dx = e1.screenX - e2.screenX
    dy = e1.screenY - e2.screenY
    return Math.sqrt dx*dx+dy*dy

random_choice = (list) -> list[Math.floor(Math.random() * list.length)]

window.ui = {}
window.game = {}

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
        if $this.hasClass 'selected'
            $this.addClass 'depressed'

        $(window).one 'mouseup', (second) =>
            if click_dist(first, second) < 10
                if $this.hasClass 'depressed'
                    $this.data('tile').act()
                else
                    $('.map .tile.selected').removeClass 'selected'
                    $this.addClass 'selected'

            $this.removeClass 'depressed'

    ui.map_frame = new EasyScroller $('.map').get 0, {
        scrollingX: true 
        scrollingY: true
        zooming: true
        minZoom: 0.25
        maxZoom: 4
    }

    target_tile = game.map.get 10,10
    ui.map_frame.scroller.scrollTo target_tile.left() - $('.map_frame').width()/2 + tile_size/2, target_tile.top() - $('.map_frame').height()/2 + tile_size/2