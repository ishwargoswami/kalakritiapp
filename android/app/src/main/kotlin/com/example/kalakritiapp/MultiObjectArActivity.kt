package com.example.kalakritiapp

import android.app.Activity
import android.app.AlertDialog
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Color
import android.os.Bundle
import android.os.Environment
import android.util.Log
import android.view.MotionEvent
import android.view.View
import android.widget.ImageButton
import android.widget.ImageView
import android.widget.LinearLayout
import android.widget.SeekBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.google.android.filament.utils.Utils
import com.google.ar.core.*
import com.google.ar.core.exceptions.*
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.text.SimpleDateFormat
import java.util.*
import kotlin.math.abs

class MultiObjectArActivity : AppCompatActivity() {
    companion object {
        private const val TAG = "MultiObjectArActivity"
        private val AVAILABLE_MODELS = listOf(
            "alien_flowers.glb",
            "chair.glb",
            "table.glb",
            "stand.glb",
            "AR-Code-1683007596576.glb"
        )
        
        fun launch(activity: Activity) {
            val intent = Intent(activity, MultiObjectArActivity::class.java)
            activity.startActivity(intent)
        }
    }

    private lateinit var messageText: TextView
    private lateinit var modelsLayout: LinearLayout
    private val placedModels = mutableListOf<ArModel>()
    private var selectedModel: ArModel? = null
    
    // Track currently selected model file name
    private var currentModelFileName = AVAILABLE_MODELS[0]

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_multi_object_ar)

        messageText = findViewById(R.id.message_text)
        modelsLayout = findViewById(R.id.models_layout)

        // Set up button listeners
        findViewById<ImageButton>(R.id.close_button).setOnClickListener { finish() }
        findViewById<ImageButton>(R.id.reset_button).setOnClickListener { resetScene() }
        findViewById<ImageButton>(R.id.help_button).setOnClickListener { showHelpDialog() }
        findViewById<ImageButton>(R.id.capture_button).setOnClickListener { captureArScene() }

        // Initialize AR session
        initializeArSession()
        
        // Set up model selection thumbnails
        setupModelSelectionThumbnails()
    }

    private fun setupModelSelectionThumbnails() {
        modelsLayout.removeAllViews()
        
        // Create thumbnails for each available model
        AVAILABLE_MODELS.forEachIndexed { index, modelName ->
            val thumbnail = ImageView(this).apply {
                setImageResource(getModelThumbnailResource(modelName))
                layoutParams = LinearLayout.LayoutParams(150, 150).apply {
                    marginEnd = 16
                }
                contentDescription = "3D model: ${modelName.replace(".glb", "")}"
                
                // Highlight the current selection
                background = if (modelName == currentModelFileName) {
                    ContextCompat.getDrawable(this@MultiObjectArActivity, 
                        android.R.drawable.picture_frame)
                } else null
                
                // Set click listener to select this model
                setOnClickListener {
                    currentModelFileName = modelName
                    messageText.text = "Selected model: ${modelName.replace(".glb", "")}"
                    
                    // Update thumbnail highlighting
                    setupModelSelectionThumbnails()
                }
            }
            
            // Add "+" button after each thumbnail
            val addButton = ImageButton(this).apply {
                setImageResource(android.R.drawable.ic_input_add)
                layoutParams = LinearLayout.LayoutParams(100, 100).apply {
                    marginEnd = 24
                }
                contentDescription = "Add ${modelName.replace(".glb", "")} to scene"
                setBackgroundColor(Color.TRANSPARENT)
                
                setOnClickListener {
                    addModelToScene(modelName)
                }
            }
            
            modelsLayout.addView(thumbnail)
            modelsLayout.addView(addButton)
        }
    }
    
    private fun getModelThumbnailResource(modelName: String): Int {
        // Replace with actual thumbnail resources based on model name
        return when(modelName) {
            "chair.glb" -> android.R.drawable.ic_menu_add
            "table.glb" -> android.R.drawable.ic_menu_agenda
            "stand.glb" -> android.R.drawable.ic_menu_gallery
            "AR-Code-1683007596576.glb" -> android.R.drawable.ic_menu_compass
            else -> android.R.drawable.ic_menu_view
        }
    }
    
    private fun addModelToScene(modelName: String) {
        // Logic to add a new model with the selected file name to the AR scene
        try {
            // Create a new AR model using the selected file name
            val newModel = ArModel(modelName)
            placedModels.add(newModel)
            selectedModel = newModel
            
            messageText.text = "Tap on a surface to place ${modelName.replace(".glb", "")}"
        } catch (e: Exception) {
            Log.e(TAG, "Error loading model: ${e.message}")
            Toast.makeText(this, "Failed to load model", Toast.LENGTH_SHORT).show()
        }
    }

    private fun initializeArSession() {
        try {
            // ARCore initialization code would go here
            messageText.text = "AR session ready. Select a model and tap to place."
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing AR: ${e.message}")
            messageText.text = "AR not supported: ${e.message}"
        }
    }

    private fun resetScene() {
        placedModels.clear()
        selectedModel = null
        messageText.text = "Scene reset. Select a model to place."
    }
    
    private fun showHelpDialog() {
        AlertDialog.Builder(this)
            .setTitle("AR Help")
            .setMessage(
                "• Select a model from the bottom bar\n" +
                "• Tap the + button to add it\n" +
                "• Tap on a surface to place\n" +
                "• Long press to select/modify placed models\n" +
                "• Use the reset button to clear all models\n" +
                "• Camera button takes a screenshot"
            )
            .setPositiveButton("OK", null)
            .show()
    }
    
    private fun captureArScene() {
        // Screenshot capturing logic would go here
        Toast.makeText(this, "Screenshot saved", Toast.LENGTH_SHORT).show()
    }
    
    // Inner class to represent a 3D model in AR scene
    inner class ArModel(val fileName: String) {
        var scale = 0.5f
        var rotationDegrees = 0f
        
        // Additional AR model properties and methods would be implemented here
    }
} 