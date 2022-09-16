using Godot;
using System;
using MyMath;

public class Chicken : KinematicBody2D
{
Vector2 spriteScale, velocity, shoveVel = Vector2.Zero;
float speed = 300;
float momentum, gravity = 0;
float weight = .007F;
float bounce = 0;
float[] shoveCounter = new float[] {0,0};
float[] dir = new float[] {0,0};
float[] dirListx = new float[10];
float[] dirListy = new float[10];
bool idle, onFloor = false;
Sprite sprite;

// Called when the node enters the scene tree for the first time.
public override void _Ready(){
    sprite = GetNode<Sprite>("Sprite");
    spriteScale = sprite.Scale;
    for (int i = 0; i < dirListx.Length; i++){
        dirListx[i] = 0;
        dirListy[i] = 0;
    }
}

public override void _PhysicsProcess(float _delta){
    _Move();
    _ShoveCheck();
    _Squish(spriteScale);
}

public void _Move(){
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
    onFloor = IsOnWall() && Mathf.Round(GetSlideCollision(0).Normal.y) == -1;
    momentum = _GetMomentum();
    MoveAndSlide(new Vector2(velocity.x, velocity.y) * speed);
    if (shoveCounter[0] > 0){
        shoveCounter[0] -= 10;
        MoveAndSlide(shoveVel * (shoveCounter[1] * (shoveCounter[0] / shoveCounter[1])));
        if (shoveCounter[0] < 0){
            bounce = 0;
            shoveCounter[0] = 0;
        }
    }
}

public float _GetMomentum(String XorY = ""){
    float mom;
    velocity = new Vector2(myMath.arrayMean(dirListx), myMath.arrayMean(dirListy));
    float absx = Mathf.Abs(velocity.x);
    float absy = Mathf.Abs(velocity.y);
    if (XorY == "") mom = (absx >= absy) ? absx : absy;
    else mom = ("XorY" == "x") ? absx : absy;
    if (mom > 1) mom = 1;
    return mom;
}

public void _ShoveCheck(){
    GD.Print(IsOnWall());
    if (IsOnWall() == false) return;
    shoveVel = new Vector2(-1 * Mathf.Sign(velocity.x), -1 * Mathf.Sign(velocity.y));
    int i;
    int dirChange;
    float squishAmount;
    bool hitGround = Mathf.Round(GetSlideCollision(0).Normal.y) == -1;
    if (Mathf.Round(GetSlideCollision(0).Normal.x) != 0){
        bounce = _GetMomentum("x");
        shoveVel.y = 0;
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.x));
        for (i = 0; i < dirListx.Length; i++){
            dirListx[i] *= (Mathf.Sign(dirListx[i]) != dirChange) ? -bounce : bounce;
            if (Mathf.Abs(dirListx[i]) < .05F) dirListx[i] = 0;
        }
        squishAmount = myMath.arrayMax(dirListx) * .6F * spriteScale.x;
        _Squish(new Vector2(spriteScale.x - squishAmount, spriteScale.x + squishAmount));
    }
    else if (Mathf.Round(GetSlideCollision(0).Normal.y) != 0){
        bounce = _GetMomentum("y");
        shoveVel.x = 0;
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.y));
        for (i = 0; i < dirListx.Length; i++){
            dirListy[i] *= (Mathf.Sign(dirListy[i]) != dirChange) ? -bounce : bounce;
            if (Mathf.Abs(dirListy[i]) < .05F) dirListy[i] = 0;
        }
        squishAmount = myMath.arrayMax(dirListy) * spriteScale.y;
        squishAmount *= (hitGround) ? .3F : .4F;
        _Squish(new Vector2(spriteScale.x + squishAmount, spriteScale.y - squishAmount));
    }
    // if (hitGround) bounce *= .01F;
    // if (bounce < 0.1F){
    //     bounce = 0;
    //     return;
    // }
    shoveCounter[0] = speed;
    shoveCounter[1] = shoveCounter[0];
}

public void _Squish(Vector2 scale){
    if (scale != spriteScale){ //setter
        sprite.Scale = scale;
        return;
    }
    float newXsc = Mathf.Lerp(sprite.Scale.x, spriteScale.x, .07F);
    float newYsc = Mathf.Lerp(sprite.Scale.y, spriteScale.y, .07F);
    sprite.Scale = new Vector2(newXsc, newYsc);
}

public void _on_Hitbox_area_entered(Node body){
    // Godot.Collections.Array groups = body.GetGroups();
    // foreach (String group in groups){
    //     switch (group){

    //     }
    // }
}
}
