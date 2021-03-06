
// third-party stuff
use dye
import dye/[core, loop, input, primitives, math, sprite, text]

use deadlogger
import deadlogger/[Log, Logger]

use gnaar
import gnaar/[grid, utils]

// sdk stuff
import structs/[ArrayList, List]

// our stuff
import isaac/[game, options, hero]

Menu: class {

    game: Game

    group: GlGroup
    bg: GlRectangle

    lightBg: GlSprite

    enabled := false

    screenSize: Vec2
    menuSize: Vec2
    bottomLeft: Vec2
    center: Vec2

    clickables := ArrayList<Clickable> new()
    stats := ArrayList<Stat> new()

    input: Input

    logger := static Log getLogger(This name)

    init: func (=game) {
        input = game scene input sub()

        group = GlGroup new()
        group visible = false
        game menuGroup add(group)

        screenSize = vec2(game dye size x, game dye size y)
        center = screenSize mul(0.5)

        bg = GlRectangle new(screenSize)
        bg color set!(0, 0, 0)
        bg opacity = 0.5
        bg center = false
        group add(bg)

        menuSize = vec2(460, 330)
        bottomLeft = screenSize mul(0.5) sub(menuSize mul(0.5))

        lightBg = GlSprite new("assets/png/menu-bg.png")
        lightBg pos set!(screenSize mul(0.5))
        group add(lightBg)

        {
            clickable := Clickable new(this, "paused",
                vec2(0, menuSize y - 30))
            clickable clickable = false
            addClickable(clickable)
        }

        {
            clickable := Clickable new(this, "exit-to-main-menu",
                vec2(0, 80))
            clickable size set!(280, 40)
            addClickable(clickable)
        }

        {
            clickable := Clickable new(this, "back",
                vec2(menuSize x * 0.5 - 55, 30))
            clickable size set!(280, 40)
            addClickable(clickable)
        }

        /* Stats */

        addStat(-160, StatType SPEED)
        addStat(-50, StatType FIRESPEED)
        addStat(50, StatType DAMAGE)
        addStat(160, StatType RANGE)

        /* Events */

        input onMousePress(MouseButton LEFT, |mp|
            logger info("Got mouse click") 

            if (!inside?(mp pos, center, menuSize)) {
                // just forget it man
                logger info("Outside menu")
            }

            for (c in clickables) {
                if (!c clickable) {
                    continue
                }

                if (inside?(mp pos, c pos, c size)) {
                    logger info("Clicked on %s", c name)
                    game onMenuEvent(c name)
                }
            }
        )

        logger info("Menu created!")
    }

    /**
     * :return: true if needle is inside a rectangle
     * at position 'pos' of dimensions 'size', false
     * otherwise
     */
    inside?: func (needle, pos, size: Vec2) -> Bool {
        if (needle x > (pos x + size x * 0.5)) {
            return false
        }
        if (needle x < (pos x - size x * 0.5)) {
            return false
        }
        if (needle y > (pos y + size y * 0.5)) {
            return false
        }
        if (needle y < (pos y - size y * 0.5)) {
            return false
        }
        true
    }

    addClickable: func (clickable: Clickable) {
        clickables add(clickable)
        group add(clickable group)
    }

    addStat: func (xOffset: Float, type: StatType) {
        pos := vec2(center x + xOffset - 35, center y + 80)
        stat := Stat new(this, type, pos)

        stats add(stat)
        group add(stat group)
    }

    setEnabled: func (=enabled) {
        group visible = enabled
        input enabled = enabled

        if (enabled) {
            for (stat in stats) {
                stat update()
            }
        }
    }

    update: func {
        // handle events and the shiznit

        for (c in clickables) {
            c update()
        }
    }

}

Clickable: class {

    name: String

    group: GlGroup
    sprite: GlSprite

    menu: Menu

    pos: Vec2
    size := vec2(100, 80)

    clickable := true
    hover := false

    init: func (=menu, =name, offset: Vec2) {
        group = GlGroup new()

        pos = vec2(
            menu screenSize x * 0.5 + offset x,
            menu bottomLeft y + offset y
        )

        path := "assets/png/menu-%s.png" format(name)
        sprite = GlSprite new(path)
        group add(sprite)
        group pos set!(pos)
    }

    update: func {
        if (!clickable) {
            sprite opacity = 0.4
            return
        }

        hover = menu inside?(menu input getMousePos(), pos, size)
        sprite opacity = hover ? 0.9 : 0.8

        scale := hover ? 1.0 : 0.95
        sprite scale set!(scale, scale)
    }

}

Stat: class {

    menu: Menu
    type: StatType

    sprite: GlSprite
    ticks := ArrayList<GlSprite> new()
    
    group: GlGroup
    pos: Vec2

    dark := 0.9
    light := 0.5

    init: func (=menu, =type, =pos) {
        "New stat at pos %s" printfln(pos toString())

        group = GlGroup new()
        group pos set!(pos)

        spritePath := "assets/png/stat-%s.png" format(getSpriteName())
        sprite = GlSprite new(spritePath)
        group add(sprite)

        currentPos := vec2(25, 0)
        offsetX := 8

        indices := ArrayList<Int> new()
        for (i in 0..7) {
            indices add(i)
        }
        indices = indices shuffle()

        for (i in 0..7) {
            index := indices[i]
            path := "assets/png/stat-tick%d.png" format(index)
            sprite := GlSprite new(path)
            sprite pos set!(currentPos)
            sprite opacity = dark

            currentPos x += offsetX

            group add(sprite)
            ticks add(sprite)
        }
    }

    getSpriteName: func -> String {
        match type {
            case StatType SPEED =>
                "speed"
            case StatType FIRESPEED =>
                "firespeed"
            case StatType DAMAGE =>
                "damage"
            case =>
                "range"
        }
    }
    
    update: func {
        stat := getStat()
        for (i in 0..7) {
            highlight := stat > i
            ticks[i] opacity = highlight ? dark : light
        }
    }

    getStat: func -> Int {
        stats := menu game heroStats
        if (!stats) {
            return 0
        }

        match type {
            case StatType SPEED =>
                stats speed
            case StatType DAMAGE =>
                stats damage
            case StatType FIRESPEED =>
                stats shootRate
            case StatType RANGE =>
                stats shootRange
            case =>
                0
        }
    }

}

StatType: enum {
    SPEED
    FIRESPEED     
    DAMAGE
    RANGE
}

