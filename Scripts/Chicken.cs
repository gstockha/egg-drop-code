using Godot;
using System;
using System.Collections.Generic;
using MyMath;

public class Chicken : KinematicBody2D
{
Vector2 baseScale, velocity, shoveVel = Vector2.Zero;
float speed = 300;
float momentum, gravity = 0;
float weight = .007F;
float[] shoveCounter = new float[] {0,0};
float[] dir = new float[] {0,0};
float[] dirListx = new float[10];
float[] dirListy = new float[10];
bool idle, invincible, onFloor = false;
Sprite sprite;
Timer invTimer;
RayCast2D[] rayCasts = new RayCast2D[12];
Dictionary<int, string> rays = new Dictionary<int, string>(){
	{0, "bottom"}, {1, "top"}, {2, "right"}, {3, "left"}, {4, "br1"}, {5, "tr1"}, {6, "bl1"}, {7, "tl1"}, {8, "br2"}, {9, "tr2"}, {10, "bl2"}, {11, "tl2"}
};

// Called when the node enters the scene tree for the first time.
public override void _Ready(){
    sprite = GetNode<Sprite>("Sprite");
    baseScale = sprite.Scale;
    for (int i = 0; i < dirListx.Length; i++){
        dirListx[i] = 0;
        dirListy[i] = 0;
    }
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
    Squish(baseScale);
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
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.x));
    }
    else if (Mathf.Round(GetSlideCollision(0).Normal.y) != 0){
        direction = "y";
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.y));
    }
    KnockBack(direction, dirChange, speed, .05F, 0);
}

public void KnockBack(string direction, int dirChange, float power, float lowerBound, float invTime){
    if (direction != "x" && direction != "y") return;
    shoveVel = new Vector2(-Mathf.Sign(velocity.x), -Mathf.Sign(velocity.y));
    float bounce = GetMomentum(direction);
    float[] targetList = new float[0];
    float squishAmount = 0;
    float squishMult = .6F;
    if (direction == "x"){
        targetList = dirListx;
        shoveVel.y = 0;
        if (Mathf.Sign(myMath.arrayMean(targetList)) == dirChange) bounce *= -1; //don't reverse
    }
    else if (direction == "y"){
        targetList = dirListy;
        shoveVel.x = 0;
        squishMult *= .5F;
        if (Mathf.Sign(myMath.arrayMean(targetList)) == dirChange) shoveVel.y *= -1; //don't reverse
    }
    for (int i = 0; i < dirListx.Length; i++){
        targetList[i] *= (Mathf.Sign(targetList[i]) == dirChange) ? bounce : -bounce;
        if (Mathf.Abs(targetList[i]) < lowerBound) targetList[i] = lowerBound * Mathf.Sign(targetList[i]);
        else if (Mathf.Abs(targetList[i]) > 1) targetList[i] = 1 * Mathf.Sign(targetList[i]);
    }
    squishAmount = (myMath.arrayMax(targetList) * squishMult * baseScale.x) * (power / speed);
    if (direction == "y") squishAmount *= -1;
    Squish(new Vector2(baseScale.x - squishAmount, baseScale.x + squishAmount));
    shoveCounter[0] = power;
    shoveCounter[1] = shoveCounter[0];
    if (invTime != 0){
        invincible = true;
        invTimer.Start(invTime);
    }
}

public void Squish(Vector2 scale){
    if (scale != baseScale){ //setter
        if (Mathf.Abs(scale.x) > Mathf.Abs(baseScale.x * 1.8F)) scale.x = baseScale.x * 1.7F * Mathf.Sign(scale.x);
        if (Mathf.Abs(scale.y) > Mathf.Abs(baseScale.y * 1.8F)) scale.y = baseScale.y * 1.7F * Mathf.Sign(scale.y);
        sprite.Scale = scale;
        return;
    }
    float newXsc = Mathf.Lerp(sprite.Scale.x, baseScale.x, .07F);
    float newYsc = Mathf.Lerp(sprite.Scale.y, baseScale.y, .07F);
    sprite.Scale = new Vector2(newXsc, newYsc);
}

public void _on_Hitbox_area_entered(Node body){
    Godot.Collections.Array group = body.GetGroups();
    switch (group[0]){
        case "eggs":
            if (invincible) return;
            int i;
            for (i = 0; i < rayCasts.Length; i++){
                if (rayCasts[i].IsColliding()) break;
            }
            if (i == rayCasts.Length) return;
            GD.Print(rays[i]);
            switch(rays[i]){
                case "bottom":
                    KnockBack("y", -1, speed * 2, .6F, .1F);
                    break;
                case "top":
                    KnockBack("y", 1, speed * 2, .6F, .1F);
                    break;
                case "right":
                    KnockBack("x", 1, speed * 2, .6F, .1F);
                    break;
                case "left":
                    KnockBack("x", -1, speed * 2, .6F, .1F);
                    break;
                case "br1":
                    KnockBack("x", 1, speed * 2, .6F, .1F);
                    break;
                case "tr1":
                    KnockBack("x", 1, speed * 2, .6F, .1F);
                    break;
                case "bl1":
                    KnockBack("x", -1, speed * 2, .6F, .1F);
                    break;
                case "tl1":
                    KnockBack("x", -1, speed * 2, .6F, .1F);
                    break;
                case "br2":
                    KnockBack("y", -1, speed * 2, .6F, .1F);
                    break;
                case "tr2":
                    KnockBack("y", 1, speed * 2, .6F, .1F);
                    break;
                case "bl2":
                    KnockBack("y", -1, speed * 2, .6F, .1F);
                    break;
                case "tl2":
                    KnockBack("y", 1, speed * 2, .6F, .1F);
                    break;
            }
            break;
    }
}

public void _on_Invincible_timeout(){
    invincible = false;
}

}
