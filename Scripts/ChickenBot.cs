using Godot;
using System;
using System.Collections.Generic;
using MyMath;

public class ChickenBot : KinematicBody2D
{
Vector2 baseSpriteScale, baseScale, velocity, calcMove, shoveVel = Vector2.Zero;
float speed = 200;
float momentum, eggCooldown, screenShake, moveCooldown, shakeTimer, gravity = 0;
float baseWeight, weight = .007F;
float eggSpdBoost = 1;
float[] shoveCounter = new float[] {0,0};
float[] dir = new float[] {0,0};
float[] dirListx = new float[12];
float[] dirListy = new float[12];
float[] powerupDir = new float[] {0,0};
bool idle, invincible, powerup, shielded, onFloor = false;
int eggBuffer, eatBuffer, eggCount = 0;
string[] eggs;
int moveRate = 12;
int maxEggs = 25;
int health = 5;
int id = 99;
int lastHitId = 99;
Sprite shield, sprite;
Timer invTimer;
Node2D eggParent, itemParent, gameSpace;
Node2D gun = null;
RayCast2D[] rayCasts = new RayCast2D[12];
Dictionary<int, string> rays = new Dictionary<int, string>(){
	{0, "bottom"}, {1, "top"}, {2, "right"}, {3, "left"}, {4, "br1"}, {5, "tr1"}, {6, "bl1"}, {7, "tl1"}, {8, "br2"}, {9, "tr2"}, {10, "bl2"}, {11, "tl2"}
};
Node Global, Network;
// TextureRect[] heartIcons = new TextureRect[6];
Control game;
Area2D hitbox, itemArea, eggArea;
CollisionShape2D collisionBox;
// Called when the node enters the scene tree for the first time.
public override void _Ready(){
    Global = GetNode<Node>("/root/Global");
    Network = GetNode<Node>("/root/Network");
    sprite = GetNode<Sprite>("Sprite");
    shield = GetNode<Sprite>("Sprite/Shield");
    hitbox = GetNode<Area2D>("Hitbox");
    collisionBox = GetNode<CollisionShape2D>("CollisionShape2D");
    eggParent = GetNode<Node2D>("../EggParent");
    itemParent = GetNode<Node2D>("../ItemParent");
    itemArea = GetNode<Area2D>("ItemArea");
    eggArea = GetNode<Area2D>("EggArea");
    gameSpace = (Node2D)GetParent();
    game = (Control)GetParent().GetParent().GetParent().GetParent();
    baseScale = Scale;
    baseSpriteScale = sprite.Scale;
    baseWeight = weight;
    id = (int)Global.Get("eid");
    moveRate -= (int)Global.Get("difficulty") * 2;
    int i;
    for (i = 0; i < dirListx.Length; i++){
        dirListx[i] = 0;
        dirListy[i] = 0;
    }
    eggs = new string[maxEggs];
    #region raycasts
    rayCasts[0] = GetNode<RayCast2D>("RayCasts/RayCastB");
    rayCasts[1] = GetNode<RayCast2D>("RayCasts/RayCastT");
    rayCasts[2] = GetNode<RayCast2D>("RayCasts/RayCastR");
    rayCasts[3] = GetNode<RayCast2D>("RayCasts/RayCastL");
    rayCasts[4] = GetNode<RayCast2D>("RayCasts/RayCastBR1");
    rayCasts[5] = GetNode<RayCast2D>("RayCasts/RayCastTR1");
    rayCasts[6] = GetNode<RayCast2D>("RayCasts/RayCastBL1");
    rayCasts[7] = GetNode<RayCast2D>("RayCasts/RayCastTL1");
    rayCasts[8] = GetNode<RayCast2D>("RayCasts/RayCastBR2");
    rayCasts[9] = GetNode<RayCast2D>("RayCasts/RayCastTR2");
    rayCasts[10] = GetNode<RayCast2D>("RayCasts/RayCastBL2");
    rayCasts[11] = GetNode<RayCast2D>("RayCasts/RayCastTL2");
    for (i = 0; i < rayCasts.Length; i++){
        if (rayCasts[i].CastTo.y != 0) rayCasts[i].Scale = new Vector2(10, 4);
        else rayCasts[i].Scale = new Vector2(4, 10);
    }
    rayCasts[1].Scale = new Vector2(16,8);
    #endregion
    invTimer = GetNode<Timer>("Invincible");
}

public override void _PhysicsProcess(float delta){
    Move();
    WallCheck();
    Squish(baseSpriteScale);
    ScreenShake();
    if (powerup){
        powerupDir[0] -= delta;
        powerup = powerupDir[0] > 0;
        if (!powerup) ResetPowerups();
    }
}

public void Move(){
	if (!idle){ //update direction
        CalculateMove();
		dir[0] = calcMove.x;
		dir[1] = calcMove.y;
		if (Mathf.Abs(dir[0]) > Mathf.Abs(dir[1])) dir[0] = Mathf.Round(dir[0]);
		else dir[1] = Mathf.Round(dir[1]);
	}
	else{
        invincible = true;
		dir[0] = 0;
		dir[1] = 0;
	}
    onFloor = IsOnWall() && Mathf.Round(GetSlideCollision(0).Normal.y) == -1;
    int current = dirListx.Length - 1;
	int i;
	for (i = 0; i < current; i++){
		dirListx[i] = dirListx[i+1];
		dirListy[i] = dirListy[i+1];
	}
	dirListx[current] = dir[0];
	dirListy[current] = dir[1] + gravity;
	dirListx[current] = myMath.arrayMean(dirListx);
	dirListy[current] = myMath.arrayMean(dirListy);
    momentum = GetMomentum();
    MoveAndSlide(new Vector2(velocity.x, velocity.y) * speed);
    if (idle){
        if (dir[1] < 0 || onFloor) gravity = 0;
        else{
            gravity += weight;
            if (gravity > weight * 200) gravity = weight * 200;
        }
        if (shoveCounter[0] > 0){
            shoveCounter[0] -= 10;
            MoveAndSlide(shoveVel * (shoveCounter[1] * (shoveCounter[0] / shoveCounter[1])));
            if (shoveCounter[0] < 0){
                shoveCounter[0] = 0;
            }
        }
    }
    if (eggCooldown > 0){
        eggCooldown -= 10;
        if (eggCooldown <= 0){
            eggCooldown = 0;
            if (eatBuffer > 0){
                eatBuffer --;
                MakeEgg(true);
                EatFood("normal");
            }
            else if (eggBuffer > 0){
                if (eggCount > 0){
                    eggBuffer --;
                    MakeEgg(false);
                }
                else eggBuffer = 0;
            }
        }
    }
}

public void CalculateMove(float knockBackMod = 1){
    if (moveCooldown > 0){
        moveCooldown -= 1;
        return;
    }
    Vector2 newMove = new Vector2(0,0);
    float[] directions = new float[] {0,0,0,0}; //left, right, up, down
    int i;
    Godot.Collections.Array items = eggArea.GetOverlappingAreas();
    bool isClose = items.Count > 0;
    Node2D item;
    if (isClose){
        float add;
        for (i = 0; i < items.Count; i++){
            item = (Node2D)items[i];
            add = Mathf.Clamp(4 - ((Position.DistanceTo(item.Position)) / 20), 3, 1);
            if (item.Position.y > Position.y) directions[2] += add;
            else directions[3] += add;
            if (item.Position.x > Position.x) directions[0] += add;
            else directions[1] += add;
        }
        for (i = 0; i < rayCasts.Length; i++){
            if (rayCasts[i].IsColliding()){
                switch(rays[i]){
                    case "bottom": directions[2] += 3; break;
                    case "top": directions[3] += 3; break;
                    case "right": directions[0] += 3; break;
                    case "left": directions[1] += 3; break;
                    case "br1": directions[0] += 2; directions[2] += 1; break;
                    case "tr1": directions[0] += 2; directions[3] += 1; break;
                    case "bl1": directions[1] += 2; directions[2] += 1; break;
                    case "tl1": directions[1] += 2; directions[3] += 1; break;
                    case "br2": directions[0] += 1; directions[2] += 2; break;
                    case "tr2": directions[0] += 1; directions[3] += 2; break;
                    case "bl2": directions[1] += 1; directions[2] += 2; break;
                    case "tl2": directions[1] += 1; directions[3] += 2; break;
                }
            }
        }
        if (directions[0] == 0 && directions[1] == 0){
            int sign = Mathf.Sign(calcMove.x);
            if (Position.x < 200) directions[1] += 6;
            else directions[0] += 6;
        }
        int total = (int)(directions[0] + directions[1] + directions[2] + directions[3]);
        for (i = 0; i < 4; i++) directions[i] = directions[i] / total;
        float saver;
        if (Position.x < 40 && directions[0] > directions[1]){
            saver = directions[0];
            directions[0] = directions[1];
            directions[1] = saver;
        }
        else if (Position.x > 440 && directions[1] > directions[0]){
            saver = directions[1];
            directions[1] = directions[0];
            directions[0] = saver;
        }
        newMove = new Vector2(Mathf.Sign(-directions[0] + directions[1]), -directions[2] + directions[3]);
    }
    else{
        // Godot.Collections.Array eggs = eggParent.GetChildren();
        float closest = 999;
        // Node2D item;
        // float mod = 1;
        // for (i = 0; i < eggs.Count; i++){
        //     item = (Node2D)eggs[i];
        //     if (closest == 999 || Position.DistanceTo(item.Position) < closest) closest = Position.DistanceTo(item.Position);
        // }
        // if (closest > 60){
        items = itemArea.GetOverlappingAreas();
        float dist;
        // closest = 999;
        float healthClosest = 999;
        int target = -1;
        for (i = 0; i < items.Count; i++){
            item = (Area2D)items[i];
            dist = Position.DistanceTo(item.Position);
            if (health < 5 && item.IsInGroup("health")){
                if (dist >= healthClosest) continue;
                healthClosest = dist;
                target = i;
            }
            else if (healthClosest > 998 && dist < closest){
                closest = dist;
                target = i;
            }
        }
        if (target != -1){
            item = (Area2D)items[target];
            if (item.Position.x < Position.x){
                directions[0] = 1;
            }
            else directions[1] = 1;
            if (item.Position.y < Position.y){
                directions[2] = 1;
            }
            else directions[3] = 1;
        }
        else{
            Godot.Collections.Array eggs = eggParent.GetChildren();
            for (i = 0; i < eggs.Count; i++){
                item = (Node2D)eggs[i];
                if (244 <= item.Position.x) directions[0] ++;
                else directions[1] ++;
                if (200 <= item.Position.y) directions[2] ++;
                else directions[3] ++;
            }
        }
        // }
        int total = (int)(directions[0] + directions[1] + directions[2] + directions[3]);
        for (i = 0; i < 4; i++) directions[i] = directions[i] / total;
        newMove = new Vector2(Mathf.Sign(-directions[0] + directions[1]), -directions[2] + directions[3]);
        if (newMove == Vector2.Zero) newMove.x = (Position.x > 420 || Position.x < 60) ? 0 : calcMove.x;
    }
    calcMove = newMove * knockBackMod;
    moveCooldown = moveRate;
}

public float GetMomentum(string XorY = ""){
    float mom;
    velocity = new Vector2(myMath.arrayMean(dirListx), myMath.arrayMean(dirListy));
    float absx = Mathf.Abs(velocity.x);
    float absy = Mathf.Abs(velocity.y);
    if (XorY == "") mom = (absx >= absy) ? absx : absy;
    else mom = ("XorY" == "x") ? absx : absy;
    if (mom > 1) mom = 1;
    return mom;
}

public void WallCheck(){
    if (GetSlideCount() < 1) return;
    string direction = "";
    int dirChange = 0;
    if (Mathf.Round(GetSlideCollision(0).Normal.x) != 0){
        direction = "x";
        dirChange = -Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.x));
    }
    else if (Mathf.Round(GetSlideCollision(0).Normal.y) != 0){
        direction = "y";
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.y));
    }
    KnockBack(direction, dirChange, speed * .5F, .05F, 0);
}

public void Squish(Vector2 scale){
    if (scale != baseSpriteScale){ //setter
        scale.x = Mathf.Clamp(scale.x, baseSpriteScale.x * .3F, baseSpriteScale.x * 1.7F);
        scale.y = Mathf.Clamp(scale.y, baseSpriteScale.y * .3F, baseSpriteScale.y * 1.7F);
        sprite.Scale = scale;
        return;
    }
    float newXsc = Mathf.Lerp(sprite.Scale.x, baseSpriteScale.x, .07F);
    float newYsc = Mathf.Lerp(sprite.Scale.y, baseSpriteScale.y, .07F);
    sprite.Scale = new Vector2(newXsc, newYsc);
}

public void ScreenShake(){
    if (screenShake == 0) return;
    if (shakeTimer < 1){
        screenShake = 0;
        gameSpace.Position = new Vector2(0, 0);
        return;
    }
    float rollx = (GD.Randf() < .5F) ? -.5F : .5F;
    float rolly = (GD.Randf() < .5F) ? -.5F : .5F;
    gameSpace.Position = new Vector2(0 + (screenShake * rollx), 0 + (screenShake * rolly));
    shakeTimer -= 10;
}

public void KnockBack(string direction, int dirChange, float power, float lowerBound, float invTime){
    if (direction != "x" && direction != "y") return;
    float bounce = momentum;
    if (bounce < lowerBound) bounce = lowerBound;
    if (bounce > 1) bounce = 1;
    shoveVel = new Vector2(-dirChange, -Mathf.Sign(velocity.y));
    float[] targetList = new float[0];
    float squishAmount = 0;
    if (direction == "x"){
        targetList = dirListx;
        shoveVel.y = 0;
        bounce *= -1;
    }
    else if (direction == "y"){
        targetList = dirListy;
        shoveVel.x = 0;
        if (Mathf.Sign(myMath.arrayMean(targetList)) == dirChange) shoveVel.y *= -1;
    }
    for (int i = 0; i < dirListx.Length; i++){
        targetList[i] = dirChange * bounce;
    }
    float squishPower = power;
    if (invTime != 0 && !shielded){
        invincible = true;
        invTimer.Start(invTime);
        squishPower += 200;
        screenShake = 15 + (power * .025F);
        shakeTimer = 25 + screenShake * 1.3F;
    }
    squishAmount = (myMath.arrayMax(targetList) * .5F * baseSpriteScale.x) * (squishPower / 200);
    if (squishAmount > .75F) squishAmount = .75F;
    if (direction == "y") squishAmount *= -1;
    Squish(new Vector2(baseSpriteScale.x - squishAmount, baseSpriteScale.x + squishAmount));
    shoveCounter[0] = power;
    shoveCounter[1] = shoveCounter[0];
    CalculateMove(.3F);
}

public void EatFood(string type){
    if (idle) return;
    if (eggCount >= maxEggs){
        int eggCnt = eggCount;
        MakeEgg(true);
        if (eggCnt != eggCount) EatFood(type);
        return;
    }
    else{
        eggs[eggCount] = type;
        eggCount ++;
        eggParent.Set("botEggCount", eggCount * .0001F);
    }
    sprite.Scale = baseSpriteScale;
    Scale = new Vector2(baseScale.x + (.05F * eggCount), baseScale.y + (.05F * eggCount));
    baseSpriteScale = sprite.Scale;
    weight = baseWeight + (eggCount * .0002F);
    Squish(new Vector2(baseSpriteScale.x * .85F, baseSpriteScale.y * 1.15F));
    float roll = (GD.Randi() % 100 + 1) * .01F;
    if (roll < (eggCount / maxEggs)){
        eggBuffer = Mathf.RoundToInt(eggCount * roll);
        if (eggCooldown <= 0) eggCooldown = 1;
    }
    // eggBar.Call("drawEggs", eggs[eggCount - 1]);
}

public void MakeEgg(bool automatic){
    if (eggs[0] == "") eggs[0] = "normal";
    if (eggCount < 1 || idle) return;
    if (eggCooldown > 0){
        if (!automatic) eggBuffer ++;
        return;
    }
    eggCount --;
    eggParent.Set("botEggCount", eggCount * .0001F);
    eggParent.Call("makeEgg", id, eggs[0], new Vector2(Position.x, Position.y + 15 + (15 * (eggCount/maxEggs))), eggSpdBoost);
    for (int i = 0; i < maxEggs - 1; i++){
        if (eggs[i+1] == null) break;
        eggs[i] = eggs[i+1];
        eggs[i+1] = null;
    }
    sprite.Scale = baseSpriteScale;
    Scale = new Vector2(baseScale.x + (.05F * eggCount), baseScale.y + (.05F * eggCount));
    baseSpriteScale = sprite.Scale;
    weight = baseWeight + (eggCount * .0002F);
    Squish(new Vector2(baseSpriteScale.x * 1.3F, baseSpriteScale.y * .7F));
    eggCooldown = (automatic) ? 90 : 30;
    // eggBar.Call("drawEggs", "");
}

public void DetectCollision(float power, float lowerBound, float invTime){
    int i;
    for (i = 0; i < rayCasts.Length; i++){
        if (rayCasts[i].IsColliding()) break;
    }
    if (i == rayCasts.Length){ //default if not detected
        KnockBack("y", 1, power, lowerBound, invTime);
        return;
    }
    String dir = "";
    int dirChange = 0;
    switch(rays[i]){
        case "bottom":
            dir = "y";
            dirChange = -1;
            break;
        case "top":
            dir = "y";
            dirChange = 1;
            break;
        case "right":
            dir = "x";
            dirChange = 1;
            break;
        case "left":
            dir = "x";
            dirChange = -1;
            break;
        case "br1":
            dir = "x";
            dirChange = 1;
            break;
        case "tr1":
            dir = "x";
            dirChange = 1;
            break;
        case "bl1":
            dir = "x";
            dirChange = -1;
            break;
        case "tl1":
            dir = "x";
            dirChange = -1;
            break;
        case "br2":
            dir = "y";
            dirChange = -1;
            break;
        case "tr2":
            dir = "y";
            dirChange = 1;
            break;
        case "bl2":
            dir = "y";
            dirChange = -1;
            break;
        case "tl2":
            dir = "y";
            dirChange = 1;
            break;
    }
    KnockBack(dir, dirChange, power, lowerBound, invTime);
}

public void _on_Hitbox_area_entered(Node body){
    Godot.Collections.Array groups = body.GetGroups();
    float knockb = 0;
    string type;
    foreach (string group in groups){
    switch (group){
        case "eggs":
            int eggId = (int)body.Get("id");
            if (invincible || eggId == id) return;
            knockb = (float)body.Get("knockback");
            if (!shielded){
                health -= (int)body.Get("damage");
                if (eggId != 99) lastHitId = eggId;
                if (health < 1) health = 0;
                game.Call("registerHealth", (int)Global.Get("eid"), lastHitId, health);
                itemParent.Set("playerHealth", health);
            }
            DetectCollision(knockb, .3F + (knockb * .0005F), .25F);
            body.QueueFree();
            if ((bool)Global.Get("online")) Network.Call("sendHealth", id, lastHitId, health, 0);
            break;
        case "food":
            if (eatBuffer > 0) return;
            type = (string)body.Get("type");
            int c = 1;
            if (type == "three"){
                c = 3;
                type = "normal";
            }
            for (int i = 0; i < c; i++){
                if (c > 1 && eggCount == maxEggs){
                    eatBuffer = c - i;
                    if (eggCooldown < 1) eggCooldown = 1;
                    break;
                }
                EatFood(type);
            }
            body.QueueFree();
            itemParent.Set("itemCount", (int)itemParent.Get("itemCount") - 1);
            break;
        case "health":
            if (health < 1) return;
            if (health < 5){
                health ++;
                // heartIcons[health-1].Visible = true;
                itemParent.Set("playerHealth", health);
                if (health == 5) lastHitId = 99;
                game.Call("registerHealth", (int)Global.Get("eid"), lastHitId, health);
            }
            else EatFood("normal");
            body.QueueFree();
            itemParent.Set("itemCount", (int)itemParent.Get("itemCount") - 1);
            Squish(new Vector2(baseSpriteScale.x * .85F, baseSpriteScale.y * 1.15F));
            if ((bool)Global.Get("online")) Network.Call("sendHealth", id, lastHitId, health, 0);
            break;
        case "powerups":
            type = (string)body.Get("type");
            Squish(new Vector2(baseSpriteScale.x * .85F, baseSpriteScale.y * 1.15F));
            bool isPowerup = type == "butter" || type == "shield" || type == "gun" || type == "shrink";
            if (isPowerup && powerupDir[0] != 0) ResetPowerups();
            if (type == "butter"){
                eggSpdBoost = 1.5F;
                powerupDir[0] = 5;
                sprite.Modulate = Godot.Colors.Yellow;
            }
            else if (type == "shield"){
                powerupDir[0] = 8;
                shielded = true;
                shield.Visible = true;
            }
            else if (type == "shrink"){
                powerupDir[0] = 13;
                baseSpriteScale = new Vector2(.3F, .3F);
                collisionBox.Scale *= .5F;
                hitbox.Scale *= .5F;
            }
            else if (type == "gun"){
                powerupDir[0] = 10;
                itemParent.Call("spawnGun");
            }
            else if (type == "wildcard") eggParent.Call("activateWildcard");
            if (isPowerup){
                powerupDir[1] = powerupDir[0];
                game.Call("setPowerupIcon", id, type);
                powerup = true;
            }
            body.QueueFree();
            if ((bool)Global.Get("online")) Network.Call("sendStatus", id, type, 0);
            break;
        case "explosions":
            int explosionId = (int)body.Get("id");
            if (invincible) return;
            knockb = (float)body.Get("knockback");
            if (!shielded){
                health -= (int)body.Get("damage");
                if (explosionId != 99) lastHitId = explosionId;
                if (health < 1) health = 0;
                game.Call("registerHealth", (int)Global.Get("eid"), lastHitId, health);
                itemParent.Set("playerHealth", health);
            }
            DetectCollision(knockb, .3F + (knockb * .0005F), .25F);
            if ((bool)Global.Get("online")) Network.Call("sendHealth", id, lastHitId, health, 0);
            break;
    }
    }
}

public void ResetPowerups(){
    game.Call("setPowerupIcon", id, "");
    powerupDir[0] = 0;
    powerupDir[1] = 0;
    if (eggSpdBoost != 1){
        eggSpdBoost = 1;
        sprite.Modulate = Godot.Colors.White;
    }
    else if (shielded){
        shielded = false;
        shield.Visible = false;
    }
    else if (baseSpriteScale.x < .6F){
        baseSpriteScale = new Vector2(.6F, .6F);
        collisionBox.Scale *= 2;
        hitbox.Scale *= 2;
    }
    else if (gun != null){
        gun.QueueFree();
        gun = null;
    }
    if ((bool)Global.Get("online")) Network.Call("sendStatus", id, "", 0);
}

public void _on_Invincible_timeout(){
    invincible = false;
}

}
