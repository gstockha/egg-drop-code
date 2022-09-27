using Godot;
using System;

public class Game : Control
{
    public override void _Ready(){
        
    }

    public override void _Input(InputEvent @event){
        if (@event.IsActionPressed("fullscreen")){
            OS.WindowFullscreen = !OS.WindowFullscreen;
        }
    }
}
