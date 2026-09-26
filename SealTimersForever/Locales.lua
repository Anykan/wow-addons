local _, ns = ...

-- Ingles por defecto: cualquier clave sin traducir cae aqui.
local L = {
    TITLE = "Seal Timers",
    DRAG_HINT = "Drag to move",
    LOCK = "Lock position",
    LOCK_TOOLTIP = "Unlock to drag the seal icons anywhere on the screen.",
    SIZE = "Size",
    SIZE_TOOLTIP = "Size of the seal icons.",
    BAR_WIDTH = "Bar width",
    BAR_WIDTH_TOOLTIP = "Width of the timer bar under the icon, independent of its size. Set it wide for a long bar.",
    SHOW_ICON = "Show icon",
    SHOW_ICON_TOOLTIP = "Show the seal icon with its circular timer swipe.",
    SHOW_BAR = "Show bar",
    SHOW_BAR_TOOLTIP = "Show the timer bar.",
    BLIZZ_STYLE = "Game cast bar style",
    BLIZZ_STYLE_TOOLTIP = "Draw the timer bar like the game's own cast bar (frame, background and fill). Turn it off for the plain colored bar; the bar color (/stf color) only applies then.",
    CHECK_BLIZZ_OK = "Cast bar style: the game's cast bar textures were found.",
    CHECK_BLIZZ_MISSING = "Cast bar style: the game's cast bar textures were NOT found, the plain bar is used.",
    CHECK_HEADER = "Your seals in combat:",
    CHECK_OPEN = "%s: readable, exact time",
    CHECK_SECRET = "%s: secret aura, tracked by its cast with the last duration seen (%s)",
    CHECK_CAST_SECRET = "%s: even its cast is secret, it cannot be tracked in combat",
    NOT_SEEN = "not seen yet: cast it once out of combat",
    CHECK_NONE = "No seals in your spellbook yet.",
    DEBUG_ON = "debug on: every seal cast and aura change is written to the chat.",
    DEBUG_OFF = "debug off.",
    RESET_DONE = "learned durations cleared: cast each seal once out of combat.",
}

local locale = GetLocale()
if locale == "esES" or locale == "esMX" then
    L.TITLE = "Temporizador de sellos"
    L.DRAG_HINT = "Arrastra para mover"
    L.LOCK = "Bloquear posición"
    L.LOCK_TOOLTIP = "Desbloquéalo para arrastrar los iconos de los sellos a cualquier parte de la pantalla."
    L.SIZE = "Tamaño"
    L.SIZE_TOOLTIP = "Tamaño de los iconos de los sellos."
    L.BAR_WIDTH = "Ancho de la barra"
    L.BAR_WIDTH_TOOLTIP = "Ancho de la barra de tiempo bajo el icono, independiente de su tamaño. Ponlo alto para una barra larga."
    L.SHOW_ICON = "Mostrar icono"
    L.SHOW_ICON_TOOLTIP = "Muestra el icono del sello con su barrido circular de tiempo."
    L.SHOW_BAR = "Mostrar barra"
    L.SHOW_BAR_TOOLTIP = "Muestra la barra de tiempo."
    L.BLIZZ_STYLE = "Estilo de la barra de lanzamiento"
    L.BLIZZ_STYLE_TOOLTIP = "Dibuja la barra de tiempo como la barra de lanzamiento del juego (marco, fondo y relleno). Desactívalo para la barra lisa de color; el color de la barra (/stf color) solo se aplica entonces."
    L.CHECK_BLIZZ_OK = "Estilo de barra: se encontraron las texturas de la barra de lanzamiento del juego."
    L.CHECK_BLIZZ_MISSING = "Estilo de barra: NO se encontraron las texturas de la barra de lanzamiento del juego, se usa la barra lisa."
    L.CHECK_HEADER = "Tus sellos en combate:"
    L.CHECK_OPEN = "%s: se lee, tiempo exacto"
    L.CHECK_SECRET = "%s: aura secreta, se sigue por su lanzamiento con la última duración vista (%s)"
    L.CHECK_CAST_SECRET = "%s: hasta su lanzamiento es secreto, no se puede seguir en combate"
    L.NOT_SEEN = "aún no vista: lánzalo una vez fuera de combate"
    L.CHECK_NONE = "Todavía no tienes sellos en el libro de hechizos."
    L.DEBUG_ON = "depuración activada: cada lanzamiento de sello y cambio de auras se escribe en el chat."
    L.DEBUG_OFF = "depuración desactivada."
    L.RESET_DONE = "duraciones aprendidas borradas: lanza cada sello una vez fuera de combate."
end

ns.L = L
