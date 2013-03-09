
// third-party stuff
use deadlogger
import deadlogger/[Log, Logger]

use chipmunk
import chipmunk

use dye
import dye/[core, sprite, primitives, math]

use gnaar
import gnaar/[utils]

// our stuff
import isaac/[level, bomb, tear, hero]

/*
 * Any type of enemy
 */
Enemy: abstract class extends Entity {

    life := 10.0

    z := 0.0

    damageCount := 0
    damageLength := 20

    shape: CpShape
    body: CpBody
    
    redish: Bool

    heroHandler: CpCollisionHandler

    init: func (.level, .pos) {
        super(level, pos)

        initHandlers()
    }

    harm: func (damage: Float) {
        if (damageCount <= 0) {
            damageCount = damageLength
            life -= damage
        }
    }

    bombHarm: func (bomb: Bomb) {
        harm(bomb damage)            
    }

    update: func -> Bool {
        if (damageCount > 0) {
            damageCount -= 1
            intval := damageCount / (damageLength * 0.4)
            if (intval % 2 == 0) {
                redish = true
            } else {
                redish = false
            }
        } else {
            redish = false
        }

        if (life <= 0.0) {
            die()
            return false
        }

        true
    }

    setOpacity: abstract func (opacity: Float)

    grounded?: func -> Bool {
        z < level groundLevel
    }

    fixed?: func -> Bool {
        // override for stuff like sacks etc.
        false
    }

    hitBack: func (tear: Tear) {
        if (fixed?()) {
            return
        }

        // TODO: make blast dependant on tear damage
        dir := pos sub(tear pos) normalized()
        hitbackSpeed := 200
        vel := dir mul(hitbackSpeed)
        body setVel(cpv(vel))
    }

    die: func {
        // normally, die in peace
    }

    touchHero: func (hero: Hero) -> Bool {
        // override if the enemy doesn't hurt on touch
        // (most enemies do, though..)
        hero harmHero(1)
        true
    }

    initHandlers: func {
        if (!heroHandler) {
            heroHandler = EnemyHeroHandler new()
            level space addCollisionHandler(CollisionTypes ENEMY,
                CollisionTypes HERO, heroHandler)
        }
    }

}

Mob: class extends Enemy {

    sprite: GlSprite

    init: func (.level, .pos) {
        super(level, pos)
    }

    setOpacity: func (opacity: Float) {
        sprite opacity = opacity
    }

    update: func -> Bool {
        if (redish) {
            sprite color set!(255, 30, 30)
        } else {
            sprite color set!(255, 255, 255)
        }

        super()
    }

}

EnemyHeroHandler: class extends CpCollisionHandler {

    begin: func (arbiter: CpArbiter, space: CpSpace) -> Bool {
        shape1, shape2: CpShape
        arbiter getShapes(shape1&, shape2&)

        enemy := shape1 getUserData() as Enemy
        hero := shape2 getUserData() as Hero

        enemy touchHero(hero)
    }

}

