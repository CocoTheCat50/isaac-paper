
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils, physics]

// sdk stuff
import math, math/Random

// our stuff
import isaac/[level, shadow, enemy, hero, utils, paths, tear]
import isaac/enemies/[spider]

/*
 * Spiderer. Among other things..
 */
Sack: class extends Mob {

    spawnCount := 120
    spawnCountMax := 160
    spawnCountWiggle := 80
    radius := 250

    damage := 4.0

    maxLife := 30.0
    lifeIncr := 0.04

    type: SackType

    init: func (.level, .pos, =type) {
        super(level, pos)

        life = maxLife

        loadSprite(getSpriteName(), level charGroup)
        createShadow(30)

        createBox(20, 20, INFINITY, INFINITY)

        ownBombImmune = true

        match type {
            case SackType GUT =>
                radius = 180
        }
    }

    getSpriteName: func -> String {
        match type {
            case SackType SACK =>
                "sack"
            case SackType BOIL =>
                "boil"
            // otherwise, gut
            case =>
                "gut"
        }
    }

    fixed?: func -> Bool {
        true
    }

    touchHero: func (hero: Hero) -> Bool {
        // we only spawn stuff, we don't hurt per se
        true
    }

    update: func -> Bool {
        pos set!(body getPos())

        if (life < maxLife) {
           if (damageCount <= 0) {
                life += lifeIncr
           }
        } else {
            if (spawnCount > 0) {
                dist := level hero pos dist(pos)
                if (dist < radius) {
                    spawnCount -= Random randInt(1, 2)
                }
            } else {
                spawn()
            }
        }

        scale := 0.8 * life / maxLife
        sprite scale set!(scale, scale)
        shadow setScale(scale)

        if (life <= 8.0) {
            return false
        }

        super()
    }

    spawn: func {
        match type {
            case SackType SACK =>
                spawnSpider()
            case SackType BOIL =>
                spawnShots()
            case SackType GUT =>
                spawnIpecac()
        }
        resetSpawnCount()
    }

    spawnSpider: func {
        spider := Spider new(level, pos, SpiderType SMALL)
        spider catapult()
        level add(spider)
    }

    spawnShots: func {
        target := level hero aimPos()
        diff := target sub(pos)
        shotSpeed := 240
        splurt(Random randInt(3, 5), pos, diff, shotSpeed)
    }

    resetSpawnCount: func {
        spawnCount = spawnCountMax + Random randInt(0, spawnCountWiggle)
    }

    destroy: func {
        super()
    }

    harm: func (damage: Float) {
        super(damage)
        resetSpawnCount()
    }

}

SackType: enum {
    SACK
    BOIL
    GUT
}

