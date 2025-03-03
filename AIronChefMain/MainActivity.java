package com.example.lab1homework;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TextView;

public class MainActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        LinearLayout screen = new LinearLayout(this);
        screen.setOrientation(LinearLayout.VERTICAL);
        screen.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.MATCH_PARENT
        ));

        LinearLayout nameSection = new LinearLayout(this);
        nameSection.setOrientation(LinearLayout.VERTICAL);

        TextView nameLabel = new TextView(this);
        nameLabel.setText("Please enter your name:");
        EditText nameInput = new EditText(this);

        nameSection.addView(nameLabel);
        nameSection.addView(nameInput);

        LinearLayout optionsLayout = new LinearLayout(this);
        optionsLayout.setOrientation(LinearLayout.HORIZONTAL);
        optionsLayout.setLayoutParams(new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
        ));

        LinearLayout checkBoxLayout = new LinearLayout(this);
        checkBoxLayout.setOrientation(LinearLayout.VERTICAL);
        checkBoxLayout.setLayoutParams(new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1 // Weight 1
        ));

        TextView checkBoxLabel = new TextView(this);
        checkBoxLabel.setText("Select your colors:");
        CheckBox chk1 = new CheckBox(this);
        CheckBox chk2 = new CheckBox(this);
        CheckBox chk3 = new CheckBox(this);
        CheckBox chk4 = new CheckBox(this);
        chk1.setText("Red");
        chk2.setText("Green");
        chk3.setText("Blue");
        chk4.setText("Yellow");

        checkBoxLayout.addView(checkBoxLabel);
        checkBoxLayout.addView(chk1);
        checkBoxLayout.addView(chk2);
        checkBoxLayout.addView(chk3);
        checkBoxLayout.addView(chk4);

        LinearLayout radioButtonLayout = new LinearLayout(this);
        radioButtonLayout.setOrientation(LinearLayout.VERTICAL);
        radioButtonLayout.setLayoutParams(new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1 // Weight 1
        ));

        TextView radioLabel = new TextView(this);
        radioLabel.setText("Select your course:");
        RadioGroup radioGroup = new RadioGroup(this);
        RadioButton rb1 = new RadioButton(this);
        RadioButton rb2 = new RadioButton(this);
        RadioButton rb3 = new RadioButton(this);
        RadioButton rb4 = new RadioButton(this);
        rb1.setText("CS");
        rb2.setText("IA");
        rb3.setText("IB");
        rb4.setText("CN");

        radioGroup.addView(rb1);
        radioGroup.addView(rb2);
        radioGroup.addView(rb3);
        radioGroup.addView(rb4);

        radioButtonLayout.addView(radioLabel);
        radioButtonLayout.addView(radioGroup);

        optionsLayout.addView(checkBoxLayout);
        optionsLayout.addView(radioButtonLayout);

        Button submitButton = new Button(this);
        submitButton.setText("Submit");

        screen.addView(nameSection);
        screen.addView(optionsLayout);
        screen.addView(submitButton);

        setContentView(screen);

    }
}