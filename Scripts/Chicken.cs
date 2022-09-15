using Godot;
using System;
using MyMath;

public class Chicken : KinematicBody2D
{
Vector2 velocity, shoveVel = Vector2.Zero;
float speed = 300;
float momentum, gravity = 0;
float weight = .007F;
float bounce = .7F;
float[] shoveCounter = new float[] {0,0};
float[] dir = new float[] {0,0};
float[] dirListx = new float[10];
float[] dirListy = new float[10];
bool idle, onFloor = false;

// Called when the node enters the scene tree for the first time.
public override void _Ready(){
    for (int i = 0; i < dirListx.Length; i++){
        dirListx[i] = 0;
        dirListy[i] = 0;
    }
}

public override void _PhysicsProcess(float delta){
    _Move(delta);
    _WallCheck();
}

public void _Move(float delta){
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
        // if (shoveVel.x != 0 && Mathf.Sign(velocity.x) == Mathf.Sign(shoveVel.x)) shoveVel.x = 0;
        // if (shoveVel.y != 0 && Mathf.Sign(velocity.y) == Mathf.Sign(shoveVel.y)) shoveVel.y = 0;
        if (shoveVel != Vector2.Zero){
            shoveCounter[0] -= 10;
            MoveAndSlide(shoveVel * (shoveCounter[1] * (shoveCounter[0] / shoveCounter[1])));
        }
        else shoveCounter[0] = 0;
    }
}

public float _GetMomentum(){
    float mom;
    velocity = new Vector2(myMath.arrayMean(dirListx), myMath.arrayMean(dirListy));
    float absx = Mathf.Abs(velocity.x);
    float absy = Mathf.Abs(velocity.y);
    mom = (absx >= absy) ? absx : absy;
    if (mom > 1) mom = 1;
    return mom;
}
public void _WallCheck(){
    if (IsOnWall() == false) return;
    shoveVel = new Vector2(-1 * Mathf.Sign(velocity.x), -1 * Mathf.Sign(velocity.y));
    int i;
    int dirChange;
    if (Mathf.Round(GetSlideCollision(0).Normal.x) != 0){
        shoveVel.y = 0;
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.x));
        for (i = 0; i < dirListx.Length; i++){
            dirListx[i] *= (Mathf.Sign(dirListx[i]) != dirChange) ? -bounce : bounce;
            if (Mathf.Abs(dirListx[i]) < .05F) dirListx[i] = 0;
        }
    }
    else if (Mathf.Round(GetSlideCollision(0).Normal.y) != 0){
        shoveVel.x = 0;
        dirChange = Mathf.Sign(Mathf.Round(GetSlideCollision(0).Normal.y));
        for (i = 0; i < dirListx.Length; i++){
            dirListy[i] *= (Mathf.Sign(dirListy[i]) != dirChange) ? -bounce : bounce;
            if (Mathf.Abs(dirListy[i]) < .05F) dirListy[i] = 0;
        }
    }
    shoveCounter[0] = speed;
    shoveCounter[1] = shoveCounter[0];
}

public void _on_Hitbox_body_entered(Node body){
    // Godot.Collections.Array groups = body.GetGroups();
    // foreach (String group in groups){
    //     switch (group){
    //     }
    // }
}
}
