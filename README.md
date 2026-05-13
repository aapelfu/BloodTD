# 🌌 BloodTD:

**BloodTD** es un juego de Tower Defense de alta calidad desarrollado íntegramente en **Godot 4**. Sumérgete en un universo de ciencia ficción oscura donde tu misión es defender tu base recolectando la sangre de invasores cósmicos para construir y mejorar tus defensas.

---

## 🎮 Resumen del Juego

En una galaxia donde la sangre es el recurso más valioso, asumes el papel de un Comandante defendiendo un puesto vital. Coloca torres estratégicamente a lo largo de la ruta orbital para eliminar las oleadas de enemigos. Cada enemigo derrotado proporciona la "Esencia de Sangre" necesaria para expandir tu red defensiva.

### 🚀 Características Principales

*   **Sistema de Oleadas Dinámico**: 15 oleadas de dificultad progresiva con enemigos cósmicos únicos.
*   **Estrategia Tower Defense**: Múltiples tipos de torres con diferentes perfiles de daño y cadencia.
*   **Audio Retro Procedural**: Música de fondo y efectos sintetizados en tiempo real para una atmósfera de arcade clásico.
*   **Visuales Interactivos**: Previsualización de torres (fantasmas), texto de combate flotante y sacudidas de cámara cinemáticas.
*   **Interfaz Profesional (UI/UX)**: HUD completo, barras de vida animadas y sistema de menús integrado.

---

## 🛠 Implementación Técnica

Este proyecto sigue los estándares profesionales y las mejores prácticas de Godot 4:

### 📐 Arquitectura
*   **Lógica de Estados**: Separación limpia entre los estados del juego (Menú, Jugando, Pausa, Game Over).
*   **Comunicación por Señales**: Uso extensivo de señales para una interacción desacoplada entre torres, enemigos y la interfaz.
*   **Optimización de Rendimiento**: Algoritmos eficientes de detección de objetivos mediante áreas de colisión y geometría de segmentos.
*   **Tipado Estático**: Todos los archivos GDScript utilizan tipado fuerte para mejorar el rendimiento y evitar errores en tiempo de ejecución.

### 🔊 Audio Procedural
El `AudioManager` genera flujos de audio en tiempo real utilizando `AudioStreamGeneratorPlayback`, creando una atmósfera retro única y no repetitiva.

### 🎨 Efectos Visuales
*   **Sistema de Tweens**: Animaciones fluidas para el disparo de torres y transiciones de la interfaz.
*   **Dibujo Dinámico**: La validez de la posición de las torres se calcula y renderiza en tiempo real mediante llamadas a `_draw()`.

---

## 🕹 Controles

| Acción | Control |
| :--- | :--- |
| **Mover Cazador** | `W`, `A`, `S`, `D` o Flechas |
| **Seleccionar Torre** | Clic en los iconos de la UI |
| **Colocar Torre** | `Clic Izquierdo` (Verde = Válido, Rojo = Inválido) |
| **Cancelar Selección** | `Clic Derecho` |
| **Pausar Juego** | `ESC` |

---

## 📦 Requisitos

*   **Motor**: Godot 4.2+
*   **Plataformas**: Windows, macOS, Linux, Web

---

*Desarrollado con pasión para el proyecto BloodTD.*
