
tile_size = 60

class Tile
    constructor: (@x, @y, @name) ->
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
            left: @x * 60
            top: @y * 60
        }

    bind: ($sel) ->
        @sel = $sel

    act: () ->
        if @fogged
            @fogged = false
            @update()

class Map
    constructor: (@width, @height) ->
        @tiles = (new Array(@width) for n in [0..@height])

    create_tile: (x, y, args...) ->
        @set x, y, new Tile(x,y, args...)

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
    game.map = new Map 20, 20
    for x in [0..20]
        for y in [0..20]
            tile_name = random_choice ["grass", "grass", "grass", "grass", "forest", "forest", "mountain"]
            tile = game.map.create_tile(x, y, tile_name)
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

    ui.map = new EasyScroller $('.map').get 0, {
        scrollingX: true 
        scrollingY: true
        zooming: true
        minZoom: 0.25
        maxZoom: 4
    }