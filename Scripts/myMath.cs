using System;
using Godot;

namespace MyMath{
    public static class myMath{
        public static float arrayMean(float[] array){
            float total = 0;
            for (int i = 0; i < array.Length; i++){
                total += (float)array[i];
            }
            if (float.IsNaN(total)) return 0;
            return ((float)total / array.Length);
        }

        public static float arrayMax(float[] array){
            float maxval = 0;
            for (int i = 0; i < array.Length; i++){
                if (Math.Abs(array[i]) > maxval == true) maxval = Math.Abs(array[i]);
            }
            return maxval;
        }
    }
}