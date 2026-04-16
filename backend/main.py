from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.database import engine, Base
from app.routers import auth, quran, prayer

# Create database tables
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Misbah API",
    description="Kuran ve Namaz Vakitleri API'si",
    version="1.0.0"
)

# CORS configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/api/v1")
app.include_router(quran.router, prefix="/api/v1")
app.include_router(prayer.router, prefix="/api/v1")

@app.get("/")
def root():
    return {
        "message": "Misbah API",
        "version": "1.0.0",
        "docs": "/docs"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}
