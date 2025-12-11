
# ix_generators – Plugin completo v5.3 (Helix / Garry's Mod)

**Novedades v5.3:**
- **Persistencia de enlaces** entre equipos (guardado por mapa usando `ix.data`).
- **Cables físicos** (rope) entre generador ↔ consumidor al crear/eliminar enlaces.
- **Lámpara con luz**: emite **DynamicLight** cuando está **encendida** y con **tensión**.

Mantiene: SWEP de conexión, gauges en arco superior, garrafa consumible, paneles y fix de spawn.

## Instalación
1. Copia `ix_generators/` en tu *schema* Helix:
   ```
   garrysmod/gamemodes/<tu_schema>/plugins/ix_generators/
   ```
2. Reinicia el servidor.

## Uso
- Equipar **Herramientas de conexión** → recibes `weapon_ix_linktool`.
- SWEP:
  - **Primario**: seleccionar **origen** y **destino** (`ix_power_link_pick`).
  - **Secundario**: `ix_power_link_clear` (borra enlaces del generador apuntado).
- La **lámpara** emitirá luz si está **encendida** y recibe **corriente** vía enlace.

Licencia: CC0-1.0.
