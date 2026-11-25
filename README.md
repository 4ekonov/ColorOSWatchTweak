# ColorOSCC 1.2 — Центр управления ColorOS 16 для iOS 15–17 (rootless)

Сборка: `make package FINALPACKAGE=1` или GitHub Actions (Actions → Artifacts).
Нужен preferenceloader. Настройки: Настройки → ColorOSCC.

Жест: свайп вниз от правой половины верхнего края — шторка с кнопками, от левой — стандартные уведомления.
Нижний жест стокового ЦУ отключается (переключатель в настройках). Нужен респринг.
Диагностика: /var/mobile/Documents/OPCC_methods.txt (методы системных классов) и OPCC_gestures.txt (найденные системные жесты шторки уведомлений).
