package com.example.aironchef;

import android.os.Bundle;
import android.content.Intent;
import android.os.Handler;
import android.view.animation.Animation;
import android.view.animation.AnimationUtils;
import android.widget.ImageView;
import androidx.appcompat.app.AppCompatActivity;

public class SplashActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.splash_screen);

        ImageView knife1 = findViewById(R.id.knife1);
        ImageView knife2 = findViewById(R.id.knife2);

        // Load animations
        Animation knife1Anim = AnimationUtils.loadAnimation(this, R.anim.fly_in_left);
        Animation knife2Anim = AnimationUtils.loadAnimation(this, R.anim.fly_in_right);

        // Delay the knife animations slightly after the logo pop
        new Handler().postDelayed(() -> {
            knife1.setVisibility(ImageView.VISIBLE);
            knife2.setVisibility(ImageView.VISIBLE);
            knife1.startAnimation(knife1Anim);
            knife2.startAnimation(knife2Anim);
        }, 500); // Start knives after 500ms delay

        // Move to MainActivity after 3 seconds
        new Handler().postDelayed(() -> {
            Intent intent = new Intent(SplashActivity.this, MainActivity.class);
            startActivity(intent);
            finish();
        }, 4000);
    }
}