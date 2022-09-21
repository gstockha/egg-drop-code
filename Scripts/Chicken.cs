using Godot;
using System;
using System.Collections.Generic;
using MyMath;

public class Chicken : KinematicBody2D
{
Vector2 baseSpriteScale, baseScale, velocity, shoveVel = Vector2.Zero;
float speed = 400;
float momentum, eggCooldown, gravity = 0;
float baseWeight, weight = .007F;
float[] shoveCounter = new float[] {0,0};
float[] dir = new float[] {0,0};
float[] dirListx = new float[12];
float[] dirListy = new float[12];
bool idle, invincible, onFloor = false;
int eggCount = 0;
string[] eggs;
int maxEggs = 25;
int health = 3;
Sprite sprite;
Timer invTimer;
Node2D eggParent;
RayCast2D[] rayCasts = new RayCast2D[12];
Dictionary<int, string> rays = new Dictionary<int, string>(){
	{0, "bottom"}, {1, "top"}, {2, "right"}, {3, "left"}, {4, "br1"}, {5, "tr1"}, {6, "bl1"}, {7, "tl1"}, {8, "br2"}, {9, "tr2"}, {10, "bl2"}, {11, "tl2"}
};
Node Global;
Position2D butthole;

// Called when the node enters the scene tree for the first time.
public override void _Ready(){
    Global = GetNode<Node>("/root/Global");
    sprite = GetNode<Sprite>("Sprite");
    eggParent = GetNode<Node2D>("../EggParent");
    butthole = GetNode<Position2D>("Butthole");
    baseScale = Scale;
    baseSpriteScale = sprite.Scale;
    baseWeight = weight;
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
    #endregion
    invTimer = GetNode<Timer>("Invincible");
}

public override void _PhysicsProcess(float _delta){
    Move();
    WallCheck();
    Squish(baseSpriteScale);
    if (eggCooldown > 0){
        eggCooldown -= 10;
        if (eggCooldown < 0) eggCooldown = 0;
    }
}

public void Move(){
	if (!idle){ //update direction
		dir[0] = Input.GetActionStrength("right") - Input.GetActionStrength("left");
		dir[1] = Input.GetActionStrength("down") - Input.GetActionStrength("up");
		if (Mathf.Abs(dir[0]) > Mathf.Abs(dir[1])) dir[0] = Mathf.Round(dir[0]);
		else dir[1] = Mathf.Round(dir[1]);
	}
	else{
		dir[0] = 0;
		dir[1] = 0;
	}
    onFloor = IsOnWall() && Mathf.Round(GetSlideCollision(0).Normal.y) == -1;
    if (dir[1] < 0 || onFloor) gravity = 0;
    else{
        gravity += weight;
        if (gravity > weight * 200) gravity = weight * 200;
    }
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
    if (shoveCounter[0] > 0){
        shoveCounter[0] -= 10;
        MoveAndSlide(shoveVel * (shoveCounter[1] * (shoveCounter[0] / shoveCounter[1])));
        if (shoveCounter[0] < 0){
            shoveCounter[0] = 0;
        }
    }
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
    squishAmount = (myMath.arrayMax(targetList) * .5F * baseSpriteScale.x) * (power / 200);
    if (direction == "y") squishAmount *= -1;
    Squish(new Vector2(baseSpriteScale.x - squishAmount, baseSpriteScale.x + squishAmount));
    shoveCounter[0] = power;
    shoveCounter[1] = shoveCounter[0];
    if (invTime != 0){
        invincible = true;
        invTimer.Start(invTime);
    }
}

public void EatFood(string type){
    if (eggCount + 1 >= maxEggs){
        for (int i = 0; i < maxEggs - 1; i++) eggs[i] = eggs[i+1];
        eggs[maxEggs-1] = type;
        eggCount = maxEggs;
    }
    else{
        eggs[eggCount] = type;
        eggCount ++;
    }
    sprite.Scale = baseSpriteScale;
    Scale = new Vector2(baseScale.x + (.05F * eggCount), baseScale.y + (.05F * eggCount));
    baseSpriteScale = sprite.Scale;
    weight = baseWeight + (eggCount * .0002F);
    Squish(new Vector2(baseSpriteScale.x * .85F, baseSpriteScale.y * 1.15F));
    GD.Print(eggCount);
}

public override void _Input(InputEvent @event){
    if (@event.IsActionPressed("egg_lay")){
        if (eggCount < 1 || eggCooldown > 0) return;
        eggCount --;
        eggParent.Call("makeEgg", (int)Global.Get("id"), eggs[eggCount], butthole.GlobalPosition);
        eggs[eggCount] = null;
        sprite.Scale = baseSpriteScale;
        Scale = new Vector2(baseScale.x + (.05F * eggCount), baseScale.y + (.05F * eggCount));
        baseSpriteScale = sprite.Scale;
        weight = baseWeight + (eggCount * .0002F);
        Squish(new Vector2(baseSpriteScale.x * 1.3F, baseSpriteScale.y * .7F));
        eggCooldown = 10;
        GD.Print(eggCount);
    }
}

public void DetectCollision(float power, float lowerBound, float invTime){
    int i;
    for (i = 0; i < rayCasts.Length; i++){
        if (rayCasts[i].IsColliding()) break;
    }
    if (i == rayCasts.Length) return;
    GD.Print(rays[i]);
    switch(rays[i]){
        case "bottom":
            KnockBack("y", -1, power, lowerBound, invTime);
            break;
        case "top":
            KnockBack("y", 1, power, lowerBound, invTime);
            break;
        case "right":
            KnockBack("x", 1, power, lowerBound, invTime);
            break;
        case "left":
            KnockBack("x", -1, power, lowerBound, invTime);
            break;
        case "br1":
            KnockBack("x", 1, power, lowerBound, invTime);
            break;
        case "tr1":
            KnockBack("x", 1, power, lowerBound, invTime);
            break;
        case "bl1":
            KnockBack("x", -1, power, lowerBound, invTime);
            break;
        case "tl1":
            KnockBack("x", -1, power, lowerBound, invTime);
            break;
        case "br2":
            KnockBack("y", -1, power, lowerBound, invTime);
            break;
        case "tr2":
            KnockBack("y", 1, power, lowerBound, invTime);
            break;
        case "bl2":
            KnockBack("y", -1, power, lowerBound, invTime);
            break;
        case "tl2":
            KnockBack("y", 1, power, lowerBound, invTime);
            break;
    }
    if (!invincible) KnockBack("y", 1, power, lowerBound, invTime); //default if not detected
}

public void _on_Hitbox_area_entered(Node body){
    Godot.Collections.Array group = body.GetGroups();
    int knockb = 0;
    string type;
    switch (group[0]){
        case "eggs":
            if (invincible || (int)body.Get("id") == (int)Global.Get("id")) return;
            knockb = (int)body.Get("knockback");
            health -= (int)body.Get("damage");
            eggParent.Set("playerHealth", health);
            DetectCollision(knockb, .3F + (knockb * .0005F), .1F);
            body.QueueFree();
            break;
        case "food":
            type = (string)body.Get("type");
            EatFood(type);
            body.QueueFree();
            break;
    }
}

public void _on_Invincible_timeout(){
    invincible = false;
}

}
