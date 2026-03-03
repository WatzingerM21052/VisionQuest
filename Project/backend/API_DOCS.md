# VisionQuest API Dokumentation

## 🔐 Authentication

Alle geschützten Endpoints benötigen einen JWT-Token im Authorization-Header:
```
Authorization: Bearer <your_jwt_token>
```

---

## 📝 API Endpoints

### **Authentication**

#### POST `/api/auth/register`
Neuen User registrieren.

**Request Body:**
```json
{
  "username": "maxmuster",
  "email": "max@example.com",
  "password": "geheim123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Registrierung erfolgreich",
  "data": {
    "user": {
      "id": 1,
      "username": "maxmuster",
      "email": "max@example.com"
    },
    "token": "eyJhbGciOiJIUzI1..."
  }
}
```

---

#### POST `/api/auth/login`
User-Login.

**Request Body:**
```json
{
  "email": "max@example.com",
  "password": "geheim123"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login erfolgreich",
  "data": {
    "user": {
      "id": 1,
      "username": "maxmuster",
      "email": "max@example.com",
      "level": 1,
      "xp": 0
    },
    "token": "eyJhbGciOiJIUzI1..."
  }
}
```

---

### **Users**

#### GET `/api/users/me` 🔐
Aktuellen User abrufen.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "username": "maxmuster",
    "email": "max@example.com",
    "level": 5,
    "xp": 4500,
    "streak_days": 7,
    "theme": "dark",
    "total_quests_completed": 12,
    "total_scans": 45
  }
}
```

---

#### PUT `/api/users/me` 🔐
User-Profil aktualisieren.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "username": "neuer_name",
  "theme": "ocean",
  "xp": 5000
}
```

**Response:**
```json
{
  "success": true,
  "message": "User erfolgreich aktualisiert"
}
```

---

#### DELETE `/api/users/me` 🔐
User-Account löschen.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "User erfolgreich gelöscht"
}
```

---

### **Quests**

#### POST `/api/quests` 🔐
Neue Quest erstellen.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "title": "Finde einen Baum",
  "description": "Scanne einen Baum in der Natur",
  "category": "Natur",
  "difficulty": "easy",
  "xp_reward": 100
}
```

**Response:**
```json
{
  "success": true,
  "message": "Quest erfolgreich erstellt",
  "data": {
    "id": 5,
    "user_id": 1,
    "title": "Finde einen Baum"
  }
}
```

---

#### GET `/api/quests` 🔐
Alle Quests des Users abrufen.

**Headers:**
```
Authorization: Bearer <token>
```

**Query Parameters:**
- `status` (optional): `active`, `completed`, `failed`

**Beispiel:**
```
GET /api/quests?status=active
```

**Response:**
```json
{
  "success": true,
  "count": 3,
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "title": "Finde einen Baum",
      "description": "Scanne einen Baum in der Natur",
      "category": "Natur",
      "difficulty": "easy",
      "xp_reward": 100,
      "status": "active",
      "created_at": "2026-02-25T10:30:00.000Z"
    }
  ]
}
```

---

#### GET `/api/quests/:id` 🔐
Einzelne Quest abrufen.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": 1,
    "user_id": 1,
    "title": "Finde einen Baum",
    "description": "Scanne einen Baum in der Natur",
    "category": "Natur",
    "difficulty": "easy",
    "xp_reward": 100,
    "status": "active",
    "created_at": "2026-02-25T10:30:00.000Z"
  }
}
```

---

#### PUT `/api/quests/:id` 🔐
Quest aktualisieren.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "title": "Neuer Titel",
  "status": "completed"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Quest erfolgreich aktualisiert"
}
```

---

#### POST `/api/quests/:id/complete` 🔐
Quest abschließen (gibt XP).

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "detected_object": "tree"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Quest abgeschlossen!",
  "data": {
    "xp_earned": 100,
    "new_xp": 4600,
    "new_level": 5
  }
}
```

---

#### DELETE `/api/quests/:id` 🔐
Quest löschen.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Quest erfolgreich gelöscht"
}
```

---

### **Vision Detection**

#### POST `/api/vision/detect` 🔐
Objekterkennung mit YOLO v11 oder COCO-SSD.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
x-vision-model: yolo | coco        (optional, default: yolo)
x-vision-focus: strict | balanced  (optional, default: strict)
```

**Request Body (multipart/form-data):**
```
image: [Binary Image File]
focusCircle: {
  "x": 640,
  "y": 360,
  "radius": 200
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "label": "cell phone",
    "confidence": 0.92,
    "model": "yolo",
    "focusMode": "strict",
    "bbox": {
      "x": 580,
      "y": 300,
      "width": 120,
      "height": 120
    }
  }
}
```

**Detection Models:**
- **yolo**: YOLO v11 via Python Subprocess (höhere Genauigkeit)
- **coco**: COCO-SSD via TensorFlow.js (schneller, kein Python nötig)

**Focus Modes:**
- **strict**: 1.35x Context-Scale (minimal Hintergrund)
- **balanced**: 1.85x Context-Scale (mehr Kontext für teilweise sichtbare Objekte)

**Circle-Intersection Filtering:**
Nur Objekte die den focusCircle schneiden werden zurückgegeben.

**Error Handling:**
- Falls YOLO fehlschlägt (Python nicht verfügbar): Automatischer Fallback zu COCO-SSD
- Falls kein Objekt erkannt: `{"success": false, "message": "Kein Objekt erkannt"}`

---

### **Stats**

#### PUT `/api/stats` 🔐
User-Stats aktualisieren.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "total_scans": 50,
  "longest_streak": 10,
  "favorite_category": "Natur"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Stats aktualisiert"
}
```

---

## ⚠️ Error Responses

Bei Fehlern gibt der Server folgendes Format zurück:

```json
{
  "success": false,
  "message": "Fehlerbeschreibung"
}
```

### Häufige Status-Codes:
- **200**: Erfolg
- **201**: Erstellt
- **400**: Bad Request (ungültige Eingabe)
- **401**: Unauthorized (kein Token)
- **403**: Forbidden (Token ungültig)
- **404**: Not Found
- **500**: Server Error

---

## 🧪 Testing mit curl

### Registrierung:
```bash
curl -X POST http://localhost:5000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser","email":"test@example.com","password":"test123"}'
```

### Login:
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"test123"}'
```

### Quest erstellen (mit Token):
```bash
curl -X POST http://localhost:5000/api/quests \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -d '{"title":"Test Quest","description":"Test","category":"Test","difficulty":"easy","xp_reward":50}'
```

### Quests abrufen:
```bash
curl -X GET http://localhost:5000/api/quests \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

---

**Version:** 2.0.0  
**Letzte Aktualisierung:** 03.03.2026
