# ML - UNO Vision

Dieses Verzeichnis enthält die Machine Learning Modelle und Notebooks für die Kartenerkennung.

---

## Modelle

| Datei | Typ | Beschreibung | Accuracy | Grösse |
|---|---|---|---|---|
| `uno_model.tflite` | CNN float32 | Einzelkarten-Erkennung | 99.9% | ~250 KB |
| `uno_model_quantized.tflite` | CNN int8 | Einzelkarten-Erkennung (optimiert) | ~99.4% | ~65 KB |
| `yolo_float32.tflite` | YOLOv8n float32 | Mehrere Karten gleichzeitig | 99% mAP50 | ~12 MB |
| `yolo_float16.tflite` | YOLOv8n float16 | Mehrere Karten gleichzeitig (optimiert) | 99% mAP50 | ~6 MB |

> Für die App wird `yolo_float16.tflite` empfohlen – kleiner und schneller auf Mobilgeräten.

---

## Wann welches Modell verwenden?

| Szenario | Modell | Begründung |
|---|---|---|
| Einzelne Karte flach auf dem Tisch | `uno_model_quantized.tflite` | Schneller, kleiner, reicht für eine Karte |
| Fächerförmige Hand (mehrere Karten) | `yolo_float16.tflite` | Erkennt mehrere Karten gleichzeitig mit Bounding Boxes |
| **App (empfohlen)** | `yolo_float16.tflite` | Deckt beide Szenarien ab |

---

## Modell-Eingabe / Ausgabe

### CNN (`uno_model.tflite` / `uno_model_quantized.tflite`)

| | Wert |
|---|---|
| **Input Shape** | `(1, 128, 128, 3)` |
| **Input Format** | RGB, normalisiert 0.0–1.0 |
| **Output Shape** | `(1, 15)` – Wahrscheinlichkeiten pro Klasse |
| **Verwendung** | Einzelnes, bereits ausgeschnittenes Kartenbild |

**Vorbereitung in Flutter:**
```
1. Foto aufnehmen
2. Auf 128x128 skalieren
3. Pixel durch 255 dividieren (Normalisierung)
4. Als Float32 Array übergeben
5. Index mit höchster Wahrscheinlichkeit = Klasse
```

---

### YOLO (`yolo_float32.tflite` / `yolo_float16.tflite`)

| | Wert |
|---|---|
| **Input Shape** | `(1, 416, 416, 3)` |
| **Input Format** | RGB, normalisiert 0.0–1.0 |
| **Output** | Bounding Boxes + Klassen + Konfidenz |
| **Verwendung** | Foto der gesamten Hand (mehrere Karten) |

**Vorbereitung in Flutter:**
```
1. Foto aufnehmen
2. Auf 416x416 skalieren
3. Pixel durch 255 dividieren (Normalisierung)
4. Als Float32 Array übergeben
5. Output parsen: [x, y, w, h, konfidenz, klasse0..klasse14]
6. NMS (Non-Maximum Suppression) anwenden → Duplikate entfernen
7. Klassen mit Konfidenz > 0.5 verwenden
```

**Wichtig:** Das Dataset wurde mit `416x416` trainiert – andere Grössen reduzieren die Genauigkeit!

---

## Label Mapping

YOLO gibt Klassen **alphabetisch sortiert** zurück (nicht nach Kartenwert):

| Klasse | Karte | Punkte (Classic) | Punkte (Golf) |
|---|---|---|---|
| 0 | Zahlenkarte 0 | 0 | 0 |
| 1 | Zahlenkarte 1 | 1 | 1 |
| 2 | Zahlenkarte 10 | 10 | 10 |
| 3 | Zahlenkarte 11... | | |

> ⚠️ Achtung: Die Klassen entsprechen **nicht** direkt den Kartenwerten!
> Klasse 2 = Karte "10" weil alphabetisch "10" vor "2" kommt.

**Vollständiges Mapping:**

| Klasse | Karte | Punkte |
|---|---|---|
| 0 | 0 | 0 |
| 1 | 1 | 1 |
| 2 | 2 | 2 |
| 3 | 3 | 3 |
| 4 | 4 | 4 |
| 5 | 5 | 5 |
| 6 | 6 | 6 |
| 7 | 7 | 7 |
| 8 | 8 | 8 |
| 9 | 9 | 9 |
| 10 | +4 Wild | 50 |
| 11 | +2 | 20 |
| 12 | Seitenwechsel (Reverse) | 20 |
| 13 | Überspringen (Skip) | 20 |
| 14 | Farbwünschen (Wild) | 50 |

**In Flutter als Map:**
```dart
const Map<int, int> labelToPoints = {
  0: 0,   // 0
  1: 1,   // 1
  2: 2,   // 2
  3: 3,   // 3
  4: 4,   // 4
  5: 5,   // 5
  6: 6,   // 6
  7: 7,   // 7
  8: 8,   // 8
  9: 9,   // 9
  10: 50, // +4 Wild
  11: 20, // +2
  12: 20, // Reverse
  13: 20, // Skip
  14: 50, // Wild
};
```

---

## Notebooks

| Datei | Beschreibung |
|---|---|
| `notebooks/UNO_KI.ipynb` | CNN Training – Grundlagen, Datenvorbereitung, Training, Export |
| `notebooks/UNO_YOLO.ipynb` | YOLO Training – Object Detection, Fine-tuning, Export |

---

## Training reproduzieren

### Voraussetzungen
- Google Colab (kostenlos, GPU empfohlen – T4 aktivieren!)
- Roboflow Account (kostenlos)
- Roboflow API Key (in Colab als Secret speichern unter `KEY_ROBOFLOW`)

### CNN Training
1. `notebooks/UNO_KI.ipynb` in Google Colab öffnen
2. Roboflow API Key als Secret setzen
3. T4 GPU aktivieren (Runtime → Change runtime type → T4 GPU)
4. Alle Zellen ausführen
5. Modell wird exportiert als:
   - `uno_model.tflite` (float32)
   - `uno_model_quantized.tflite` (int8)

### YOLO Training
1. `notebooks/UNO_YOLO.ipynb` in Google Colab öffnen
2. Roboflow API Key als Secret setzen
3. T4 GPU aktivieren
4. Alle Zellen ausführen
5. Modell wird exportiert als:
   - `best_float32.tflite`
   - `best_float16.tflite`

### Trainingszeiten (mit T4 GPU)
| Modell | Epochs | Zeit |
|---|---|---|
| CNN | 10 | ~8 Minuten |
| YOLOv8n | 5 | ~25 Minuten |

---

## Dataset

[UNO Cards Dataset](https://universe.roboflow.com/joseph-nelson/uno-cards) von Adam Crawshaw via Roboflow.

| | |
|---|---|
| Quellbilder | 8'992 |
| Bilder nach Augmentation | 21'582 |
| Auflösung | 416x416 px |
| Klassen | 15 |
| Lizenz | MIT |

**Augmentierungen im Dataset:**
- Zufälliger Crop (0–20%)
- Rotation (±3°)
- Helligkeit (±25%)