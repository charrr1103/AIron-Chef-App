from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
from typing import List
import numpy as np
from PIL import Image
import io

app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class YOLOModel:
    def __init__(self):
        # TODO: Load your trained YOLO model here
        pass

    async def detect_ingredients(self, image: Image.Image) -> List[dict]:
        # TODO: Implement actual YOLO detection
        # This is just a placeholder that returns dummy results
        return [
            {"name": "Mackerel fish", "confidence": 0.95},
            {"name": "Shiitake mushroom", "confidence": 0.87},
            {"name": "Cabbage", "confidence": 0.92}
        ]

# Initialize the YOLO model
model = YOLOModel()

@app.post("/detect")
async def detect_ingredients(file: UploadFile = File(...)):
    try:
        # Read and process the image
        contents = await file.read()
        image = Image.open(io.BytesIO(contents))
        
        # Perform ingredient detection
        results = await model.detect_ingredients(image)
        
        return {
            "success": True,
            "detected_ingredients": results
        }
    except Exception as e:
        return {
            "success": False,
            "error": str(e)
        }

if __name__ == "__main__":
    uvicorn.run("model:app", host="0.0.0.0", port=8000, reload=True) 