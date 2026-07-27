-- ~/.config/hypr/hyprland.lua

-- =========================================================================
-- Nisfere Shell - Master Hyprland Configuration (Lua API)
-- =========================================================================

-- Σύστημα Ασφαλούς Φόρτωσης (Safe Loader)
-- Χρησιμοποιούμε pcall (protected call) ώστε αν ένα module έχει συντακτικό λάθος, 
-- να καταγράφεται στο log χωρίς να κρασάρει το υπόλοιπο Hyprland.
local function load_module(module_name)
    local status, err = pcall(require, module_name)
    if not status then
        print("[Nisfere Error] Αποτυχία φόρτωσης: " .. module_name)
        print("[Λεπτομέρειες]: " .. err)
        -- Προαιρετικά: Εδώ θα μπορούσαμε στο μέλλον να καλούμε το notification daemon μας
        -- για να σου πετάει popup στην οθόνη ότι "Το αρχείο X έχει λάθος!"
    end
end

-- =========================================================================
-- Σειρά Φόρτωσης (Load Order)
-- Η σειρά ΕΧΕΙ ΣΗΜΑΣΙΑ. Το Environment πρέπει να μπει πρώτο, τα Autostarts τελευταία.
-- =========================================================================

-- 1. Περιβάλλον (Πρέπει να φορτωθεί πριν ξεκινήσει το Wayland να σχεδιάζει)
load_module("modules.environment")

-- 2. Μεταβλητές (Το αρχείο που φτιάχνει ο Python ThemeManager μας)
load_module("modules.variables")

-- [Σημείωση]: Αν στο μέλλον φτιάξεις αρχείο για τις οθόνες, βάλε το εδώ!
-- load_module("modules.monitors")

-- 3. Πυρήνας (Core Settings)
load_module("modules.input")
load_module("modules.general")
load_module("modules.misc")

-- 4. Εμφάνιση & Κίνηση (Look & Feel)
load_module("modules.decoration")
load_module("modules.animations")
load_module("modules.group")
load_module("modules.gestures")

-- 5. Κανόνες Παραθύρων (Window Rules)
load_module("modules.windowrules")

-- 6. Συντομεύσεις Πληκτρολογίου (Keybinds)
load_module("modules.keybinds")

-- 7. Εκκίνηση Εφαρμογών (Autostart)
-- Μπαίνει πάντα στο τέλος, ώστε όταν τρέξουν τα προγράμματα (π.χ. το Quickshell), 
-- το Hyprland να έχει ήδη φορτώσει τα χρώματα, τα rules και το περιβάλλον.
load_module("modules.autostart")