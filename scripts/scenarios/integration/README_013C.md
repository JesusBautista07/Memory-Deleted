# Ticket 013C — Integración del Sistema de Escenarios

Esta carpeta contiene **únicamente archivos nuevos**. Ningún archivo
existente del proyecto fue modificado, editado, reemplazado ni movido.

## Arquitectura

```
SceneManager (existente, sin cambios)
      │  señales (scene_loaded, scene_changed, scene_reset, ...)
      ▼
ScenarioEventBus  ← único punto que conoce a SceneManager
      │  señales propias + señal genérica `scenario_event`
      ▼
ScenarioIntegrationBridge (clase base, Template Method)
      │
      ├── AudioScenarioBridge        → AudioManager      (grupo "audio_manager")
      ├── AmbientScenarioBridge      → AmbientManager     (grupo "ambient_manager")
      ├── AIScenarioBridge           → AIController(es)   (grupo "ai_controller")
      ├── EventsScenarioBridge       → EventManager       (grupo "event_manager")
      ├── SaveScenarioBridge         → SaveManager        (autoload o grupo "save_manager")
      ├── DocumentsScenarioBridge    → DocumentManager    (grupo "document_manager")
      ├── UIScenarioBridge           → LoadingScreen      (grupo "loading_screen")
      └── GroupNotifyScenarioBridge  → cualquier grupo de nodos (Objetos, Puertas,
                                        Puzzles, Cinemáticas...), configurable con
                                        `target_group` (p. ej. "saveable_objects",
                                        "saveable_doors", "saveable_puzzles",
                                        "cinematic_manager")
```

Ningún sistema (Audio, Ambientación, IA, Eventos, Guardado, Objetos,
Puertas, Puzzles, Documentos, UI) depende de `SceneManager`. Todos
dependen únicamente de `ScenarioEventBus`, que es el único punto
desacoplado que sabe que `SceneManager` existe.

Añadir una integración nueva en el futuro (por ejemplo, Cinemáticas
cuando exista un `CinematicManager` propio) solo requiere crear una
nueva subclase de `ScenarioIntegrationBridge`: nunca hace falta tocar
`ScenarioEventBus`, `SceneManager` ni ningún bridge existente
(principio Open/Closed).

## Cómo activarlo en el editor (no requiere editar ningún script)

1. Añadir un nodo `Node` con el script `scenario_event_bus.gd` en
   algún punto del árbol accesible (por ejemplo, junto al nodo que
   tenga `scene_manager.gd`).
2. Añadir un nodo `Node` por cada bridge que se quiera activar, con el
   script correspondiente (`audio_scenario_bridge.gd`,
   `ambient_scenario_bridge.gd`, etc.).
3. Para `GroupNotifyScenarioBridge`, asignar la propiedad exportada
   `target_group` al grupo que se quiera notificar.
4. Asegurarse (vía el panel de grupos del editor) de que los nodos que
   deban reaccionar a los escenarios pertenezcan al grupo que su
   bridge espera (por ejemplo, los `AIController` que deban reaccionar
   a `ai_profile` deben añadirse al grupo `"ai_controller"`).

No hace falta cablear señales a mano ni escribir código adicional: el
bus y los bridges se localizan entre sí por grupo en `_ready()`.
